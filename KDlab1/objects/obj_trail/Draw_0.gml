/// obj_trail - Draw
var _life = 4 * KD_TRAIL_FRAME_STEPS;
var _fr = min(3, t div KD_TRAIL_FRAME_STEPS);
var _a  = 1 - power(t / _life, 2) * 0.85;    // stays solid, then fades out at the end
draw_sprite_ext(spr_trail, _fr, x, y, image_xscale, image_yscale, 0, col, _a);
if (glow)
{
    gpu_set_blendmode(bm_add);
    draw_sprite_ext(spr_trail, _fr, x, y, image_xscale, image_yscale, 0, col, _a * 0.7);
    draw_sprite_ext(spr_trail, _fr, x, y - 1, image_xscale * 1.25, image_yscale * 1.25, 0, col, _a * 0.25);
    gpu_set_blendmode(bm_normal);
}
