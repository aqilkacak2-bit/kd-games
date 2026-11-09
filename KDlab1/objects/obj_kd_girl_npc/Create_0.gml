/// obj_kd_girl_npc - Create
// Simple example using the pre-baked sprites (spr_kd_girl_idle / spr_kd_walk).
// Walks back and forth on its floor, turns at walls and edges.
sprite_index = spr_kd_girl_idle;
image_speed  = 1;
mask_index   = spr_kd_body_mask;

facing = sign(image_xscale);
if (facing == 0) facing = 1;
image_xscale = 1;

walking      = false;
wander_timer = irandom_range(60, 150);
move_speed   = 0.6;
vsp  = 0;
grav = 0.25;

// chat
npc_name     = choose("Siti", "Aina", "Mei Ling");
bubble_text  = "";
bubble_timer = 0;
hit_flash    = 0;

// every NPC gets a random outfit from the customisation system
look   = kd_look_random();
anim_t = irandom(100);

// weapon effects (see kd_npc_status_step)
burn   = 0;   // on fire: runs around
freeze = 0;   // frozen solid
shock  = 0;   // stunned by lightning
hp_max     = 100;
hp         = hp_max;
ko         = 0;            // knocked out (steps left)
base_speed = move_speed;   // walking speed to return to after burning
fire_fx    = noone;        // fire.ts flames while burning
