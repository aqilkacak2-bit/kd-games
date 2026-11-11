import test from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import { readFileSync } from 'node:fs';

const html = readFileSync(new URL('../../index.html', import.meta.url), 'utf8');
const names = [
  'liveHitPose', 'stepLiveHitEffects', 'startLiveHitEffect', 'playLiveHitSound', 'applyLiveHits',
  'reportLiveHit', 'segRectEntry', 'firstSolidOnSegment', 'liveTargetsOnSegment',
  'makeBullet', 'bSetSpeed', 'pointSolid', 'bulletStep', 'reportLiveExplosion',
  'kdExplode', 'beamUpdate', 'lightningFire', 'swordHit',
];
const functions = names.map(name => {
  const match = html.match(new RegExp('function ' + name + '\\([^]*?\\n\\}'));
  assert.ok(match, 'Missing game function ' + name);
  return match[0];
}).join('\n');
const weaponKeys = ['smg', 'shotgun', 'sniper', 'burst', 'ricochet', 'keris', 'laser', 'lightning', 'flame', 'rocket', 'grenade', 'freeze', 'thrown_grenade'];

function fixture() {
  const reports = [];
  const impacts = [];
  const player = { x: 0, y: 150, hp: 100, hp_max: 100, shield_cd: 0, invul: 0, hurt_t: 0, hsp: 0, vsp: 0, mode: 'normal', xstart: 0, ystart: 150, inventory: ['smg'] };
  const peers = [{ id: '200000000000000001', x: 100, y: 150, state: { look: {} } }];
  const weapons = Object.fromEntries(weaponKeys.map(key => [key, { knock: 4, blast_knock: 8 }]));
  Object.assign(weapons.laser, { beam_range: 240, tick: 6, damage: 3, pitch: 2 });
  Object.assign(weapons.lightning, { beam_range: 160, chain: 4, shock: 50, pitch: 2, colour: 1 });
  Object.assign(weapons.keris, { reach: 28, arc: 80, damage: 18 });
  const context = vm.createContext({
    R: { player, npcs: [], boxes: [], solids: [], kfx: [], w: 1000, h: 400, title: null },
    GL_: { flash: 0, shake: 0 },
    presence: { user: { id: '100000000000000001' }, players: () => peers, reportHit: (...args) => { reports.push(args); return true; } },
    liveHitEffects: new Map(), lastLiveHitSound: -Infinity, performance: { now: () => 0 }, WEAPONS: weapons, WHITE: 0xffffff, PAL: { wall: {} },
    npcBox: n => [Math.round(n.x) - 6, Math.round(n.y) - 26, Math.round(n.x) + 7, Math.round(n.y)],
    lerp: (a, b, t) => a + (b - a) * t,
    pdist: (x, y, a, b) => Math.hypot(a - x, b - y),
    pdir: (x, y, a, b) => (Math.atan2(y - b, a - x) * 180 / Math.PI + 360) % 360,
    angleDiff: (a, b) => ((a - b + 540) % 360) - 180,
    ldx: (length, angle) => length * Math.cos(angle * Math.PI / 180),
    ldy: (length, angle) => -length * Math.sin(angle * Math.PI / 180),
    sign: Math.sign, clamp: (v, min, max) => Math.max(min, Math.min(max, v)),
    rr: (a, b) => (a + b) / 2, irr: a => a, choose: (...args) => args[0],
    bSpeed: b => Math.hypot(b.hsp, b.vsp),
    bDir: b => (Math.atan2(-b.vsp, b.hsp) * 180 / Math.PI + 360) % 360,
    npcAt: () => null, boxAt: () => null, npcsOnLine: () => [],
    lineHitsSolid: () => false,
    vfxImpact: (...args) => impacts.push(args),
    kdSfx() {}, kdSfxP() {}, kdRecoilKick() {},
    makeKfx: (kind, x, y, options) => ({ kind, x, y, ...options }),
    npcHit() { assert.fail('A peer reaction called NPC damage'); },
    npcDamage() { assert.fail('A peer reaction called NPC damage'); },
    playerDamage() { assert.fail('A peer reaction called player damage'); },
    kdBoxDamage() {},
    blastMult: () => 1,
  });
  context.inSolidPoint = (x, y) => context.R.solids.find(solid => x >= solid.x1 && x < solid.x2 && y >= solid.y1 && y < solid.y2);
  vm.runInContext(functions, context);
  return { context, player, peers, reports, impacts };
}

