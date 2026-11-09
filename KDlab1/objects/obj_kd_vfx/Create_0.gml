/// obj_kd_vfx - Create
// One visual effect (scr_kd_vfx): "impact", "blood", "fire", "shield", "powerup", "powerup_back", "heal".
// The kd_vfx_* function that creates it sets "kind", "owner" and the effect's own variables.
kind     = "impact";
owner    = noone;     // instance the effect follows (or noone)
main     = noone;     // powerup_back: the front half of the power-up
t        = 0;         // seconds since it started
P        = [];        // particles
finished = false;
