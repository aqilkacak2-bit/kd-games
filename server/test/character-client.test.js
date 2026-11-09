import assert from 'node:assert/strict';
import fs from 'node:fs';
import test from 'node:test';
import vm from 'node:vm';

const source = fs.readFileSync(new URL('../../discord-presence.js', import.meta.url), 'utf8');
const appearance = { hair: 2, hair_col: 6, face: 1, skin: 3, top: 4, top_col: 8, bottom: 2, bottom_col: 5 };
const alice = { id: '100000000000000001', name: 'Alice', avatar: '' };
const bob = { id: '100000000000000002', name: 'Bob', avatar: '' };
const clone = value => JSON.parse(JSON.stringify(value));
const response = (body, status = 200) => ({ ok: status >= 200 && status < 300, status, json: async () => body });
const settle = () => new Promise(resolve => setImmediate(resolve));

class Element {
    constructor() {
        this.attributes = new Map();
        this.events = new Map();
        this.children = new Map();
        this.classes = new Set();
        this.classList = {
            add: name => this.classes.add(name),
            contains: name => this.classes.has(name),
            toggle: (name, value) => value ? this.classes.add(name) : this.classes.delete(name)
        };
    }
    addEventListener(name, handler) { this.events.set(name, handler); }
    setAttribute(name, value) { this.attributes.set(name, value); }
    getAttribute(name) { return this.attributes.get(name) || null; }
    removeAttribute(name) { this.attributes.delete(name); }
    querySelector(selector) {
        if (!this.children.has(selector)) this.children.set(selector, new Element());
        return this.children.get(selector);
    }
    before() {}
    append() {}
}

async function runtime(initialUser = alice) {
    let auth = { configured: true, user: initialUser };
    let characterHandler = async () => response({ look: appearance, updatedAt: 1730000000000 });
    let nextTimer = 0;
    const calls = [], events = new Map(), timers = new Map();
    const context = {
        console, URL, AbortController,
        performance: { now: () => 1000 },
        location: { href: 'https://game.krackeddevs.com/' },
        navigator: { onLine: true },
        history: { replaceState() {} },
        document: {
            head: new Element(), body: new Element(),
            createElement: () => new Element(),
            getElementById: () => new Element()
        },
        window: { addEventListener: (name, callback) => events.set(name, callback) },
        fetch: async (url, options) => {
            calls.push({ url, options });
            if (url === '/api/me') return response(auth);
            if (url === '/api/character') return characterHandler(options);
            throw new Error('Unexpected fetch ' + url);
        },
        setTimeout: (callback, delay) => {
            const id = ++nextTimer;
            timers.set(id, { callback, delay });
            return id;
        },
        clearTimeout: id => timers.delete(id),
        setInterval: () => 0,
        clearInterval() {}
    };
    vm.runInNewContext(source, context, { filename: 'discord-presence.js' });
    const client = context.window.KD_PRESENCE;
    client.init({ onIdentity() {}, onFocus() {}, beforeLogin() {}, getState: () => ({ room: 'rm_title' }) });
    await settle();
    return {
        client, calls, timers,
        handleCharacter: callback => { characterHandler = callback; },
        async identity(user) {
            auth = { configured: true, user };
            events.get('pageshow')({ persisted: true });
            await settle();
        }
    };
}

test('loads and saves validated outfit records using same-origin requests', async () => {
    const r = await runtime();
    assert.equal(r.calls.filter(call => call.url === '/api/character').length, 0);
    const loaded = await r.client.loadCharacter();
    assert.deepEqual(clone(loaded), { look: appearance, updatedAt: 1730000000000 });
    assert.notEqual(loaded.look, appearance);
    const get = r.calls.at(-1);
    assert.equal(get.url, '/api/character');
    assert.equal(get.options.method, 'GET');
    assert.equal(get.options.credentials, 'same-origin');
    assert.equal(get.options.cache, 'no-store');
    assert.equal(get.options.headers.Accept, 'application/json');
    assert.ok(get.options.signal instanceof AbortSignal);

    const input = { ...appearance, top_col: 2 };
    r.handleCharacter(async options => response({ look: JSON.parse(options.body).look, updatedAt: 1730000000001 }));
    const saved = await r.client.saveCharacter(input);
    assert.deepEqual(clone(saved.look), input);
    const put = r.calls.at(-1);
    assert.equal(put.options.method, 'PUT');
    assert.equal(put.options.headers['Content-Type'], 'application/json');
    assert.equal(put.options.credentials, 'same-origin');
    assert.equal(put.options.cache, 'no-store');
    assert.deepEqual(JSON.parse(put.options.body), { look: input });
    assert.equal(r.timers.size, 0);
});

