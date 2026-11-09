import fs from 'node:fs';
import vm from 'node:vm';
import assert from 'node:assert/strict';
import test from 'node:test';
const source = fs.readFileSync(new URL('../../index.html', import.meta.url), 'utf8');
const start = source.indexOf('// Persistent outfits are isolated by Discord account');
const end = source.indexOf('if (presence)', start);
assert(start >= 0 && end > start, 'Persistence block markers exist');
const block = source.slice(start, end);
const keys = ['hair', 'hair_col', 'face', 'skin', 'top', 'top_col', 'bottom', 'bottom_col'];
const look = n => Object.fromEntries(keys.map(key => [key, n]));
const copy = value => JSON.parse(JSON.stringify(value));
const deferred = () => { let resolve, reject; const promise = new Promise((yes, no) => { resolve = yes; reject = no; }); return { promise, resolve, reject }; };
const drain = async () => { for (let n = 0; n < 5; n++) await new Promise(resolve => setImmediate(resolve)); };
function storage(data = new Map(), unavailable = false) {
  return { data, getItem(key) { if (unavailable) throw Error('storage unavailable'); return data.get(key) ?? null; }, setItem(key, value) { if (unavailable) throw Error('storage unavailable'); data.set(key, String(value)); }, removeItem(key) { if (unavailable) throw Error('storage unavailable'); data.delete(key); } };
}
function create(options = {}) {
  const local = options.local || storage();
  const session = options.session || storage();
  const toasts = [], saves = [], loads = [], events = {};
  const presence = {
    user: null,
    async loadCharacter() { loads.push(this.user?.id); return options.load ? options.load(this.user?.id) : { look: null, updatedAt: 0 }; },
    async saveCharacter(value) { const record = { account: this.user?.id, look: copy(value) }; saves.push(record); return options.save ? options.save(record) : { look: record.look, updatedAt: Date.now() }; }
  };
  const context = vm.createContext({
    GL_: { look: look(0), name: 'Guest' }, R: { player: { look: look(0) } }, SLOTS: keys.map(key => ({ key, names: ['zero', 'one', 'two'] })),
    presence, localStorage: local, sessionStorage: session, lookCopy: copy, GREY: 'grey', GREEN: 'green', kdToast: (text, color) => toasts.push({ text, color }),
    window: { addEventListener: (name, fn) => { events[name] = fn; } }, document: { hidden: false, addEventListener: (name, fn) => { events[name] = fn; } }, console, Date, Map
  });
  vm.runInContext(block + '\nglobalThis.api = { switchCharacterIdentity, saveChosenCharacter, flushCharacterSave, getSavedCharacter, validCharacterLook, applySavedCharacter };', context);
  return {
    context, local, session, presence, toasts, saves, loads, events,
    identify(id) { presence.user = id ? { id } : null; context.api.switchCharacterIdentity(presence.user); },
    choose(n) { context.GL_.look = look(n); context.R.player.look = look(n); context.api.saveChosenCharacter(); },
    current() { return copy(context.GL_.look); },
    saved(id) { return copy(context.api.getSavedCharacter(id)); }
  };
}

