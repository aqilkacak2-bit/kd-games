/// NEON DUNGEON - a Neon Abyss style run.
///
///   Training Range -> the neon portal -> 7 arenas in a row:
///       fight, fight, treasure, fight, shop, fight, BOSS
///   Fight arenas lock until every enemy is down. Enemies drop coins.
///   Items stack (take Bouncy Code twice = 2 bounces). They last until the run ends.
///   Die -> back to the range with chips for the skill tree.  Beat the boss -> +15 chips.
///
/// Enemies are children of obj_kd_npc, so every weapon, burn, freeze and shock already works on them.

#macro KD_FLOOR_Y 208

// ================================================================ the run
function kd_run_active()
{
    return variable_global_exists("kd_run") && is_struct(global.kd_run);
}

function kd_run_start()
{
    global.kd_run = {
        plan  : ["fight", "fight", "treasure", "fight", "shop", "fight", "boss"],
        idx   : 0,
        coins : 0,
        items : {},
        kills : 0,
        hp    : -1
    };
    // items bought in the KD Item Shop come with you
    var _b = kd_backpack();
    var _names = variable_struct_get_names(_b);
    if (array_length(_names) > 0)
    {
        for (var _i = 0; _i < array_length(_names); _i++) variable_struct_set(global.kd_run.items, _names[_i], variable_struct_get(_b, _names[_i]));
        global.kd_backpack = {};
        kd_toast("Backpack unpacked: " + string(array_length(_names)) + " item type(s) ready for this run", make_colour_rgb(64, 226, 110));
    }
}

/// 1.0 in the first arena, a bit tougher in each one after
function kd_run_level()
{
    if (!kd_run_active()) return 1;
    return 1 + 0.12 * global.kd_run.idx;
}

/// walk through the exit: next arena (the room restarts and builds a new layout)
function kd_run_next()
{
    if (!kd_run_active()) return;
    if (instance_exists(obj_player)) global.kd_run.hp = obj_player.hp;
    global.kd_run.idx += 1;
    kd_sfx(snd_door, 0.03);
    room_restart();
}

/// the run is over: back to the Training Range with chips
function kd_run_end(_win)
{
    if (!kd_run_active()) return;
    var _r = global.kd_run;
    var _chips = _win ? 15 : max(1, _r.idx * 2);
    kd_chips_add(_chips);
    if (_win)
    {
        kd_toast("DUNGEON CLEARED!  +" + string(_chips) + " chips  (" + string(_r.kills) + " enemies down)", make_colour_rgb(255, 214, 90));
        kd_sfx(snd_levelup, 0);
    }
    else
    {
        kd_toast("You fell in arena " + string(_r.idx + 1) + ".  +" + string(_chips) + " chips - spend them with K", make_colour_rgb(255, 110, 110));
        kd_sfx(snd_ui_close);
    }
    global.kd_run = undefined;
    global.kd_prev_room = rm_dungeon;
    room_goto(rm_range);
}

// ================================================================ items (they stack)
function kd_run_items()
{
    static _defs = [
        { key : "hollow",   name : "Hollow Points", desc : "+20% damage.",                           icon : 0, col : make_colour_rgb(255, 214, 90)  },
        { key : "overclock",name : "Overclock",     desc : "Shoot 15% faster.",                      icon : 1, col : make_colour_rgb(255, 214, 90)  },
        { key : "bouncy",   name : "Bouncy Code",   desc : "Bullets bounce off walls one more time.",icon : 2, col : make_colour_rgb(255, 84, 170)  },
        { key : "multi",    name : "Multithread",   desc : "Every shot fires one more bullet.",      icon : 3, col : make_colour_rgb(90, 236, 250)  },
        { key : "bigdata",  name : "Big Data",      desc : "Bigger bullets that pierce one more enemy.", icon : 4, col : make_colour_rgb(110, 170, 255) },
        { key : "fire",     name : "Hot Fix",       desc : "Hits can set enemies on fire.",          icon : 5, col : make_colour_rgb(255, 150, 60)  },
        { key : "cryo",     name : "Cold Cache",    desc : "Hits can freeze enemies.",               icon : 6, col : make_colour_rgb(170, 240, 255) },
        { key : "heap",     name : "Heap Memory",   desc : "+25 max health.",                        icon : 7, col : make_colour_rgb(110, 240, 130) },
        { key : "coffee",   name : "Kopi O",        desc : "Move 10% faster.",                       icon : 8, col : make_colour_rgb(220, 170, 120) },
        { key : "pet",      name : "Bug Pet",       desc : "A little bug flies with you and shoots enemies.", icon : 9, col : make_colour_rgb(110, 240, 130) },
        // robot pets (each copy adds another robot)
        { key : "laserbot", name : "Laser Bot",     desc : "Robot pet: zaps the nearest enemy with a laser.",        icon : 10, col : make_colour_rgb(255, 84, 170) },
        { key : "shieldbot",name : "Shield Bot",    desc : "Robot pet: circles you and blocks enemy bullets.",       icon : 11, col : make_colour_rgb(90, 236, 250) },
        { key : "rocketbot",name : "Rocket Bot",    desc : "Robot pet: fires homing mini rockets.",                  icon : 12, col : make_colour_rgb(255, 150, 60) },
        { key : "coinbot",  name : "Coin Bot",      desc : "Robot pet: fetches coins for you from anywhere.",       icon : 13, col : make_colour_rgb(255, 214, 60) }
    ];
    return _defs;
}

