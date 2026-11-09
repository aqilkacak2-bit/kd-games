/// obj_showcase - Draw
// glowing outline: strong when hovered, a soft pulse when you stand next to it
if (hover || near || opened > 0)
{
    var _al = 0.3 + 0.2 * sin(t / 12);
    if (hover) _al = 0.6 + 0.4 * glow;
    if (opened > 0) _al = 1;
    gpu_set_fog(true, info.col, 0, 1);
    draw_sprite_ext(sprite_index, 0, x - 1, y, 1, 1, 0, c_white, _al);
    draw_sprite_ext(sprite_index, 0, x + 1, y, 1, 1, 0, c_white, _al);
    draw_sprite_ext(sprite_index, 0, x, y - 1, 1, 1, 0, c_white, _al);
    draw_sprite_ext(sprite_index, 0, x, y + 1, 1, 1, 0, c_white, _al);
    gpu_set_fog(false, c_white, 0, 0);
}
draw_sprite(sprite_index, 0, x, y);
// brighten while hovered
if (glow > 0.02 || opened > 0)
{
    gpu_set_blendmode(bm_add);
    draw_sprite_ext(sprite_index, 0, x, y, 1, 1, 0, info.col, glow * 0.22 + opened / 40);
    gpu_set_blendmode(bm_normal);
}
