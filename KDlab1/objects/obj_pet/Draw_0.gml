/// obj_pet - Draw
var _glow = make_colour_rgb(110, 240, 130);
var _fr = -1;
switch (kind)
{
    case "laserbot":  _glow = make_colour_rgb(255, 84, 170); _fr = 0; break;
    case "shieldbot": _glow = make_colour_rgb(90, 236, 250);  _fr = 2; break;
    case "rocketbot": _glow = make_colour_rgb(255, 150, 60);  _fr = 4; break;
    case "coinbot":   _glow = make_colour_rgb(255, 214, 60);  _fr = 6; break;
}
gpu_set_blendmode(bm_add);
draw_circle_colour(x, y, 10, merge_colour(c_black, _glow, 0.3), c_black, false);
gpu_set_blendmode(bm_normal);

if (_fr < 0)
{
    // Bug Pet
    draw_set_colour(_glow);
    draw_ellipse(x - 4, y - 3, x + 4, y + 4, false);
    draw_set_colour(make_colour_rgb(40, 120, 60));
    draw_line(x, y - 3, x, y + 4);
    var _w = (t div 3) mod 2;
    draw_set_colour(make_colour_rgb(220, 255, 230));
    draw_line(x - 3, y - 2, x - 7, y - 5 + _w * 2);
    draw_line(x + 3, y - 2, x + 7, y - 5 + _w * 2);
}
else draw_sprite_ext(spr_robot_pets, _fr + (t div 8) mod 2, round(x), round(y), face, 1, 0, c_white, 1);

// laser beam
if (beam_t > 0)
{
    gpu_set_blendmode(bm_add);
    draw_set_alpha(beam_t / 8);
    draw_set_colour(_glow);
    draw_line_width(x, y, beam_x, beam_y, 3);
    draw_set_colour(c_white);
    draw_line_width(x, y, beam_x, beam_y, 1);
    draw_set_alpha(1);
    gpu_set_blendmode(bm_normal);
}
// shield bubble
if (kind == "shieldbot")
{
    draw_set_alpha(0.25 + 0.1 * sin(t / 6));
    draw_set_colour(_glow);
    draw_circle(x, y, 9, true);
    draw_set_alpha(1);
}
// mini rockets
for (var _i = 0; _i < array_length(rockets); _i++)
{
    var _r = rockets[_i];
    draw_set_colour(make_colour_rgb(255, 220, 120));
    draw_circle(_r.x - lengthdir_x(3, _r.dir), _r.y - lengthdir_y(3, _r.dir), 1.5, false);
    draw_set_colour(make_colour_rgb(255, 150, 60));
    draw_line_width(_r.x - lengthdir_x(2, _r.dir), _r.y - lengthdir_y(2, _r.dir), _r.x + lengthdir_x(2, _r.dir), _r.y + lengthdir_y(2, _r.dir), 2);
}
draw_set_colour(c_white);
