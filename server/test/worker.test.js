import assert from "node:assert/strict";
import test from "node:test";
import { readFile, mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { Miniflare, Log, LogLevel, convertV4MiniflareOptions } from "miniflare";

const ORIGIN = "https://game.krackeddevs.com";
const GUILD = "1445246968367677573";
const users = {
  alice: { id: "100000000000000001", username: "alice", global_name: "Alice", avatar: null },
  bob: { id: "100000000000000002", username: "bob", global_name: "Bob", avatar: null },
  charlie: { id: "100000000000000004", username: "charlie", global_name: "Charlie", avatar: null },
  dana: { id: "100000000000000005", username: "dana", global_name: "Dana", avatar: null },
  outsider: { id: "100000000000000003", username: "outsider", global_name: "Outsider", avatar: null },
};
const appearance = {
  hair: 0, hair_col: 0, face: 0, skin: 1, top: 0, top_col: 0, bottom: 0, bottom_col: 0,
};

async function runtime(t, { legacyAttachments = false, persistencePath } = {}) {
  const scriptOptions = { scriptPath: new URL("../worker.js", import.meta.url).pathname, modules: true };
  if (legacyAttachments) {
    const source = await readFile(new URL("../worker.js", import.meta.url), "utf8");
    scriptOptions.script = source.replace(
      "export class GameRoom extends DurableObject {", "class GameRoomBase extends DurableObject {") + `
export class GameRoom extends GameRoomBase {
  makeLegacyAttachments() {
    for (const socket of this.ctx.getWebSockets()) {
      const info = socket.deserializeAttachment();
      for (const key of ["stateAt", "lastHitSeq", "hitCooldowns", "hitWindowAt", "hitPacketCount"]) delete info[key];
      socket.serializeAttachment(info);
    }
  }
}
`;
    delete scriptOptions.scriptPath;
  }
  const state = { membershipStatus: 200, tokenCalls: 0, memberCalls: 0 };
  const mf = new Miniflare(convertV4MiniflareOptions({
    name: "kd-games-presence-test",
    ...scriptOptions,
    compatibilityDate: "2026-11-09",
    compatibilityFlags: ["nodejs_compat"],
    log: new Log(LogLevel.ERROR),
    resourcePersistencePath: persistencePath,
    bindings: {
      APP_ORIGIN: ORIGIN,
      LEGACY_ORIGIN: "https://platform.danialalias.com",
      DISCORD_CLIENT_ID: "1514460582357762158",
      DISCORD_CLIENT_SECRET: "test-only-secret",
      DISCORD_GUILD_ID: GUILD,
    },
    durableObjects: {
      AUTH_SESSIONS: { className: "AuthSession", useSQLite: true },
      ROOMS: { className: "GameRoom", useSQLite: true },
      PLAYER_PROFILES: { className: "PlayerProfile", useSQLite: true },
    },
    outboundService: async request => {
      const url = new URL(request.url);
      assert.equal(url.hostname, "discord.com", "tests must never contact another service");
      if (url.pathname === "/api/oauth2/token") {
        state.tokenCalls++;
        const body = new URLSearchParams(await request.text());
        assert.equal(body.get("client_secret"), "test-only-secret");
        assert.equal(body.get("redirect_uri"), ORIGIN + "/auth/callback");
        const user = body.get("code");
        return Response.json({ access_token: user, token_type: "Bearer", expires_in: 3600 });
      }
      const user = request.headers.get("Authorization")?.replace("Bearer ", "");
      if (url.pathname === "/api/v10/users/@me") return Response.json(users[user]);
      if (url.pathname === "/api/v10/users/@me/guilds/" + GUILD + "/member") {
        state.memberCalls++;
        if (user === "outsider") return Response.json({ error: "Unknown Member" }, { status: 404 });
        if (state.membershipStatus !== 200) {
          return Response.json({ error: "membership error" }, { status: state.membershipStatus });
        }
        return Response.json({ nick: user === "alice" ? "KD Alice" : null, avatar: null });
      }
      throw new Error("Unexpected Discord request " + url.pathname);
    },
  }));
  t.after(() => mf.dispose());
  await mf.ready;
  return { mf, state };
}

function pair(response, name) {
  const value = response.headers.get("Set-Cookie") || "";
  return value.match(new RegExp(name + "=[a-f0-9]+"))?.[0];
}

async function begin(mf) {
  const response = await mf.dispatchFetch(ORIGIN + "/auth/discord", { redirect: "manual" });
  assert.equal(response.status, 302);
  const location = new URL(response.headers.get("Location"));
  assert.equal(location.searchParams.get("scope"), "identify guilds.members.read");
  assert.equal(location.searchParams.get("redirect_uri"), ORIGIN + "/auth/callback");
  assert.match(response.headers.get("Set-Cookie"), /HttpOnly; Secure; SameSite=Lax/);
  return { state: location.searchParams.get("state"), cookie: pair(response, "__Host-kd_state") };
}

async function signIn(mf, user = "alice") {
  const login = await begin(mf);
  const response = await mf.dispatchFetch(
    ORIGIN + "/auth/callback?state=" + login.state + "&code=" + user,
    { headers: { Cookie: login.cookie }, redirect: "manual" },
  );
  return { response, cookie: pair(response, "__Host-kd_session"), login };
}

async function socketClient(mf, session, room = "rm_select") {
  const response = await mf.dispatchFetch(ORIGIN + "/api/presence?room=" + room, {
    headers: { Cookie: session, Origin: ORIGIN, Upgrade: "websocket" },
  });
  assert.equal(response.status, 101);
  const socket = response.webSocket;
  const messages = [];
  const waiting = [];
  socket.addEventListener("message", event => {
    const message = JSON.parse(event.data);
    if (waiting.length) waiting.shift()(message);
    else messages.push(message);
  });
  function next() {
    if (messages.length) return Promise.resolve(messages.shift());
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => reject(new Error("WebSocket message timeout")), 3000);
      waiting.push(message => { clearTimeout(timer); resolve(message); });
    });
  }
  socket.accept();
  return { socket, next, messages, welcome: await next() };
}

