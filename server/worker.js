import { DurableObject } from "cloudflare:workers";

const SESSION_COOKIE = "__Host-kd_session";
const STATE_COOKIE = "__Host-kd_state";
const OAUTH_TTL = 10 * 60 * 1000;
const SESSION_TTL = 24 * 60 * 60 * 1000;
const MEMBER_CHECK_TTL = 5 * 60 * 1000;
const CONNECTION_TTL = 10 * 60 * 1000;
const DISCORD_API = "https://discord.com/api/v10";
const ROOMS = {
  rm_select: [320, 180],
  rm_showcase: [1073, 373],
  rm_kl: [960, 240],
  rm_main: [721, 373],
  rm_range: [480, 180],
  rm_rooftop: [480, 180],
};
const LOOK_LIMITS = {
  hair: 5, hair_col: 9, face: 5, skin: 5,
  top: 5, top_col: 9, bottom: 2, bottom_col: 7,
};

function json(body, status = 200) {
  return Response.json(body, {
    status,
    headers: { "Cache-Control": "no-store", "X-Content-Type-Options": "nosniff" },
  });
}

function token() {
  return Array.from(crypto.getRandomValues(new Uint8Array(32)), byte =>
    byte.toString(16).padStart(2, "0")).join("");
}

function cookie(name, value, seconds) {
  return name + "=" + value + "; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=" + seconds;
}

function readCookie(request, name) {
  const parts = (request.headers.get("Cookie") || "").split(";");
  const match = parts.map(part => part.trim()).find(part => part.startsWith(name + "="));
  const value = match ? match.slice(name.length + 1) : "";
  return /^[a-f0-9]{64}$/.test(value) ? value : null;
}

function redirect(origin, result, cookies = []) {
  const headers = new Headers({
    Location: origin + "/?login=" + result,
    "Cache-Control": "no-store",
    "Referrer-Policy": "no-referrer",
  });
  for (const value of cookies) headers.append("Set-Cookie", value);
  return new Response(null, { status: 302, headers });
}

function safeName(value) {
  return Array.from(String(value || "").normalize("NFC")
    .replace(/[\u0000-\u001f\u007f-\u009f\u202a-\u202e\u2066-\u2069]/g, "")
    .trim()).slice(0, 32).join("") || "KD member";
}

function publicUser(user, member, guildId) {
  const id = user.id;
  const hash = member.avatar || user.avatar;
  let avatar;
  if (/^(a_)?[a-f0-9]{32}$/i.test(hash || "")) {
    const base = member.avatar
      ? DISCORD_CDN + "/guilds/" + guildId + "/users/" + id + "/avatars/"
      : DISCORD_CDN + "/avatars/" + id + "/";
    avatar = base + hash + ".png?size=128";
  } else {
    const index = Number((BigInt(id) >> 22n) % 6n);
    avatar = DISCORD_CDN + "/embed/avatars/" + index + ".png";
  }
  return { id, name: safeName(member.nick || user.global_name || user.username), avatar };
}
const DISCORD_CDN = "https://cdn.discordapp.com";

async function discordRequest(path, accessToken) {
  let response;
  try {
    response = await fetch(DISCORD_API + path, {
      headers: { Authorization: "Bearer " + accessToken },
      signal: AbortSignal.timeout(8000),
    });
  } catch {
    return { status: 503 };
  }
  if (!response.ok) return { status: response.status };
  try {
    return { status: 200, data: await response.json() };
  } catch {
    return { status: 503 };
  }
}

function sessionStub(env, id) {
  return env.AUTH_SESSIONS.getByName(id);
}

async function verifySession(request, env) {
  const id = readCookie(request, SESSION_COOKIE);
  if (!id) return { status: 401 };
  const result = await sessionStub(env, id).verify();
  return { ...result, sessionId: id };
}

function methodAllowed(request, method) {
  return request.method === method;
}

