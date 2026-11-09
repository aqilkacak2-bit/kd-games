/// obj_kd_npc - Step
wander_timer -= 1;
if (wander_timer <= 0)
{
    walking = !walking;
    if (walking)
    {
        if (irandom(1) == 0) facing = -facing;
        wander_timer = irandom_range(60, 140);
    }
    else
    {
        wander_timer = irandom_range(60, 180);
    }
}

// burning / frozen / shocked (scr_kd_weapons)
kd_npc_status_step();

// gravity
vsp = min(vsp + grav, 5);
if (place_meeting(x, y + vsp, obj_solid))
{
    while (!place_meeting(x, y + sign(vsp), obj_solid)) y += sign(vsp);
    vsp = 0;
}
y += vsp;

if (walking)
{
    var _dx = facing * move_speed;
    // turn around at walls and at the edge of a floor
    if (place_meeting(x + _dx, y, obj_solid) || !place_meeting(x + facing * 8, y + 1, obj_solid))
    {
        facing = -facing;
    }
    else
    {
        x += _dx;
    }
    if (sprite_index != spr_kd_walk) { sprite_index = spr_kd_walk; image_index = 0; }
}
else
{
    if (sprite_index != spr_kd_idle) { sprite_index = spr_kd_idle; image_index = 0; }
}

x = clamp(x, 8, room_width - 8);

if (hit_flash > 0) hit_flash -= 1;
anim_t += 1;
