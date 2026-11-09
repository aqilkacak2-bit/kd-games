/// Weapons (KDlab1)
/// 12 weapons. Each has a slot: keys 1-9, 0, -, = (or the mouse wheel) switch between the ones you own.
///
///   type "gun"       : fires obj_bullet. "kind" picks the projectile:
///                        "bullet"  normal shot   (pellets / burst / pierce / bounces / knock)
///                        "flame"   flamethrower particle, sets people on fire (burn)
///                        "ice"     freeze ray shot, people can't move (freeze)
///                        "rocket"  speeds up, explodes on impact (blast)
///                        "grenade" arcs with gravity, bounces, explodes after a moment (blast)
///   type "beam"      : hold for a continuous laser that hits everyone along the line
///   type "lightning" : bolt that jumps from person to person (chain)
///   type "melee"     : swings through an arc in front of you
///
/// ADD A WEAPON: draw its sprite pointing RIGHT with the origin on the grip (see spr_gun),
/// add an entry to kd_weapons() and its key to kd_weapon_order().

/// defaults for every field, so each weapon only lists what is different
function kd_weapon_def(_over)
{
    var _d = {
        name         : "Weapon",
        desc         : "",
        type         : "gun",
        kind         : "bullet",
        sprite       : spr_gun,
        hold_dist    : 8,      // pixels from the aim pivot (chest) to the grip
        muzzle_x     : 5,      // muzzle (or blade tip) relative to the sprite origin (grip)
        muzzle_y     : -6,
        support_x    : 4,      // where the BACK hand holds it, relative to the grip
        support_y    : -1,
        fire_delay   : 7,      // steps between shots / swings
        auto         : true,   // hold to keep firing
        bullet_speed : 6,
        bullet_life  : 90,     // steps before a projectile fades (range)
        spread       : 3,      // degrees
        recoil       : 2,      // pixels the gun kicks back
        pellets      : 1,
        burst        : 1,
        burst_gap    : 0,
        pierce       : 0,
        bounces      : 0,
        knock        : 1,
        damage       : 6,       // health taken per hit (per pellet / per beam tick)
        blast_damage : 0,       // explosion damage at the centre
        colour       : c_white, // projectile / beam colour
        bullet_scale : 1,
        pitch        : 1,       // shot sound pitch
        burn         : 0,       // steps a person keeps burning
        freeze       : 0,       // steps a person stays frozen
        shock        : 0,       // steps a person is stunned by lightning
        blast        : 0,       // explosion radius (rockets / grenades)
        blast_knock  : 0,
        grav         : 0,       // projectile gravity (grenades)
        beam_range   : 0,       // beam / lightning reach
        tick         : 6,       // beam: steps between hits
        chain        : 0,       // lightning: people it can jump to
        reach        : 0,       // melee
        arc          : 0,       // melee: half-angle of the swing
        swing_time   : 0        // melee: steps per swing
    };
    var _k = variable_struct_get_names(_over);
    for (var _i = 0; _i < array_length(_k); _i++)
    {
        variable_struct_set(_d, _k[_i], variable_struct_get(_over, _k[_i]));
    }
    return _d;
}