function closed(socket, label = "") {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error("WebSocket close timeout " + label)), 3000);
    socket.addEventListener("close", event => {
      clearTimeout(timer);
      resolve(event);
    }, { once: true });
  });
}

test("origin, authentication, room and method boundaries", async t => {
  const { mf } = await runtime(t);
  assert.equal((await mf.dispatchFetch("https://other.example/api/me")).status, 421);
  const me = await mf.dispatchFetch(ORIGIN + "/api/me");
  assert.deepEqual(await me.json(), { user: null, configured: true });
  assert.match(me.headers.get("Cache-Control"), /no-store/);
  const unauthorized = await mf.dispatchFetch(ORIGIN + "/api/presence?room=rm_select", {
    headers: { Upgrade: "websocket", Origin: ORIGIN },
  });
  assert.equal(unauthorized.status, 401);
  const crossOrigin = await mf.dispatchFetch(ORIGIN + "/api/presence?room=rm_select", {
    headers: { Upgrade: "websocket", Origin: "https://other.example" },
  });
  assert.equal(crossOrigin.status, 403);
  const room = await mf.dispatchFetch(ORIGIN + "/api/presence?room=rm_title", {
    headers: { Upgrade: "websocket", Origin: ORIGIN },
  });
  assert.equal(room.status, 400);
  assert.equal((await mf.dispatchFetch(ORIGIN + "/auth/logout", { method: "POST" })).status, 403);
});