function kd_run_item_def(_key)
{
    var _d = kd_run_items();
    for (var _i = 0; _i < array_length(_d); _i++) if (_d[_i].key == _key) return _d[_i];
    return _d[0];
}

/// how many of an item you hold this run (0 outside a run)
function kd_item_count(_key)
{
    if (!kd_run_active()) return 0;
    var _it = global.kd_run.items;
    return variable_struct_exists(_it, _key) ? variable_struct_get(_it, _key) : 0;
}

function kd_item_give(_key)
{
    if (!kd_run_active()) return;
    var _d = kd_run_item_def(_key);
    variable_struct_set(global.kd_run.items, _key, kd_item_count(_key) + 1);
    var _n = kd_item_count(_key);
    kd_toast(_d.name + ((_n > 1) ? "  x" + string(_n) : "") + "  -  " + _d.desc, _d.col);
    kd_sfx(snd_levelup, 0);
    with (obj_player)
    {
        kd_skills_apply(id);
        kd_vfx_powerup(id);
    }
    kd_pets_sync();
}

function kd_item_random()
{
    var _d = kd_run_items();
    return _d[irandom(array_length(_d) - 1)].key;
}

/// pets: one per pet item (Bug Pet + the four robots); they line up behind you
function kd_pet_kinds() { return ["pet", "laserbot", "shieldbot", "rocketbot", "coinbot"]; }

function kd_pets_sync()
{
    if (!instance_exists(obj_player)) return;
    var _p = instance_find(obj_player, 0);
    var _kinds = kd_pet_kinds();
    for (var _k = 0; _k < array_length(_kinds); _k++)
    {
        var _kind = _kinds[_k];
        var _have = 0;
        with (obj_pet) if (kind == _kind) _have += 1;
        repeat (kd_item_count(_kind) + ((kd_companion() == _kind) ? 1 : 0) - _have)   // run items + your Pet Bay companion
        {
            var _pet = instance_create_depth(_p.x, _p.y - 30, -3, obj_pet);
            _pet.kind = _kind;
            _pet.idx  = instance_number(obj_pet) - 1;
            if (_kind == "shieldbot") _pet.orbit = random(360);
        }
    }
}

/// robot pet weapons: damage every enemy close to a point (never hurts the player)
function kd_pet_blast(_x, _y, _r, _dmg)
{
    with (obj_enemy)
    {
        if (point_distance(_x, _y, x, y - 13 * scale) <= _r + 6 * scale)
            kd_npc_hit(id, point_direction(_x, _y, x, y), 3, "", _dmg);
    }
    var _f = instance_create_depth(_x, _y, -20, obj_kd_fx);
    _f.kind = "boom";
    _f.r    = _r;
    _f.life = 14;
    global.kd_shake = max(global.kd_shake, 2);
    kd_sfx_p(snd_land, 1.2, 0.1, 0.5);
}

