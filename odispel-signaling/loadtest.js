"use strict";

// Prova di carico del server di segnalazione: apre N stanze, ognuna con un host e
// alcuni client, e misura quanto ci mette a far entrare tutti.
//   node loadtest.js [url] [stanze] [client_per_stanza]
// Esempio contro il server in cloud:  node loadtest.js wss://odispel-signaling.onrender.com 50 3
const WebSocket = require("ws");

const URL = process.argv[2] || "ws://127.0.0.1:9080";
const ROOMS = Number(process.argv[3] || 50);
const CLIENTS = Number(process.argv[4] || 3);

function open() {
  return new Promise((resolve, reject) => {
    const s = new WebSocket(URL);
    s.inbox = [];
    s.on("message", (raw) => s.inbox.push(JSON.parse(raw.toString())));
    s.once("open", () => resolve(s));
    s.once("error", reject);
  });
}

async function waitFor(s, type, ms = 15000) {
  const end = Date.now() + ms;
  while (Date.now() < end) {
    const i = s.inbox.findIndex((m) => m.type === type || m.type === "error");
    if (i >= 0) {
      const m = s.inbox.splice(i, 1)[0];
      if (m.type === "error") throw new Error(m.code);
      return m;
    }
    await new Promise((r) => setTimeout(r, 15));
  }
  throw new Error("timeout " + type);
}

async function room(n) {
  const id = `load-${process.pid}-${n}`;
  const t0 = Date.now();
  const host = await open();
  await waitFor(host, "connected");
  host.send(JSON.stringify({ type: "join", room_id: id, role: "host" }));
  await waitFor(host, "joined");
  const sockets = [host];
  for (let c = 0; c < CLIENTS; c++) {
    const cl = await open();
    await waitFor(cl, "connected");
    cl.send(JSON.stringify({ type: "join", room_id: id, role: "client" }));
    const joined = await waitFor(cl, "joined");
    const peer = await waitFor(host, "peer_joined");
    // scambio di prova: il client manda un'offerta all'host
    cl.send(JSON.stringify({ type: "offer", target_peer_id: joined.host_peer_id, payload: { n } }));
    await waitFor(host, "offer");
    sockets.push(cl);
  }
  return { sockets, ms: Date.now() - t0 };
}

(async () => {
  const t0 = Date.now();
  const results = await Promise.allSettled(Array.from({ length: ROOMS }, (_, i) => room(i)));
  const ok = results.filter((r) => r.status === "fulfilled");
  const failed = results.filter((r) => r.status === "rejected");
  const times = ok.map((r) => r.value.ms).sort((a, b) => a - b);
  const pct = (p) => times[Math.min(times.length - 1, Math.floor(times.length * p))] ?? 0;
  console.log(`stanze riuscite: ${ok.length}/${ROOMS}  (client per stanza: ${CLIENTS})`);
  console.log(`tempo totale: ${Date.now() - t0} ms   mediana stanza: ${pct(0.5)} ms   p95: ${pct(0.95)} ms`);
  if (failed.length) {
    const reasons = {};
    for (const f of failed) reasons[f.reason.message] = (reasons[f.reason.message] || 0) + 1;
    console.log("errori:", reasons);
  }
  for (const r of ok) for (const s of r.value.sockets) s.close();
  setTimeout(() => process.exit(failed.length ? 1 : 0), 300);
})();