test("OAuth state is bound to its cookie, issuer and one callback", async t => {
  const { mf, state } = await runtime(t);
  const first = await begin(mf);
  const mismatched = await mf.dispatchFetch(
    ORIGIN + "/auth/callback?state=" + "a".repeat(64) + "&code=alice",
    { headers: { Cookie: first.cookie }, redirect: "manual" },
  );
  assert.equal(mismatched.headers.get("Location"), ORIGIN + "/?login=error");
  assert.equal(state.tokenCalls, 0);
  const badIssuer = await mf.dispatchFetch(
    ORIGIN + "/auth/callback?state=" + first.state + "&code=alice&iss=https://evil.example",
    { headers: { Cookie: first.cookie }, redirect: "manual" },
  );
  assert.equal(badIssuer.headers.get("Location"), ORIGIN + "/?login=error");
  assert.equal(state.tokenCalls, 0);
  const success = await mf.dispatchFetch(
    ORIGIN + "/auth/callback?state=" + first.state + "&code=alice&iss=https://discord.com",
    { headers: { Cookie: first.cookie }, redirect: "manual" },
  );
  assert.equal(success.headers.get("Location"), ORIGIN + "/?login=success");
  const replay = await mf.dispatchFetch(
    ORIGIN + "/auth/callback?state=" + first.state + "&code=alice",
    { headers: { Cookie: first.cookie }, redirect: "manual" },
  );
  assert.equal(replay.headers.get("Location"), ORIGIN + "/?login=error");
  assert.equal(state.tokenCalls, 1);
});

test("members receive private sessions and nonmembers are rejected", async t => {
  const { mf } = await runtime(t);
  const alice = await signIn(mf);
  assert.equal(alice.response.headers.get("Location"), ORIGIN + "/?login=success");
  assert.ok(alice.cookie);
  assert.match(alice.response.headers.get("Set-Cookie"), /__Host-kd_session=[a-f0-9]{64}/);
  const me = await mf.dispatchFetch(ORIGIN + "/api/me", { headers: { Cookie: alice.cookie } });
  const body = await me.json();
  assert.equal(body.user.id, users.alice.id);
  assert.equal(body.user.name, "KD Alice");
  assert.ok(body.user.avatar.startsWith("https://cdn.discordapp.com/"));
  assert.deepEqual(Object.keys(body.user).sort(), ["avatar", "id", "name"]);
  assert.equal(JSON.stringify(body).includes("access"), false);
  const outsider = await signIn(mf, "outsider");
  assert.equal(outsider.response.headers.get("Location"), ORIGIN + "/?login=not_member");
  assert.equal(outsider.cookie, undefined);
});

test("lobby presence uses verified identity and logout removes the player", async t => {
  const { mf } = await runtime(t);
  const alice = await signIn(mf, "alice");
  const bob = await signIn(mf, "bob");
  const a = await socketClient(mf, alice.cookie, "rm_lobby");
  const b = await socketClient(mf, bob.cookie, "rm_lobby");
  assert.equal(a.welcome.selfId, users.alice.id);
  assert.equal(b.welcome.players.length, 0);
  a.socket.send(JSON.stringify({
    type: "state", id: "forged-id", name: "forged name",
    state: { x: 715, y: 308, facing: 1, state: "idle", frame: 0, look: appearance },
  }));
  const update = await b.next();
  assert.equal(update.type, "presence");
  assert.equal(update.player.id, users.alice.id);
  assert.equal(update.player.name, "KD Alice");
  assert.equal(update.player.state.x, 715);
  assert.equal(update.player.state.y, 308);
  const otherRoom = await socketClient(mf, bob.cookie, "rm_main");
  assert.deepEqual(otherRoom.welcome.players, []);
  const aClosed = closed(a.socket);
  const leave = b.next();
  const response = await mf.dispatchFetch(ORIGIN + "/auth/logout", {
    method: "POST", headers: { Cookie: alice.cookie, Origin: ORIGIN },
  });
  assert.equal(response.status, 200);
  assert.equal((await aClosed).code, 4401);
  assert.deepEqual(await leave, { type: "leave", id: users.alice.id });
  const me = await mf.dispatchFetch(ORIGIN + "/api/me", { headers: { Cookie: alice.cookie } });
  assert.equal((await me.json()).user, null);
  b.socket.close();
  otherRoom.socket.close();
});