// ================================================================ arenas
/// platform layouts for a 480 x 240 arena: [x, y, width, height]. The first one is the boss arena.
/// The player jumps about 24 px, so every level is 22 px above the last:
///   y 186, height 22 = a block standing on the floor;  y 164 / 142 = thin floating platforms
function kd_arena_layouts()
{
    return [
        [[60, 186, 60, 22], [360, 186, 60, 22], [130, 164, 50, 6], [300, 164, 50, 6]],
        [[100, 186, 50, 22], [330, 186, 50, 22], [160, 164, 60, 6], [260, 164, 60, 6], [222, 142, 36, 6]],
        [[60, 186, 60, 22], [130, 164, 60, 6], [200, 142, 80, 6], [290, 164, 60, 6], [360, 186, 60, 22]],
        [[80, 186, 80, 22], [320, 186, 80, 22], [170, 164, 140, 6]],
        [[40, 186, 50, 22], [110, 164, 50, 6], [180, 142, 50, 6], [250, 142, 50, 6], [320, 164, 50, 6], [390, 186, 50, 22]],
        [[150, 186, 180, 22], [60, 164, 60, 6], [360, 164, 60, 6]]
    ];
}

/// (runs inside obj_dungeon) an invisible solid + remember it for drawing
function kd_arena_solid(_x, _y, _w, _h)
{
    var _s = instance_create_depth(_x, _y, 0, obj_solid);
    _s.image_xscale = _w;
    _s.image_yscale = _h;
    array_push(solids, [_x, _y, _w, _h]);
}

/// (runs inside obj_dungeon) queue a wave: each enemy appears from a portal a moment later
function kd_arena_wave(_n)
{
    var _idx = global.kd_run.idx;
    for (var _i = 0; _i < _n; _i++)
    {
        var _r = irandom(99);
        var _k = "chaser";
        if (_r >= 40) _k = "shooter";
        if (_r >= 65) _k = "flyer";
        if (_r >= 85 && _idx >= 1) _k = "bomber";
        var _sx = random_range(150, 440);
        var _sy = KD_FLOOR_Y;
        // standing on the floor where a block is: stand on top of the block instead
        for (var _b = 0; _b < array_length(platforms); _b++)
        {
            var _pb = platforms[_b];
            if (_pb[3] > 6 && _sx > _pb[0] - 8 && _sx < _pb[0] + _pb[2] + 8) _sy = _pb[1];
        }
        if (_k == "flyer") _sy = random_range(60, 120);
        else if (array_length(platforms) > 0 && irandom(2) == 0)
        {
            var _pl = platforms[irandom(array_length(platforms) - 1)];
            _sx = _pl[0] + random_range(8, _pl[2] - 8);
            _sy = _pl[1];
        }
        array_push(queue, { kind : _k, x : _sx, y : _sy, t : 30 + _i * 14 });
    }
}

/// a pedestal with an item on it (price 0 = free)
function kd_pedestal(_x, _key, _price)
{
    var _o = instance_create_depth(_x, KD_FLOOR_Y, 40, obj_run_item);
    _o.key   = _key;
    _o.price = _price;
    return _o;
}

/// coins / hearts that pop out and fall
function kd_drop(_x, _y, _type, _n)
{
    repeat (_n)
    {
        var _o = instance_create_depth(_x, _y, -2, obj_pickup);
        _o.type = _type;
    }
}

// ================================================================ enemies
function kd_enemy_spawn(_kind, _x, _y)
{
    var _e = instance_create_depth(_x, _y, -1, obj_enemy);
    with (_e) kd_enemy_setup(_kind);
    kd_vfx_impact(_x, _y - 14 * _e.scale, 90, false, -1, 0, _y, 0.7);
    kd_sfx_p(snd_dash, 1.6, 0.05, 0.4);
    return _e;
}

/// (runs inside obj_enemy)
function kd_enemy_setup(_k)
{
    kind = _k;
    switch (_k)
    {
        case "chaser":
            hp_max = 40; spd = 0.9; contact = 10;
            neon = make_colour_rgb(255, 60, 140);
            npc_name = choose("Glitch", "Bug", "Null Pointer");
            break;
        case "shooter":
            hp_max = 30; spd = 0.6; contact = 6;
            neon = make_colour_rgb(70, 232, 246);
            npc_name = choose("Spammer", "Popup", "Clickbait");
            atk_t = 60 + irandom(40);
            break;
        case "flyer":
            hp_max = 24; spd = 0.9; contact = 8; flying = true; grav = 0;
            neon = make_colour_rgb(255, 222, 96);
            npc_name = choose("Drone", "Pinger", "Ad Bot");
            atk_t = 90 + irandom(60);
            break;
        case "bomber":
            hp_max = 50; spd = 0.45; contact = 0;
            neon = make_colour_rgb(255, 150, 60);
            npc_name = "Fork Bomb";
            break;
        case "boss":
            hp_max = 900; spd = 0.7; contact = 18;
            neon = make_colour_rgb(255, 50, 70);
            npc_name = "MERGE CONFLICT";
            scale = 2;
            image_xscale = 2;
            image_yscale = 2;
            atk_t = 90;
            break;
    }
    hp_max = round(hp_max * kd_run_level());
    hp = hp_max;
}