test('all weapon reactions leave player state intact and expire visually', () => {
  const { context, player, peers, impacts } = fixture();
  const before = JSON.stringify(player);
  const peerBefore = JSON.stringify(peers);
  for (const weapon of weaponKeys) {
    context.applyLiveHits({ hits: [
      { targetId: context.presence.user.id, weapon, dir: 0 },
      { targetId: peers[0].id, weapon, dir: 180 },
    ] });
    assert.equal(JSON.stringify(player), before);
    assert.equal(JSON.stringify(peers), peerBefore);
    assert.equal(context.liveHitEffects.get(context.presence.user.id).age, 0);
    const pose = context.liveHitPose(context.presence.user.id, player.x, player.y);
    assert.notEqual(pose[0], player.x);
  }
  assert.equal(impacts.length, 0, 'Shared hits do not spawn a heavy particle burst');
  for (let frame = 0; frame < 75; frame++) context.stepLiveHitEffects();
  assert.equal(context.liveHitEffects.size, 0);
  assert.equal(JSON.stringify(player), before);
});

test('swept bullet contact reaches a fast-moving segment and stops normally', () => {
  const { context, reports } = fixture();
  let wallScans = 0;
  const firstSolidOnSegment = context.firstSolidOnSegment;
  context.firstSolidOnSegment = (...args) => {
    wallScans++;
    return firstSolidOnSegment(...args);
  };
  const bullet = context.makeBullet(70, 137, 0, 60, { weapon_key: 'smg' });
  context.bulletStep(bullet);
  assert.equal(wallScans, 1);
  assert.equal(reports.length, 1);
  assert.equal(reports[0][0], 'smg');
  assert.equal(bullet.dead, true);
});

test('the shooter reacts at bullet contact and its server echo does not restart the effect', () => {
  const { context, peers, reports, impacts } = fixture();
  const target = peers[0];
  const shot = () => context.bulletStep(context.makeBullet(70, 137, 0, 60, { weapon_key: 'smg' }));

  shot();
  assert.equal(reports.length, 1);
  assert.equal(context.liveHitEffects.get(target.id).age, 0);
  assert.equal(impacts.length, 0);

  context.stepLiveHitEffects();
  shot();
  assert.equal(reports.length, 2, 'Visual debounce does not block hit reports');
  const echo = { hits: [{ targetId: target.id, weapon: 'smg', dir: 0 }] };
  context.applyLiveHits({ ...echo, attackerId: context.presence.user.id });
  assert.equal(context.liveHitEffects.get(target.id).age, 1);

  context.applyLiveHits({ ...echo, attackerId: '300000000000000001' });
  assert.equal(context.liveHitEffects.get(target.id).age, 0, 'Other shooters still react from the server event');
  assert.equal(impacts.length, 0);
});

test('guest bullets skip the live collision sweep while wall impacts still render', () => {
  const { context, reports, impacts } = fixture();
  context.presence.user = null;
  context.firstSolidOnSegment = () => assert.fail('A guest ran a live-player sweep');
  const clearShot = context.makeBullet(70, 137, 0, 60, { weapon_key: 'smg' });
  context.bulletStep(clearShot);
  assert.equal(clearShot.dead, false);
  context.R.solids.push({ x1: 60, y1: 0, x2: 100, y2: 200 });
  context.bulletStep(context.makeBullet(70, 137, 0, 60, { weapon_key: 'smg' }));
  assert.equal(reports.length, 0);
  assert.equal(impacts.length, 1);
});