test("invalid appearance and replaced tabs cannot impersonate players", async t => {
  const { mf } = await runtime(t);
  const session = await signIn(mf);
  const bob = await signIn(mf, "bob");
  const first = await socketClient(mf, session.cookie);
  const observer = await socketClient(mf, bob.cookie);
  first.socket.send(JSON.stringify({
    type: "state",
    state: { x: 90, y: 150, facing: 1, state: "idle", frame: 0, look: appearance },
  }));
  assert.equal((await observer.next()).player.state.x, 90);
  const duplicateClose = closed(first.socket, "replaced tab handshake");
  const newSession = await signIn(mf);
  const second = await socketClient(mf, newSession.cookie);
  assert.deepEqual(await first.next(), { type: "replaced" });
  assert.equal(second.welcome.selfId, users.alice.id);
  // Browsers close when they receive the replacement notice. This also
  // completes Miniflare's half-close handshake for the retired connection.
  first.socket.send(JSON.stringify({
    type: "state",
    state: { x: 120, y: 150, facing: 1, state: "idle", frame: 0, look: appearance },
  }));
  first.socket.close(4009, "Switched to another tab");
  assert.equal((await duplicateClose).code, 4009);
  second.socket.send(JSON.stringify({ type: "ping" }));
  assert.deepEqual(await second.next(), { type: "pong" });
  await new Promise(resolve => setTimeout(resolve, 50));
  assert.deepEqual(observer.messages, [], "retired tabs cannot broadcast or remove the replacement");
  second.socket.send(JSON.stringify({
    type: "state",
    state: { x: 100, y: 150, facing: 1, state: "idle", frame: 0, look: appearance },
  }));
  assert.equal((await observer.next()).player.state.x, 100);
  await mf.dispatchFetch(ORIGIN + "/auth/logout", {
    method: "POST", headers: { Cookie: session.cookie, Origin: ORIGIN },
  });
  second.socket.send(JSON.stringify({ type: "ping" }));
  assert.deepEqual(await second.next(), { type: "pong" });
  assert.deepEqual(observer.messages, [], "signing out a replaced session leaves the new session visible");
  const newMe = await mf.dispatchFetch(ORIGIN + "/api/me", { headers: { Cookie: newSession.cookie } });
  assert.equal((await newMe.json()).user.id, users.alice.id);
  const invalidClose = closed(second.socket, "invalid state");
  second.socket.send(JSON.stringify({
    type: "state",
    state: { x: 100, y: 150, facing: 1, state: "idle", frame: 0,
      look: { ...appearance, hair: 1000 } },
  }));
  assert.equal((await invalidClose).code, 1008);
  observer.socket.close();
});

test("membership is rechecked and transient outages do not erase sessions", async t => {
  const { mf, state } = await runtime(t);
  const sessionId = "b".repeat(64);
  const namespace = await mf.getDurableObjectNamespace("AUTH_SESSIONS");
  const stub = namespace.get(namespace.idFromName(sessionId));
  await stub.createSession({
    accessToken: "alice", discordUser: users.alice,
    user: { id: users.alice.id, name: "KD Alice", avatar: "" },
    checkedAt: Date.now() - 6 * 60 * 1000, expiresAt: Date.now() + 3600000,
  });
  const headers = { Cookie: "__Host-kd_session=" + sessionId };
  state.membershipStatus = 503;
  assert.equal((await mf.dispatchFetch(ORIGIN + "/api/me", { headers })).status, 503);
  state.membershipStatus = 200;
  const recovered = await mf.dispatchFetch(ORIGIN + "/api/me", { headers });
  assert.equal((await recovered.json()).user.id, users.alice.id);
  await stub.createSession({
    accessToken: "alice", discordUser: users.alice,
    user: { id: users.alice.id, name: "KD Alice", avatar: "" },
    checkedAt: Date.now() - 6 * 60 * 1000, expiresAt: Date.now() + 3600000,
  });
  state.membershipStatus = 404;
  const revoked = await mf.dispatchFetch(ORIGIN + "/api/me", { headers });
  assert.equal((await revoked.json()).user, null);
  state.membershipStatus = 200;
  const stillRevoked = await mf.dispatchFetch(ORIGIN + "/api/me", { headers });
  assert.equal((await stillRevoked.json()).user, null);
});

test("excessive login attempts are bounded", async t => {
  const { mf } = await runtime(t);
  for (let i = 0; i < 10; i++) {
    assert.equal((await mf.dispatchFetch(ORIGIN + "/auth/discord", { redirect: "manual" })).status, 302);
  }
  assert.equal((await mf.dispatchFetch(ORIGIN + "/auth/discord", { redirect: "manual" })).status, 429);
});