function kd_weapons()
{
    static w = undefined;
    if (is_undefined(w))
    {
        w = {
            // 1 - fast, full auto
            smg : kd_weapon_def({
                damage : 6,
                name : "KD Vector SMG", desc : "Full auto - hold to spray.",
                sprite : spr_gun, hold_dist : 8, muzzle_x : 5, muzzle_y : -6, support_x : 4, support_y : -1,
                fire_delay : 7, auto : true, bullet_speed : 6, spread : 3, recoil : 2, knock : 1
            }),
            // 2 - six pellets, short range, big knockback
            shotgun : kd_weapon_def({
                damage : 5,
                name : "Hotfix Shotgun", desc : "6 pellets per shot, short range, pushes people back.",
                sprite : spr_gun_shotgun, hold_dist : 6, muzzle_x : 19, muzzle_y : -6, support_x : 9, support_y : -3,
                fire_delay : 42, auto : false, bullet_speed : 5.5, bullet_life : 26, spread : 16, recoil : 4,
                pellets : 6, knock : 4, colour : make_colour_rgb(255, 170, 90), pitch : 0.7
            }),
            // 3 - slow, very fast bullet that passes through everyone in a line
            sniper : kd_weapon_def({
                damage : 45,
                name : "Deploy Rifle", desc : "Sniper - the bullet pierces through up to 5 people.",
                sprite : spr_gun_sniper, hold_dist : 6, muzzle_x : 20, muzzle_y : -5, support_x : 10, support_y : -2,
                fire_delay : 55, auto : false, bullet_speed : 12, bullet_life : 120, spread : 0, recoil : 5,
                pierce : 5, knock : 6, colour : make_colour_rgb(110, 255, 150), bullet_scale : 2.5, pitch : 0.55
            }),
            // 4 - one click = 3-round burst
            burst : kd_weapon_def({
                damage : 9,
                name : "Commit Burst Rifle", desc : "Each click fires a 3-round burst.",
                sprite : spr_gun_burst, hold_dist : 7, muzzle_x : 20, muzzle_y : -5, support_x : 6, support_y : -2,
                fire_delay : 24, auto : false, bullet_speed : 7.5, spread : 1.5, recoil : 2,
                burst : 3, burst_gap : 4, knock : 2, colour : make_colour_rgb(255, 214, 80), pitch : 1.2
            }),
            // 5 - energy shots bounce off walls and floors
            ricochet : kd_weapon_def({
                damage : 7,
                name : "Recursion Blaster", desc : "Shots bounce off walls up to 3 times.",
                sprite : spr_gun_ricochet, hold_dist : 7, muzzle_x : 19, muzzle_y : -4, support_x : 6, support_y : -2,
                fire_delay : 14, auto : true, bullet_speed : 4.5, bullet_life : 170, spread : 2, recoil : 1.5,
                bounces : 3, knock : 1, colour : make_colour_rgb(90, 226, 245), bullet_scale : 1.3, pitch : 1.45
            }),
            // 6 - melee: alternating slashes in front of you
            keris : kd_weapon_def({
                damage : 18,
                name : "KD Keris", desc : "Sword - slash everyone in front of you. Hold to keep swinging.",
                type : "melee", sprite : spr_sword_keris, hold_dist : 6, muzzle_x : 17, muzzle_y : -6,
                support_x : 0, support_y : 0, fire_delay : 20, auto : true, recoil : 0,
                knock : 7, reach : 28, arc : 80, swing_time : 11, pitch : 1.5
            }),
            // 7 - continuous laser beam
            laser : kd_weapon_def({
                damage : 3,
                name : "Prod Laser", desc : "Hold for a beam that hits everyone along the line.",
                type : "beam", sprite : spr_gun_laser, hold_dist : 6, muzzle_x : 21, muzzle_y : -4, support_x : 7, support_y : -2,
                fire_delay : 0, auto : true, recoil : 0.6, beam_range : 240, tick : 6, knock : 1,
                colour : make_colour_rgb(255, 60, 140), pitch : 2
            }),
            // 8 - chain lightning
            lightning : kd_weapon_def({
                damage : 20,
                name : "Stack Overflow Coil", desc : "Lightning jumps from person to person and stuns them.",
                type : "lightning", sprite : spr_gun_lightning, hold_dist : 6, muzzle_x : 21, muzzle_y : -4, support_x : 7, support_y : -2,
                fire_delay : 32, auto : false, recoil : 3, beam_range : 160, chain : 4, shock : 50, knock : 3,
                colour : make_colour_rgb(150, 220, 255), pitch : 1.8
            }),
            // 9 - flamethrower
            flame : kd_weapon_def({
                damage : 1,
                name : "Hot Reload", desc : "Flamethrower - short range, sets people on fire.",
                kind : "flame", sprite : spr_gun_flame, hold_dist : 6, muzzle_x : 21, muzzle_y : -4, support_x : 8, support_y : -1,
                fire_delay : 2, auto : true, bullet_speed : 3.4, bullet_life : 28, spread : 9, recoil : 0.5,
                pellets : 2, burn : 150, knock : 0, colour : make_colour_rgb(255, 150, 40), pitch : 0.6
            }),
            // 0 - rocket launcher
            rocket : kd_weapon_def({
                damage : 0, blast_damage : 55,
                name : "Merge Conflict RPG", desc : "Rocket - speeds up and explodes, blasting everyone away.",
                kind : "rocket", sprite : spr_gun_rocket, hold_dist : 5, muzzle_x : 21, muzzle_y : -4, support_x : 10, support_y : -1,
                fire_delay : 60, auto : false, bullet_speed : 1.5, bullet_life : 150, spread : 0, recoil : 6,
                blast : 42, blast_knock : 14, pitch : 0.5
            }),
            // - grenade launcher
            grenade : kd_weapon_def({
                damage : 0, blast_damage : 45,
                name : "Bug Bomb Launcher", desc : "Lobs bouncing grenades that explode after a moment.",
                kind : "grenade", sprite : spr_gun_grenade, hold_dist : 6, muzzle_x : 21, muzzle_y : -5, support_x : 6, support_y : -2,
                fire_delay : 40, auto : false, bullet_speed : 4.6, bullet_life : 80, spread : 1, recoil : 4,
                grav : 0.18, blast : 36, blast_knock : 11, pitch : 0.8
            }),
            // = freeze ray
            freeze : kd_weapon_def({
                damage : 4,
                name : "Cold Start Cryo", desc : "Freeze ray - frozen people can't move for a few seconds.",
                kind : "ice", sprite : spr_gun_freeze, hold_dist : 6, muzzle_x : 21, muzzle_y : -3, support_x : 7, support_y : -2,
                fire_delay : 9, auto : true, bullet_speed : 4, bullet_life : 70, spread : 3, recoil : 1,
                freeze : 180, knock : 0, colour : make_colour_rgb(170, 240, 255), pitch : 1.6
            })
        };
    }
    return w;
}

