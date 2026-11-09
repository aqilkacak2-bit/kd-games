/// obj_item - Step
t += 1;
// fall onto the floor
vsp = min(vsp + 0.2, 4);
if (place_meeting(x, y + vsp, obj_solid))
{
    var _guard = 20;
    while (!place_meeting(x, y + sign(vsp), obj_solid) && _guard > 0) { y += sign(vsp); _guard -= 1; }
    vsp = 0;
}
else y += vsp;
// walk over it to pick it up
var _pl = instance_nearest(x, y, obj_player);
if (_pl != noone && abs(_pl.x - x) < 10 && abs((_pl.y - 12) - (y - 6)) < 16) kd_item_pickup(_pl, id);