test("legacy domain redirects paths and queries only to the canonical game host", async t => {
  const { mf, state } = await runtime(t);
  const legacy = "https://platform.danialalias.com";
  for (const path of [
    "/",
    "/auth/discord?next=https%3A%2F%2Fevil.example",
    "//evil.example/path?x=1",
    "/%2f%2fevil.example/path?code=abc&state=def",
  ]) {
    const response = await mf.dispatchFetch(legacy + path, { redirect: "manual" });
    assert.equal(response.status, 308);
    assert.equal(response.headers.get("Cache-Control"), "no-store");
    const from = new URL(legacy + path);
    const to = new URL(response.headers.get("Location"));
    assert.equal(to.origin, ORIGIN);
    assert.equal(to.pathname, from.pathname);
    assert.equal(to.search, from.search);
  }
  const post = await mf.dispatchFetch(legacy + "/auth/logout", {
    method: "POST", redirect: "manual", headers: { Origin: legacy },
  });
  assert.equal(post.status, 308);
  assert.equal(post.headers.get("Location"), ORIGIN + "/auth/logout");
  assert.equal(state.tokenCalls, 0);
});

async function until(client, type) {
  for (;;) {
    const message = await client.next();
    if (message.type === type) return message;
  }
}

async function sync(client) {
  client.socket.send(JSON.stringify({ type: "ping" }));
  await until(client, "pong");
}

async function pose(client, x = 100, y = 150) {
  client.socket.send(JSON.stringify({
    type: "state",
    state: { x, y, facing: 1, state: "idle", frame: 0, look: appearance, hp: 0 },
  }));
  await sync(client);
}

async function combat(t, options) {
  const result = await runtime(t, options);
  const sessions = await Promise.all(["alice", "bob", "charlie", "dana"]
    .map(name => signIn(result.mf, name)));
  const clients = [];
  for (let i = 0; i < sessions.length; i++) {
    clients.push(await socketClient(result.mf, sessions[i].cookie, i === 3 ? "rm_range" : "rm_main"));
  }
  const [a, b, c, other] = clients;
  await pose(a, 100);
  await pose(b, 160);
  await pose(c, 200);
  await pose(other, 160);
  await new Promise(resolve => setTimeout(resolve, 20));
  for (const client of clients) client.messages.length = 0;
  t.after(() => {
    for (const client of clients) {
      try { client.socket.close(); } catch {}
    }
  });
  return { ...result, a, b, c, other };
}

function hit(targetId = users.bob.id, weapon = "smg", x = 160, y = 137) {
  return { targetId, weapon, x, y, dir: 90 };
}

function sendHits(client, seq, hits = [hit()]) {
  client.socket.send(JSON.stringify({ type: "hits", seq, hits, attackerId: "forged", hp: -100 }));
}

test("canonical nonlethal hits reach shooter, victim and room observers only", async t => {
  const { a, b, c, other } = await combat(t);
  sendHits(a, 1, [
    hit(), hit(), hit(users.alice.id, "smg", 100), hit(users.dana.id),
    hit("100000000000000099"),
  ]);
  const event = await until(a, "hits");
  assert.equal(event.attackerId, users.alice.id);
  assert.match(event.id, /^[a-f0-9-]{36}$/);
  assert.deepEqual(event.hits, [{ targetId: users.bob.id, weapon: "smg", x: 160, y: 137, dir: 90 }]);
  assert.deepEqual(await until(b, "hits"), event);
  assert.deepEqual(await until(c, "hits"), event);
  assert.deepEqual(other.messages, []);
  assert.equal(JSON.stringify(event).includes("hp"), false);
  sendHits(a, 2);
  await sync(a);
  assert.deepEqual(b.messages, [], "fresh sequences still obey target reaction cooldowns");
  assert.deepEqual(c.messages, []);
  await new Promise(resolve => setTimeout(resolve, 170));
  sendHits(a, 1);
  await sync(a);
  await new Promise(resolve => setTimeout(resolve, 20));
  assert.deepEqual(b.messages, [], "a replay must not repeat reactions");
  assert.deepEqual(c.messages, []);
  const leaveA = until(a, "leave");
  const leaveC = until(c, "leave");
  b.socket.close();
  await Promise.all([leaveA, leaveC]);
  sendHits(a, 3);
  await sync(a);
  assert.deepEqual(c.messages, [], "a disconnected target is ignored");
});