async function login(request, env) {
  const ip = request.headers.get("CF-Connecting-IP") || "unknown";
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(ip));
  const bucket = Array.from(new Uint8Array(digest), byte => byte.toString(16).padStart(2, "0")).join("");
  if (!await sessionStub(env, "rate-" + bucket).allowLogin()) {
    return json({ error: "too_many_sign_in_attempts" }, 429);
  }
  const state = token();
  await sessionStub(env, "oauth-" + state).createState(Date.now() + OAUTH_TTL);
  const url = new URL("https://discord.com/oauth2/authorize");
  url.search = new URLSearchParams({
    client_id: env.DISCORD_CLIENT_ID,
    response_type: "code",
    redirect_uri: env.APP_ORIGIN + "/auth/callback",
    scope: "identify guilds.members.read",
    state,
  }).toString();
  return new Response(null, {
    status: 302,
    headers: {
      Location: url.toString(),
      "Set-Cookie": cookie(STATE_COOKIE, state, OAUTH_TTL / 1000),
      "Cache-Control": "no-store",
      "Referrer-Policy": "no-referrer",
    },
  });
}

async function callback(request, env) {
  const url = new URL(request.url);
  const clearState = cookie(STATE_COOKIE, "", 0);
  const state = url.searchParams.get("state");
  const expected = readCookie(request, STATE_COOKIE);
  const issuer = url.searchParams.get("iss");
  if (!state || state !== expected || url.searchParams.getAll("state").length !== 1 ||
      (issuer !== null && issuer !== "https://discord.com")) {
    return redirect(env.APP_ORIGIN, "error", [clearState]);
  }
  const consumed = await sessionStub(env, "oauth-" + state).consumeState();
  if (!consumed) return redirect(env.APP_ORIGIN, "error", [clearState]);
  if (url.searchParams.get("error") === "access_denied") {
    return redirect(env.APP_ORIGIN, "denied", [clearState]);
  }
  const code = url.searchParams.get("code");
  if (!code || code.length > 2048 || url.searchParams.getAll("code").length !== 1) {
    return redirect(env.APP_ORIGIN, "error", [clearState]);
  }

  let tokenResponse;
  try {
    tokenResponse = await fetch("https://discord.com/api/oauth2/token", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        client_id: env.DISCORD_CLIENT_ID,
        client_secret: env.DISCORD_CLIENT_SECRET,
        grant_type: "authorization_code",
        code,
        redirect_uri: env.APP_ORIGIN + "/auth/callback",
      }),
      signal: AbortSignal.timeout(8000),
    });
  } catch {
    return redirect(env.APP_ORIGIN, "error", [clearState]);
  }
  if (!tokenResponse.ok) return redirect(env.APP_ORIGIN, "error", [clearState]);
  let credentials;
  try {
    credentials = await tokenResponse.json();
  } catch {
    return redirect(env.APP_ORIGIN, "error", [clearState]);
  }
  if (typeof credentials.access_token !== "string" ||
      !Number.isFinite(credentials.expires_in) || credentials.expires_in <= 0) {
    return redirect(env.APP_ORIGIN, "error", [clearState]);
  }
  const [profile, membership] = await Promise.all([
    discordRequest("/users/@me", credentials.access_token),
    discordRequest("/users/@me/guilds/" + env.DISCORD_GUILD_ID + "/member", credentials.access_token),
  ]);
  if ([401, 403, 404].includes(membership.status)) {
    return redirect(env.APP_ORIGIN, "not_member", [clearState]);
  }
  if (profile.status !== 200 || membership.status !== 200 ||
      !/^\d{17,20}$/.test(profile.data?.id || "")) {
    return redirect(env.APP_ORIGIN, "error", [clearState]);
  }
  const sessionId = token();
  const expiresAt = Date.now() + Math.min(SESSION_TTL, credentials.expires_in * 1000);
  await sessionStub(env, sessionId).createSession({
    accessToken: credentials.access_token,
    discordUser: {
      id: profile.data.id,
      username: profile.data.username,
      global_name: profile.data.global_name,
      avatar: profile.data.avatar,
    },
    user: publicUser(profile.data, membership.data, env.DISCORD_GUILD_ID),
    checkedAt: Date.now(),
    expiresAt,
  });
  return redirect(env.APP_ORIGIN, "success", [
    clearState, cookie(SESSION_COOKIE, sessionId, Math.floor((expiresAt - Date.now()) / 1000)),
  ]);
}

