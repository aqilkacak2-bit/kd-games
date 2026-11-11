/// obj_station_shop - Draw: neon vending kiosk
t += 1;
var _g = make_colour_rgb(64, 226, 110);
gpu_set_blendmode(bm_add);
draw_circle_colour(x, y - 16, 20, make_colour_rgb(16, 60, 34), c_black, false);
gpu_set_blendmode(bm_normal);
draw_set_colour(make_colour_rgb(16, 40, 30));
draw_rectangle(x - 10, y - 30, x + 10, y - 1, false);
draw_set_colour(_g);
draw_rectangle(x - 10, y - 30, x + 10, y - 1, true);
draw_set_colour(make_colour_rgb(8, 20, 14));
draw_rectangle(x - 7, y - 26, x + 7, y - 12, false);
// items cycling in the window
draw_sprite_ext(spr_run_items, (t div 40) mod 14, x, y - 19, 0.7, 0.7, 0, c_white, 1);
draw_set_colour((t div 20) mod 2 == 0 ? _g : make_colour_rgb(255, 214, 60));
draw_set_halign(fa_center);
draw_text_transformed(x, y - 39, "SHOP", 0.3, 0.3, 0);
draw_set_halign(fa_left);
draw_set_colour(c_white);
