/// obj_station_door_dungeon - Draw: spinning neon portal
t += 1;
var _cy = y - 18;
gpu_set_blendmode(bm_add);
draw_circle_colour(x, _cy, 22 + 2 * sin(t / 10), make_colour_rgb(90, 20, 80), c_black, false);
gpu_set_blendmode(bm_normal);
for (var _i = 0; _i < 3; _i++)
{
    var _r = 14 - _i * 4;
    var _c = (_i mod 2 == 0) ? make_colour_rgb(255, 84, 170) : make_colour_rgb(70, 232, 246);
    draw_set_colour(_c);
    for (var _a = 0; _a < 360; _a += 30)
    {
        var _aa = _a + t * (2 + _i) * ((_i mod 2 == 0) ? 1 : -1);
        draw_line(x + lengthdir_x(_r, _aa), _cy + lengthdir_y(_r * 1.3, _aa), x + lengthdir_x(_r, _aa + 20), _cy + lengthdir_y(_r * 1.3, _aa + 20));
    }
}
draw_set_colour(c_white);
