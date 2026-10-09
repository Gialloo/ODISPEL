"use strict";

const WebSocket = require("ws");
const crypto = require("node:crypto");

const HOST = process.env.ODISPEL_SIGNALING_HOST || "127.0.0.1";
const PORT = Number(process.env.ODISPEL_SIGNALING_PORT || 9080);
const MAX_CLIENTS_PER_ROOM = 6;
const MAX_MESSAGE_BYTES = 64 * 1024;

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
  const roomId = clients.get(socket);
  if (!roomId) return;

  clients.delete(socket);
  const room = rooms.get(roomId);
  if (!room) return;

  room.delete(socket);

  for (const member of room) {
    send(member, { type: "peer_left", peer_id: socket.peerId });
  }

  if (room.size === 0) rooms.delete(roomId);
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

      let room = rooms.get(message.room_id);

      if (!room) {
        room = new Set();
        rooms.set(message.room_id, room);
      }

      if (room.size >= MAX_CLIENTS_PER_ROOM) {
        send(socket, { type: "error", code: "room_full" });
        return;
      }

      const existingPeers = [...room].map((peer) => peer.peerId);
      room.add(socket);
      clients.set(socket, message.room_id);

      send(socket, {
        type: "joined",
        room_id: message.room_id,
        peer_id: socket.peerId,
        peers: existingPeers,
      });

      for (const peer of room) {
        if (peer !== socket) {
          send(peer, { type: "peer_joined", peer_id: socket.peerId });
        }
      }

      return;
    }

    const roomId = clients.get(socket);
    const room = roomId ? rooms.get(roomId) : null;

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

    const target = [...room].find(
      (peer) => peer.peerId === message.target_peer_id
    );

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

