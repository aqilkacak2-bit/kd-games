/// obj_player - Draw
var _shadow = (mode != "normal") || on_ground;
kd_draw(x, y - recoil_lift, facing, state, anim_frame, look, 1, image_blend, image_alpha, _shadow, KD_ARM_NONE);   // arm = obj_hand; recoil_lift = small hop when shooting down

// red flash when hurt
if (hit_flash > 0)
{
    gpu_set_fog(true, make_colour_rgb(255, 60, 60), 0, 1);
    kd_draw(x, y - recoil_lift, facing, state, anim_frame, look, 1, c_white, 0.6, false, KD_ARM_NONE);
    gpu_set_fog(false, c_white, 0, 0);
}
