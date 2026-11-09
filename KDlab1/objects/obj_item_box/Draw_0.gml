/// obj_item_box - Draw
var _f = (hp <= 7) ? 1 : 0;          // cracked when half broken
draw_sprite_ext(sprite_index, _f, x, y, 1, 1, 0, c_white, 1);
if (hit_flash > 0)
{
    gpu_set_fog(true, c_white, 0, 1);
    draw_sprite_ext(sprite_index, _f, x, y, 1, 1, 0, c_white, 0.7);
    gpu_set_fog(false, c_white, 0, 0);
}
if (near) draw_sprite_ext(spr_key_e, 0, x + 8, y - 8 + round(sin(current_time / 200)), 1, 1, 0, c_white, 1);