test("stale poses and impossible impacts are ignored without disconnecting", async t => {
  const { a, b, c } = await combat(t);
  sendHits(a, 1, [hit(users.bob.id, "smg", 500, 50)]);
  await sync(a);
  assert.deepEqual(b.messages, []);
  await pose(b, 600);
  c.messages.length = 0;
  a.messages.length = 0;
  sendHits(a, 2, [hit(users.bob.id, "keris", 600)]);
  await sync(a);
  assert.equal(b.messages.some(message => message.type === "hits"), false);
  await new Promise(resolve => setTimeout(resolve, 3100));
  await pose(a, 100);
  b.messages.length = 0;
  sendHits(a, 3, [hit(users.bob.id, "sniper", 600)]);
  await sync(a);
  assert.equal(b.messages.some(message => message.type === "hits"), false, "stale targets cannot be tagged");
  await pose(b, 600);
  sendHits(a, 4, [hit(users.bob.id, "sniper", 600)]);
  assert.equal((await until(a, "hits")).hits[0].targetId, users.bob.id);
});

test("all weapon classes emit cosmetic-only hit events", async t => {
  const { a, b } = await combat(t);
  const weapons = ["smg", "shotgun", "sniper", "burst", "ricochet", "keris", "laser",
    "lightning", "flame", "rocket", "grenade", "freeze", "thrown_grenade"];
  for (let i = 0; i < weapons.length; i++) {
    if (i) await new Promise(resolve => setTimeout(resolve, 160));
    await pose(a, 100);
    await pose(b, 160);
    sendHits(a, i + 1, [hit(users.bob.id, weapons[i])]);
    const event = await until(a, "hits");
    assert.deepEqual(Object.keys(event).sort(), ["attackerId", "hits", "id", "type"]);
    assert.equal(event.hits[0].weapon, weapons[i]);
    assert.deepEqual(Object.keys(event.hits[0]).sort(), ["dir", "targetId", "weapon", "x", "y"]);
  }
});

test("malformed or oversized hit packets close the sender", async t => {
  const cases = [
    [{ type: "hits", seq: 0, hits: [hit()] }, 1008],
    [{ type: "hits", seq: 1, hits: [hit(users.bob.id, "unknown")] }, 1008],
    [{ type: "hits", seq: 1, hits: [hit(users.bob.id, "smg", null)] }, 1008],
    [{ type: "hits", seq: 1, hits: [{ ...hit(), dir: 361 }] }, 1008],
    [{ type: "hits", seq: 1, hits: Array(17).fill(hit()) }, 1008],
    [{ type: "hits", seq: 1, hits: [{ ...hit(), targetId: "not-an-id" }] }, 1008],
    [{ type: "hits", seq: 1, hits: [hit()], padding: "x".repeat(5000) }, 1009],
  ];
  for (const [packet, code] of cases) {
    await t.test("reject " + JSON.stringify(packet).slice(0, 80), async subtest => {
      const { a } = await combat(subtest);
      const closing = closed(a.socket, "malformed hit");
      a.socket.send(JSON.stringify(packet));
      assert.equal((await closing).code, code);
    });
  }
});

test("state plus hit updates at 10Hz remain connected and hit floods are bounded", async t => {
  const { a, b } = await combat(t);
  let closeCode = null;
  a.socket.addEventListener("close", event => { closeCode = event.code; });
  for (let i = 1; i <= 12; i++) {
    a.socket.send(JSON.stringify({
      type: "state",
      state: { x: 100, y: 150, facing: 1, state: "idle", frame: 0, look: appearance },
    }));
    sendHits(a, i);
    await new Promise(resolve => setTimeout(resolve, 100));
  }
  await sync(a);
  assert.equal(closeCode, null);
  assert.ok(b.messages.some(message => message.type === "hits"));
  await new Promise(resolve => setTimeout(resolve, 1100));
  const closing = closed(a.socket, "hit flood");
  for (let i = 13; i <= 25; i++) sendHits(a, i);
  assert.equal((await closing).code, 1008);
});