/// slot order: first entry = key 1
function kd_weapon_order()
{
    return ["smg", "shotgun", "sniper", "burst", "ricochet", "keris",
            "laser", "lightning", "flame", "rocket", "grenade", "freeze"];
}

/// the key for each slot (189 = minus, 187 = equals on most keyboards)
function kd_weapon_keys()
{
    return [ord("1"), ord("2"), ord("3"), ord("4"), ord("5"), ord("6"),
            ord("7"), ord("8"), ord("9"), ord("0"), 189, 187];
}

function kd_weapon_key_labels()
{
    return ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "="];
}

function kd_weapon_get(_key)
{
    var _w = kd_weapons();
    if (variable_struct_exists(_w, _key)) return variable_struct_get(_w, _key);
    return undefined;
}

function kd_weapon_owned(_key)
{
    for (var _i = 0; _i < array_length(global.kd_owned); _i++)
    {
        if (global.kd_owned[_i] == _key) return true;
    }
    return false;
}

/// give a weapon to the player (and remember you own it): creates obj_gun that follows the player
function kd_equip(_owner, _key)
{
    var _wp = kd_weapon_get(_key);
    if (is_undefined(_wp)) return;
    if (!kd_weapon_owned(_key)) array_push(global.kd_owned, _key);
    with (_owner)
    {
        if (instance_exists(gun)) instance_destroy(gun);

        gun = instance_create_depth(x, y, depth - 1, obj_gun);
        gun.owner        = id;
        gun.weapon_key   = _key;
        gun.weapon       = _wp;
        gun.sprite_index = _wp.sprite;
        gun.equipped     = true;

        // the arms (obj_hand) already exist - just give them the weapon to hold
        if (!instance_exists(hand))
        {
            hand = instance_create_depth(x, y, depth - 2, obj_hand);
            hand.owner = id;
        }
        hand.gun = gun;
        if (instance_exists(hand_back)) hand_back.gun = gun;
    }
    global.kd_weapon = _key;
    global.kd_weapon_out = true;
}

/// mouse wheel: next / previous weapon you own
function kd_weapon_cycle(_owner, _dir)
{
    var _order = kd_weapon_order();
    var _n = array_length(_order);
    var _cur = 0;
    for (var _i = 0; _i < _n; _i++) if (_order[_i] == global.kd_weapon) _cur = _i;
    for (var _s = 1; _s < _n; _s++)
    {
        var _k = _order[((_cur + _dir * _s) mod _n + _n) mod _n];
        if (kd_weapon_owned(_k))
        {
            kd_equip(_owner, _k);
            kd_sfx(snd_holster, 0.05);
            return;
        }
    }
}