test('thin walls prevent peer hits on this step and later tunneled steps', () => {
  const { context, peers, reports } = fixture();
  context.R.solids.push({ x1: 90, y1: 0, x2: 91, y2: 200 });
  const bullet = context.makeBullet(70, 137, 0, 60, { weapon_key: 'smg' });
  context.bulletStep(bullet);
  assert.equal(bullet.live_path_blocked, true);
  peers[0].x = 160;
  context.bulletStep(bullet);
  assert.equal(reports.length, 0);
});

test('piercing rounds tag distinct peers and flame avoids repeat tags', () => {
  const { context, peers, reports } = fixture();
  peers.push({ id: '300000000000000001', x: 120, y: 150 });
  const bullet = context.makeBullet(70, 137, 0, 60, { weapon_key: 'sniper', pierce: 5 });
  context.bulletStep(bullet);
  assert.equal(reports.length, 2);
  assert.equal(bullet.pierce, 3);
  reports.length = 0;
  peers.length = 1;
  const flame = context.makeBullet(93, 137, 0, 3.4, { kind: 'flame', weapon_key: 'flame' });
  context.bulletStep(flame);
  context.bulletStep(flame);
  assert.equal(reports.length, 1);
});

test('rocket wall impact reports splash once even if legacy motion crosses the wall', () => {
  const { context, peers, reports } = fixture();
  peers[0].x = 65;
  context.R.solids.push({ x1: 50, y1: 0, x2: 51, y2: 200 });
  const rocket = context.makeBullet(48, 137, 0, 9, { kind: 'rocket', weapon_key: 'rocket', blast: 20, blast_knock: 3 });
  context.bulletStep(rocket);
  assert.equal(reports.length, 1);
  assert.equal(reports[0][0], 'rocket');
  rocket.life = 1;
  context.bulletStep(rocket);
  assert.equal(reports.length, 1);
});

test('a bouncing grenade still shares its final nonlethal splash', () => {
  const { context, peers, reports } = fixture();
  peers[0].x = 110;
  context.R.solids.push({ x1: 0, y1: 150, x2: 1000, y2: 180 });
  const grenade = context.makeBullet(100, 150.5, 270, 2, { kind: 'grenade', weapon_key: 'thrown_grenade', life: 1, grav: 0.2, blast: 34, blast_knock: 3 });
  context.bulletStep(grenade);
  assert.equal(reports.length, 1);
  assert.equal(reports[0][0], 'thrown_grenade');
  assert.equal(grenade.live_path_blocked, undefined);
});

test('laser respects its clipped wall and keris tags once per swing', () => {
  const { context, peers, reports } = fixture();
  context.gunMuzzle = () => [0, 137];
  const beam = { weapon: context.WEAPONS.laser, weapon_key: 'laser', aim_dir: 0, beam_tick: 5 };
  context.beamUpdate(beam);
  assert.equal(reports.length, 1);
  reports.length = 0;
  context.R.solids.push({ x1: 50, y1: 0, x2: 51, y2: 200 });
  beam.beam_tick = 5;
  context.beamUpdate(beam);
  assert.equal(reports.length, 0);
  context.R.solids.length = 0;
  peers[0].x = 25;
  const sword = { weapon: context.WEAPONS.keris, weapon_key: 'keris', owner: context.R.player, aim_dir: 0, swing_hit: [] };
  context.swordHit(sword);
  context.swordHit(sword);
  assert.equal(reports.length, 1);
  assert.equal(reports[0][0], 'keris');
});

test('lightning includes live targets without calling NPC status or damage', () => {
  const { context, peers, reports } = fixture();
  context.gunMuzzle = () => [0, 137];
  context.lightningFire({ weapon: context.WEAPONS.lightning, weapon_key: 'lightning', aim_dir: 0 });
  assert.equal(reports.length, 1);
  assert.equal(reports[0][0], 'lightning');
  assert.equal(peers[0].shock, undefined);
});