test('guest save persists and a fresh VM restores GL and player', async () => {
  const local = storage(); const first = create({ local }); first.identify(null); first.choose(1);
  assert.deepEqual(first.saved(null).look, look(1)); assert.equal(first.saved(null).pending, false);
  assert.match(first.toasts.at(-1).text, /saved in this browser/);
  const fresh = create({ local }); fresh.identify(null);
  assert.deepEqual(fresh.current(), look(1)); assert.deepEqual(copy(fresh.context.R.player.look), look(1));
  assert.equal(fresh.saves.length, 0);
});
test('cloud account outfit restores over guest, without writing', async () => {
  const app = create({ load: async () => ({ look: look(2), updatedAt: 123 }) }); app.identify('A'); await drain();
  assert.deepEqual(app.current(), look(2)); assert.deepEqual(copy(app.context.R.player.look), look(2));
  assert.equal(app.saved('A').pending, false); assert.equal(app.saves.length, 0);
});
test('confirmed Wear after slow GET cannot be overwritten', async () => {
  const get = deferred(); const app = create({ load: () => get.promise });
  app.identify('A'); app.choose(1); await drain();
  get.resolve({ look: look(2), updatedAt: 900 }); await drain();
  assert.deepEqual(app.current(), look(1)); assert.deepEqual(app.saved('A').look, look(1));
  assert.equal(app.saves.length, 1);
});
test('queued rapid saves serialize and persist final outfit', async () => {
  const firstSave = deferred(), lastSave = deferred();
  const app = create({ load: async () => ({ look: look(0), updatedAt: 1 }), save: record => record.look.hair === 1 ? firstSave.promise : lastSave.promise });
  app.identify('A'); await drain(); app.choose(1); app.choose(0); app.choose(2); await drain();
  assert.equal(app.saves.length, 1);
  firstSave.resolve({ look: look(1), updatedAt: 10 }); await drain();
  assert.equal(app.saves.length, 2); assert.deepEqual(app.saves[1].look, look(2));
  lastSave.resolve({ look: look(2), updatedAt: 20 }); await drain();
  assert.deepEqual(app.saved('A').look, look(2)); assert.equal(app.saved('A').pending, false);
});
test('failed account save stays pending and fresh startup retries before GET', async () => {
  const local = storage();
  const first = create({ local, load: async () => ({ look: look(0), updatedAt: 1 }), save: async () => { throw Error('offline'); } });
  first.identify('A'); await drain(); first.choose(2); await drain();
  assert.equal(first.saved('A').pending, true); assert.deepEqual(first.saved('A').look, look(2));
  assert.match(first.toasts.at(-1).text, /account sync pending/);
  const fresh = create({ local }); fresh.identify('A'); await drain();
  assert.deepEqual(fresh.current(), look(2)); assert.equal(fresh.loads.length, 0); assert.equal(fresh.saves.length, 1); assert.equal(fresh.saved('A').pending, false);
});
test('account switching and logout isolate outfits', async () => {
  const app = create({ load: async id => ({ look: look(id === 'A' ? 1 : 2), updatedAt: 1 }) });
  app.identify(null); app.choose(0); app.identify('A'); await drain(); assert.deepEqual(app.current(), look(1));
  app.identify('B'); await drain(); assert.deepEqual(app.current(), look(2));
  app.identify(null); assert.deepEqual(app.current(), look(0));
  app.identify('A'); await drain(); assert.deepEqual(app.current(), look(1));
  assert.deepEqual(app.saved('B').look, look(2)); assert.deepEqual(app.saved(null).look, look(0));
});
test('new account without cloud record adopts guest, not prior account', async () => {
  const app = create({ load: async id => ({ look: id === 'A' ? look(2) : null, updatedAt: 1 }) });
  app.identify(null); app.choose(1); app.identify('A'); await drain(); assert.deepEqual(app.current(), look(2));
  app.identify('B'); await drain(); assert.deepEqual(app.current(), look(1)); assert.deepEqual(app.saved('B').look, look(1));
});
test('storage unavailable reports failure honestly and keeps session choice', async () => {
  const app = create({ local: storage(new Map(), true), session: storage(new Map(), true) });
  app.identify(null); app.choose(1); assert.deepEqual(app.current(), look(1)); assert.equal(app.saved(null).deviceSaved, false);
  assert.match(app.toasts.at(-1).text, /Could not save outfit.*storage is unavailable/);
});
test('storage and cloud unavailable does not claim successful persistence', async () => {
  const app = create({ local: storage(new Map(), true), load: async () => ({ look: look(0), updatedAt: 1 }), save: async () => { throw Error('offline'); } });
  app.identify('A'); await drain(); app.choose(2); await drain();
  assert.equal(app.saved('A').pending, true); assert.equal(app.saved('A').deviceSaved, false);
  assert.match(app.toasts.at(-1).text, /Could not save outfit.*reconnect/);
});
test('choice before identity readiness is adopted by signed-in account', async () => {
  const app = create({ load: async () => ({ look: look(2), updatedAt: 1 }) });
  app.choose(1); app.identify('A'); await drain(); assert.deepEqual(app.current(), look(1)); assert.deepEqual(app.saved('A').look, look(1)); assert.equal(app.loads.length, 0);
});
test('malformed stored outfit is ignored; valid redirect migration persists', async () => {
  const local = storage(new Map([['kd-character-v1:guest', JSON.stringify({ look: { hair: 500 } })]]));
  const session = storage(new Map([['kd-discord-character', JSON.stringify({ look: look(2), guestName: 'Migrated' })]]));
  const app = create({ local, session }); app.identify(null); assert.deepEqual(app.current(), look(2)); assert.equal(app.context.GL_.name, 'Migrated'); assert.equal(session.data.has('kd-discord-character'), false);
});
test('late cloud GET from previous account cannot change new account', async () => {
  const getA = deferred();
  const app = create({ load: id => id === 'A' ? getA.promise : Promise.resolve({ look: look(2), updatedAt: 2 }) });
  app.identify('A'); app.identify('B'); await drain();
  getA.resolve({ look: look(1), updatedAt: 1 }); await drain();
  assert.deepEqual(app.current(), look(2)); assert.deepEqual(app.saved('B').look, look(2));
});
test('late PUT from logged-out account never changes current guest', async () => {
  const putA = deferred();
  const app = create({ load: async () => ({ look: look(0), updatedAt: 1 }), save: () => putA.promise });
  app.identify(null); app.choose(2); app.identify('A'); await drain(); app.choose(1); app.identify(null);
  putA.resolve({ look: look(1), updatedAt: 2 }); await drain();
  assert.deepEqual(app.current(), look(2)); assert.deepEqual(app.saved(null).look, look(2));
});
test('online event retries a locally pending account save', async () => {
  let offline = true;
  const app = create({ load: async () => ({ look: look(0), updatedAt: 1 }), save: async record => { if (offline) throw Error('offline'); return { look: record.look, updatedAt: 3 }; } });
  app.identify('A'); await drain(); app.choose(2); await drain(); assert.equal(app.saved('A').pending, true);
  offline = false; app.events.online(); await drain();
  assert.equal(app.saved('A').pending, false); assert.deepEqual(app.saved('A').look, look(2));
});