/// muzzle position of an equipped weapon (runs in obj_gun scope) -> [x, y]
function kd_gun_muzzle()
{
    var _w = weapon;
    return [x + lengthdir_x(_w.muzzle_x, aim_dir) + lengthdir_x(_w.muzzle_y * image_yscale, aim_dir - 90),
            y + lengthdir_y(_w.muzzle_x, aim_dir) + lengthdir_y(_w.muzzle_y * image_yscale, aim_dir - 90)];
}

/// fire one shot (runs in the scope of an equipped obj_gun)
function kd_gun_shoot()
{
    var _w = weapon;
    recoil   = _w.recoil;
    flash    = 3;
    kick_ang = _w.recoil * 3;                                   // muzzle flips up a little
    if (instance_exists(owner)) kd_recoil_kick(owner, aim_dir, _w.recoil * 0.55);   // shooting down: small hop
    switch (_w.kind)
    {
        case "flame":   flash = 0; if (irandom(3) == 0) kd_sfx_p(snd_skid, 0.6, 0.1, 0.25); break;
        case "rocket":  kd_sfx_p(snd_dash, 0.6, 0.05, 0.9); global.kd_shake = max(global.kd_shake, 4); break;
        case "grenade": kd_sfx_p(snd_jump, 0.6, 0.05, 0.9); break;
        case "ice":     kd_sfx_p(snd_chat_send, 1.6, 0.1, 0.35); break;
        default:        kd_sfx_p(snd_shoot, _w.pitch, 0.08, 0.7);
    }
    var _m  = kd_gun_muzzle();
    var _mx = _m[0];
    var _my = _m[1];
    for (var _p = 0; _p < _w.pellets; _p++)
    {
        var _dir = aim_dir + random_range(-_w.spread, _w.spread);
        var _spd = _w.bullet_speed;
        if (_w.pellets > 1)
        {
            // fan the pellets evenly, with a little jitter
            _dir = aim_dir + lerp(-_w.spread, _w.spread, _p / (_w.pellets - 1)) + random_range(-2, 2);
            _spd = _w.bullet_speed * random_range(0.9, 1.1);
        }
        var _b = instance_create_depth(_mx, _my, depth - 1, obj_bullet);
        _b.direction    = _dir;
        _b.speed        = _spd;
        _b.image_angle  = _dir;
        _b.kind         = _w.kind;
        _b.life         = _w.bullet_life;
        _b.life_max     = _w.bullet_life;
        _b.pierce       = _w.pierce;
        _b.bounces      = _w.bounces;
        _b.knock        = _w.knock;
        _b.damage       = _w.damage;
        _b.blast_damage = _w.blast_damage;
        _b.burn         = _w.burn;
        _b.freeze       = _w.freeze;
        _b.blast        = _w.blast;
        _b.blast_knock  = _w.blast_knock;
        _b.grav         = _w.grav;
        _b.image_blend  = _w.colour;
        _b.image_xscale = _w.bullet_scale;
    }
    muzzle_x = _mx;
    muzzle_y = _my;
}

/// laser beam: find where it stops and hit everyone on it (runs in obj_gun scope)
function kd_beam_update()
{
    var _w  = weapon;
    var _m  = kd_gun_muzzle();
    var _ex = _m[0];
    var _ey = _m[1];
    var _len = 0;
    while (_len < _w.beam_range)
    {
        _len += 2;
        _ex = _m[0] + lengthdir_x(_len, aim_dir);
        _ey = _m[1] + lengthdir_y(_len, aim_dir);
        if (position_meeting(_ex, _ey, obj_solid)) break;
    }
    beam_x1 = _m[0];
    beam_y1 = _m[1];
    beam_x2 = _ex;
    beam_y2 = _ey;
    recoil  = _w.recoil;
    beam_tick += 1;
    if (beam_tick mod _w.tick == 0)
    {
        if (instance_exists(owner)) kd_recoil_kick(owner, aim_dir, 0.5);
        var _bx = instance_position(_ex, _ey, obj_item_box);
        if (_bx != noone) kd_box_damage(_bx, _w.damage * 2);
        var _list = ds_list_create();
        var _n = collision_line_list(_m[0], _m[1], _ex, _ey, obj_kd_npc, false, true, _list, false);
        for (var _i = 0; _i < _n; _i++)
        {
            kd_npc_hit(_list[| _i], aim_dir, _w.knock, choose("Ow, that burns!", "Who turned on the laser?!", "Pew pew... OUCH"), _w.damage);
        }
        ds_list_destroy(_list);
        kd_sfx_p(snd_shoot, _w.pitch, 0.05, 0.22);
        kd_vfx_impact(_ex, _ey, aim_dir, false, kd_pal().wall, aim_dir + 180, 100000, 0.4);
    }
}