async function logout(request, env) {
  if (request.headers.get("Origin") !== env.APP_ORIGIN) {
    return json({ error: "origin_denied" }, 403);
  }
  const id = readCookie(request, SESSION_COOKIE);
  if (id) {
    await sessionStub(env, id).remove();
    const results = await Promise.allSettled(Object.keys(ROOMS).map(room =>
      env.ROOMS.getByName(env.DISCORD_GUILD_ID + ":" + room).revokeSession(id)));
    if (results.some(result => result.status === "rejected")) {
      console.warn(JSON.stringify({ event: "presence_revoke_incomplete" }));
    }
  }
  const response = json({ ok: true });
  response.headers.append("Set-Cookie", cookie(SESSION_COOKIE, "", 0));
  return response;
}

async function presence(request, env) {
  if (request.headers.get("Origin") !== env.APP_ORIGIN) {
    return json({ error: "origin_denied" }, 403);
  }
  if ((request.headers.get("Upgrade") || "").toLowerCase() !== "websocket") {
    return json({ error: "websocket_required" }, 426);
  }
  const room = new URL(request.url).searchParams.get("room");
  if (!Object.hasOwn(ROOMS, room)) return json({ error: "invalid_room" }, 400);
  const result = await verifySession(request, env);
  if (result.status !== 200) return json({ error: "sign_in_required" }, result.status);
  const headers = new Headers({
    Upgrade: "websocket",
    "X-KD-Identity": JSON.stringify({
      user: result.user,
      sessionId: result.sessionId,
      room,
      expiresAt: Math.min(result.expiresAt, Date.now() + CONNECTION_TTL),
    }),
  });
  const stub = env.ROOMS.getByName(env.DISCORD_GUILD_ID + ":" + room, { locationHint: "apac" });
  return stub.fetch(new Request(env.APP_ORIGIN + "/internal/connect", { headers }));
}

export default {
  async fetch(request, env) {
    try {
      const url = new URL(request.url);
      if (url.origin !== env.APP_ORIGIN) return json({ error: "host_denied" }, 421);
      if (url.search.length > 4096) return json({ error: "request_too_long" }, 414);
      const configured = Boolean(env.DISCORD_CLIENT_ID && env.DISCORD_CLIENT_SECRET && env.DISCORD_GUILD_ID);
      if (url.pathname === "/api/health") {
        return methodAllowed(request, "GET")
          ? json({ ok: true, configured })
          : new Response(null, { status: 405, headers: { Allow: "GET" } });
      }
      if (url.pathname === "/api/me" && methodAllowed(request, "GET")) {
        if (!configured) return json({ user: null, configured: false });
        const result = await verifySession(request, env);
        if (result.status === 503) return json({ error: "discord_unavailable" }, 503);
        const response = json({ user: result.status === 200 ? result.user : null, configured: true });
        if (result.status === 401 && result.sessionId) {
          response.headers.append("Set-Cookie", cookie(SESSION_COOKIE, "", 0));
        }
        return response;
      }
      if (!configured) return json({ error: "auth_not_configured" }, 503);
      if (url.pathname === "/auth/discord" && methodAllowed(request, "GET")) return await login(request, env);
      if (url.pathname === "/auth/callback" && methodAllowed(request, "GET")) return await callback(request, env);
      if (url.pathname === "/auth/logout" && methodAllowed(request, "POST")) return await logout(request, env);
      if (url.pathname === "/api/presence" && methodAllowed(request, "GET")) return await presence(request, env);
      return json({ error: "not_found" }, 404);
    } catch (error) {
      console.error(JSON.stringify({ event: "request_failed", type: error?.name || "Error" }));
      return json({ error: "temporarily_unavailable" }, 503);
    }
  },
};

export class AuthSession extends DurableObject {
  constructor(ctx, env) {
    super(ctx, env);
    this.verification = null;
  }

  async allowLogin() {
    const now = Date.now();
    const allowed = await this.ctx.storage.transaction(async txn => {
      const previous = await txn.get("rate");
      const count = previous?.window === Math.floor(now / 60000) ? previous.count + 1 : 1;
      await txn.put("rate", { window: Math.floor(now / 60000), count });
      return count <= 10;
    });
    await this.ctx.storage.setAlarm(now + 120000);
    return allowed;
  }

  async createState(expiresAt) {
    await this.ctx.storage.put("record", { kind: "state", expiresAt });
    await this.ctx.storage.setAlarm(expiresAt);
  }