/// (runs inside obj_enemy) move with walls / floors; flyers float freely
function kd_enemy_move()
{
    blocked = false;
    if (flying)
    {
        x = clamp(x + hsp, 16, room_width - 16);
        y = clamp(y + vsp, 30, KD_FLOOR_Y - 4);
        return;
    }
    vsp = min(vsp + grav, 5);
    if (hsp != 0)
    {
        if (place_meeting(x + hsp, y, obj_solid))
        {
            var _g = 0;
            while (!place_meeting(x + sign(hsp), y, obj_solid) && _g < 8) { x += sign(hsp); _g += 1; }
            hsp = 0;
            blocked = true;
        }
        else x += hsp;
    }
    if (vsp != 0)
    {
        if (place_meeting(x, y + vsp, obj_solid))
        {
            var _g2 = 0;
            while (!place_meeting(x, y + sign(vsp), obj_solid) && _g2 < 8) { y += sign(vsp); _g2 += 1; }
            vsp = 0;
        }
        else y += vsp;
    }
    on_ground = place_meeting(x, y + 1, obj_solid);
    x = clamp(x, 12, room_width - 12);
}

/// (runs inside obj_enemy) a glowing shot
function kd_enemy_shoot(_dir, _spd, _dmg)
{
    var _s = instance_create_depth(x, y - 16 * scale, -4, obj_enemy_shot);
    _s.dir = _dir;
    _s.spd = _spd;
    _s.dmg = _dmg;
    _s.col = neon;
    kd_sfx_p(snd_shoot, 0.6 + 0.4 * random(1), 0.05, 0.35);
}

/// (runs inside obj_enemy)
function kd_enemy_ai()
{
    var _stun = (freeze > 0 || shock > 0);
    if (!instance_exists(obj_player) || _stun)
    {
        hsp = 0;
        if (flying) vsp = 0;
        kd_enemy_move();
        return;
    }
    var _p  = instance_find(obj_player, 0);
    var _dx = _p.x - x;
    var _dist = point_distance(x, y - 13 * scale, _p.x, _p.y - 13);
    if (_dx != 0) facing = sign(_dx);
    var _fast = (burn > 0) ? 1.4 : 1;
    atk_t -= 1;

    switch (kind)
    {
        case "chaser":
            hsp = facing * spd * _fast;
            if (on_ground && (blocked || (_p.y < y - 24 && abs(_dx) < 60 && irandom(30) == 0))) vsp = -3.6;
            break;

        case "shooter":
            var _want = 0;
            if (abs(_dx) < 70) _want = -sign(_dx);
            else if (abs(_dx) > 150) _want = sign(_dx);
            hsp = _want * spd * _fast;
            if (on_ground && blocked) vsp = -3.4;
            if (atk_t <= 0 && _dist < 260)
            {
                kd_enemy_shoot(point_direction(x, y - 16, _p.x, _p.y - 13), 2.6, 8);
                atk_t = 100 + irandom(40);
            }
            break;

        case "flyer":
            var _tx = _p.x - facing * 30;
            var _ty = _p.y - 50 + sin(anim_t / 20) * 10;
            var _d  = point_direction(x, y, _tx, _ty);
            var _sp = (point_distance(x, y, _tx, _ty) > 8) ? spd : 0;
            hsp = lerp(hsp, lengthdir_x(_sp, _d), 0.08);
            vsp = lerp(vsp, lengthdir_y(_sp, _d), 0.08);
            if (atk_t <= 0)
            {
                kd_enemy_shoot(point_direction(x, y - 16, _p.x, _p.y - 13), 2.2, 7);
                atk_t = 120 + irandom(40);
            }
            break;

        case "bomber":
            if (fuse > 0)
            {
                hsp = 0;
                fuse -= 1;
                if (fuse == 0)
                {
                    kd_explode(x, y - 12, 36, 10, 40);
                    hp = 0;
                }
            }
            else
            {
                hsp = facing * spd * _fast;
                if (on_ground && blocked) vsp = -3.4;
                if (_dist < 26)
                {
                    fuse = 45;
                    kd_sfx_p(snd_skid, 1.8, 0.05, 0.7);
                    bubble_text = "sudo rm -rf";
                    bubble_timer = 45;
                }
            }
            break;

        case "boss":
            kd_boss_ai(_p, _dx);
            break;
    }
    kd_enemy_move();

    // touching the player hurts
    if (contact > 0 && place_meeting(x, y, obj_player)) kd_player_damage(contact, x, y - 13 * scale);
}

