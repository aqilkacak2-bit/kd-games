/// obj_player - Draw
var _shadow = (mode != "normal") || on_ground;

// jetpack on the back (once unlocked): spr_jetpack  0 = off, 1 / 2 = flame
if (kd_skill_has("jetpack"))
{
    var _bx = x - facing * 6;
    var _by = y - recoil_lift - 14;
    var _jf = 0;
    if (jet_on) _jf = 1 + (jet_t div 3) mod 2;           // flame flickers between frames 1 and 2
    if (jet_on)
    {
        gpu_set_blendmode(bm_add);
        draw_circle_colour(_bx, _by + 12, 9, make_colour_rgb(40, 90, 10), c_black, false);
        gpu_set_blendmode(bm_normal);
    }
    draw_sprite_ext(spr_jetpack, _jf, _bx, _by, facing, 1, 0, c_white, 1);
    // fuel gauge when not full
    if (jet_fuel < jet_fuel_max)
    {
        var _gx = x - facing * 15;
        draw_set_colour(make_colour_rgb(30, 34, 44));
        draw_rectangle(_gx, _by - 6, _gx + 1, _by + 6, false);
        draw_set_colour((jet_fuel < 30) ? make_colour_rgb(255, 90, 90) : make_colour_rgb(160, 240, 80));
        draw_rectangle(_gx, _by + 6 - 12 * jet_fuel / jet_fuel_max, _gx + 1, _by + 6, false);
    }
    draw_set_colour(c_white);
}
kd_draw(x, y - recoil_lift, facing, state, anim_frame, look, 1, image_blend, image_alpha, _shadow, KD_ARM_NONE);   // arm = obj_hand; recoil_lift = small hop when shooting down

// red flash when hurt
if (hit_flash > 0)
{
    gpu_set_fog(true, make_colour_rgb(255, 60, 60), 0, 1);
    kd_draw(x, y - recoil_lift, facing, state, anim_frame, look, 1, c_white, 0.6, false, KD_ARM_NONE);
    gpu_set_fog(false, c_white, 0, 0);
}