/// chain lightning (runs in obj_gun scope)
function kd_lightning_fire()
{
    var _w = weapon;
    recoil = _w.recoil;
    flash  = 4;
    if (instance_exists(owner)) kd_recoil_kick(owner, aim_dir, 1.6);
    var _m   = kd_gun_muzzle();
    var _pts = [_m[0], _m[1]];
    var _hit = [];
    var _cx  = _m[0];
    var _cy  = _m[1];
    var _range = _w.beam_range;
    var _cone  = true;      // the first jump must be roughly where you aim
    var _aim   = aim_dir;
    for (var _c = 0; _c < _w.chain; _c++)
    {
        var _best = noone;
        var _bd   = _range;
        with (obj_kd_npc)
        {
            var _tx = x;
            var _ty = y - 13;
            var _d  = point_distance(_cx, _cy, _tx, _ty);
            if (_d > _bd) continue;
            if (_cone && abs(angle_difference(point_direction(_cx, _cy, _tx, _ty), _aim)) > 35) continue;
            var _skip = false;
            for (var _j = 0; _j < array_length(_hit); _j++) if (_hit[_j] == id) _skip = true;
            if (_skip) continue;
            if (collision_line(_cx, _cy, _tx, _ty, obj_solid, false, true) != noone) continue;
            _best = id;
            _bd   = _d;
        }
        if (_best == noone) break;
        array_push(_hit, _best);
        var _dir = point_direction(_cx, _cy, _best.x, _best.y - 13);
        _cx = _best.x;
        _cy = _best.y - 13;
        array_push(_pts, _cx, _cy);
        _best.shock = max(_best.shock, _w.shock);
        kd_npc_hit(_best, _dir, _w.knock, choose("BZZZT!", "My hair!", "Who pushed to prod?!"), _w.damage);
        _range = 90;
        _cone  = false;
    }
    if (array_length(_hit) == 0)
    {
        // nobody in front: the bolt strikes the first wall in front of you
        var _len = 0;
        var _ex = _m[0];
        var _ey = _m[1];
        while (_len < 120)
        {
            _len += 3;
            _ex = _m[0] + lengthdir_x(_len, _aim);
            _ey = _m[1] + lengthdir_y(_len, _aim);
            if (position_meeting(_ex, _ey, obj_solid)) break;
        }
        array_push(_pts, _ex, _ey);
        kd_vfx_impact(_ex, _ey, _aim, false, kd_pal().wall, _aim + 180, 100000, 0.7);
    }
    var _fx = instance_create_depth(0, 0, depth - 2, obj_kd_fx);
    _fx.kind = "bolt";
    _fx.pts  = _pts;
    _fx.life = 14;
    _fx.col  = _w.colour;
    kd_sfx_p(snd_skid, 1.8, 0.1, 0.8);
    kd_sfx_p(snd_shoot, 0.7, 0.05, 0.5);
    global.kd_flash = max(global.kd_flash, 0.08);
}

