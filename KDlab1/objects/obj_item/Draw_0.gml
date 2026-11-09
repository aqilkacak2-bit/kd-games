/// obj_item - Draw
var _bob = round(sin(t / 12) * 1.5) - 1;
kd_glow(x, y - 6 + _bob, 9, kd_item_colour(type), 0.35 + 0.15 * sin(t / 8));
draw_sprite_ext(spr_item, kd_item_frame(type), x, y + _bob, 1, 1, 0, c_white, 1);
