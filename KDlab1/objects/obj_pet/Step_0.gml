/// obj_pet - Step
t += 1;
if (!instance_exists(obj_player)) exit;
var _p = instance_find(obj_player, 0);
face = _p.facing;
var _e = instance_exists(obj_enemy) ? instance_nearest(x, y, obj_enemy) : noone;

// ---------- where to fly ----------
var _tx = _p.x - _p.facing * (16 + idx * 12);
var _ty = _p.y - 32 - idx * 4 + sin(t / 15 + idx) * 3;
if (kind == "shieldbot")
{
    orbit += 4;
    _tx = _p.x + lengthdir_x(22, orbit);
    _ty = _p.y - 14 + lengthdir_y(16, orbit);
}
if (kind == "coinbot")
{
    if (instance_exists(carry))
    {
        carry.x = x;  carry.y = y + 10;  carry.hsp = 0;  carry.vsp = 0;   // bring it home
        if (point_distance(x, y, _p.x, _p.y - 20) < 14) carry = noone;
    }
    else
    {
        carry = noone;
        var _c = instance_exists(obj_pickup) ? instance_nearest(x, y, obj_pickup) : noone;
        if (_c != noone && point_distance(_c.x, _c.y, _p.x, _p.y) > 50)
        {
            _tx = _c.x;
            _ty = _c.y - 10;
            if (point_distance(x, y, _tx, _ty) < 6) carry = _c;
        }
    }
}
var _k = (kind == "shieldbot") ? 0.35 : ((kind == "coinbot") ? 0.08 : 0.12);
x = lerp(x, _tx, _k);
y = lerp(y, _ty, _k);

// ---------- what it does ----------
cd -= 1;
if (beam_t > 0) beam_t -= 1;
switch (kind)
{
    case "pet":
        if (cd <= 0 && _e != noone && point_distance(x, y, _e.x, _e.y) < 160)
        {
            var _b = instance_create_depth(x, y, depth, obj_bullet);
            _b.direction   = point_direction(x, y, _e.x, _e.y - 13 * _e.scale);
            _b.speed       = 5;
            _b.image_angle = _b.direction;
            _b.damage      = 5;
            _b.life        = 50;
            _b.life_max    = 50;
            _b.image_blend = make_colour_rgb(110, 240, 130);
            kd_sfx_p(snd_shoot, 1.8, 0.05, 0.25);
            cd = 45;
        }
        break;

    case "laserbot":
        if (cd <= 0 && _e != noone && point_distance(x, y, _e.x, _e.y) < 150)
        {
            beam_x = _e.x;
            beam_y = _e.y - 13 * _e.scale;
            beam_t = 8;
            kd_npc_hit(_e, point_direction(x, y, beam_x, beam_y), 2, "", 12);
            kd_vfx_impact(beam_x, beam_y, point_direction(x, y, beam_x, beam_y), false, -1, 0, _e.y, 0.5);
            kd_sfx_p(snd_shoot, 2.2, 0.05, 0.35);
            cd = 80;
        }
        break;

    case "shieldbot":
        with (obj_enemy_shot)
        {
            if (point_distance(x, y, other.x, other.y) < 9)
            {
                kd_vfx_impact(x, y, dir, false, -1, 0, 100000, 0.4);
                kd_sfx_p(snd_ricochet, 1.6, 0.1, 0.4);
                instance_destroy();
            }
        }
        break;

    case "rocketbot":
        if (cd <= 0 && _e != noone && point_distance(x, y, _e.x, _e.y) < 220)
        {
            array_push(rockets, { x : x, y : y - 4, dir : 90 + random_range(-30, 30), life : 120 });
            kd_sfx_p(snd_dash, 1.8, 0.05, 0.3);
            cd = 110;
        }
        break;
}

// homing rockets
for (var _i = array_length(rockets) - 1; _i >= 0; _i--)
{
    var _r = rockets[_i];
    _r.life -= 1;
    if (_e != noone)
    {
        var _want = point_direction(_r.x, _r.y, _e.x, _e.y - 13 * _e.scale);
        _r.dir += clamp(angle_difference(_want, _r.dir), -9, 9);       // steer
    }
    _r.x += lengthdir_x(3, _r.dir);
    _r.y += lengthdir_y(3, _r.dir);
    var _hit = (_e != noone && point_distance(_r.x, _r.y, _e.x, _e.y - 13 * _e.scale) < 10 * _e.scale);
    if (_hit || _r.life <= 0 || position_meeting(_r.x, _r.y, obj_solid))
    {
        kd_pet_blast(_r.x, _r.y, 20, 18);
        array_delete(rockets, _i, 1);
    }
}
