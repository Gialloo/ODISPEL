"use strict";

// Limiti di sicurezza del server: stanze massime, frequenza dei messaggi,
// timeout di ingresso, statistiche, heartbeat.
const { test, after, before } = require("node:test");
const assert = require("node:assert/strict");
const WebSocket = require("ws");
const http = require("node:http");
const { spawn } = require("node:child_process");
const path = require("node:path");

const PORT = 19081;
const URL = `ws://127.0.0.1:${PORT}`;
let proc;

function wait(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

function connect() {
  return new Promise((resolve, reject) => {
    const s = new WebSocket(URL);
    s.messages = [];
    s.on("message", (raw) => s.messages.push(JSON.parse(raw.toString())));
    s.once("open", () => resolve(s));
    s.once("error", reject);
  });
}

async function nextOfType(s, type, ms = 2000) {
  const end = Date.now() + ms;
  while (Date.now() < end) {
    const i = s.messages.findIndex((m) => m.type === type);
    if (i >= 0) return s.messages.splice(i, 1)[0];
    await wait(20);
  }
  throw new Error("timeout " + type);
}

function getJson(p) {
  return new Promise((resolve, reject) => {
    http
      .get({ host: "127.0.0.1", port: PORT, path: p }, (res) => {
        let body = "";
        res.on("data", (c) => (body += c));
        res.on("end", () => resolve(JSON.parse(body)));
      })
      .on("error", reject);
  });
}

before(async () => {
  proc = spawn(process.execPath, [path.join(__dirname, "server.js")], {
    env: {
      ...process.env,
      ODISPEL_SIGNALING_PORT: String(PORT),
      ODISPEL_MAX_ROOMS: "2",
      ODISPEL_RATE_LIMIT: "12",
      ODISPEL_RATE_WINDOW_MS: "5000",
      ODISPEL_JOIN_TIMEOUT_MS: "700",
      ODISPEL_HEARTBEAT_MS: "200",
    },
    stdio: "ignore",
  });
  await wait(600);
});

after(() => proc && proc.kill());

test("le statistiche mostrano stanze e connessioni", async () => {
  const stats = await getJson("/stats");
  assert.equal(stats.rooms, 0);
  assert.equal(stats.max_rooms, 2);
  assert.equal(typeof stats.uptime_s, "number");
});

test("oltre il numero massimo di stanze il server risponde 'server_full'", async () => {
  const a = await connect();
  const b = await connect();
  const c = await connect();
  a.send(JSON.stringify({ type: "join", room_id: "r1", role: "host" }));
  b.send(JSON.stringify({ type: "join", room_id: "r2", role: "host" }));
  await nextOfType(a, "joined");
  await nextOfType(b, "joined");
  c.send(JSON.stringify({ type: "join", room_id: "r3", role: "host" }));
  const err = await nextOfType(c, "error");
  assert.equal(err.code, "server_full");
  assert.equal((await getJson("/stats")).rooms, 2);
  // chi esce libera il posto
  b.close();
  await wait(200);
  c.send(JSON.stringify({ type: "join", room_id: "r3", role: "host" }));
  await nextOfType(c, "joined");
  a.close();
  c.close();
  await wait(200);
});

test("chi manda troppi messaggi viene scollegato", async () => {
  const s = await connect();
  const closed = new Promise((r) => s.once("close", (code) => r(code)));
  for (let i = 0; i < 30; i++) s.send("{}");
  const code = await Promise.race([closed, wait(2000).then(() => "timeout")]);
  assert.equal(code, 1008);
});

test("chi non entra in una stanza viene chiuso dopo il timeout", async () => {
  const s = await connect();
  const closed = new Promise((r) => s.once("close", () => r("chiuso")));
  const result = await Promise.race([closed, wait(2500).then(() => "timeout")]);
  assert.equal(result, "chiuso");
});

test("un host in una stanza non viene chiuso dal timeout di ingresso", async () => {
  const h = await connect();
  h.send(JSON.stringify({ type: "join", room_id: "stay", role: "host" }));
  await nextOfType(h, "joined");
  await wait(1200);
  assert.equal(h.readyState, WebSocket.OPEN);
  h.close();
  await wait(100);
});

test("il ping periodico non scollega chi risponde", async () => {
  const h = await connect();
  h.send(JSON.stringify({ type: "join", room_id: "ping", role: "host" }));
  await nextOfType(h, "joined");
  await wait(900);
  assert.equal(h.readyState, WebSocket.OPEN);
  h.close();
});
