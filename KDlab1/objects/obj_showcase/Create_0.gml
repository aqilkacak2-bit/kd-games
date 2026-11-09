/// obj_showcase - Create  (parent of the 5 exhibits; each child only sets its sprite)
info   = kd_showcase_info(object_index);
depth  = 85;            // on the wall, behind people
hover  = false;
glow   = 0;             // 0..1 hover highlight
near   = false;         // the player is standing at this exhibit
opened = 0;             // little flash after clicking
t      = irandom(100);
