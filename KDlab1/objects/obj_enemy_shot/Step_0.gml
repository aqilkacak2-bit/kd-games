/// obj_enemy_shot - Step
t += 1;
life -= 1;
x += lengthdir_x(spd, dir);
y += lengthdir_y(spd, dir);
if (life <= 0 || x < -10 || x > room_width + 10 || y < -10 || y > room_height + 10) { instance_destroy(); exit; }
if (position_meeting(x, y, obj_solid))
{
    kd_vfx_impact(x, y, dir, false, -1, 0, 100000, 0.4);
    instance_destroy();
    exit;
}
if (instance_exists(obj_player))
{
    var _p = instance_find(obj_player, 0);
    if (point_distance(x, y, _p.x, _p.y - 13) < 9)
    {
        kd_player_damage(dmg, x, y);      // the shield (F) blocks it
        instance_destroy();
    }
}
