/// obj_pickup - Draw
var _bob = sin(t / 10) * 1;
if (type == "coin")
{
    var _w = max(0.2, abs(sin(t / 8)));       // spinning
    gpu_set_blendmode(bm_add);
    draw_circle_colour(x, y - 6, 7, make_colour_rgb(90, 70, 10), c_black, false);
    gpu_set_blendmode(bm_normal);
    draw_set_colour(make_colour_rgb(150, 100, 10));
    draw_ellipse(x - 4 * _w - 1, y - 11 + _bob, x + 4 * _w + 1, y - 1 + _bob, false);
    draw_set_colour(make_colour_rgb(255, 214, 60));
    draw_ellipse(x - 4 * _w, y - 10 + _bob, x + 4 * _w, y - 2 + _bob, false);
}
else
{
    gpu_set_blendmode(bm_add);
    draw_circle_colour(x, y - 6, 8, make_colour_rgb(90, 20, 30), c_black, false);
    gpu_set_blendmode(bm_normal);
    draw_sprite_ext(spr_skill_icons, 1, x, y - 6 + _bob, 0.7, 0.7, 0, c_white, 1);
}
draw_set_colour(c_white);
