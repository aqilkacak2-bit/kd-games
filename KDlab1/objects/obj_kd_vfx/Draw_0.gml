/// obj_kd_vfx - Draw
switch (kind)
{
    case "impact":       kd_vfx_impact_draw();       break;
    case "blood":        kd_vfx_blood_draw();        break;
    case "fire":         kd_vfx_fire_draw();         break;
    case "shield":       kd_vfx_shield_draw();       break;
    case "powerup":      kd_vfx_powerup_draw();      break;
    case "powerup_back": kd_vfx_powerup_back_draw(); break;
    case "heal":         kd_vfx_heal_draw();         break;
}
draw_set_alpha(1);
draw_set_colour(c_white);
gpu_set_blendmode(bm_normal);
