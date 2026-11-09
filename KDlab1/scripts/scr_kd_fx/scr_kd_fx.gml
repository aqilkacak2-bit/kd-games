/// Tiny particle helpers for the dash effect (ported from movement.ts "Particles").
/// Units are game pixels; speeds are pixels per second.

function kd_smooth(_a, _b, _x)
{
    var _t = clamp((_x - _a) / (_b - _a), 0, 1);
    return _t * _t * (3 - 2 * _t);
}

function kd_fx_spawn(_list, _kind, _x, _y, _vx, _vy, _life, _col, _size)
{
    array_push(_list, { k : _kind, x : _x, y : _y, vx : _vx, vy : _vy, life : _life, max : _life,
                        col : _col, size : _size, seed : random(100) });
}

function kd_fx_update(_list, _dt, _ground)
{
    for (var _i = array_length(_list) - 1; _i >= 0; _i--)
    {
        var _p = _list[_i];
        _p.life -= _dt;
        if (_p.life <= 0) { array_delete(_list, _i, 1); continue; }
        switch (_p.k)
        {
            case 0: // spark: gravity, drag, bounce on the ground
                _p.vy += 950 * 0.45 * _dt;
                _p.vx -= _p.vx * 2.2 * _dt;
                _p.vy -= _p.vy * 2.2 * _dt;
                var _ny = _p.y + _p.vy * _dt;
                _p.x += _p.vx * _dt;
                if (_p.vy > 0 && _p.y <= _ground && _ny >= _ground) { _p.vy = -_p.vy * 0.45; _p.vx *= 0.7; _p.y = _ground - 0.5; }
                else _p.y = _ny;
                break;
            case 3: // smoke: rises and drifts
                _p.vy -= 16 * _dt;
                _p.vx += sin(current_time / 1000 * 1.3 + _p.seed) * 8 * _dt;
                _p.vx -= _p.vx * 1.6 * _dt;
                _p.vy -= _p.vy * 1.2 * _dt;
                _p.x += _p.vx * _dt;
                _p.y += _p.vy * _dt;
                break;
            case 4: // dust
                _p.vx -= _p.vx * 4 * _dt;
                _p.vy -= _p.vy * 4 * _dt + 5 * _dt;
                _p.x += _p.vx * _dt;
                _p.y += _p.vy * _dt;
                break;
        }
    }
}

/// _front = false draws smoke + dust, true draws sparks. _fx = the obj_dash_fx (for its colours)
function kd_fx_draw(_list, _front, _fx)
{
    for (var _i = 0; _i < array_length(_list); _i++)
    {
        var _p = _list[_i];
        var _behind = (_p.k == 3 || _p.k == 4);
        if (_behind == _front) continue;
        var _k = _p.life / _p.max;
        switch (_p.k)
        {
            case 3:
                var _age = 1 - _k;
                var _r = _p.size * (0.65 + min(1, _age * 2.5) * 0.45 + _age * 0.4);
                var _a = min(1, _age * 12) * min(1, _k * 2.4) * 0.58;
                var _ri = min(3, floor(_age * 4));
                var _rc = merge_colour(_fx.SMOKE_RAMP[_ri], _fx.SMOKE_RAMP[_ri + 1], frac(_age * 4));
                var _c = merge_colour(_p.col, _rc, _age);
                draw_set_colour(_c);
                draw_set_alpha(_a * 0.45);
                draw_circle(_p.x, _p.y, _r, false);
                draw_set_alpha(_a * 0.62);
                draw_circle(_p.x + _r * 0.05, _p.y + _r * 0.06, _r * 0.74, false);
                break;
            case 4:
                draw_set_colour(_p.col);
                draw_set_alpha(power(_k, 1.3) * 0.7);
                draw_circle(_p.x, _p.y, _p.size * (0.6 + (1 - _k) * 0.9) * 0.5, false);
                break;
            case 0:
                var _hot = _fx.SPARK_ORA;
                if (_k > 0.6) _hot = _fx.SPARK_HOT; else if (_k > 0.3) _hot = _fx.SPARK_YEL;
                var _sp = max(1, point_distance(0, 0, _p.vx, _p.vy));
                var _ux = _p.vx / _sp, _uy = _p.vy / _sp;
                var _len = min(9, 1 + _sp * 2 * 0.011) * 0.5;
                var _tail = _fx.SPARK_TAIL;
                if (_k > 0.5) _tail = _hot;
                draw_set_alpha(1);
                draw_line_colour(_p.x - _ux * _len, _p.y - _uy * _len, _p.x - _ux * _len * 0.4, _p.y - _uy * _len * 0.4, _tail, _tail);
                draw_line_colour(_p.x - _ux * _len * 0.45, _p.y - _uy * _len * 0.45, _p.x, _p.y, _hot, _hot);
                break;
        }
    }
    draw_set_alpha(1);
}