/// sword hit check during a swing (runs in the scope of an equipped obj_gun)
function kd_sword_hit()
{
    var _w  = weapon;
    var _me = id;
    var _px = owner.x;
    var _py = owner.y - 13;
    with (obj_kd_npc)
    {
        var _cx = x;
        var _cy = y - 13;
        if (point_distance(_px, _py, _cx, _cy) > _w.reach + 6) continue;
        if (abs(angle_difference(point_direction(_px, _py, _cx, _cy), _me.aim_dir)) > _w.arc + 20) continue;
        var _seen = false;
        for (var _i = 0; _i < array_length(_me.swing_hit); _i++) if (_me.swing_hit[_i] == id) _seen = true;
        if (_seen) continue;
        array_push(_me.swing_hit, id);
        kd_npc_hit(id, _me.aim_dir, _w.knock, choose("Hey, that's sharp!", "Whoa, a keris!", "Easy there, pendekar!", "Not the face!"), _w.damage);
        kd_vfx_impact(_cx, _cy, _me.aim_dir, false, -1, 0, y, 0.8);
    }
    // item boxes in reach get slashed too
    with (obj_item_box)
    {
        if (point_distance(_px, _py, x + 8, y + 8) > _w.reach + 10) continue;
        if (abs(angle_difference(point_direction(_px, _py, x + 8, y + 8), _me.aim_dir)) > _w.arc + 20) continue;
        var _hit_before = false;
        for (var _j = 0; _j < array_length(_me.swing_hit); _j++) if (_me.swing_hit[_j] == id) _hit_before = true;
        if (_hit_before) continue;
        array_push(_me.swing_hit, id);
        kd_box_damage(id, _w.damage);
    }
}

/// how a person reacts to being hit: loses health, white flash, pushed back, says something
function kd_npc_hit(_npc, _dir, _knock, _say, _dmg)
{
    if (is_undefined(_dmg)) _dmg = 0;
    if (_npc.ko > 0) return;
    kd_npc_damage(_npc, _dmg);
    if (_dmg >= 4) kd_vfx_blood(_npc, _dir, clamp(_dmg / 20, 0.25, 1.3));   // blood.ts
    with (_npc)
    {
        hit_flash = 8;
        if (_knock != 0)
        {
            var _kx = lengthdir_x(_knock, _dir);
            if (!place_meeting(x + _kx, y, obj_solid)) x += _kx;
        }
        if (bubble_timer <= 0 && _say != "")
        {
            bubble_text  = _say;
            bubble_timer = 90;
        }
    }
    kd_sfx(snd_hit, 0.1, 0.7);
}

/// explosion: damages and pushes everyone in the radius away, pops them into the air
function kd_explode(_x, _y, _r, _knock, _dmg)
{
    if (is_undefined(_dmg)) _dmg = 40;
    with (obj_kd_npc)
    {
        var _d = point_distance(_x, _y, x, y - 13);
        if (_d > _r) continue;
        var _f   = 1 - _d / _r;
        kd_npc_damage(id, round(_dmg * (0.4 + 0.6 * _f)));
        if (ko > 0) continue;
        var _dir = point_direction(_x, _y, x, y - 13);
        hit_flash = 12;
        var _kx = lengthdir_x(_knock * (0.4 + 0.6 * _f), _dir);
        var _i = 0;
        while (_i < abs(_kx) && !place_meeting(x + sign(_kx), y, obj_solid)) { x += sign(_kx); _i += 1; }
        vsp = -2 - 2 * _f;
        if (_f > 0.45 && freeze <= 0) burn = max(burn, 120);   // close to the blast: on fire
        if (bubble_timer <= 0)
        {
            bubble_text  = choose("WHOA!", "Merge conflict!!", "My ears!", "Not in the lab!");
            bubble_timer = 90;
        }
    }
    // item boxes in the blast break open
    with (obj_item_box) if (point_distance(_x, _y, x + 8, y + 8) < _r + 8) kd_box_damage(id, _dmg);
    // you get hurt too if you stand too close (half damage)
    with (obj_player)
    {
        var _pd = point_distance(_x, _y, x, y - 13);
        if (_pd <= _r) kd_player_damage(round(_dmg * 0.5 * (0.4 + 0.6 * (1 - _pd / _r))), _x, _y);
    }
    kd_vfx_impact(_x, _y, 90, false, -1, 0, 100000, 1.8);    // impact.ts burst
    var _fx = instance_create_depth(_x, _y, -50, obj_kd_fx);
    _fx.kind = "boom";
    _fx.r    = _r;
    _fx.life = 22;
    repeat (6)
    {
        var _s = instance_create_depth(_x + random_range(-_r * 0.4, _r * 0.4), _y + random_range(-_r * 0.3, _r * 0.2), -49, obj_kd_fx);
        _s.kind = "smoke";
        _s.life = irandom_range(30, 50);
        _s.r    = random_range(4, 8);
    }
    global.kd_shake = max(global.kd_shake, 10);
    global.kd_flash = max(global.kd_flash, 0.18);
    kd_sfx_p(snd_land, 0.45, 0.05, 1);
    kd_sfx_p(snd_hit, 0.5, 0.05, 0.9);
}