/// (runs inside obj_enemy) MERGE CONFLICT: walks, slams, bursts, aims
function kd_boss_ai(_p, _dx)
{
    switch (phase)
    {
        case 0:     // walk at the player
            hsp = facing * spd;
            if (on_ground && blocked) vsp = -4;
            if (atk_t <= 0) { phase = irandom_range(1, 3); atk_t = 40; hsp = 0; }
            break;
        case 1:     // jump + ground slam
            if (atk_t == 39) { vsp = -5.2; hsp = clamp(_dx / 40, -3, 3); jumping = true; kd_sfx_p(snd_jump, 0.5, 0.05, 1); }
            if (jumping && atk_t < 34 && on_ground)
            {
                jumping = false;
                hsp = 0;
                global.kd_shake = max(global.kd_shake, 9);
                kd_sfx_p(snd_land, 0.4, 0.05, 1);
                kd_vfx_impact(x, y, 90, false, kd_pal().wall, 90, y, 1.6);
                if (abs(_p.x - x) < 70 && _p.y >= y - 6) kd_player_damage(20, x, y);
                kd_enemy_shoot(0, 2.4, 10);
                kd_enemy_shoot(180, 2.4, 10);
                phase = 0;
                atk_t = 90;
            }
            if (atk_t < -150) { phase = 0; atk_t = 60; jumping = false; }
            break;
        case 2:     // spinning radial bursts
            hsp = 0;
            if (atk_t > 0 && atk_t mod 12 == 0) for (var _i = 0; _i < 12; _i++) kd_enemy_shoot(_i * 30 + atk_t * 3, 2, 10);
            if (atk_t <= 0) { phase = 0; atk_t = 100; }
            break;
        case 3:     // three aimed spreads
            hsp = 0;
            if (atk_t == 30 || atk_t == 15 || atk_t == 0)
            {
                var _d = point_direction(x, y - 26, _p.x, _p.y - 13);
                for (var _k = -1; _k <= 1; _k++) kd_enemy_shoot(_d + _k * 12, 3.2, 10);
            }
            if (atk_t <= 0) { phase = 0; atk_t = 100; }
            break;
    }
    // calls for help at half health
    if (!summoned && hp < hp_max / 2)
    {
        summoned = true;
        kd_enemy_spawn("chaser", 60, KD_FLOOR_Y);
        kd_enemy_spawn("chaser", 420, KD_FLOOR_Y);
        kd_toast("MERGE CONFLICT calls for help!", neon);
    }
}

/// (runs inside obj_enemy) down: loot, effects, gone
function kd_enemy_die()
{
    if (kd_run_active()) global.kd_run.kills += 1;
    var _boss = (kind == "boss");
    kd_vfx_impact(x, y - 13 * scale, 90, false, -1, 0, y, _boss ? 2 : 1.1);
    var _f = instance_create_depth(x, y - 13 * scale, -20, obj_kd_fx);
    _f.kind = "boom";
    _f.r    = _boss ? 50 : 14;
    _f.life = _boss ? 30 : 16;
    global.kd_shake = max(global.kd_shake, _boss ? 14 : 3);
    if (_boss) global.kd_flash = 0.5;
    kd_sfx_p(snd_hit, 0.7, 0.1, 0.8);
    kd_drop(x, y - 10, "coin", _boss ? 15 : irandom_range(1, 2));
    if (irandom(9) == 0 || _boss) kd_drop(x, y - 10, "heart", 1);
    if (instance_exists(fire_fx)) fire_fx.owner = noone;
    instance_destroy();
}

