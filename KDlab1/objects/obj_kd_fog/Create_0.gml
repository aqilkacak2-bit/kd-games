/// obj_kd_fog - Create
// One drifting fog layer (baked from fog.ts). Made by kd_fog_bank() in scr_kd_vfx.
spr       = spr_fog_0;
top_off   = -40;      // strip top, relative to area_y
spd       = 14;       // drift, pixels per second
area_y    = 0;        // bottom of the fog bank (room y)
layer_i   = 0;
alpha_mul = 1;
t         = random(100);