// ---------------- people: burning / frozen / shocked ----------------

/// call in the NPC Step (after the wander logic, before gravity)
function kd_npc_status_step()
{
    if (ko > 0)
    {
        // knocked out: lie still, then get back up with full health
        ko -= 1;
        walking = false;
        anim_t -= 1;
        if (ko == 0)
        {
            hp = hp_max;
            kd_vfx_heal(id);
            bubble_text  = choose("Back to work!", "Rebooted. Where was I?", "OK, I'm good.");
            bubble_timer = 90;
        }
        return;
    }
    if (burn > 0)
    {
        burn -= 1;
        walking    = true;              // run around in a panic
        move_speed = 1.6;
        if (burn mod 25 == 0) { if (irandom(2) == 0) facing = -facing; hit_flash = 3; }
        if (burn mod 10 == 0) kd_npc_damage(id, 2);
        if (burn mod 40 == 0 && bubble_timer <= 0)
        {
            bubble_text  = choose("Hot hot hot!", "PANAS!!", "Who deployed fire?!", "Water! Water!");
            bubble_timer = 60;
        }
        if (!instance_exists(fire_fx)) fire_fx = kd_vfx_fire(id);     // fire.ts
        if (burn == 0) { move_speed = base_speed; walking = false; }
    }
    if (freeze > 0)
    {
        freeze -= 1;
        burn       = 0;
        move_speed = base_speed;
        walking    = false;
        anim_t    -= 1;                 // frozen in one pose
        if (freeze == 0 && bubble_timer <= 0)
        {
            bubble_text  = choose("Brrr...", "Who set the aircond to -20?", "I can feel my hands again");
            bubble_timer = 70;
        }
    }
    if (shock > 0)
    {
        shock  -= 1;
        walking = false;
    }
}

/// call in the NPC Draw, after the body is drawn
function kd_npc_status_draw(_st, _fr)
{
    if (ko > 0)
    {
        // knocked out: greyed out + floating "z z"
        gpu_set_fog(true, make_colour_rgb(60, 64, 76), 0, 1);
        kd_draw(x, y, facing, _st, _fr, look, 1, c_white, 0.45, false);
        gpu_set_fog(false, c_white, 0, 0);
        var _zt = (current_time / 400) mod 2;
        draw_set_colour(c_white);
        draw_text_transformed(x + 6, y - 36 - _zt * 4, "z", 0.35, 0.35, 0);
        draw_text_transformed(x + 10, y - 44 - _zt * 4, "Z", 0.45, 0.45, 0);
        return;
    }
    if (freeze > 0)
    {
        // icy tint + a block of ice
        gpu_set_fog(true, make_colour_rgb(150, 220, 255), 0, 1);
        kd_draw(x, y, facing, _st, _fr, look, 1, c_white, 0.55, false);
        gpu_set_fog(false, c_white, 0, 0);
        draw_set_alpha(0.3);
        draw_set_colour(make_colour_rgb(190, 240, 255));
        draw_rectangle(x - 9, y - 30, x + 9, y - 1, false);
        draw_set_alpha(0.9);
        draw_set_colour(c_white);
        draw_rectangle(x - 9, y - 30, x + 9, y - 1, true);
        draw_line(x - 6, y - 27, x - 2, y - 27);
        draw_set_alpha(1);
    }
    if (shock > 0)
    {
        // little sparks crawling over the body
        draw_set_colour(make_colour_rgb(150, 220, 255));
        repeat (3)
        {
            var _a  = random(360);
            var _r  = random_range(4, 10);
            var _sx = x + lengthdir_x(_r, _a);
            var _sy = y - 13 + lengthdir_y(_r * 1.4, _a);
            draw_line(_sx, _sy, _sx + random_range(-4, 4), _sy + random_range(-4, 4));
        }
        draw_set_colour(c_white);
    }
    // burning is drawn by the fire effect (kd_vfx_fire)

}