  async consumeState() {
    return this.ctx.storage.transaction(async txn => {
      const record = await txn.get("record");
      await txn.delete("record");
      return Boolean(record?.kind === "state" && record.expiresAt > Date.now());
    });
  }

  async createSession(record) {
    await this.ctx.storage.put("record", { ...record, kind: "session" });
    await this.ctx.storage.setAlarm(record.expiresAt);
  }

  async remove() {
    await this.ctx.storage.deleteAll();
  }

  async alarm() {
    await this.ctx.storage.deleteAll();
  }

  async verify() {
    if (this.verification) return this.verification;
    this.verification = this.checkMembership();
    try {
      return await this.verification;
    } finally {
      this.verification = null;
    }
  }

  async checkMembership() {
    const record = await this.ctx.storage.get("record");
    if (record?.kind !== "session" || record.expiresAt <= Date.now()) {
      await this.ctx.storage.deleteAll();
      return { status: 401 };
    }
    if (Date.now() - record.checkedAt >= MEMBER_CHECK_TTL) {
      const member = await discordRequest(
        "/users/@me/guilds/" + this.env.DISCORD_GUILD_ID + "/member", record.accessToken);
      if ([401, 403, 404].includes(member.status)) {
        await this.ctx.storage.deleteAll();
        return { status: 401 };
      }
      if (member.status !== 200) return { status: 503 };
      const current = await this.ctx.storage.get("record");
      if (current?.kind !== "session") return { status: 401 };
      record.user = publicUser(record.discordUser, member.data, this.env.DISCORD_GUILD_ID);
      record.checkedAt = Date.now();
      await this.ctx.storage.put("record", record);
    }
    return { status: 200, user: record.user, expiresAt: record.expiresAt };
  }
}

function validState(value, room) {
  if (!value || typeof value !== "object" || Array.isArray(value)) return null;
  const [width, height] = ROOMS[room];
  if (!Number.isFinite(value.x) || value.x < -64 || value.x > width + 64 ||
      !Number.isFinite(value.y) || value.y < -256 || value.y > height + 256 ||
      ![1, -1].includes(value.facing) || !["idle", "walk"].includes(value.state) ||
      !Number.isFinite(value.frame) || value.frame < 0 || value.frame >= 6 ||
      !value.look || typeof value.look !== "object") return null;
  const look = {};
  for (const [key, max] of Object.entries(LOOK_LIMITS)) {
    const item = value.look[key];
    if (!Number.isInteger(item) || item < 0 || item > max) return null;
    look[key] = item;
  }
  return {
    x: Math.round(value.x * 100) / 100,
    y: Math.round(value.y * 100) / 100,
    facing: value.facing,
    state: value.state,
    frame: value.frame,
    look,
  };
}

function attachment(socket) {
  return socket.deserializeAttachment();
}

function active(info) {
  return info && !info.closed && info.expiresAt > Date.now();
}

function player(info) {
  return { ...info.user, state: info.state };
}

export class GameRoom extends DurableObject {
  async fetch(request) {
    if (new URL(request.url).pathname !== "/internal/connect" ||
        (request.headers.get("Upgrade") || "").toLowerCase() !== "websocket") {
      return json({ error: "not_found" }, 404);
    }
    let identity;
    try {
      identity = JSON.parse(request.headers.get("X-KD-Identity") || "");
    } catch {
      return json({ error: "invalid_identity" }, 403);
    }
    if (!identity?.user?.id || !Object.hasOwn(ROOMS, identity.room) ||
        !/^[a-f0-9]{64}$/.test(identity.sessionId || "") ||
        !Number.isFinite(identity.expiresAt) || identity.expiresAt <= Date.now()) {
      return json({ error: "invalid_identity" }, 403);
    }
    const sockets = this.ctx.getWebSockets();
    if (sockets.filter(socket => active(attachment(socket)) && attachment(socket).user.id !== identity.user.id).length >= 100) {
      return json({ error: "room_full" }, 429);
    }
    const pair = new WebSocketPair();
    const [client, server] = Object.values(pair);
    this.ctx.acceptWebSocket(server);
    const info = { ...identity, state: null, windowAt: Date.now(), messageCount: 0 };
    server.serializeAttachment(info);
    for (const socket of sockets) {
      const other = attachment(socket);
      if (other?.user.id === info.user.id) {
        socket.serializeAttachment({ ...other, closed: true });
        try {
          socket.send(JSON.stringify({ type: "replaced" }));
          socket.close(4009, "Connected in another tab");
        } catch {
          // A tab that already disconnected cannot block its replacement.
        }
      }
    }
    server.send(JSON.stringify({
      type: "welcome",
      selfId: info.user.id,
      players: sockets.map(attachment).filter(item =>
        active(item) && item.state && item.user.id !== info.user.id).map(player),
    }));
    await this.scheduleExpiry();
    return new Response(null, { status: 101, webSocket: client });
  }

