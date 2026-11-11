/// obj_player - Create  (side-view platformer)
// What the character wears comes from the Character Customiser (global.kd_look, see scr_kd_custom).
kd_globals_init();
gun  = noone;              // obj_gun  (created by kd_equip)
hand = noone;              // front obj_hand
hand_back = noone;         // back obj_hand
look = kd_look_copy(global.kd_look);
draw_bob = 0;              // body bob of the current frame (the gun + hand follow it)
arm_swing      = 0;        // front arm angle when no gun is held (0 = hanging down)
arm_swing_back = 0;        // back arm angle

// dash (R) - port of movement.ts
dash_distance = 64;        // pixels
dash_time     = 0.2;       // seconds of burst
dash_windup   = 0.06;      // seconds before the burst
dash_cooldown = 0.45;
dash_cool     = 0;
dash_t        = 0;
dash_dir      = 1;
dash_x0       = x;
dash_air_used = false;     // one dash in the air until you land
skid_v        = 0;         // skid speed after a dash
step_prev_frame = -1;      // for footstep sounds

// both arms are always there (obj_hand). Without a weapon they swing from the shoulders.
hand = instance_create_depth(x, y, depth - 2, obj_hand);
hand.owner = id;
hand.side  = "front";
hand_back = instance_create_depth(x, y, depth + 1, obj_hand);
hand_back.owner = id;
hand_back.side  = "back";

// movement
move_speed   = 1.2;
run_speed    = 2.0;
climb_speed  = 1.0;
stairs_speed = 0.8;
grav         = 0.25;
jump_speed   = 3.6;
max_fall     = 5;
hsp = 0;
vsp = 0;
on_ground = false;

// "normal" = walking/jumping, "ladder" = climbing, "stairs" = walking on stairs
mode   = "normal";
ladder = noone;
stairs = noone;

// animation
facing     = 1;        // 1 = right, -1 = left
state      = "idle";
anim_frame = 0;
anim_timer = 0;

image_speed = 0;
mask_index  = spr_kd_body_mask;   // collision box: body only

// chat bubble (set by obj_game)
bubble_text  = "";
bubble_timer = 0;

// re-equip the weapon you picked up (it carries over between rooms)
if (global.kd_weapon != "") kd_equip(id, global.kd_weapon);

// health: explosions hurt you, it regenerates after a short rest, at 0 you respawn
hp_max    = 100;
hp        = hp_max;
hurt_t    = 0;
invul     = 0;
hit_flash = 0;

// abilities: F = shield dome (shield.ts), H = heal (heal.ts)
shield_fx = noone;
shield_cd = 0;        // steps until the shield can be used again
heal_cd   = 0;

// hand grenade throw (G)
throw_t    = 0;       // steps left in the throw animation
throw_ang  = 0;       // throwing arm angle
thrown     = true;    // has the grenade left the hand yet
grenade_cd = 0;

// shooting downward pops the character up a little (visual only)
recoil_lift = 0;
recoil_vel  = 0;

// foot trail (spr_trail) + stats from the skill tree
trail_t      = 0;
trail_ground = true;
trail_frame  = 0;
kd_skills_apply(id);

// jetpack (skill tree: Jetpack) - hold SPACE in the air
jet_fuel_max = 120;          // steps of flying on a full tank (2 seconds)
jet_fuel     = jet_fuel_max;
jet_on       = false;
jet_t        = 0;