test('accepts an empty profile only when both profile fields are null', async () => {
    const r = await runtime();
    r.handleCharacter(async () => response({ look: null, updatedAt: null }));
    assert.deepEqual(clone(await r.client.loadCharacter()), { look: null, updatedAt: null });
    await assert.rejects(r.client.saveCharacter(appearance), /invalid_character_response/);
    for (const record of [{ look: null, updatedAt: 123 }, {}, { look: appearance, updatedAt: null }]) {
        r.handleCharacter(async () => response(record));
        await assert.rejects(r.client.loadCharacter(), /invalid_character_response/);
    }
});

test('rejects invalid input locally and malformed returned outfits', async () => {
    const r = await runtime();
    const invalid = [null, [], {}, { ...appearance, top: 6 }, { ...appearance, hair: -1 },
        { ...appearance, skin: 0.5 }, { ...appearance, face: '1' }, { ...appearance, accountId: alice.id }];
    for (const look of invalid) await assert.rejects(r.client.saveCharacter(look), /invalid_character/);
    assert.equal(r.calls.filter(call => call.url === '/api/character').length, 0);
    for (const look of invalid) {
        r.handleCharacter(async () => response({ look, updatedAt: 1730000000000 }));
        await assert.rejects(r.client.loadCharacter(), /invalid_character_response/);
    }
    for (const updatedAt of [0, -1, 1.5, Infinity, Number.MAX_SAFE_INTEGER + 1, '1730000000000']) {
        r.handleCharacter(async () => response({ look: appearance, updatedAt }));
        await assert.rejects(r.client.loadCharacter(), /invalid_character_response/);
    }
});

test('requires a signed-in user before loading or saving', async () => {
    const r = await runtime(null);
    await assert.rejects(r.client.loadCharacter(), /sign_in_required/);
    await assert.rejects(r.client.saveCharacter(appearance), /sign_in_required/);
    assert.equal(r.calls.filter(call => call.url === '/api/character').length, 0);
});

test('HTTP, malformed JSON and network failures reject without clearing identity', async () => {
    const r = await runtime();
    for (const status of [401, 403, 429, 503]) {
        r.handleCharacter(async () => response({ error: 'failed' }, status));
        await assert.rejects(r.client.loadCharacter(), /character_unavailable/);
        assert.equal(r.client.user.id, alice.id);
    }
    r.handleCharacter(async () => ({ ok: true, json: async () => { throw new SyntaxError('Invalid JSON'); } }));
    await assert.rejects(r.client.loadCharacter(), /Invalid JSON/);
    r.handleCharacter(async () => { throw new TypeError('Network failure'); });
    await assert.rejects(r.client.saveCharacter(appearance), /Network failure/);
    assert.equal(r.client.user.id, alice.id);
    assert.equal(r.timers.size, 0);
});

test('aborts a stalled request after ten seconds and clears its timeout', async () => {
    const r = await runtime();
    r.handleCharacter(options => new Promise((resolve, reject) => {
        options.signal.addEventListener('abort', () => reject(options.signal.reason));
    }));
    const request = r.client.loadCharacter();
    const rejection = assert.rejects(request, { name: 'AbortError' });
    const [timer] = r.timers.values();
    assert.equal(timer.delay, 10000);
    timer.callback();
    await rejection;
    assert.equal(r.timers.size, 0);
});

test('discards load and save responses after identity or auth session changes', async () => {
    for (const method of ['loadCharacter', 'saveCharacter']) {
        for (const nextUser of [bob, null, alice]) {
            const r = await runtime();
            let finish;
            r.handleCharacter(() => new Promise(resolve => { finish = resolve; }));
            const request = r.client[method](appearance);
            const rejected = assert.rejects(request, /character_identity_changed/);
            await r.identity(nextUser);
            finish(response({ look: appearance, updatedAt: 1730000000000 }));
            await rejected;
            assert.equal(r.client.user?.id || null, nextUser?.id || null);
            assert.equal(r.timers.size, 0);
        }
    }
});
