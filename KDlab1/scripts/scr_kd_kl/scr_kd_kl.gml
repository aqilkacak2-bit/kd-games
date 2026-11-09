/// KDlab1: hand grenades (G), recoil when shooting downward, item boxes + pickups.

#macro KD_GRENADE_MAX 9
#macro KD_THROW_TIME 22          // steps for the whole throw animation

// ================================================================ HAND GRENADES
/// G pressed: start the throw (limited grenades + a short cooldown so you can't spam them)
function kd_grenade_try_throw(_p)
{
    with (_p)
    {
        if (grenade_cd > 0 || throw_t > 0 || mode != "normal") return;
        if (global.kd_grenades <= 0)
        {
            kd_toast("No grenades left - break item boxes to find more", c_white);
            grenade_cd = 30;
            return;
        }
        global.kd_grenades -= 1;
        throw_t    = KD_THROW_TIME;
        thrown     = false;
        grenade_cd = 50;
        kd_sfx_p(snd_dash, 1.4, 0.05, 0.45);
    }
}

/// arm angle during the throw: wind up behind the head, then whip forward over the shoulder
function kd_throw_angle(_t)
{
    var _p = 1 - _t / KD_THROW_TIME;
    if (_p < 0.35) return lerp(0, -140, _p / 0.35);
    return lerp(-140, 110, 1 - power(1 - (_p - 0.35) / 0.65, 3));
}

/// where the throwing hand is right now (same maths as kd_draw_arm)
function kd_throw_hand(_p)
{
    var _by = round(_p.y) + _p.draw_bob - _p.recoil_lift;
    var _sx = round(_p.x) + _p.facing * KD_SHOULDER_X;
    var _sy = _by + KD_SHOULDER_Y;
    var _a  = 270 + _p.throw_ang * _p.facing;
    return [_sx + lengthdir_x(KD_ARM_LEN, _a), _sy + lengthdir_y(KD_ARM_LEN, _a)];
}

/// every step: animate the throw; the grenade leaves the hand halfway through
function kd_grenade_throw_step(_p)
{
    with (_p)
    {
        if (grenade_cd > 0) grenade_cd -= 1;
        if (throw_t <= 0) { throw_ang = 0; return; }
        throw_t  -= 1;
        throw_ang = kd_throw_angle(throw_t);
        facing    = (mouse_x >= x) ? 1 : -1;      // face where you throw
        if (!thrown && throw_t <= KD_THROW_TIME * 0.5)
        {
            thrown = true;
            var _h    = kd_throw_hand(id);
            var _dir  = point_direction(_h[0], _h[1], mouse_x, mouse_y);
            var _dist = point_distance(_h[0], _h[1], mouse_x, mouse_y);
            var _g = instance_create_depth(_h[0], _h[1], depth - 1, obj_bullet);
            _g.kind         = "grenade";
            _g.thrown       = true;
            _g.direction    = _dir;
            _g.speed        = clamp(2.2 + _dist / 45, 3, 5.8);   // further mouse = harder throw
            _g.vspeed      -= 1.3;                                 // forward and a little up, then it falls
            _g.image_angle  = _dir;
            _g.life         = 600;                                 // the real fuse starts when it lands
            _g.life_max     = 600;
            _g.grav         = 0.2;
            _g.blast        = 34;
            _g.blast_knock  = 11;
            _g.blast_damage = 50;
            _g.knock        = 0;
            _g.damage       = 0;
            kd_sfx_p(snd_jump, 0.75, 0.05, 0.7);
        }
    }
}

// ================================================================ RECOIL WHEN SHOOTING DOWNWARD
/// shooting downward pops the character up a little. Visual only: x / y / physics are untouched,
/// so jumping, falling and collisions work exactly as before.
function kd_recoil_kick(_p, _aim, _amount)
{
    var _down = -dsin(_aim);            // 1 = straight down, 0 = sideways, below 0 = upward
    if (_down <= 0.25) return;           // only when aiming down
    with (_p) recoil_vel = max(recoil_vel, _amount * _down);
}

/// every step: a small spring that brings the character smoothly back down
function kd_recoil_step(_p)
{
    with (_p)
    {
        recoil_vel -= recoil_lift * 0.25;
        recoil_vel *= 0.72;
        recoil_lift = max(0, recoil_lift + recoil_vel);
        if (recoil_lift < 0.05 && abs(recoil_vel) < 0.05) { recoil_lift = 0; recoil_vel = 0; }
    }
}

// ================================================================ ITEM BOXES + PICKUPS
/// what can be inside a box (repeat an entry to make it more common)
function kd_box_loot()
{
    return choose("health", "health", "grenade", "grenade", "shield", "exp");
}

function kd_box_damage(_box, _dmg)
{
    with (_box)
    {
        if (broken) return;
        hp -= max(1, _dmg);
        hit_flash = 6;
        if (hp <= 0) kd_box_break(id);
    }
}

/// the box bursts open and its item pops out
function kd_box_break(_box)
{
    with (_box)
    {
        if (broken) return;
        broken = true;
        var _it = instance_create_depth(x + 8, y + 12, depth - 1, obj_item);
        _it.type = item;
        _it.vsp  = -2.6;
        kd_vfx_impact(x + 8, y + 8, 90, false, make_colour_rgb(176, 124, 70), 90, y + 16, 1.1);
        kd_sfx_p(snd_hit, 0.6, 0.05, 0.9);
        kd_sfx_p(snd_skid, 1.4, 0.05, 0.5);
        instance_destroy();
    }
}

function kd_item_frame(_type)
{
    switch (_type)
    {
        case "health":  return 0;
        case "grenade": return 1;
        case "shield":  return 2;
    }
    return 3;
}

function kd_item_colour(_type)
{
    switch (_type)
    {
        case "health":  return make_colour_rgb(255, 110, 110);
        case "grenade": return make_colour_rgb(150, 220, 120);
        case "shield":  return make_colour_rgb(98, 200, 244);
    }
    return make_colour_rgb(255, 204, 64);
}

/// walking over an item uses it
function kd_item_pickup(_p, _it)
{
    switch (_it.type)
    {
        case "health":
            _p.hp = min(_p.hp_max, _p.hp + 35);
            kd_vfx_heal(_p);
            kd_toast("+35 HP", make_colour_rgb(98, 226, 106));
            break;
        case "grenade":
            global.kd_grenades = min(KD_GRENADE_MAX, global.kd_grenades + 2);
            kd_toast("+2 grenades (" + string(global.kd_grenades) + ")   press G to throw", make_colour_rgb(150, 220, 120));
            break;
        case "shield":
            _p.shield_cd = 0;
            kd_toast("Shield recharged - press F", make_colour_rgb(98, 200, 244));
            break;
        default:
            kd_add_exp(25, "Found a dev bounty in a box");
    }
    kd_sfx(snd_pickup, 0.05);
    with (_it) instance_destroy();
}

/// boxes for the older rooms (the KL street has its boxes placed in the room itself)
function kd_spawn_boxes()
{
    var _list = [];
    if (room == rm_range)   _list = [[90, 134], [150, 134], [150, 118]];
    if (room == rm_main)    _list = [[300, 341], [316, 341], [620, 341]];
    if (room == rm_rooftop) _list = [[200, 134], [360, 134]];
    for (var _i = 0; _i < array_length(_list); _i++)
    {
        instance_create_depth(_list[_i][0], _list[_i][1], 0, obj_item_box);
    }
}
