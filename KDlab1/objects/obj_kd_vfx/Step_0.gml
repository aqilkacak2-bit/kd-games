/// obj_kd_vfx - Step
t += KD_DT;
switch (kind)
{
    case "impact":  kd_vfx_impact_step();  break;
    case "blood":   kd_vfx_blood_step();   break;
    case "fire":    kd_vfx_fire_step();    break;
    case "shield":  kd_vfx_shield_step();  break;
    case "powerup": kd_vfx_powerup_step(); break;
    case "heal":    kd_vfx_heal_step();    break;
    case "powerup_back":
        if (!instance_exists(main)) finished = true;
        else { x = main.x; y = main.y; }
        break;
    default:
        finished = true;
}
if (finished) instance_destroy();