test("legacy open-socket attachments accept state and ping before enabling hits", async t => {
  const { mf, a, b } = await combat(t, { legacyAttachments: true });
  const namespace = await mf.getDurableObjectNamespace("ROOMS");
  const room = namespace.get(namespace.idFromName(GUILD + ":rm_main"));
  await room.makeLegacyAttachments();
  await sync(a);
  sendHits(a, 1);
  await sync(a);
  assert.equal(b.messages.some(message => message.type === "hits"), false);
  await pose(a, 100);
  await pose(b, 160);
  sendHits(a, 2);
  assert.equal((await until(a, "hits")).hits[0].targetId, users.bob.id);
});


test("a full precision 16-hit batch fits the bounded packet envelope", async t => {
  const { a } = await combat(t);
  const packet = {
    type: "hits", seq: 1,
    hits: Array.from({ length: 16 }, () => ({
      targetId: users.bob.id, weapon: "thrown_grenade",
      x: 160.12345678901234, y: 137.12345678901234, dir: 123.45678901234567,
    })),
  };
  const encoded = JSON.stringify(packet);
  assert.ok(Buffer.byteLength(encoded) > 2048);
  assert.ok(Buffer.byteLength(encoded) < 4096);
  a.socket.send(encoded);
  const event = await until(a, "hits");
  assert.equal(event.hits.length, 1);
  assert.equal(event.hits[0].targetId, users.bob.id);
});


function characterRequest(mf, session, { method = "GET", payload, body, origin = ORIGIN, contentType = "application/json", headers = {} } = {}) {
  return mf.dispatchFetch(ORIGIN + "/api/character", {
    method, duplex: "half",
    headers: { Cookie: session || "", Origin: origin, "Content-Type": contentType, ...headers },
    ...(method === "GET" ? {} : { body: body ?? JSON.stringify(payload) }),
  });
}

test("character outfits persist across sessions and logout while staying account-isolated", async t => {
  const { mf } = await runtime(t);
  const alice = await signIn(mf, "alice");
  const bob = await signIn(mf, "bob");
  const empty = await characterRequest(mf, alice.cookie);
  assert.equal(empty.status, 200);
  assert.deepEqual(await empty.json(), { look: null, updatedAt: null });
  assert.equal(empty.headers.get("Cache-Control"), "no-store");

  const outfit = { ...appearance, hair: 5, face: 5, top: 4, top_col: 9, bottom: 2, bottom_col: 7 };
  const response = await characterRequest(mf, alice.cookie, { method: "PUT", payload: { look: outfit } });
  assert.equal(response.status, 200);
  const saved = await response.json();
  assert.deepEqual(saved.look, outfit);
  assert.ok(Number.isFinite(saved.updatedAt));
  assert.ok(Math.abs(Date.now() - saved.updatedAt) < 5000);
  assert.deepEqual(Object.keys(saved).sort(), ["look", "updatedAt"]);
  const newSession = await signIn(mf, "alice");
  assert.notEqual(newSession.cookie, alice.cookie);
  assert.deepEqual(await (await characterRequest(mf, newSession.cookie)).json(), saved);
  assert.deepEqual(await (await characterRequest(mf, bob.cookie)).json(), { look: null, updatedAt: null });

  const forged = await characterRequest(mf, bob.cookie, {
    method: "PUT", payload: { look: appearance, userId: users.alice.id },
  });
  assert.equal(forged.status, 400);
  assert.deepEqual(await (await characterRequest(mf, newSession.cookie)).json(), saved);
  await mf.dispatchFetch(ORIGIN + "/auth/logout", {
    method: "POST", headers: { Cookie: alice.cookie, Origin: ORIGIN },
  });
  assert.equal((await characterRequest(mf, alice.cookie)).status, 401);
  assert.deepEqual(await (await characterRequest(mf, newSession.cookie)).json(), saved);
  const returning = await signIn(mf, "alice");
  assert.deepEqual(await (await characterRequest(mf, returning.cookie)).json(), saved);
});

