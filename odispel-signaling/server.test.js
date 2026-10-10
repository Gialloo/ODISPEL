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

async function joinRoom(socket, roomId, role = "client") {
  const joinedPromise = waitForMessage(
    socket,
    (message) => message.type === "joined"
  );

  send(socket, { type: "join", room_id: roomId, role });
  return joinedPromise;
}

async function expectError(socket, action) {
  const errorPromise = waitForMessage(
    socket,
    (message) => message.type === "error"
  );

  action();
  return errorPromise;
}

// Verifica che NON arrivi un messaggio di un certo tipo entro un breve tempo.
async function expectNoMessage(socket, type, waitMs = 300) {
  let received = false;

  const onMessage = (raw) => {
    try {
      if (JSON.parse(raw.toString()).type === type) received = true;
    } catch {
      // ignorato
    }
  };

  socket.on("message", onMessage);
  await new Promise((resolve) => setTimeout(resolve, waitMs));
  socket.off("message", onMessage);

  assert.equal(received, false, `messaggio inatteso: ${type}`);
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

test("l'host crea la stanza e un client entra", async () => {
  const host = await newClient();
  const hostJoined = await joinRoom(host, "test-room", "host");

  assert.equal(hostJoined.role, "host");
  assert.deepEqual(hostJoined.peers, []);

  const peerJoined = waitForMessage(
    host,
    (message) => message.type === "peer_joined"
  );

  const client = await newClient();
  const clientJoined = await joinRoom(client, "test-room", "client");

  assert.equal(clientJoined.role, "client");
  assert.equal(clientJoined.host_peer_id, hostJoined.peer_id);
  assert.equal(clientJoined.peers.includes(hostJoined.peer_id), true);

  const notification = await peerJoined;
  assert.equal(notification.peer_id, clientJoined.peer_id);
});

test("il server rifiuta un identificativo stanza non valido", async () => {
  const client = await newClient();

  const error = await expectError(client, () =>
    send(client, { type: "join", room_id: "stanza non valida!", role: "host" })
  );

  assert.equal(error.code, "invalid_room_id");
});

test("il server rifiuta un ruolo mancante o non valido", async () => {
  const client = await newClient();

  const missing = await expectError(client, () =>
    send(client, { type: "join", room_id: "role-room" })
  );
  assert.equal(missing.code, "invalid_role");

  const wrong = await expectError(client, () =>
    send(client, { type: "join", room_id: "role-room", role: "admin" })
  );
  assert.equal(wrong.code, "invalid_role");
});

test("un client non può entrare se l'host non c'è, ma può riprovare", async () => {
  const client = await newClient();

  const error = await expectError(client, () =>
    send(client, { type: "join", room_id: "late-host-room", role: "client" })
  );
  assert.equal(error.code, "no_host");

  // L'host arriva dopo: la stanza non è stata bloccata dal client.
  const host = await newClient();
  const hostJoined = await joinRoom(host, "late-host-room", "host");
  assert.equal(hostJoined.role, "host");

  // Lo stesso socket del client può ora entrare.
  const clientJoined = await joinRoom(client, "late-host-room", "client");
  assert.equal(clientJoined.host_peer_id, hostJoined.peer_id);
});

test("una stanza ha un solo host", async () => {
  const first = await newClient();
  await joinRoom(first, "single-host-room", "host");

  const second = await newClient();
  const error = await expectError(second, () =>
    send(second, { type: "join", room_id: "single-host-room", role: "host" })
  );

  assert.equal(error.code, "room_taken");
});

test("il server inoltra offerta e risposta tra host e client", async () => {
  const host = await newClient();
  const hostJoined = await joinRoom(host, "relay-room", "host");

  const client = await newClient();
  const clientJoined = await joinRoom(client, "relay-room", "client");

  const offerPromise = waitForMessage(
    client,
    (message) => message.type === "offer"
  );

  send(host, {
    type: "offer",
    target_peer_id: clientJoined.peer_id,
    payload: { sdp: "offerta-di-test" },
  });

  const offer = await offerPromise;
  assert.equal(offer.from_peer_id, hostJoined.peer_id);
  assert.equal(offer.payload.sdp, "offerta-di-test");

  const answerPromise = waitForMessage(
    host,
    (message) => message.type === "answer"
  );

  send(client, {
    type: "answer",
    target_peer_id: hostJoined.peer_id,
    payload: { sdp: "risposta-di-test" },
  });

  const answer = await answerPromise;
  assert.equal(answer.from_peer_id, clientJoined.peer_id);
  assert.equal(answer.payload.sdp, "risposta-di-test");
});

test("i client non possono scambiarsi messaggi tra loro", async () => {
  const host = await newClient();
  await joinRoom(host, "isolated-room", "host");

  const first = await newClient();
  await joinRoom(first, "isolated-room", "client");

  const second = await newClient();
  const secondJoined = await joinRoom(second, "isolated-room", "client");

  const error = await expectError(first, () =>
    send(first, {
      type: "offer",
      target_peer_id: secondJoined.peer_id,
      payload: { sdp: "non-deve-arrivare" },
    })
  );

  assert.equal(error.code, "invalid_target");
});

test("i client non vedono gli ingressi degli altri client", async () => {
  const host = await newClient();
  await joinRoom(host, "quiet-room", "host");

  const first = await newClient();
  await joinRoom(first, "quiet-room", "client");

  const watching = expectNoMessage(first, "peer_joined");
  const second = await newClient();
  await joinRoom(second, "quiet-room", "client");
  await watching;
});

test("quando un client esce l'host riceve peer_left", async () => {
  const host = await newClient();
  await joinRoom(host, "leave-room", "host");

  const client = await newClient();
  const clientJoined = await joinRoom(client, "leave-room", "client");

  const left = waitForMessage(host, (message) => message.type === "peer_left");
  await closeClient(client);

  assert.equal((await left).peer_id, clientJoined.peer_id);
});

test("quando l'host esce la stanza si chiude e si può ricreare", async () => {
  const host = await newClient();
  await joinRoom(host, "closing-room", "host");

  const client = await newClient();
  await joinRoom(client, "closing-room", "client");

  const closed = waitForMessage(
    client,
    (message) => message.type === "room_closed"
  );
  await closeClient(host);

  assert.equal((await closed).reason, "host_left");

  // Un nuovo host può creare di nuovo la stanza con lo stesso nome...
  const newHost = await newClient();
  const newHostJoined = await joinRoom(newHost, "closing-room", "host");

  // ...e il vecchio client, liberato, può rientrare.
  const rejoined = await joinRoom(client, "closing-room", "client");
  assert.equal(rejoined.host_peer_id, newHostJoined.peer_id);
});

test("la stanza ha un massimo di 6 partecipanti", async () => {
  const host = await newClient();
  await joinRoom(host, "full-room", "host");

  for (let index = 0; index < 5; index += 1) {
    const client = await newClient();
    await joinRoom(client, "full-room", "client");
  }

  const extra = await newClient();
  const error = await expectError(extra, () =>
    send(extra, { type: "join", room_id: "full-room", role: "client" })
  );

  assert.equal(error.code, "room_full");
});

test("il server rifiuta messaggi diversi da quelli consentiti", async () => {
  const client = await newClient();
  await joinRoom(client, "invalid-type-room", "host");

  const error = await expectError(client, () =>
    send(client, { type: "unexpected_message" })
  );

  assert.equal(error.code, "unknown_type");
});

test("chi non è in una stanza non può inviare segnali", async () => {
  const client = await newClient();

  const error = await expectError(client, () =>
    send(client, { type: "offer", target_peer_id: "x", payload: {} })
  );

  assert.equal(error.code, "not_in_room");
});