/// obj_dash_fx - Draw   (BACK layer: behind the player)
var _n = array_length(C);

// skid mark on the ground
if (stopped && grounded)
{
    var _a = 0.8 * (1 - kd_smooth(0.6, 1.4, t - d1));
    if (_a > 0.01)
    {
        var _xa = end_x - dir * 35 * (dist / 200) - dir * 4;
        var _x1 = min(_xa, stop_x), _x2 = max(_xa, stop_x);
        draw_set_colour(COL_SKID);
        for (var _xx = floor(_x1); _xx <= _x2; _xx++)
        {
            draw_set_alpha(_a * min(1, abs(_xx - _xa) / 12));
            draw_point(_xx, g - 1);
        }
    }
}

// afterimage ghosts (character silhouette tinted with the dash colours)
if (instance_exists(owner))
{
    for (var _i = 0; _i < array_length(ghosts); _i++)
    {
        var _gh = ghosts[_i];
        var _k = (t - _gh.t) / 0.4;
        var _ci = min(_n - 3, 1 + floor(_k * (_n - 3)));
        var _a = 1;
        if (_k >= 0.45) _a = (1 - _k) / 0.55;
        gpu_set_fog(true, C[_ci + 2], 0, 1);
        kd_draw(_gh.x, _gh.y, _gh.f, "walk", 2, owner.look, 1, c_white, _a * 0.85, false, -50);
        gpu_set_fog(false, c_white, 0, 0);
    }
}

// speed lines
for (var _i = 0; _i < array_length(lines); _i++)
{
    var _l = lines[_i];
    var _k = (t - _l.t) / 0.2;
    var _len = _l.l * (1 - _k * 0.6);
    draw_set_alpha(1 - _k);
    draw_line_colour(_l.x, _l.y, _l.x - dir * 3, _l.y, C[0], C[0]);
    draw_set_alpha((1 - _k) * 0.8);
    draw_line_colour(_l.x - dir * 3, _l.y, _l.x - dir * _len * 0.4, _l.y, C[1], C[1]);
    draw_set_alpha((1 - _k) * 0.4);
    draw_line_colour(_l.x - dir * _len * 0.4, _l.y, _l.x - dir * _len, _l.y, C[3], C[3]);
}
draw_set_alpha(1);

// dust + smoke (behind)
kd_fx_draw(parts, false, id);
draw_set_alpha(1);
draw_set_colour(c_white);