test("character writes reject cross-origin, invalid and oversized data without replacing an outfit", async t => {
  const { mf } = await runtime(t);
  assert.equal((await characterRequest(mf, null)).status, 401);
  assert.equal((await characterRequest(mf, null, { method: "PUT", payload: { look: appearance } })).status, 401);
  const alice = await signIn(mf);
  const valid = await characterRequest(mf, alice.cookie, { method: "PUT", payload: { look: appearance } });
  const saved = await valid.json();
  assert.equal((await characterRequest(mf, alice.cookie, {
    method: "PUT", payload: { look: appearance }, origin: "https://other.example",
  })).status, 403);
  assert.equal((await characterRequest(mf, alice.cookie, { origin: "https://other.example" })).status, 403);
  assert.equal((await characterRequest(mf, alice.cookie, {
    method: "PUT", payload: { look: appearance }, origin: "",
  })).status, 403);
  assert.equal((await characterRequest(mf, alice.cookie, {
    method: "PUT", payload: { look: appearance }, contentType: "text/plain",
  })).status, 415);
  const unsupported = await characterRequest(mf, alice.cookie, { method: "POST", payload: { look: appearance } });
  assert.equal(unsupported.status, 405);
  assert.equal(unsupported.headers.get("Allow"), "GET, PUT");

  for (const payload of [
    null, [], { look: null }, { look: [] }, { look: { ...appearance, hair: 6 } },
    { look: { ...appearance, top_col: -1 } }, { look: { ...appearance, face: 1.5 } },
    { look: { ...appearance, hair: "1" } }, { look: { ...appearance, outfitName: "extra" } },
    { look: { hair: 0 } }, { look: appearance, userId: users.bob.id },
  ]) {
    const invalid = await characterRequest(mf, alice.cookie, { method: "PUT", payload });
    assert.equal(invalid.status, 400, JSON.stringify(payload));
  }
  assert.equal((await characterRequest(mf, alice.cookie, { method: "PUT", body: "{" })).status, 400);
  assert.equal((await characterRequest(mf, alice.cookie, {
    method: "PUT", body: JSON.stringify({ look: appearance, padding: "x".repeat(1024) }),
  })).status, 413);
  const streamed = new ReadableStream({
    start(controller) {
      controller.enqueue(new TextEncoder().encode(" ".repeat(600)));
      controller.enqueue(new TextEncoder().encode(" ".repeat(600)));
      controller.close();
    },
  });
  assert.equal((await characterRequest(mf, alice.cookie, { method: "PUT", body: streamed })).status, 413);
  assert.deepEqual(await (await characterRequest(mf, alice.cookie)).json(), saved);
});

test("character access rechecks membership and persisted outfits survive a runtime restart", async t => {
  const persistencePath = await mkdtemp(join(tmpdir(), "kd-character-test-"));
  t.after(() => rm(persistencePath, { recursive: true, force: true }));
  const first = await runtime(t, { persistencePath });
  const alice = await signIn(first.mf);
  const outfit = { ...appearance, top: 3, top_col: 8 };
  const saved = await (await characterRequest(first.mf, alice.cookie, { method: "PUT", payload: { look: outfit } })).json();
  await first.mf.dispose();
  const second = await runtime(t, { persistencePath });
  assert.deepEqual(await (await characterRequest(second.mf, alice.cookie)).json(), saved);

  const sessions = await second.mf.getDurableObjectNamespace("AUTH_SESSIONS");
  const oldSession = "c".repeat(64);
  await sessions.get(sessions.idFromName(oldSession)).createSession({
    accessToken: "alice", discordUser: users.alice,
    user: { id: users.alice.id, name: "KD Alice", avatar: "" },
    checkedAt: Date.now() - 6 * 60 * 1000, expiresAt: Date.now() + 3600000,
  });
  second.state.membershipStatus = 404;
  const revoked = "__Host-kd_session=" + oldSession;
  assert.equal((await characterRequest(second.mf, revoked)).status, 401);
  assert.equal((await characterRequest(second.mf, revoked, { method: "PUT", payload: { look: appearance } })).status, 401);
  second.state.membershipStatus = 200;
  assert.deepEqual(await (await characterRequest(second.mf, alice.cookie)).json(), saved);
});
