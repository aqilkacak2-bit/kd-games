/// obj_gun - Create
// Any weapon (guns and the keris). Two modes:
//   equipped = false : lying in the room (pick up with E - handled by obj_game)
//   equipped = true  : held by "owner", aims at the mouse (set up by kd_equip)
kd_globals_init();
owner      = noone;
equipped   = false;
weapon_key = "smg";
weapon     = kd_weapon_get(weapon_key);
aim_dir    = 0;
recoil     = 0;
cooldown   = 0;
flash      = 0;
bob        = 0;
muzzle_x   = x;
muzzle_y   = y;

// burst fire (Commit Burst Rifle)
burst_left  = 0;
burst_timer = 0;

// melee swing (KD Keris)
swing_t     = 0;     // steps left in the current swing (0 = resting)
swing_dir   = 1;     // flips every swing: down-slash, up-slash, ...
swing_hit   = [];    // NPCs already hit by this swing
swing_from  = 0;     // angle the blade started the swing at (for the slash trail)

// laser beam (Prod Laser)
beam_on   = 0;       // > 0 while the beam is firing
beam_tick = 0;
beam_x1 = x; beam_y1 = y; beam_x2 = x; beam_y2 = y;

kick_ang = 0;        // muzzle flip when firing

image_speed = 0;
