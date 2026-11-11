/// obj_enemy - Step
if (hit_flash > 0) hit_flash -= 1;
if (ko > 0 || hp <= 0) { kd_enemy_die(); exit; }
kd_npc_status_step();      // burning / frozen / shocked
anim_t += 1;
kd_enemy_ai();
