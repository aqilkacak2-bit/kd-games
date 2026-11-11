/// obj_dungeon - Step
if (!kd_run_active()) exit;
t += 1;
if (banner_t > 0) banner_t -= 1;

// enemies come out of their portals
for (var _i = array_length(queue) - 1; _i >= 0; _i--)
{
    var _q = queue[_i];
    _q.t -= 1;
    if (_q.t <= 0)
    {
        kd_enemy_spawn(_q.kind, _q.x, _q.y);
        array_delete(queue, _i, 1);
    }
}

// everyone down: the exit opens
if (!cleared && t > 40 && array_length(queue) == 0 && !instance_exists(obj_enemy))
{
    cleared  = true;
    banner   = (type == "boss") ? "BOSS DOWN - walk into the portal" : "ROOM CLEAR";
    banner_t = 120;
    kd_sfx(snd_confirm);
    if (type == "fight") kd_drop(240, 120, "coin", 3);
}

// walk into the open exit on the right
if (cleared && instance_exists(obj_player))
{
    var _p = instance_find(obj_player, 0);
    if (_p.x > room_width - 30 && _p.y > KD_FLOOR_Y - 40)
    {
        if (type == "boss") kd_run_end(true);
        else kd_run_next();
    }
}
