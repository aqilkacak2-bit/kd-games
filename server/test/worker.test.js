import assert from "node:assert/strict";
import test from "node:test";
import { Miniflare, Log, LogLevel, convertV4MiniflareOptions } from "miniflare";

const ORIGIN = "https://game.krackeddevs.com";
const GUILD = "1445246968367677573";
const users = {
  alice: { id: "100000000000000001", username: "alice", global_name: "Alice", avatar: null },
  bob: { id: "100000000000000002", username: "bob", global_name: "Bob", avatar: null },
  outsider: { id: "100000000000000003", username: "outsider", global_name: "Outsider", avatar: null },
};
const appearance = {
  hair: 0, hair_col: 0, face: 0, skin: 1, top: 0, top_col: 0, bottom: 0, bottom_col: 0,
};

async function runtime(t) {
  const state = { membershipStatus: 200, tokenCalls: 0, memberCalls: 0 };
  const mf = new Miniflare(convertV4MiniflareOptions({
    name: "kd-games-presence-test",
    scriptPath: new URL("../worker.js", import.meta.url).pathname,
    modules: true,
    compatibilityDate: "2026-11-09",
    compatibilityFlags: ["nodejs_compat"],
    log: new Log(LogLevel.ERROR),
    bindings: {
      APP_ORIGIN: ORIGIN,
      DISCORD_CLIENT_ID: "1514460582357762158",
      DISCORD_CLIENT_SECRET: "test-only-secret",
      DISCORD_GUILD_ID: GUILD,
    },
    durableObjects: {
      AUTH_SESSIONS: { className: "AuthSession", useSQLite: true },
      ROOMS: { className: "GameRoom", useSQLite: true },
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

test("room presence uses verified identity and logout removes the player", async t => {
  const { mf } = await runtime(t);
  const alice = await signIn(mf, "alice");
  const bob = await signIn(mf, "bob");
  const a = await socketClient(mf, alice.cookie);
  const b = await socketClient(mf, bob.cookie);
  assert.equal(a.welcome.selfId, users.alice.id);
  assert.equal(b.welcome.players.length, 0);
  a.socket.send(JSON.stringify({
    type: "state", id: "forged-id", name: "forged name",
    state: { x: 100, y: 150, facing: 1, state: "idle", frame: 0, look: appearance },
  }));
  const update = await b.next();
  assert.equal(update.type, "presence");
  assert.equal(update.player.id, users.alice.id);
  assert.equal(update.player.name, "KD Alice");
  assert.equal(update.player.state.x, 100);
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
