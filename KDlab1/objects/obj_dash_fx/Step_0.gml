/// obj_dash_fx - Step
var _dt = 1 / game_get_speed(gamespeed_fps);
t += _dt;
var _k = dist / 200;                       // scale: movement.ts dashes 200 px, ours is shorter

var _ox = x0, _oy = g;
if (instance_exists(owner)) { _ox = owner.x; _oy = owner.y; }

// ---------- start of the dash: kick dust + smoke backwards ----------
if (!started && t >= d0)
{
    started = true;
    if (grounded)
    {
        repeat (14) kd_fx_spawn(parts, PK_DUST, x0 + random_range(-1.5, 1.5), g - 0.5,
                                choose(-1, 1) * random_range(10, 55) * 1.6, -random_range(2.5, 22.5),
                                random_range(0.3, 0.65), COL_DUST, random_range(1.3, 2.8));
    }
    repeat (8) kd_fx_spawn(parts, PK_SMOKE, x0 + random_range(-3, 3), g - random_range(1, 6),
                           -dir * random_range(40, 130), -random_range(5, 25), random_range(0.6, 1.1), COL_SMOKE, random_range(3, 6));
}

// ---------- during the dash: ghosts + speed lines ----------
if (t >= d0 && !stopped && instance_exists(owner) && owner.mode == "dash")
{
    if (is_undefined(last_ghost_x) || (abs(_ox - last_ghost_x) > 22 && t > d0 + 0.03))
    {
        last_ghost_x = _ox;
        array_push(ghosts, { x : _ox, y : _oy, f : owner.facing, t : t });
    }
    repeat (4) array_push(lines, { x : _ox - dir * random_range(2, 8), y : _oy - random_range(1, 22), l : random_range(8, 32), t : t });
    end_x = _ox;
}

// ---------- end: skid, sparks, shake ----------
if (!stopped && (t >= d1 || !instance_exists(owner) || owner.mode != "dash") && started)
{
    stopped = true;
    end_x = _ox;
    stop_x = _ox;
    shake = 0.25;
}
if (stopped && instance_exists(owner) && owner.skid_v > 60 * _k && grounded)
{
    stop_x = _ox;
    kd_fx_spawn(parts, PK_DUST, _ox + dir * 4, g - 1, dir * random_range(30, 130), -random_range(10, 45), random_range(0.4, 0.8), COL_SMOKE, random_range(1.5, 3));
    if (random(1) < 0.6) kd_fx_spawn(parts, PK_SPARK, _ox + dir * 3, g - 0.5, dir * random_range(100, 300), -random_range(20, 100), random_range(0.1, 0.25), c_white, 1);
    if (random(1) < 0.4) kd_fx_spawn(parts, PK_SMOKE, _ox, g - 2, dir * random_range(20, 70), -random_range(5, 20), random_range(0.6, 1), COL_SMOKE, random_range(3, 5));
}

// screen shake (moves the view port a little)
if (shake > 0)
{
    shake = max(0, shake - _dt * 1.4);
    var _amp = shake * shake * 40;
    view_set_xport(0, round(random_range(-_amp, _amp)));
    view_set_yport(0, round(random_range(-_amp, _amp)));
    if (shake == 0) { view_set_xport(0, 0); view_set_yport(0, 0); }
}

// expire lines / ghosts
for (var _i = array_length(lines) - 1; _i >= 0; _i--) if (t - lines[_i].t > 0.2) array_delete(lines, _i, 1);
for (var _i = array_length(ghosts) - 1; _i >= 0; _i--) if (t - ghosts[_i].t > 0.4) array_delete(ghosts, _i, 1);

kd_fx_update(parts, _dt, g);

if (t > d1 + 1.2 && array_length(parts) == 0 && shake == 0) instance_destroy();
