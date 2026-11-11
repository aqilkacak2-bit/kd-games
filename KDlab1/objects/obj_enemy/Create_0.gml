/// obj_enemy - Create  (child of obj_kd_npc: health, burn, freeze, shock and every weapon hit come from there)
event_inherited();
kind      = "chaser";     // set by kd_enemy_setup()
hsp       = 0;
on_ground = false;
blocked   = false;
flying    = false;
spd       = 0.8;
contact   = 10;           // damage when touching the player
atk_t     = 60;
fuse      = 0;            // bomber
phase     = 0;            // boss
jumping   = false;
summoned  = false;
scale     = 1;
neon      = c_red;
walking   = false;
move_speed = 0;
base_speed = 0;
