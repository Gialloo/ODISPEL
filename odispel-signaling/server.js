"use strict";

const WebSocket = require("ws");
const crypto = require("node:crypto");

const HOST = process.env.ODISPEL_SIGNALING_HOST || "127.0.0.1";
const PORT = Number(process.env.ODISPEL_SIGNALING_PORT || 9080);
const MAX_CLIENTS_PER_ROOM = 6;
const MAX_MESSAGE_BYTES = 64 * 1024;

// rooms:   roomId -> { host: socket, clients: Set<socket> }
// clients: socket  -> { roomId, role }
const rooms = new Map();
const clients = new Map();

const server = new WebSocket.Server({
  host: HOST,
  port: PORT,
  maxPayload: MAX_MESSAGE_BYTES,
});

function send(socket, message) {
  if (socket.readyState === WebSocket.OPEN) {
    socket.send(JSON.stringify(message));
  }
}

function leaveRoom(socket) {
  const info = clients.get(socket);
  if (!info) return;

  clients.delete(socket);
  const room = rooms.get(info.roomId);
  if (!room) return;

  if (info.role === "host") {
    // Senza host la stanza non ha senso: si chiude e i client sono liberi
    // di entrare in un'altra stanza (o di riprovare più tardi).
    rooms.delete(info.roomId);

    for (const member of room.clients) {
      clients.delete(member);
      send(member, { type: "room_closed", reason: "host_left" });
    }

    return;
  }

  room.clients.delete(socket);
  send(room.host, { type: "peer_left", peer_id: socket.peerId });
}

function handleJoin(socket, message) {
  if (clients.has(socket)) {
    send(socket, { type: "error", code: "already_in_room" });
    return;
  }

  if (
    typeof message.room_id !== "string" ||
    !/^[a-zA-Z0-9_-]{1,48}$/.test(message.room_id)
  ) {
    send(socket, { type: "error", code: "invalid_room_id" });
    return;
  }

  if (message.role !== "host" && message.role !== "client") {
    send(socket, { type: "error", code: "invalid_role" });
    return;
  }

  const roomId = message.room_id;

  if (message.role === "host") {
    if (rooms.has(roomId)) {
      send(socket, { type: "error", code: "room_taken" });
      return;
    }

    rooms.set(roomId, { host: socket, clients: new Set() });
    clients.set(socket, { roomId, role: "host" });

    send(socket, {
      type: "joined",
      room_id: roomId,
      role: "host",
      peer_id: socket.peerId,
      peers: [],
    });

    return;
  }

  const room = rooms.get(roomId);

  if (!room) {
    // Il client non entra nella stanza: può riprovare sullo stesso socket.
    send(socket, { type: "error", code: "no_host" });
    return;
  }

  if (1 + room.clients.size >= MAX_CLIENTS_PER_ROOM) {
    send(socket, { type: "error", code: "room_full" });
    return;
  }

  room.clients.add(socket);
  clients.set(socket, { roomId, role: "client" });

  send(socket, {
    type: "joined",
    room_id: roomId,
    role: "client",
    peer_id: socket.peerId,
    host_peer_id: room.host.peerId,
    peers: [room.host.peerId],
  });

  send(room.host, { type: "peer_joined", peer_id: socket.peerId });
}

server.on("connection", (socket) => {
  socket.peerId = crypto.randomUUID();

  send(socket, { type: "connected", peer_id: socket.peerId });

  socket.on("message", (raw) => {
    let message;

    try {
      message = JSON.parse(raw.toString());
    } catch {
      send(socket, { type: "error", code: "invalid_json" });
      return;
    }

    if (!message || typeof message.type !== "string") {
      send(socket, { type: "error", code: "invalid_message" });
      return;
    }

    if (message.type === "join") {
      handleJoin(socket, message);
      return;
    }

    const info = clients.get(socket);
    const room = info ? rooms.get(info.roomId) : null;

    if (!room) {
      send(socket, { type: "error", code: "not_in_room" });
      return;
    }

    if (!["offer", "answer", "ice_candidate"].includes(message.type)) {
      send(socket, { type: "error", code: "unknown_type" });
      return;
    }

    if (
      typeof message.target_peer_id !== "string" ||
      message.target_peer_id === socket.peerId
    ) {
      send(socket, { type: "error", code: "invalid_target" });
      return;
    }

    let target = null;

    if (info.role === "client") {
      // I client parlano solo con l'host, mai tra loro.
      if (message.target_peer_id !== room.host.peerId) {
        send(socket, { type: "error", code: "invalid_target" });
        return;
      }

      target = room.host;
    } else {
      target = [...room.clients].find(
        (peer) => peer.peerId === message.target_peer_id
      );
    }

    if (!target) {
      send(socket, { type: "error", code: "target_not_found" });
      return;
    }

    send(target, {
      type: message.type,
      from_peer_id: socket.peerId,
      payload: message.payload ?? null,
    });
  });

  socket.on("close", () => leaveRoom(socket));
  socket.on("error", () => leaveRoom(socket));
});

server.on("listening", () => {
  console.log(`ODISPEL signaling in ascolto su ws://${HOST}:${PORT}`);
});

server.on("error", (error) => {
  console.error("Errore signaling:", error.message);
  process.exitCode = 1;
});