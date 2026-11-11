/// obj_pickup - Step
t += 1;
var _p = instance_exists(obj_player) ? instance_find(obj_player, 0) : noone;
if (_p != noone && t > 20 && point_distance(x, y - 6, _p.x, _p.y - 12) < 46)
{
    // magnet
    var _d = point_direction(x, y - 6, _p.x, _p.y - 12);
    x += lengthdir_x(3, _d);
    y += lengthdir_y(3, _d);
    if (point_distance(x, y - 6, _p.x, _p.y - 12) < 10)
    {
        if (type == "coin")
        {
            if (kd_run_active()) global.kd_run.coins += 1;
            kd_sfx_p(snd_pickup, 1.5, 0.1, 0.5);
        }
        else
        {
            _p.hp = min(_p.hp_max, _p.hp + 15);
            kd_toast("+15 HP", make_colour_rgb(98, 226, 106));
            kd_sfx(snd_pickup, 0.05);
        }
        instance_destroy();
    }
    exit;
}
// fall and bounce
vsp = min(vsp + 0.2, 4);
if (place_meeting(x + hsp, y, obj_solid)) hsp = -hsp * 0.5;
x += hsp;
if (place_meeting(x, y + vsp, obj_solid))
{
    var _g = 0;
    while (vsp != 0 && !place_meeting(x, y + sign(vsp), obj_solid) && _g < 6) { y += sign(vsp); _g += 1; }
    vsp = 0;
    hsp *= 0.8;
}
else y += vsp;
