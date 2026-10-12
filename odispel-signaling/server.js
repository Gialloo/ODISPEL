"use strict";

const http = require("node:http");
const WebSocket = require("ws");
const crypto = require("node:crypto");

// In locale: 127.0.0.1:9080. Sul cloud (Render ecc.) la piattaforma imposta PORT:
// in quel caso ascoltiamo su 0.0.0.0 e usiamo quella porta.
const CLOUD_PORT = process.env.PORT;
const HOST =
  process.env.ODISPEL_SIGNALING_HOST || (CLOUD_PORT ? "0.0.0.0" : "127.0.0.1");
const PORT = Number(process.env.ODISPEL_SIGNALING_PORT || CLOUD_PORT || 9080);
const MAX_CLIENTS_PER_ROOM = 6;
const MAX_MESSAGE_BYTES = 64 * 1024;

// Limiti di sicurezza (tutti regolabili con variabili d'ambiente, utili nei test).
// MAX_ROOMS / MAX_CONNECTIONS: oltre, le nuove richieste ricevono un errore.
// RATE_LIMIT: massimo di messaggi per socket ogni RATE_WINDOW_MS; chi esagera
// viene scollegato. JOIN_TIMEOUT: chi non entra in una stanza viene chiuso.
// HEARTBEAT: ping periodico (tiene aperte le connessioni dietro ai proxy del
// cloud, che chiudono quelle inattive) e chiusura dei socket che non rispondono.
const MAX_ROOMS = Number(process.env.ODISPEL_MAX_ROOMS || 500);
const MAX_CONNECTIONS = Number(process.env.ODISPEL_MAX_CONNECTIONS || 2000);
const RATE_LIMIT = Number(process.env.ODISPEL_RATE_LIMIT || 120);
const RATE_WINDOW_MS = Number(process.env.ODISPEL_RATE_WINDOW_MS || 10000);
const JOIN_TIMEOUT_MS = Number(process.env.ODISPEL_JOIN_TIMEOUT_MS || 60000);
const HEARTBEAT_MS = Number(process.env.ODISPEL_HEARTBEAT_MS || 25000);

// rooms:   roomId -> { host: socket, clients: Set<socket> }
// clients: socket  -> { roomId, role }
const rooms = new Map();
const clients = new Map();

// Piccolo server HTTP: risponde "ok" a /health (serve a svegliare il server
// e ai controlli della piattaforma); le connessioni WebSocket passano da qui.
const httpServer = http.createServer((req, res) => {
  if (req.url === "/health" || req.url === "/") {
    res.writeHead(200, { "Content-Type": "text/plain" });
    res.end("ok");
    return;
  }

  if (req.url === "/stats") {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(
      JSON.stringify({
        rooms: rooms.size,
        connections: server.clients.size,
        max_rooms: MAX_ROOMS,
        max_connections: MAX_CONNECTIONS,
        uptime_s: Math.round(process.uptime()),
      })
    );
    return;
  }
  res.writeHead(404);
  res.end();
});

const server = new WebSocket.Server({
  server: httpServer,
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

    if (rooms.size >= MAX_ROOMS) {
      send(socket, { type: "error", code: "server_full" });
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

function startHeartbeat() {
  const timer = setInterval(() => {
    for (const socket of server.clients) {
      if (socket.isAlive === false) {
        socket.terminate();
        continue;
      }

      socket.isAlive = false;
      socket.ping();
    }
  }, HEARTBEAT_MS);

  timer.unref();
  return timer;
}

server.on("connection", (socket) => {
  if (server.clients.size > MAX_CONNECTIONS) {
    send(socket, { type: "error", code: "server_full" });
    socket.close(1013, "server_full");
    return;
  }

  socket.peerId = crypto.randomUUID();
  socket.isAlive = true;
  socket.on("pong", () => {
    socket.isAlive = true;
  });

  // Chi si collega e non entra mai in una stanza non deve occupare un posto.
  const joinTimer = setTimeout(() => {
    if (!clients.has(socket)) {
      send(socket, { type: "error", code: "join_timeout" });
      socket.close(1000, "join_timeout");
    }
  }, JOIN_TIMEOUT_MS);
  joinTimer.unref();
  socket.on("close", () => clearTimeout(joinTimer));

  let windowStart = Date.now();
  let windowCount = 0;

  send(socket, { type: "connected", peer_id: socket.peerId });

  socket.on("message", (raw) => {
    const now = Date.now();

    if (now - windowStart > RATE_WINDOW_MS) {
      windowStart = now;
      windowCount = 0;
    }

    windowCount += 1;

    if (windowCount > RATE_LIMIT) {
      send(socket, { type: "error", code: "rate_limited" });
      socket.close(1008, "rate_limited");
      return;
    }

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

httpServer.on("listening", () => {
  console.log(`ODISPEL signaling in ascolto su ws://${HOST}:${PORT}`);
});

httpServer.on("error", (error) => {
  console.error("Errore signaling:", error.message);
  process.exitCode = 1;
});

startHeartbeat();
httpServer.listen(PORT, HOST);

// Chiusura ordinata quando la piattaforma riavvia il servizio.
process.on("SIGTERM", () => {
  for (const socket of server.clients) socket.close(1001, "server_restart");
  httpServer.close(() => process.exit(0));
  setTimeout(() => process.exit(0), 3000).unref();
});

