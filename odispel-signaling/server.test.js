"use strict";

const { test, after, before } = require("node:test");
const assert = require("node:assert/strict");
const WebSocket = require("ws");
const { spawn } = require("node:child_process");
const path = require("node:path");

const HOST = "127.0.0.1";
const PORT = 19080;
const URL = `ws://${HOST}:${PORT}`;
const serverPath = path.join(__dirname, "server.js");

let serverProcess;

function waitForMessage(socket, predicate, timeoutMs = 3000) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      cleanup();
      reject(new Error("Timeout in attesa di un messaggio"));
    }, timeoutMs);

    function onMessage(raw) {
      let message;
      try {
        message = JSON.parse(raw.toString());
      } catch {
        return;
      }

      if (predicate(message)) {
        cleanup();
        resolve(message);
      }
    }

    function onClose() {
      cleanup();
      reject(new Error("Connessione chiusa prima del messaggio atteso"));
    }

    function cleanup() {
      clearTimeout(timer);
      socket.off("message", onMessage);
      socket.off("close", onClose);
    }

    socket.on("message", onMessage);
    socket.on("close", onClose);
  });
}

function connectClient() {
  return new Promise((resolve, reject) => {
    const socket = new WebSocket(URL);
    const timer = setTimeout(() => {
      socket.terminate();
      reject(new Error("Timeout di connessione al server di test"));
    }, 3000);

    socket.once("open", () => {
      clearTimeout(timer);
      resolve(socket);
    });

    socket.once("error", (error) => {
      clearTimeout(timer);
      reject(error);
    });
  });
}

function send(socket, message) {
  socket.send(JSON.stringify(message));
}

async function joinRoom(socket, roomId) {
  const joinedPromise = waitForMessage(
    socket,
    (message) => message.type === "joined"
  );

  send(socket, { type: "join", room_id: roomId });
  return joinedPromise;
}

async function closeClient(socket) {
  if (!socket || socket.readyState === WebSocket.CLOSED) return;

  await new Promise((resolve) => {
    const timer = setTimeout(() => {
      socket.terminate();
      resolve();
    }, 1000);

    socket.once("close", () => {
      clearTimeout(timer);
      resolve();
    });

    if (socket.readyState === WebSocket.CONNECTING) {
      socket.once("open", () => socket.close());
    } else {
      socket.close();
    }
  });
}

const clients = new Set();

async function newClient() {
  const socket = await connectClient();
  clients.add(socket);
  return socket;
}

before(async () => {
  serverProcess = spawn(
    process.execPath,
    [serverPath],
    {
      env: {
        ...process.env,
        ODISPEL_SIGNALING_HOST: HOST,
        ODISPEL_SIGNALING_PORT: String(PORT),
      },
      stdio: ["ignore", "pipe", "pipe"],
    }
  );

  let output = "";
  serverProcess.stdout.on("data", (chunk) => {
    output += chunk.toString();
  });
  serverProcess.stderr.on("data", (chunk) => {
    output += chunk.toString();
  });

  const deadline = Date.now() + 5000;

  while (Date.now() < deadline) {
    if (serverProcess.exitCode !== null) {
      throw new Error(`Server di test terminato: ${output}`);
    }

    try {
      const probe = await connectClient();
      await closeClient(probe);
      return;
    } catch {
      await new Promise((resolve) => setTimeout(resolve, 100));
    }
  }

  throw new Error(`Server di test non disponibile: ${output}`);
});

after(async () => {
  for (const client of clients) {
    await closeClient(client);
  }

  if (serverProcess && serverProcess.exitCode === null) {
    serverProcess.kill();
    await new Promise((resolve) => {
      serverProcess.once("exit", resolve);
      setTimeout(resolve, 1500);
    });
  }
});

test("due client possono entrare nella stessa stanza", async () => {
  const first = await newClient();
  const firstJoined = await joinRoom(first, "test-room");

  const second = await newClient();
  const peerJoined = waitForMessage(
    first,
    (message) => message.type === "peer_joined"
  );
  const secondJoined = await joinRoom(second, "test-room");

  assert.equal(firstJoined.type, "joined");
  assert.equal(secondJoined.type, "joined");
  assert.equal(secondJoined.peers.includes(firstJoined.peer_id), true);

  const notification = await peerJoined;
  assert.equal(notification.peer_id, secondJoined.peer_id);
});

test("il server rifiuta un identificativo stanza non valido", async () => {
  const client = await newClient();
  const errorPromise = waitForMessage(
    client,
    (message) => message.type === "error"
  );

  send(client, { type: "join", room_id: "stanza non valida!" });

  const error = await errorPromise;
  assert.equal(error.code, "invalid_room_id");
});

test("il server inoltra un'offerta al destinatario corretto", async () => {
  const first = await newClient();
  const firstJoined = await joinRoom(first, "relay-room");

  const second = await newClient();
  const secondJoined = await joinRoom(second, "relay-room");

  const offerPromise = waitForMessage(
    second,
    (message) => message.type === "offer"
  );

  send(first, {
    type: "offer",
    target_peer_id: secondJoined.peer_id,
    payload: { sdp: "offerta-di-test" },
  });

  const offer = await offerPromise;
  assert.equal(offer.from_peer_id, firstJoined.peer_id);
  assert.equal(offer.payload.sdp, "offerta-di-test");
});

test("il server rifiuta messaggi diversi da quelli consentiti", async () => {
  const client = await newClient();
  await joinRoom(client, "invalid-type-room");

  const errorPromise = waitForMessage(
    client,
    (message) => message.type === "error"
  );

  send(client, { type: "unexpected_message" });

  const error = await errorPromise;
  assert.equal(error.code, "unknown_type");
});