// ================================================================ HUD (obj_dungeon Draw GUI)
function kd_run_hud()
{
    var _r = global.kd_run;
    var _n = array_length(_r.plan);
    // ---------- progress bar (top centre):  [start] - 1 - 2 - ? - 3 - $ - 4 - [!] ----------
    var _w  = 34;
    var _gap = 14;
    var _x0 = 640 - (_n * _w + (_n - 1) * _gap) / 2;
    var _y0 = 74;
    draw_set_colour(make_colour_rgb(190, 90, 30));
    draw_line_width(_x0 - 40, _y0 + _w / 2, _x0 + _n * (_w + _gap) + 26, _y0 + _w / 2, 2);
    var _fight = 0;
    draw_set_halign(fa_center);
    for (var _i = 0; _i < _n; _i++)
    {
        var _t = _r.plan[_i];
        var _lab = "";
        if (_t == "fight") { _fight += 1; _lab = string(_fight); }
        if (_t == "treasure") _lab = "?";
        if (_t == "shop")     _lab = "$";
        if (_t == "boss")     _lab = "!";
        var _bx = _x0 + _i * (_w + _gap);
        var _cur = (_i == _r.idx);
        var _col = make_colour_rgb(190, 84, 20);
        if (_t == "boss")     _col = make_colour_rgb(200, 30, 60);
        if (_t == "treasure") _col = make_colour_rgb(120, 50, 200);
        if (_t == "shop")     _col = make_colour_rgb(30, 140, 90);
        if (_i < _r.idx)      _col = merge_colour(_col, c_black, 0.55);
        if (_cur)
        {
            gpu_set_blendmode(bm_add);
            draw_circle_colour(_bx + _w / 2, _y0 + _w / 2, _w, make_colour_rgb(120, 90, 10), c_black, false);
            gpu_set_blendmode(bm_normal);
            _col = make_colour_rgb(255, 196, 30);
        }
        draw_set_colour(_col);
        draw_roundrect_ext(_bx, _y0, _bx + _w, _y0 + _w, 6, 6, false);
        draw_set_colour(_cur ? c_white : merge_colour(_col, c_white, 0.4));
        draw_roundrect_ext(_bx, _y0, _bx + _w, _y0 + _w, 6, 6, true);
        draw_set_colour(_cur ? make_colour_rgb(60, 30, 0) : c_white);
        draw_text_transformed(_bx + _w / 2, _y0 + 7, _lab, 0.9, 0.9, 0);
    }
    draw_set_halign(fa_left);

    // ---------- coins + items (left, under the skill pill) ----------
    kd_draw_chip(28, 258, 8);
    draw_set_colour(make_colour_rgb(255, 214, 60));
    draw_text_transformed(44, 248, "x " + string(_r.coins), 0.9, 0.9, 0);
    var _d = kd_run_items();
    var _ix = 16;
    for (var _k = 0; _k < array_length(_d); _k++)
    {
        var _c = kd_item_count(_d[_k].key);
        if (_c <= 0) continue;
        draw_set_alpha(0.85);
        draw_set_colour(make_colour_rgb(18, 14, 40));
        draw_roundrect_ext(_ix, 276, _ix + 34, 310, 6, 6, false);
        draw_set_alpha(1);
        draw_set_colour(_d[_k].col);
        draw_roundrect_ext(_ix, 276, _ix + 34, 310, 6, 6, true);
        draw_sprite_ext(spr_run_items, _d[_k].icon, _ix + 17, 293, 1.6, 1.6, 0, c_white, 1);
        if (_c > 1)
        {
            draw_set_colour(c_white);
            draw_text_transformed(_ix + 22, 296, "x" + string(_c), 0.55, 0.55, 0);
        }
        _ix += 40;
    }

    // ---------- boss health (bottom centre) ----------
    with (obj_enemy)
    {
        if (kind != "boss") continue;
        var _bw = 600;
        var _bx1 = 640 - _bw / 2;
        var _by1 = 640;
        draw_set_alpha(0.85);
        draw_set_colour(make_colour_rgb(20, 8, 16));
        draw_roundrect_ext(_bx1 - 10, _by1 - 30, _bx1 + _bw + 10, _by1 + 22, 10, 10, false);
        draw_set_alpha(1);
        draw_set_colour(neon);
        draw_set_halign(fa_center);
        draw_text_transformed(640, _by1 - 26, npc_name, 1, 1, 0);
        draw_set_halign(fa_left);
        draw_set_colour(make_colour_rgb(50, 20, 30));
        draw_rectangle(_bx1, _by1, _bx1 + _bw, _by1 + 12, false);
        draw_set_colour(neon);
        draw_rectangle(_bx1, _by1, _bx1 + _bw * clamp(hp / hp_max, 0, 1), _by1 + 12, false);
        draw_set_colour(c_white);
        draw_rectangle(_bx1, _by1, _bx1 + _bw, _by1 + 12, true);
    }
    draw_set_colour(c_white);
}
