/// obj_kd_girl_npc - Draw  (random customised look)
var _st = "idle";
var _fr = anim_t div 15;
if (walking) { _st = "walk"; _fr = anim_t div 6; }
kd_draw(x, y, facing, _st, _fr, look, 1, image_blend, image_alpha, true);

kd_npc_status_draw(_st, _fr);

// white flash when hit by a bullet
if (hit_flash > 0)
{
    gpu_set_fog(true, c_white, 0, 1);
    kd_draw(x, y, facing, _st, _fr, look, 1, c_white, 0.8, false);
    gpu_set_fog(false, c_white, 0, 0);
}