  async scheduleExpiry() {
    const times = this.ctx.getWebSockets().map(attachment).filter(info => info && !info.closed)
      .map(info => info.expiresAt);
    if (times.length) await this.ctx.storage.setAlarm(Math.min(...times));
  }

  async alarm() {
    const departed = new Set();
    for (const socket of this.ctx.getWebSockets()) {
      const info = attachment(socket);
      if (info && !info.closed && info.expiresAt <= Date.now()) {
        socket.serializeAttachment({ ...info, closed: true });
        socket.close(4401, "Session expired");
        departed.add(info.user.id);
      }
    }
    for (const id of departed) this.broadcast({ type: "leave", id });
    await this.scheduleExpiry();
  }

  broadcast(message, except = null) {
    const encoded = JSON.stringify(message);
    for (const socket of this.ctx.getWebSockets()) {
      const info = attachment(socket);
      if (socket === except || !active(info)) continue;
      try {
        socket.send(encoded);
      } catch {
        socket.serializeAttachment({ ...info, closed: true });
        socket.close(1011, "Connection unavailable");
      }
    }
  }

  async webSocketMessage(socket, message) {
    const info = attachment(socket);
    if (!active(info)) {
      socket.close(4401, "Session expired");
      return;
    }
    if (typeof message !== "string" || new TextEncoder().encode(message).byteLength > 2048) {
      socket.close(1009, "Message too large");
      return;
    }
    const now = Date.now();
    if (now - info.windowAt >= 1000) {
      info.windowAt = now;
      info.messageCount = 0;
    }
    info.messageCount++;
    socket.serializeAttachment(info);
    if (info.messageCount > 20) {
      socket.close(1008, "Message rate exceeded");
      return;
    }
    let payload;
    try {
      payload = JSON.parse(message);
    } catch {
      socket.close(1008, "Invalid message");
      return;
    }
    if (payload?.type === "ping") {
      socket.send(JSON.stringify({ type: "pong" }));
      return;
    }
    const state = payload?.type === "state" ? validState(payload.state, info.room) : null;
    if (!state) {
      socket.close(1008, "Invalid player state");
      return;
    }
    info.state = state;
    socket.serializeAttachment(info);
    this.broadcast({ type: "presence", player: player(info) }, socket);
  }

  webSocketClose(socket, code) {
    const info = attachment(socket);
    socket.close(1000, "Connection closed");
    if (!info) return;
    socket.serializeAttachment({ ...info, closed: true });
    const replacement = this.ctx.getWebSockets().some(other =>
      other !== socket && active(attachment(other)) && attachment(other).user.id === info.user.id);
    if (!replacement) this.broadcast({ type: "leave", id: info.user.id }, socket);
  }

  webSocketError(socket) {
    const info = attachment(socket);
    socket.close(1011, "Connection error");
    if (info) {
      socket.serializeAttachment({ ...info, closed: true });
      const replacement = this.ctx.getWebSockets().some(other =>
        other !== socket && active(attachment(other)) && attachment(other).user.id === info.user.id);
      if (!replacement) this.broadcast({ type: "leave", id: info.user.id }, socket);
    }
  }

  revokeSession(sessionId) {
    const ids = new Set();
    for (const socket of this.ctx.getWebSockets()) {
      const info = attachment(socket);
      if (info?.sessionId !== sessionId) continue;
      ids.add(info.user.id);
      socket.serializeAttachment({ ...info, closed: true });
      socket.close(4401, "Signed out");
    }
    for (const id of ids) {
      const replacement = this.ctx.getWebSockets().some(socket =>
        active(attachment(socket)) && attachment(socket).user.id === id);
      if (!replacement) this.broadcast({ type: "leave", id });
    }
  }
}
