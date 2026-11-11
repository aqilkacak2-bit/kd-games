/// obj_run_item - Draw: pedestal + floating item
var _d = kd_run_item_def(key);
draw_set_colour(make_colour_rgb(30, 22, 60));
draw_rectangle(x - 10, y - 12, x + 10, y - 1, false);
draw_set_colour(_d.col);
draw_line(x - 10, y - 12, x + 10, y - 12);
var _iy = y - 26 + sin(t / 14) * 2;
gpu_set_blendmode(bm_add);
draw_circle_colour(x, _iy, 14 + (near ? 4 : 0), merge_colour(c_black, _d.col, 0.45), c_black, false);
gpu_set_blendmode(bm_normal);
draw_sprite_ext(spr_run_items, _d.icon, x, _iy, 1, 1, 0, c_white, 1);
if (price > 0)
{
    draw_set_halign(fa_center);
    draw_set_colour(make_colour_rgb(255, 214, 60));
    draw_text_transformed(x + 3, y - 10, string(price), 0.3, 0.3, 0);
    draw_set_halign(fa_left);
}
draw_set_colour(c_white);
