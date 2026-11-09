/// KDlab1 visual effects - ported from the Sprite Fusion VFX files (fire, impact, blood, shield,
/// power-up, heal, fog). Original TypeScript: MIT License, Copyright (c) 2026 Hugo Duprez.
///
/// The originals paint a pixel buffer + a light buffer. Here every effect is one obj_kd_vfx instance:
/// the same particles, timings and colour ramps, drawn with a 1x1 pixel sprite (spr_kd_px), circles,
/// and additive glows. Positions are in room pixels (the originals use 2 screen px per art pixel).
///
///   kd_vfx_impact(x, y, dir, glance, surface_colour, normal_dir, ground_y, size)   bullet hits / ricochets
///   kd_vfx_blood(npc, dir, amount)                                                 people getting hit
///   kd_vfx_fire(npc)                                                               follows a burning person
///   kd_vfx_shield(player)                                                          F: hex dome, blocks explosions
///   kd_vfx_powerup(player)                                                         level up / new look
///   kd_vfx_heal(who)                                                               H: heal / getting back up
///   kd_room_fx_setup()                                                             fog banks (obj_kd_fog)

#macro KD_DT (1 / 60)

// ---------------------------------------------------------------- palettes (same hex values as the originals)
function kd_pal()
{
    static p = undefined;
    if (is_undefined(p))
    {
        p = {
            fire   : [make_colour_rgb(255, 255, 255), make_colour_rgb(255, 243, 166), make_colour_rgb(255, 226, 107), make_colour_rgb(255, 194, 61), make_colour_rgb(255, 138, 42), make_colour_rgb(242, 86, 29), make_colour_rgb(201, 40, 31), make_colour_rgb(138, 31, 23), make_colour_rgb(74, 23, 18)],
            smoke  : [make_colour_rgb(123, 111, 114), make_colour_rgb(93, 86, 96), make_colour_rgb(67, 61, 72), make_colour_rgb(43, 38, 48), make_colour_rgb(26, 23, 30)],
            warm   : [make_colour_rgb(255, 255, 255), make_colour_rgb(255, 243, 166), make_colour_rgb(255, 226, 107), make_colour_rgb(255, 138, 42), make_colour_rgb(242, 86, 29), make_colour_rgb(201, 40, 31)],
            blood  : [make_colour_rgb(255, 138, 122), make_colour_rgb(242, 56, 74), make_colour_rgb(199, 30, 51), make_colour_rgb(147, 19, 39), make_colour_rgb(94, 12, 27), make_colour_rgb(53, 7, 17)],
            ice    : [make_colour_rgb(255, 255, 255), make_colour_rgb(220, 251, 255), make_colour_rgb(166, 236, 255), make_colour_rgb(98, 200, 244), make_colour_rgb(58, 139, 216), make_colour_rgb(44, 88, 170), make_colour_rgb(33, 47, 107), make_colour_rgb(21, 26, 61)],
            power  : [make_colour_rgb(255, 255, 255), make_colour_rgb(224, 252, 255), make_colour_rgb(143, 240, 255), make_colour_rgb(63, 208, 255), make_colour_rgb(34, 144, 230), make_colour_rgb(31, 79, 171), make_colour_rgb(23, 42, 104)],
            heal   : [make_colour_rgb(255, 255, 255), make_colour_rgb(230, 255, 220), make_colour_rgb(172, 255, 146), make_colour_rgb(98, 226, 106), make_colour_rgb(48, 181, 91), make_colour_rgb(32, 128, 76), make_colour_rgb(23, 82, 55), make_colour_rgb(15, 49, 37)],
            soot   : make_colour_rgb(13, 10, 18),
            smoke1 : make_colour_rgb(91, 85, 102),
            smoke2 : make_colour_rgb(106, 98, 120),
            outline: make_colour_rgb(26, 20, 34),
            dust   : make_colour_rgb(106, 94, 130),
            warmglow : make_colour_rgb(255, 176, 96),
            deep_orange : make_colour_rgb(242, 86, 29),
            hot    : make_colour_rgb(255, 243, 166),
            wall   : make_colour_rgb(150, 156, 170)
        };
    }
    return p;
}

// ---------------------------------------------------------------- small helpers
function kd_hash(_n, _k)
{
    var _v = sin(_n * 12.9898 + _k * 78.233) * 43758.5453;
    return _v - floor(_v);
}
function kd_noise(_x, _seed)
{
    var _i = floor(_x);
    var _f = _x - _i;
    var _u = _f * _f * (3 - 2 * _f);
    var _a = kd_hash(_i, _seed) * 2 - 1;
    return _a + (kd_hash(_i + 1, _seed) * 2 - 1 - _a) * _u;
}
// kd_smooth(a, b, x) is shared with the dash effect (scr_kd_fx)
function kd_frac(_x) { return _x - floor(_x); }
function kd_bayer(_x, _y)
{
    static b = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5];
    var _i = (((floor(_y) mod 4) + 4) mod 4) * 4 + (((floor(_x) mod 4) + 4) mod 4);
    return (b[_i] + 0.5) / 16;
}
function kd_scale_col(_c, _k)
{
    return make_colour_rgb(min(255, colour_get_red(_c) * _k), min(255, colour_get_green(_c) * _k), min(255, colour_get_blue(_c) * _k));
}
function kd_ramp(_stops, _t)
{
    var _u = clamp(_t, 0, 0.9999) * (array_length(_stops) - 1);
    var _i = floor(_u);
    return merge_colour(_stops[_i], _stops[_i + 1], _u - _i);
}
/// a w x h block of pixels (room pixels)
function kd_px(_x, _y, _w, _h, _c, _a)
{
    if (_a <= 0.01) return;
    draw_sprite_ext(spr_kd_px, 0, floor(_x), floor(_y), _w, _h, 0, _c, min(1, _a));
}
function kd_disc(_x, _y, _r, _c, _a)
{
    if (_a <= 0.01 || _r <= 0) return;
    if (_r <= 0.6) { kd_px(_x, _y, 1, 1, _c, _a); return; }
    draw_set_colour(_c);
    draw_set_alpha(min(1, _a));
    draw_circle(_x, _y, _r, false);
    draw_set_alpha(1);
}
/// additive light (the originals' light buffer)
function kd_glow(_x, _y, _r, _c, _k)
{
    if (_r < 1 || _k <= 0.01) return;
    gpu_set_blendmode(bm_add);
    draw_circle_colour(_x, _y, _r, merge_colour(c_black, _c, clamp(_k * 0.8, 0, 1)), c_black, false);
    gpu_set_blendmode(bm_normal);
}
function kd_seg(_x1, _y1, _x2, _y2, _c, _a, _w)
{
    if (_a <= 0.01) return;
    draw_set_colour(_c);
    draw_set_alpha(min(1, _a));
    draw_line_width(_x1, _y1, _x2, _y2, _w);
    draw_set_alpha(1);
}
function kd_vfx_count() { return instance_number(obj_kd_vfx); }

/// create an effect instance (the kd_vfx_* functions below fill it in)
function kd_vfx(_kind, _x, _y, _owner)
{
    var _v = instance_create_depth(_x, _y, -20, obj_kd_vfx);
    _v.kind  = _kind;
    _v.owner = _owner;
    return _v;
}
/// add a particle to the current effect (runs in obj_kd_vfx scope)
function kd_vfx_part(_k, _x, _y, _vx, _vy, _life, _col, _size)
{
    array_push(P, { k : _k, x : _x, y : _y, vx : _vx, vy : _vy, life : _life, mx : _life, col : _col, size : _size,
                    seed : random(100), smokes : false, front : true });
    return P[array_length(P) - 1];
}
/// shared smoke puff drawing (fire + impact)
function kd_vfx_smoke_draw(_p)
{
    var _k   = _p.life / _p.mx;
    var _age = 1 - _k;
    var _r   = _p.size * (0.65 + min(1, _age * 2.5) * 0.45 + _age * 0.4);
    var _a   = min(1, _age * 12) * min(1, _k * 2.4) * 0.55;
    var _sm  = kd_pal().smoke;
    var _c   = kd_ramp(_sm, _age * 1.05);
    if (_p.col != -1) _c = merge_colour(_p.col, kd_ramp(_sm, _age), _age);
    kd_disc(_p.x, _p.y, _r, _c, _a * 0.45);
    kd_disc(_p.x + _r * 0.05, _p.y + _r * 0.06, _r * 0.74, _c, _a * 0.62);
}
function kd_vfx_smoke_step(_p, _dt)
{
    _p.vy -= 16 * _dt;
    _p.vx += sin(t * 1.3 + _p.seed) * 8 * _dt;
    _p.vx -= _p.vx * 1.6 * _dt;
    _p.vy -= _p.vy * 1.2 * _dt;
    _p.x += _p.vx * _dt;
    _p.y += _p.vy * _dt;
}
/// 4-armed twinkling star (shield / heal / power-up sparkles)
function kd_vfx_star_draw(_px, _py, _size, _col, _k, _tw)
{
    if (_size < 1)
    {
        if (_tw * _k > 0.25) kd_px(_px, _py, 1, 1, (_tw > 0.8) ? c_white : _col, 1);
        kd_glow(_px, _py, 3, _col, 0.4 * _k * _tw);
        return;
    }
    var _arm = max(1, round(_size * _tw * min(1, _k * 3)));
    var _tip = kd_scale_col(_col, 0.75);
    for (var _d = 1; _d <= _arm; _d++)
    {
        var _cc = (_d == _arm && _arm > 1) ? _tip : _col;
        kd_px(_px + _d, _py, 1, 1, _cc, 1);
        kd_px(_px - _d, _py, 1, 1, _cc, 1);
        kd_px(_px, _py + _d, 1, 1, _cc, 1);
        kd_px(_px, _py - _d, 1, 1, _cc, 1);
    }
    if (_arm >= 3)
    {
        kd_px(_px + 1, _py + 1, 1, 1, _tip, 1); kd_px(_px - 1, _py + 1, 1, 1, _tip, 1);
        kd_px(_px + 1, _py - 1, 1, 1, _tip, 1); kd_px(_px - 1, _py - 1, 1, 1, _tip, 1);
    }
    kd_px(_px, _py, 1, 1, c_white, 1);
    kd_glow(_px, _py, 3 + _arm * 2, _col, 0.5 * _k * _tw);
}

// ================================================================ IMPACT (impact.ts)
/// dir = travel direction of the bullet (GameMaker degrees). glance = ricochet streak.
/// surf = colour of the wall that was hit (-1 = hit a person / the air). normal = wall facing direction.
function kd_vfx_impact(_x, _y, _dir, _glance, _surf, _normal, _ground, _size)
{
    if (kd_vfx_count() > 160) return noone;
    var _v = kd_vfx("impact", _x, _y, noone);
    with (_v)
    {
        C       = kd_pal().warm;
        glance  = _glance;
        S       = _size;
        grd     = _ground;
        A       = -degtorad(_dir);           // radians, y down (like the original)
        on_surf = (_surf != -1);
        N       = -degtorad(_normal);
        var _dx = cos(A);
        var _dy = sin(A);
        var _nx = cos(N);
        var _ny = sin(N);
        var _dn = _dx * _nx + _dy * _ny;
        B = A;
        if (on_surf) B = arctan2(_dy - 2 * _dn * _ny, _dx - 2 * _dn * _nx);   // reflected direction
        // the 8-point star
        spikes = [];
        var _gl = glance ? 2.6 : 1.8;
        for (var _i = 0; _i < 8; _i++)
        {
            var _a   = B + (_i / 8) * 2 * pi + random_range(-0.18, 0.18);
            var _cb  = cos(_a - B);
            var _len = (7 + random(3)) * S * (1 + _gl * power(max(0, _cb), 3) + 0.6 * power(max(0, -_cb), 3));
            if (on_surf && cos(_a - N) < -0.2) _len *= 0.3;
            if (glance && abs(sin(_a - B)) > 0.6) _len *= 0.6;
            array_push(spikes, { a : _a, len : _len, w : (1.5 + random(0.6)) * S });
        }
        // the 4 longest open spikes fly off as crescents
        var _open = [];
        for (var _i = 0; _i < 8; _i++) if (kd_vfx_impact_open(spikes[_i].a)) array_push(_open, spikes[_i]);
        array_sort(_open, function(_p, _q) { return _q.len - _p.len; });
        shards = [];
        for (var _i = 0; _i < min(4, array_length(_open)); _i++)
        {
            var _s = _open[_i];
            array_push(shards, { a : _s.a + random_range(-0.15, 0.15), r : _s.len * 0.8, v : _s.len * random_range(5, 8), arc : random_range(0.35, 0.6) });
        }
        // sparks
        var _n = round((glance ? 10 : 6) + 12 * S);
        for (var _i = 0; _i < _n; _i++)
        {
            var _back = !on_surf && random(1) < 0.2;
            var _sprd = glance ? 0.3 : (on_surf ? 0.85 : 0.6);
            var _a2 = (_back ? A + pi : B) + random_range(-1, 1) * _sprd;
            var _sp = random_range(130, 450) * (0.6 + 0.4 * S) * (glance ? 1.2 : 1);
            kd_vfx_part(0, x, y, cos(_a2) * _sp, sin(_a2) * _sp - (glance ? 10 : 30), random_range(0.1, 0.3) * (glance ? 1.3 : 1), -1, 1);
        }
        if (on_surf)
        {
            var _dc = merge_colour(_surf, make_colour_rgb(150, 140, 150), 0.35);
            repeat (round((glance ? 2 : 3) + 5 * S))      // wall chips
            {
                var _a3 = (glance ? B : N) + random_range(-0.8, 0.8) * (glance ? 0.6 : 1);
                var _sp3 = random_range(75, 210) * S;
                kd_vfx_part(1, x, y + _ny, cos(_a3) * _sp3, sin(_a3) * _sp3, random_range(0.8, 1.4),
                            choose(kd_scale_col(_surf, 1.25), _surf, kd_scale_col(_surf, 0.7)), choose(1, 1, 2));
            }
            repeat (round(3 + 4 * S))                        // dust
            {
                var _a4 = N + random_range(-1, 1);
                var _sp4 = random_range(10, 45) * S;
                kd_vfx_part(2, x + _nx * 1.5, y + _ny * 1.5, cos(_a4) * _sp4, sin(_a4) * _sp4, random_range(0.35, 0.7), _dc, random_range(1.4, 2.8) * sqrt(S));
            }
            kd_vfx_part(3, x + _nx * 2, y + _ny * 2, random_range(-4, 4), random_range(-15, -7), random_range(0.8, 1.3), kd_pal().smoke2, random_range(1.6, 2.4) * sqrt(S));
        }
    }
    return _v;
}
function kd_vfx_impact_open(_a) { return !on_surf || cos(_a - N) > -0.25; }

function kd_vfx_impact_step()
{
    var _dt = KD_DT;
    for (var _i = array_length(P) - 1; _i >= 0; _i--)
    {
        var _p = P[_i];
        _p.life -= _dt;
        if (_p.life <= 0) { array_delete(P, _i, 1); continue; }
        switch (_p.k)
        {
            case 0:     // spark: gravity, drag, bounces on the floor
                _p.vy += 950 * 0.45 * _dt;
                _p.vx -= _p.vx * 2.2 * _dt;
                _p.vy -= _p.vy * 2.2 * _dt;
                var _ny = _p.y + _p.vy * _dt;
                _p.x += _p.vx * _dt;
                if (_p.vy > 0 && _p.y <= grd && _ny >= grd) { _p.vy = -_p.vy * 0.45; _p.vx *= 0.7; _p.y = grd - 0.5; }
                else _p.y = _ny;
                break;
            case 1:     // wall chip
                _p.vy += 950 * _dt;
                _p.vx -= _p.vx * 0.6 * _dt;
                var _ny2 = _p.y + _p.vy * _dt;
                _p.x += _p.vx * _dt;
                if (_p.vy > 0 && _p.y <= grd && _ny2 >= grd)
                {
                    _p.y = grd - 0.5;
                    if (_p.vy > 110) { _p.vy = -_p.vy * 0.3; _p.vx = _p.vx * 0.5 + random_range(-10, 10); }
                    else { _p.vx = 0; _p.vy = 0; _p.life = min(_p.life, 0.5); }
                }
                else _p.y = _ny2;
                break;
            case 2:     // dust
                _p.vx -= _p.vx * 4 * _dt;
                _p.vy -= _p.vy * 4 * _dt + 5 * _dt;
                _p.x += _p.vx * _dt;
                _p.y += _p.vy * _dt;
                break;
            case 3:
                kd_vfx_smoke_step(_p, _dt);
                break;
        }
    }
    if (t > (glance ? 0.3 : 0.2) && array_length(P) == 0) finished = true;
}

function kd_vfx_impact_draw()
{
    kd_vfx_impact_parts(false);
    var _f = max(1, ceil(t * 60 - 0.000001));
    if (_f == 1) kd_vfx_impact_star(1, 1, C[0], C[1], C[2], C[4]);
    else if (_f == 2) kd_vfx_impact_star(1.25, 0.55, C[1], C[2], C[3], C[4]);
    // flying crescents
    if (_f >= 3 && t < 0.13)
    {
        var _k = (t - 2 / 60) / (0.13 - 2 / 60);
        var _col = (_k < 0.4) ? C[2] : ((_k < 0.7) ? C[3] : C[4]);
        for (var _i = 0; _i < array_length(shards); _i++)
        {
            var _s = shards[_i];
            kd_vfx_impact_crescent(_s.a, _s.r + _s.v * (t - 2 / 60), _s.arc * (1 - 0.4 * _k), _col, 1 - _k);
        }
    }
    // expanding ring (open side only when it hit a wall)
    if (_f >= 3 && t < 0.2)
    {
        var _k2  = (t - 2 / 60) / (0.2 - 2 / 60);
        var _r   = (8 + 12 * (1 - power(1 - _k2, 3))) * S;
        var _col2 = (_k2 < 0.3) ? C[1] : ((_k2 < 0.6) ? C[2] : C[3]);
        var _n = ceil(_r * 2 * pi * 1.3);
        for (var _j = 0; _j < _n; _j++)
        {
            var _a = (_j / _n) * 2 * pi;
            if (!kd_vfx_impact_open(_a)) continue;
            kd_px(x + cos(_a) * _r, y + sin(_a) * _r, 1, 1, _col2, 1.15 - _k2);
        }
    }
    // ricochet streak
    if (glance && t < 0.16)
    {
        var _tx = cos(B);
        var _ty = sin(B);
        var _head = 750 * t + 6 * S;
        var _tail = max(2, _head - (20 + 110 * t));
        var _kk = t / 0.16;
        var _m1 = _tail + (_head - _tail) * 0.4;
        var _m2 = _tail + (_head - _tail) * 0.8;
        kd_seg(x + _tx * _tail, y + _ty * _tail, x + _tx * _m1, y + _ty * _m1, C[3], 1 - _kk, 1);
        kd_seg(x + _tx * _m1, y + _ty * _m1, x + _tx * _m2, y + _ty * _m2, C[1], 1, 1);
        kd_seg(x + _tx * _m2, y + _ty * _m2, x + _tx * _head, y + _ty * _head, C[0], 1, 1);
        kd_glow(x + _tx * _head, y + _ty * _head, 9, C[2], 0.6 * (1 - _kk));
    }
    kd_vfx_impact_parts(true);
    var _pop = exp(-t / 0.05);
    if (_pop > 0.02)
    {
        kd_glow(x, y, 22 * S + 6, C[3], 0.9 * _pop);
        kd_glow(x, y, 8 * S + 2, C[0], 0.7 * _pop);
    }
}

function kd_vfx_impact_star(_sc, _th, _core, _body, _inner, _rim)
{
    for (var _pass = 0; _pass < 3; _pass++)
    {
        for (var _i = 0; _i < array_length(spikes); _i++)
        {
            var _s  = spikes[_i];
            var _c  = cos(_s.a);
            var _sn = sin(_s.a);
            var _L  = _s.len * _sc;
            var _w  = _s.w * _th;
            var _col = _body;
            if (_pass == 0) { _col = _rim; _w += 0.8; _L += 0.8; }
            if (_pass == 2) { _col = _core; _w *= 0.45; _L *= 0.55; }
            draw_set_colour(_col);
            draw_triangle(x - _sn * _w, y + _c * _w, x + _sn * _w, y - _c * _w, x + _c * _L, y + _sn * _L, false);
            if (_pass == 1)
            {
                draw_set_colour(_inner);
                draw_triangle(x - _sn * _w, y + _c * _w, x + _sn * _w, y - _c * _w, x + _c * _L * 0.35, y + _sn * _L * 0.35, false);
            }
        }
    }
    var _r = 2.4 * S * _sc * sqrt(_th);
    kd_disc(x, y, _r + 0.8, _inner, 1);
    kd_disc(x, y, _r, _core, 1);
    draw_set_colour(c_white);
}

function kd_vfx_impact_crescent(_a, _r, _arc, _c, _k)
{
    var _n = max(2, ceil(_r * _arc * 2.2));
    var _px = x + cos(_a - _arc / 2) * _r;
    var _py = y + sin(_a - _arc / 2) * _r;
    for (var _j = 1; _j <= _n; _j++)
    {
        var _u  = _j / _n - 0.5;
        var _th = _a + _u * _arc;
        var _nx = x + cos(_th) * _r;
        var _ny = y + sin(_th) * _r;
        kd_seg(_px, _py, _nx, _ny, _c, _k, max(0.5, 1.4 * (1 - abs(_u) * 2)));
        _px = _nx;
        _py = _ny;
    }
}

function kd_vfx_impact_parts(_front)
{
    for (var _i = 0; _i < array_length(P); _i++)
    {
        var _p = P[_i];
        if ((_p.k == 0) != _front) continue;
        var _k = _p.life / _p.mx;
        switch (_p.k)
        {
            case 0:
                var _sp = max(1, point_distance(0, 0, _p.vx, _p.vy));
                var _len = min(4.5, 0.5 + _sp * 0.011);
                var _col = (_k > 0.6) ? C[1] : ((_k > 0.3) ? C[2] : C[3]);
                kd_seg(_p.x - _p.vx / _sp * _len, _p.y - _p.vy / _sp * _len, _p.x, _p.y, _col, 1, 1);
                kd_px(_p.x, _p.y, 1, 1, (_k > 0.5) ? C[0] : _col, 1);
                break;
            case 1:
                kd_px(_p.x, _p.y, _p.size, _p.size, _p.col, min(1, _k * 3));
                break;
            case 2:
                kd_disc(_p.x, _p.y, _p.size * (0.6 + (1 - _k) * 0.9) * 0.5, _p.col, power(_k, 1.3) * 0.7);
                break;
            case 3:
                kd_vfx_smoke_draw(_p);
                break;
        }
    }
}

// ================================================================ BLOOD (blood.ts)
/// amount 0.25 .. 1.3. The spray goes the way the hit travelled; drops land on the floor as stains.
function kd_vfx_blood(_npc, _dir, _amount)
{
    if (kd_vfx_count() > 140) return noone;
    var _v = kd_vfx("blood", _npc.x, _npc.y - 14, _npc);
    with (_v)
    {
        depth = _npc.depth - 2;
        C    = kd_pal().blood;
        A    = -degtorad(_dir);
        NB   = _amount;
        SZ   = 0.6;                   // our characters are smaller than the original's
        grd  = _npc.y;                // the floor under the person
        wx0  = x - _npc.x;            // wound position relative to the feet
        wy0  = y - _npc.y;
        wx   = x;
        wy   = y;
        LIFE = 6;                     // seconds a stain stays
        drops = [];
        stains = [];
        mist = [];
        var _ux = cos(A);
        var _uy = sin(A);
        strands = [];
        for (var _i = 0; _i < 7; _i++)
        {
            var _u = (_i - 3) / 3;
            array_push(strands, { a : A + _u * 0.62 + random_range(-0.08, 0.08),
                                  l : (11 + 7 * (1 - abs(_u)) + random_range(-2, 3)) * SZ,
                                  w : (1.3 + 0.6 * (1 - abs(_u))) * SZ });
        }
        drips = [];
        var _t0 = [random_range(0.22, 0.32), random_range(0.6, 0.8), random_range(1.1, 1.4)];
        for (var _i = 0; _i < ((NB >= 1) ? 3 : 2); _i++) array_push(drips, { t0 : _t0[_i], fell : false });
        // spray
        var _n = round(46 * NB);
        for (var _i = 0; _i < _n; _i++)
        {
            var _s = (random(1) < 0.12) ? 3 : ((random(1) < 0.35) ? 2 : 1);
            var _spread = random_range(-1, 1) * random_range(0.1, 0.65) * ((_s == 1) ? 1.2 : 0.8);
            var _delay = random(0.07);
            var _sp = ((_s == 1) ? random_range(130, 475) : ((_s == 2) ? random_range(100, 325) : random_range(75, 230))) * (1 - _delay * 4);
            var _a = A + _spread;
            array_push(drops, { x : x + _ux * random(4), y : y + _uy * random(4), vx : cos(_a) * _sp, vy : sin(_a) * _sp - random(75),
                                s : _s, delay : _delay, life : 3, crown : false, seed : random(1) });
        }
        // fast jet
        for (var _i = 0; _i < round(14 * NB); _i++)
        {
            var _a2 = A + random_range(-0.12, 0.12);
            var _sp2 = random_range(310, 525);
            array_push(drops, { x : x, y : y, vx : cos(_a2) * _sp2, vy : sin(_a2) * _sp2 - random(30),
                                s : (random(1) < 0.25) ? 2 : 1, delay : (_i / 14) * 0.05, life : 3, crown : false, seed : random(1) });
        }
        // mist
        for (var _i = 0; _i < round(6 * sqrt(NB)); _i++)
        {
            var _a3 = A + random_range(-0.5, 0.5);
            var _sp3 = random_range(15, 55);
            var _l = random_range(0.35, 0.6);
            array_push(mist, { x : x + _ux * random_range(1, 7), y : y + _uy * random_range(1, 7), vx : cos(_a3) * _sp3, vy : sin(_a3) * _sp3 - 6,
                               r : random_range(2.5, 5) * SZ, life : _l, mx : _l, t0 : random(0.05) });
        }
    }
    return _v;
}

function kd_vfx_blood_splat(_d)
{
    var _sp  = point_distance(0, 0, _d.vx, _d.vy);
    var _dir = (_d.vx >= 0) ? 1 : -1;
    var _w = ((_d.s == 1) ? 0.5 + min(0.6, _sp / 600) : _d.s * 0.6 + min(0.9, _sp / 400)) * (_d.crown ? 0.5 : 1);
    var _sats = [];
    var _ns = (_d.s >= 2 && _sp > 175) ? 2 : ((_sp > 225) ? 1 : 0);
    for (var _k = 0; _k < _ns; _k++) array_push(_sats, [random_range(1, 3) + _k * random_range(1.5, 3), (random(1) < 0.2) ? 2 : 1]);
    array_push(stains, { x : _d.x, y : grd, w : _w, lean : min(1, abs(_d.vx) / 200), dir : _dir, t0 : t, sats : _sats, tone : (random(1) < 0.3) ? 1 : 0 });
    if (!_d.crown && _d.s >= 2 && _sp > 130)
    {
        repeat (irandom_range(1, 3))
            array_push(drops, { x : _d.x, y : grd - 1, vx : _dir * random_range(5, 65) + random_range(-35, 35), vy : -random_range(40, 85),
                                s : 1, delay : 0, life : 0.8, crown : true, seed : random(1) });
    }
}

function kd_vfx_blood_step()
{
    var _dt = KD_DT;
    for (var _i = array_length(drops) - 1; _i >= 0; _i--)
    {
        var _d = drops[_i];
        if (_d.delay > 0) { _d.delay -= _dt; continue; }
        _d.life -= _dt;
        if (_d.life <= 0) { array_delete(drops, _i, 1); continue; }
        var _drag = 0.7 / _d.s;
        _d.vy += 950 * _dt;
        _d.vx -= _d.vx * _drag * _dt;
        _d.vy -= _d.vy * _drag * 0.5 * _dt;
        var _py = _d.y;
        _d.x += _d.vx * _dt;
        _d.y += _d.vy * _dt;
        if (_d.vy > 0 && _py <= grd && _d.y >= grd) { kd_vfx_blood_splat(_d); array_delete(drops, _i, 1); }
    }
    // the wound follows the person; drips fall from it
    wx = x;
    wy = y;
    if (instance_exists(owner)) { wx = owner.x + wx0; wy = owner.y + wy0; }
    for (var _i = 0; _i < array_length(drips); _i++)
    {
        var _dr = drips[_i];
        if (!_dr.fell && t >= _dr.t0 + 0.2)
        {
            _dr.fell = true;
            array_push(drops, { x : wx + random_range(-0.5, 0.5), y : wy + 3, vx : random_range(-5, 5), vy : 15,
                                s : choose(1, 2), delay : 0, life : 3, crown : false, seed : random(1) });
        }
    }
    for (var _i = array_length(mist) - 1; _i >= 0; _i--)
    {
        var _m = mist[_i];
        if (_m.t0 > 0) { _m.t0 -= _dt; continue; }
        _m.life -= _dt;
        if (_m.life <= 0) { array_delete(mist, _i, 1); continue; }
        _m.vx -= _m.vx * 3 * _dt;
        _m.vy -= _m.vy * 3 * _dt + 3 * _dt;
        _m.x += _m.vx * _dt;
        _m.y += _m.vy * _dt;
    }
    var _all_dry = true;
    for (var _i = 0; _i < array_length(stains); _i++) if (t - stains[_i].t0 <= LIFE + 1.2) _all_dry = false;
    if (t > 1 && array_length(drops) == 0 && _all_dry) finished = true;
}

function kd_vfx_blood_draw()
{
    // stains on the floor (darken as they dry, then fade)
    for (var _i = 0; _i < array_length(stains); _i++)
    {
        var _s = stains[_i];
        var _age = t - _s.t0;
        var _fade = 1 - clamp((_age - LIFE) / 1.2, 0, 1);
        if (_fade <= 0) continue;
        var _spread = kd_smooth(0, 0.12, _age);
        var _hw = _s.w * (0.55 + 0.45 * _spread);
        var _dry = min(4, ((_age < 0.35) ? 1 : ((_age < 1.4) ? 2 : ((_age < 3.2) ? 3 : 4))) + _s.tone);
        var _body = C[_dry];
        var _under = C[min(5, _dry + 1)];
        var _x0 = _s.x - _hw * (1 - 0.3 * _s.lean);
        var _x1 = _s.x + _hw * (1 + 0.8 * _s.lean);
        var _lo = (_s.dir > 0) ? _x0 : 2 * _s.x - _x1;
        var _hi = (_s.dir > 0) ? _x1 : 2 * _s.x - _x0;
        for (var _xx = floor(_lo); _xx <= ceil(_hi); _xx++)
        {
            var _q = abs(_xx + 0.5 - _s.x) / max(0.5, (_hi - _lo) / 2);
            kd_px(_xx, _s.y, 1, 1, (_q > 0.85 && _s.w > 1) ? _under : _body, _fade);
            if (_s.w > 1.6 && _q < 0.6) kd_px(_xx, _s.y + 1, 1, 1, _under, _fade);
            if (_s.w > 2.2 && _q < 0.45) kd_px(_xx, _s.y - 1, 1, 1, (_q < 0.2 && _age < 1) ? C[1] : _body, _fade);
        }
        if (_age < 0.4 && _s.w > 1) kd_px(_s.x - _s.dir * _hw * 0.3, _s.y, 1, 1, C[0], _fade);
        for (var _j = 0; _j < array_length(_s.sats); _j++)
        {
            var _sx = _s.x + _s.dir * (_hw * (1 + 0.6 * _s.lean) + _s.sats[_j][0] * _spread);
            kd_px(_sx, _s.y, 1, 1, _body, _fade);
            if (_s.sats[_j][1] > 1) kd_px(_sx + _s.dir, _s.y, 1, 1, _under, _fade);
        }
    }
    // mist
    for (var _i = 0; _i < array_length(mist); _i++)
    {
        var _m = mist[_i];
        if (_m.t0 > 0) continue;
        var _k = _m.life / _m.mx;
        kd_disc(_m.x, _m.y, _m.r * (1.6 - 0.6 * _k), C[3], 0.4 * _k * min(1, (1 - _k) * 8));
    }
    // the first burst: strands shooting out of the hit point
    if (t < 0.09)
    {
        var _grow = 1 - power(1 - clamp(t / 0.045, 0, 1), 3);
        var _brk = clamp((t - 0.04) / 0.05, 0, 1);
        for (var _i = 0; _i < array_length(strands); _i++)
        {
            var _st = strands[_i];
            var _L = _st.l * _grow;
            var _d0 = _L * _brk;
            var _ca = cos(_st.a);
            var _sa = sin(_st.a);
            var _ww = _st.w * (1 - _brk * 0.5);
            kd_seg(x + _ca * _d0, y + _sa * _d0, x + _ca * _L, y + _sa * _L, C[4], 1, (_ww + 0.7) * 2);
            kd_seg(x + _ca * _d0, y + _sa * _d0, x + _ca * _L * 0.35, y + _sa * _L * 0.35, C[1], 1, _ww * 2);
            kd_seg(x + _ca * _L * 0.35, y + _sa * _L * 0.35, x + _ca * _L, y + _sa * _L, C[2], 1, _ww * 1.4);
        }
        if (t < 0.035) { kd_disc(x, y, 2.6 * SZ, C[1], 1); kd_disc(x, y, 1.5 * SZ, C[0], 1); }
        kd_glow(x, y, 16 * SZ, C[1], 0.25 * (1 - t / 0.09));
    }
    // drips running down from the wound
    for (var _i = 0; _i < array_length(drips); _i++)
    {
        var _dr = drips[_i];
        var _u = t - _dr.t0;
        if (_u < 0 || _u > 1.6) continue;
        var _run = min(3, 3 * kd_smooth(0, 0.18, _u));
        var _fd = 1 - clamp((_u - 1) / 0.6, 0, 1);
        kd_px(wx, wy, 1, floor(_run) + 1, C[3], _fd);
        if (!_dr.fell)
        {
            kd_px(wx, wy + _run + 1, 1, 1, C[2], 1);
            if (kd_smooth(0, 0.2, _u) > 0.6) { kd_px(wx + 1, wy + _run + 1, 1, 1, C[3], 1); kd_px(wx, wy + _run + 2, 1, 1, C[2], 1); }
        }
    }
    // flying drops
    for (var _i = 0; _i < array_length(drops); _i++)
    {
        var _d = drops[_i];
        if (_d.delay > 0) continue;
        var _sp = max(1, point_distance(0, 0, _d.vx, _d.vy));
        var _ux = _d.vx / _sp;
        var _uy = _d.vy / _sp;
        var _tail = min(6, _sp * 0.016);
        if (_tail >= 1) kd_seg(_d.x - _ux * _tail, _d.y - _uy * _tail, _d.x - _ux, _d.y - _uy, (_d.s >= 2) ? C[2] : C[3], 1, 1);
        if (_d.s == 3)
        {
            kd_disc(_d.x, _d.y, 1.7 * SZ * 1.4, C[4], 1);
            kd_disc(_d.x, _d.y, 1.15 * SZ * 1.4, C[1], 1);
            kd_px(_d.x - 0.7, _d.y - 0.7, 1, 1, C[0], 1);
        }
        else if (_d.s == 2)
        {
            kd_px(_d.x, _d.y, 1, 1, C[0], 1);
            kd_px(_d.x + 1, _d.y, 1, 1, C[1], 1);
            kd_px(_d.x, _d.y + 1, 1, 1, C[2], 1);
            kd_px(_d.x + 1, _d.y + 1, 1, 1, C[3], 1);
        }
        else kd_px(_d.x, _d.y, 1, 1, (_d.seed < 0.5) ? C[1] : C[2], 1);
    }
}

// ================================================================ FIRE (fire.ts)
/// flames all over a burning person; follows them and burns out after they stop burning
function kd_vfx_fire(_npc)
{
    var _v = kd_vfx("fire", _npc.x, _npc.y, _npc);
    with (_v)
    {
        depth   = _npc.depth - 3;
        var _pl = kd_pal();
        RAMP    = _pl.fire;
        HEAT    = [RAMP[0], RAMP[1], RAMP[2], RAMP[3], RAMP[4], RAMP[5], RAMP[6], RAMP[7],
                   merge_colour(RAMP[8], _pl.soot, 0.35), merge_colour(RAMP[8], _pl.soot, 0.65)];
        GLOW_C  = _pl.warmglow;
        SMOKE_C = merge_colour(_pl.smoke1, RAMP[6], 0.25);
        WIND    = 0;
        stop_at = 1000000;
        lv      = 0;
        fx      = x;
        fy      = y;
        vxs     = 0;
        vys     = 0;
        lean    = 0;
        stretch = 0;
        licks   = [];
        // flame tongues along the top of the body box (x-6..x+6, y-26..y) + 4 inside it
        tongues = [];
        for (var _j = 0; _j <= 12; _j += 2) array_push(tongues, [-6 + _j, 5 + 5 * kd_hash(_j, 2), 1.5 + 0.6 * kd_hash(_j, 3), -25]);
        for (var _k = 0; _k < 4; _k++) array_push(tongues, [floor(kd_hash(_k, 9) * 13) - 6, 4 + 3 * kd_hash(_k, 4), 1.3, -floor(kd_hash(_k, 11) * 24)]);
        // draw the outer tongues first
        order = [];
        for (var _i = 0; _i < array_length(tongues); _i++) array_push(order, _i);
        var _tg = tongues;
        array_sort(order, method({ tg : _tg }, function(_a, _b) { return abs(tg[_b][0]) - abs(tg[_a][0]); }));
    }
    return _v;
}
function kd_vfx_fire_flick(_t) { return 0.74 + 0.16 * kd_noise(_t * 7.3, 1) + 0.1 * kd_noise(_t * 19, 2); }
function kd_vfx_fire_height(_i)
{
    var _h = tongues[_i][1];
    var _n = 37 + _i;
    var _leap = max(0, kd_noise(t * 2.6 + _n * 3.1, _n + 70) - 0.55) * 1.6;
    return (_h + 0.25 * _h * kd_noise(t * 3.3 + _n * 1.7, _n) + _h * _leap) * (0.9 + 0.1 * kd_vfx_fire_flick(t)) * lv * (1 + stretch);
}

function kd_vfx_fire_step()
{
    var _dt = KD_DT;
    var _ax = fx;
    var _ay = fy;
    if (instance_exists(owner))
    {
        _ax = owner.x;
        _ay = owner.y;
        if (owner.burn <= 0 && stop_at > t) stop_at = t;
    }
    else if (stop_at > t) stop_at = t;
    lv = kd_smooth(0, 0.3, t) * clamp(1 - (t - stop_at) / 1.2, 0, 1);
    // flames lean away from the direction the person runs
    var _k  = 1 - exp(-_dt * 10);
    var _kl = 1 - exp(-_dt * 7);
    vxs += ((_ax - fx) / _dt - vxs) * _k;
    vys += ((_ay - fy) / _dt - vys) * _k;
    fx = _ax;
    fy = _ay;
    x = fx;
    y = fy;
    lean    += (clamp((-vxs + WIND) / 260, -1.3, 1.3) - lean) * _kl;
    stretch += (clamp(vys / 450, -0.3, 0.45) - stretch) * _kl;

    var _speed = point_distance(0, 0, vxs, vys);
    var _L = lv * 0.7;
    for (var _i = 0; _i < array_length(tongues); _i++)
    {
        if (_L <= 0.02) continue;
        var _h  = kd_vfx_fire_height(_i);
        var _tx = fx + tongues[_i][0] + lean * _h * 0.9;
        var _ty = fy + tongues[_i][3] - _h * 0.88 + 4;
        if (random(1) < 0.18 * _L)
        {
            var _p = kd_vfx_part(0, _tx + random_range(-1, 1), _ty + random(4), random_range(-4, 4), random_range(-30, -15), random_range(0.14, 0.3), -1, random_range(0.8, 1.6));
            _p.smokes = random(1) < 0.45;
        }
        if (random(1) < (0.075 + _speed / 1350) * _L)
            array_push(licks, { x : _tx, y : _ty, vx : random_range(-3, 3), vy : random_range(-20, -12), s : random_range(0.9, 1.7), life : 0.26, mx : 0.26 });
        if (random(1) < 0.024 * _L)
            kd_vfx_part(2, fx + tongues[_i][0] + random_range(-3, 3), fy - random_range(5, 12), random_range(-15, 15), random_range(-60, -25), random_range(0.9, 2.2), -1, 1);
        if (random(1) < 0.017 * _L)
            kd_vfx_part(1, _tx, _ty - 3, random_range(-2.5, 2.5), random_range(-17, -10), random_range(1.6, 2.6), SMOKE_C, random_range(1.6, 2.8));
    }
    for (var _i = array_length(licks) - 1; _i >= 0; _i--)
    {
        var _lk = licks[_i];
        _lk.life -= _dt;
        if (_lk.life <= 0) { array_delete(licks, _i, 1); continue; }
        _lk.x += _lk.vx * _dt + kd_noise(t * 8 + _i, 3) * 0.15;
        _lk.y += _lk.vy * _dt;
    }
    if (random(1) < 0.7 * lv)
        kd_vfx_part(0, fx + random_range(-6, 6), fy - random(26), random_range(-5, 5) - vxs * 0.1, random_range(-40, -20), random_range(0.16, 0.3), -1, random_range(1, 1.8));
    if (random(1) < 0.16 * lv)
        kd_vfx_part(1, fx - 6, fy - 30, random_range(-3, 3) - vxs * 0.15, random_range(-20, -10), random_range(1.2, 2), SMOKE_C, random_range(2, 3.2));

    for (var _i = array_length(P) - 1; _i >= 0; _i--)
    {
        var _p2 = P[_i];
        _p2.life -= _dt;
        if (_p2.life <= 0)
        {
            if (_p2.smokes) kd_vfx_part(1, _p2.x, _p2.y, _p2.vx * 0.6, _p2.vy * 0.6 - 6, random_range(0.8, 1.4), -1, _p2.size * 0.7);
            array_delete(P, _i, 1);
            continue;
        }
        switch (_p2.k)
        {
            case 0:     // flame blob
                _p2.vy -= 95 * _dt;
                _p2.vx += sin(t * 17 + _p2.seed) * 30 * _dt;
                _p2.vx -= _p2.vx * 5 * _dt;
                _p2.vy -= _p2.vy * 3.2 * _dt;
                break;
            case 1:     // smoke
                _p2.vy -= 16 * _dt;
                _p2.vx += sin(t * 1.3 + _p2.seed) * 8 * _dt;
                _p2.vx -= _p2.vx * 1.6 * _dt;
                _p2.vy -= _p2.vy * 1.2 * _dt;
                break;
            default:    // ember
                _p2.vy += (-30 + sin(t * 3 + _p2.seed) * 20) * _dt;
                _p2.vx += cos(t * 2.3 + _p2.seed) * 45 * _dt;
                _p2.vx -= _p2.vx * 1.6 * _dt;
                _p2.vy -= _p2.vy * 1.6 * _dt;
        }
        _p2.x += _p2.vx * _dt;
        _p2.y += _p2.vy * _dt;
    }
    if (t > stop_at + 1.2 && array_length(P) == 0) finished = true;
}

function kd_vfx_fire_tongue(_x, _y, _h, _w, _sx, _n)
{
    static layers = [[1, 1, 6], [0.76, 0.86, 4], [0.54, 0.68, 2], [0.3, 0.42, 0]];
    if (_h < 1) return;
    for (var _l = 0; _l < 4; _l++)
    {
        var _lw = layers[_l][0];
        var _lh = layers[_l][1];
        var _col = RAMP[layers[_l][2]];
        var _H = _h * _lh;
        for (var _r = 0; _r <= _H; _r++)
        {
            var _u = _r / max(1, _H);
            var _half = _w * _lw * power(1 - _u, 0.85) * min(1, (_r + 1.5) / 3.5) + kd_noise(t * 9 + _r * 0.45, _n) * 0.5;
            var _cx = _x + _sx * _u * _u * _lh + kd_noise(t * 4 + _r * 0.2, _n + 7) * _u * 1.1;
            if (_half < 0.3) continue;
            var _a = round(_cx - _half);
            kd_px(_a, round(_y - _r), round(_cx + _half) - _a + 1, 1, _col, 1);
        }
    }
}

function kd_vfx_fire_draw()
{
    // smoke behind the flames
    for (var _i = 0; _i < array_length(P); _i++) if (P[_i].k == 1) kd_vfx_smoke_draw(P[_i]);
    // glowing heat on the body
    if (lv > 0.05)
    {
        for (var _by = -26; _by < 0; _by++)
        for (var _bx = -6; _bx <= 6; _bx++)
        {
            var _h = kd_hash(_bx * 73 + _by * 151, 5);
            if (_h > 0.2) continue;
            var _T = clamp(0.4 + 0.6 * kd_noise(t * (5 + _h * 20), _bx * 7 + _by), 0, 1) * lv;
            if (_T > 0.45) kd_px(fx + _bx, fy + _by, 1, 1, HEAT[min(9, 2 + floor((1 - _T) * 7))], 1);
        }
    }
    // flame tongues
    for (var _o = 0; _o < array_length(order); _o++)
    {
        var _i = order[_o];
        var _tg = tongues[_i];
        var _h = kd_vfx_fire_height(_i);
        if (_h < 1) continue;
        var _m = 37 + _i;
        kd_vfx_fire_tongue(fx + _tg[0], fy + _tg[3] + 1, _h, _tg[2] * (1 - 0.25 * abs(lean)),
                           kd_noise(t * 2.2 + _m, _m + 40) * 2 + lean * _h * 0.9 - clamp(_tg[0] * 0.25, -2, 2), _m * 13);
    }
    // licks of flame breaking off
    for (var _i = 0; _i < array_length(licks); _i++)
    {
        var _lk = licks[_i];
        var _k = _lk.life / _lk.mx;
        var _r = _lk.s * (0.4 + 0.6 * _k);
        kd_disc(_lk.x, _lk.y, _r + 0.6, (_k > 0.5) ? RAMP[5] : RAMP[6], 1);
        if (_k > 0.35) kd_disc(_lk.x, _lk.y - 0.3, _r * 0.6, (_k > 0.7) ? RAMP[2] : RAMP[4], 1);
    }
    // flame blobs + embers
    for (var _i = 0; _i < array_length(P); _i++)
    {
        var _p = P[_i];
        if (_p.k == 1) continue;
        var _k = _p.life / _p.mx;
        var _age = 1 - _k;
        if (_p.k == 0)
        {
            var _heat = min(0.999, power(_age, 0.62) + kd_frac(_p.seed) * 0.1);
            var _idx = min(7, floor(_heat * 8));
            var _r = _p.size * (0.55 + 0.45 * min(1, _age * 7)) * (1 - _age * 0.55);
            var _c = RAMP[_idx];
            if (_idx >= 7) kd_disc(_p.x, _p.y, _r, _c, min(1, _k * 3) * 0.85);
            else
            {
                kd_disc(_p.x, _p.y, _r, RAMP[min(8, _idx + 2)], 1);
                kd_disc(_p.x - _r * 0.16, _p.y - _r * 0.22, _r * 0.78, _c, 1);
                if (_r > 1.6) kd_disc(_p.x, _p.y - _r * 0.9, _r * 0.42, _c, 1);
                if (_idx <= 3 && _r > 1.8) kd_disc(_p.x - _r * 0.28, _p.y - _r * 0.34, _r * 0.36, RAMP[max(0, _idx - 1)], 1);
                if (_idx < 6) kd_glow(_p.x, _p.y, _r * 2.4 + 2, _c, 0.18 * _k);
            }
        }
        else
        {
            var _ec = (_k > 0.5) ? ((sin(t * 22 + _p.seed * 3) > -0.2) ? RAMP[2] : RAMP[4]) : ((_k > 0.2) ? RAMP[4] : RAMP[6]);
            kd_px(_p.x, _p.y, 1, 1, _ec, 1);
            kd_glow(_p.x, _p.y, 3, _ec, 0.3 * _k);
        }
    }
    // firelight
    var _fl = kd_vfx_fire_flick(t);
    var _br = 0.92 + 0.08 * sin(t * 2.1);
    kd_glow(fx + lean * 4, fy - 16, 30 * _br, GLOW_C, 0.4 * _fl * lv);
    kd_glow(fx, fy - 14, 11, RAMP[2], 0.32 * _fl * lv);
}

// ================================================================ SHIELD (shield.ts)
/// hexagon dome around the player. While it is up, explosions can't hurt you; hits ripple across it.
function kd_vfx_shield(_pl)
{
    var _v = kd_vfx("shield", _pl.x, _pl.y, _pl);
    with (_v)
    {
        depth  = _pl.depth - 5;
        C      = kd_pal().ice;
        RAD    = 22;
        GONE   = 2.75;
        hits   = [];
        lights = [];
        SPARKS = [c_white, C[1], C[2]];
    }
    kd_sfx_p(snd_levelup, 1.6, 0.05, 0.45);
    return _v;
}
function kd_shield_up(_v)
{
    return instance_exists(_v) && _v.t < _v.GONE;
}
/// something hit the shield at (_hx, _hy): ripple + sparks there
function kd_shield_hit(_v, _hx, _hy)
{
    with (_v)
    {
        var _lat = arcsin(clamp((y - _hy) / RAD, 0, 1));
        var _lon = arcsin(clamp(((_hx - x) / RAD) / max(0.05, cos(_lat)), -1, 1));
        array_push(hits, { t : t, lon : _lon, lat : _lat, done : false });
    }
}
function kd_vfx_shield_surf(_lon, _lat)
{
    return [x + RAD * sin(_lon) * cos(_lat), y - RAD * sin(_lat)];
}
/// hex grid: returns [cell id, distance to the cell edge 0..1]
function kd_hex_cell(_gx, _gy)
{
    var _s3 = sqrt(3);
    var _q = (_s3 / 3) * _gx - _gy / 3;
    var _r = (2 / 3) * _gy;
    var _s = -_q - _r;
    var _rq = round(_q);
    var _rr = round(_r);
    var _rs = round(_s);
    var _dq = abs(_rq - _q);
    var _dr = abs(_rr - _r);
    var _ds = abs(_rs - _s);
    if (_dq > _dr && _dq > _ds) _rq = -_rr - _rs;
    else if (_dr > _ds) _rr = -_rq - _rs;
    var _hx = _s3 * (_rq + _rr / 2);
    var _hy = 1.5 * _rr;
    var _dx = abs(_gx - _hx);
    var _dy = _gy - _hy;
    var _e = max(_dx, abs(_dx / 2 + (_dy * _s3) / 2), abs(_dx / 2 - (_dy * _s3) / 2)) / (_s3 / 2);
    return [_rq * 7385 + _rr * 1934, _e];
}
function kd_vfx_shield_ripple(_lon, _lat)
{
    var _hit = 0;
    for (var _i = 0; _i < array_length(hits); _i++)
    {
        var _h = hits[_i];
        var _k = t - _h.t;
        if (_k < 0 || _k > 0.7 || !_h.done) continue;
        var _d = arccos(clamp(cos(_lat) * cos(_h.lat) * cos(_lon - _h.lon) + sin(_lat) * sin(_h.lat), -1, 1));
        var _front = _k * 3.2;
        if (abs(_d - _front) < 0.22) _hit = max(_hit, 1 - _k / 0.7);
        else if (_d < _front && _d < 0.5) _hit = max(_hit, 0.4 * (1 - _k / 0.7));
    }
    return _hit;
}

function kd_vfx_shield_step()
{
    var _dt = KD_DT;
    if (instance_exists(owner)) { x = owner.x; y = owner.y; }
    // sparkles while the dome builds up
    if (t < 0.75)
    {
        repeat (3)
        {
            var _p = kd_vfx_shield_surf(random_range(-pi / 2, pi / 2), min((t / 0.65) * (pi / 2), 1.5));
            kd_vfx_part(0, _p[0], _p[1], random_range(-10, 10), random_range(-15, 5), random_range(0.2, 0.4), SPARKS[irandom(2)], random_range(0.6, 1.2));
        }
    }
    // hits: flash, glint and sparks
    for (var _i = 0; _i < array_length(hits); _i++)
    {
        var _h = hits[_i];
        if (t >= _h.t && !_h.done)
        {
            _h.done = true;
            var _p2 = kd_vfx_shield_surf(_h.lon, _h.lat);
            global.kd_shake = max(global.kd_shake, 4);
            array_push(lights, { x : _p2[0], y : _p2[1], r : 40, col : C[2], k : 0.9, life : 0.18, mx : 0.18 });
            kd_vfx_part(2, _p2[0], _p2[1], 0, 0, 0.05, c_white, 1.8);
            var _out = arctan2(_p2[1] - (y - RAD * 0.4), _p2[0] - x);
            repeat (14)
            {
                var _a = _out + random_range(-0.7, 0.7);
                var _sp = random_range(100, 300);
                kd_vfx_part(3, _p2[0], _p2[1], cos(_a) * _sp, sin(_a) * _sp - 40, random_range(0.1, 0.35), -1, 1);
            }
            kd_sfx_p(snd_ricochet, 1.4, 0.1, 0.6);
        }
    }
    // the dome breaks up into motes when it ends
    if (t > GONE - 0.05 && t < GONE + 0.6)
    {
        repeat (4)
        {
            var _p3 = kd_vfx_shield_surf(random_range(-1.4, 1.4), random_range(0, 1.4));
            kd_vfx_part(choose(0, 1), _p3[0], _p3[1], random_range(-15, 15), -random_range(10, 40), random_range(0.3, 0.7), SPARKS[irandom(2)], random_range(0.6, 1.4));
        }
    }
    for (var _i = array_length(P) - 1; _i >= 0; _i--)
    {
        var _q = P[_i];
        _q.life -= _dt;
        if (_q.life <= 0) { array_delete(P, _i, 1); continue; }
        switch (_q.k)
        {
            case 0:  _q.vx -= _q.vx * 1.6 * _dt; _q.vy -= _q.vy * 1.6 * _dt + 5 * _dt; _q.x += _q.vx * _dt; _q.y += _q.vy * _dt; break;
            case 1:  _q.vx -= _q.vx * 0.6 * _dt; _q.vy -= _q.vy * 0.6 * _dt; _q.x += _q.vx * _dt; _q.y += _q.vy * _dt; break;
            case 2:  break;
            case 3:
                _q.vy += 950 * 0.45 * _dt;
                _q.vx -= _q.vx * 2.2 * _dt;
                _q.vy -= _q.vy * 2.2 * _dt;
                var _ny = _q.y + _q.vy * _dt;
                _q.x += _q.vx * _dt;
                if (_q.vy > 0 && _q.y <= y && _ny >= y) { _q.vy = -_q.vy * 0.45; _q.vx *= 0.7; _q.y = y - 0.5; } else _q.y = _ny;
                break;
        }
    }
    for (var _i = array_length(lights) - 1; _i >= 0; _i--)
    {
        lights[_i].life -= _dt;
        if (lights[_i].life <= 0) array_delete(lights, _i, 1);
    }
    if (t > GONE + 0.6 && array_length(P) == 0) finished = true;
}

function kd_vfx_shield_draw()
{
    var _cx = x;
    var _cy = y;
    var _grid = 6.2;
    var _white = c_white;
    for (var _yy = floor(_cy - RAD - 1); _yy <= _cy; _yy++)
    for (var _xx = floor(_cx - RAD - 1); _xx <= ceil(_cx + RAD + 1); _xx++)
    {
        var _u = (_xx + 0.5 - _cx) / RAD;
        var _v = (_cy - _yy - 0.5) / RAD;
        var _q = _u * _u + _v * _v;
        if (_q > 1 || _v < 0) continue;
        var _z = sqrt(1 - _q);
        var _lon = arctan2(_u, _z);
        var _lat = arcsin(clamp(_v, 0, 1));
        var _cell = kd_hex_cell(_lon * _grid, _lat * _grid * 1.15);
        var _e = _cell[1];
        var _h = kd_hash(_cell[0], 17);
        var _appear = 0.05 + (_lat / (pi / 2)) * 0.6 + _h * 0.08;
        var _gone = GONE + _h * 0.55;
        if (t < _appear || t > _gone) continue;
        var _age = t - _appear;
        var _end = _gone - t;
        var _rim = 1 - abs(_z);
        var _hit = (array_length(hits) > 0) ? kd_vfx_shield_ripple(_lon, _lat) : 0;
        var _flash = (_age < 0.1 || _end < 0.08);
        var _sweep = abs(kd_frac(_lon * 0.35 + _lat * 0.45 - t * 0.55) - 0.5) < 0.04;
        var _b = kd_bayer(_xx, _yy);
        if (_e > 0.8)
        {
            // hexagon edges
            var _c = C[3];
            if (_flash || _hit > 0.6) _c = _white;
            else if (_hit > 0.2 || _sweep || _rim > 0.75) _c = C[1];
            else if (_rim > 0.4) _c = C[2];
            if (_flash || _hit > 0.2 || _sweep || 0.5 + _rim > _b) kd_px(_xx, _yy, 1, 1, _c, 1);
        }
        else
        {
            // faint dithered fill, brighter at the rim
            var _a = (_flash ? 0.7 : 0.08 + 0.3 * _rim * _rim) + _hit * 0.6;
            if (_a > _b) kd_px(_xx, _yy, 1, 1, (_flash || _hit > 0.5) ? C[1] : ((_rim > 0.7) ? C[3] : C[4]), 1);
        }
    }
    var _al = kd_smooth(0, 0.15, t) * (1 - kd_smooth(GONE - 0.05, GONE + 0.45, t));
    if (_al > 0)
    {
        draw_set_colour(C[2]);
        draw_set_alpha(_al);
        draw_ellipse(_cx - RAD, _cy - 3, _cx + RAD, _cy + 3, true);
        draw_set_alpha(1);
        kd_glow(_cx, _cy - RAD * 0.5, RAD * 1.3, C[3], 0.22 * _al);
    }
    // particles
    for (var _i = 0; _i < array_length(P); _i++)
    {
        var _p = P[_i];
        var _k = _p.life / _p.mx;
        switch (_p.k)
        {
            case 0:
                kd_vfx_star_draw(floor(_p.x), floor(_p.y), _p.size, _p.col, _k, 0.6 + 0.4 * sin(t * (8 + (_p.seed mod 5)) + _p.seed));
                break;
            case 1:
                var _sp = max(1, point_distance(0, 0, _p.vx, _p.vy));
                var _len = min(8, 0.25 + _sp * 0.013) * _p.size;
                kd_seg(_p.x - _p.vx / _sp * _len, _p.y - _p.vy / _sp * _len, _p.x - _p.vx / _sp * _len * 0.35, _p.y - _p.vy / _sp * _len * 0.35, kd_scale_col(_p.col, 0.55), _k, 1);
                kd_seg(_p.x - _p.vx / _sp * _len * 0.4, _p.y - _p.vy / _sp * _len * 0.4, _p.x, _p.y, _p.col, _k, 1);
                kd_glow(_p.x, _p.y, 2.5 + _p.size, _p.col, 0.4 * _k);
                break;
            case 2:
                var _r = _p.size * (0.5 + _k * 0.5);
                kd_disc(_p.x, _p.y, _r + 0.8, kd_pal().deep_orange, 1);
                kd_disc(_p.x, _p.y, _r, kd_pal().hot, 1);
                kd_glow(_p.x, _p.y, _p.size * 4, c_white, 0.6 * _k);
                break;
            case 3:
                var _sp2 = max(1, point_distance(0, 0, _p.vx, _p.vy));
                var _c2 = (_k > 0.6) ? kd_pal().hot : ((_k > 0.3) ? C[1] : C[2]);
                kd_seg(_p.x - _p.vx / _sp2 * 2, _p.y - _p.vy / _sp2 * 2, _p.x, _p.y, _c2, 1, 1);
                break;
        }
    }
    for (var _i = 0; _i < array_length(lights); _i++)
    {
        var _l = lights[_i];
        kd_glow(_l.x, _l.y, _l.r * 0.5, _l.col, _l.k * (_l.life / _l.mx));
    }
    draw_set_colour(c_white);
}

// ================================================================ POWER-UP (power-up.ts)
/// charge-in motes, a burst, then a flickering blue aura and rising streaks for ~2 seconds
function kd_vfx_powerup(_who)
{
    var _v = kd_vfx("powerup", _who.x, _who.y, _who);
    with (_v)
    {
        depth  = _who.depth - 4;
        C      = kd_pal().power;
        TOP    = [C[0], C[1], C[2]];
        burst  = false;
        T_BURST = 0.32;
        T_HOLD  = 1.75;
        T_FADE  = 2.35;
        T_END   = 2.95;
        mid_y  = y - 13;
    }
    // the aura sits behind the character: a second instance draws it
    var _b = kd_vfx("powerup_back", _who.x, _who.y, _who);
    _b.depth = _who.depth + 2;
    _b.main  = _v;
    kd_sfx_p(snd_levelup, 1.25, 0.03, 0.6);
    return _v;
}
function kd_vfx_powerup_aura()
{
    return kd_smooth(T_BURST - 0.04, T_BURST + 0.12, t) * (1 - kd_smooth(T_HOLD, T_FADE, t)) * (0.85 + 0.15 * sin(t * 13));
}
function kd_vfx_powerup_flare()
{
    var _p1 = T_BURST + 0.55;
    var _p2 = T_BURST + 1.0;
    return max(exp(-sqr((t - _p1) / 0.07)), exp(-sqr((t - _p2) / 0.07))) + exp(-sqr((t - T_BURST) / 0.08));
}
function kd_vfx_powerup_onbody()
{
    return [x + random_range(-5, 5), y - random_range(2, 30)];
}
function kd_vfx_powerup_step()
{
    var _dt = KD_DT;
    if (instance_exists(owner)) { x = owner.x; y = owner.y; }
    mid_y = y - 13;
    if (t < T_BURST)
    {
        // energy pulled in
        repeat (3)
        {
            var _a = random(2 * pi);
            var _r = random_range(17, 32);
            var _sp = random_range(130, 210);
            var _m = kd_vfx_part(0, x + cos(_a) * _r, mid_y + sin(_a) * _r * 0.8, -cos(_a) * _sp, -sin(_a) * _sp * 0.8, _r / _sp, (random(1) < 0.3) ? C[1] : C[2], 1);
        }
    }
    if (!burst && t >= T_BURST)
    {
        burst = true;
        global.kd_shake = max(global.kd_shake, 5);
        global.kd_flash = max(global.kd_flash, 0.22);
        repeat (18)
        {
            var _side = choose(-1, 1);
            var _d = kd_vfx_part(1, x + _side * random_range(1, 5), y - random(2), _side * random_range(30, 85), -random_range(1, 8), random_range(0.45, 0.8), merge_colour(kd_pal().dust, C[4], 0.25), random_range(1.5, 3));
            _d.front = false;
            _d.mx = 0.8;
        }
        repeat (22)
        {
            var _ob = kd_vfx_powerup_onbody();
            var _s = kd_vfx_part(3, _ob[0], _ob[1], random_range(-20, 20), -random_range(15, 55), random_range(0.6, 1.3), TOP[irandom(2)], (random(1) < 0.35) ? 2 : ((random(1) < 0.5) ? 1 : 0));
            _s.front = random(1) < 0.6;
            _s.mx = 1.3;
        }
    }
    var _au = kd_vfx_powerup_aura();
    if (burst && _au > 0.05)
    {
        var _fl = kd_vfx_powerup_flare();
        for (var _n = 0; _n < (5 + 5 * _fl) * _au * _dt * 10; _n++)
        {
            var _ob2 = kd_vfx_powerup_onbody();
            var _side2 = choose(-1, 1);
            var _st = kd_vfx_part(2, _ob2[0] + _side2 * random_range(2.5, 8), mid_y + random_range(-8, 13), 0, -random_range(110, 210), random_range(0.14, 0.3), (random(1) < 0.5) ? C[2] : C[1], random_range(4, 10));
            _st.front = random(1) < 0.5;
            _st.mx = 0.3;
        }
        for (var _n = 0; _n < 9 * _au * _dt; _n++)
        {
            var _ob3 = kd_vfx_powerup_onbody();
            var _up = clamp((mid_y - _ob3[1]) / 16, 0, 1);
            if (random(1) < 1 - _up * 0.8) continue;
            var _w = kd_vfx_part(4, _ob3[0] + random_range(-2, 2), _ob3[1] - random_range(3, 6), random_range(-7, 7), -random_range(35, 65), random_range(0.3, 0.55), C[2], random_range(1, 1.7));
            _w.front = false;
            _w.mx = 0.55;
        }
        if (random(1) < 0.5 * _au)
        {
            var _ob4 = kd_vfx_powerup_onbody();
            var _s2 = kd_vfx_part(3, _ob4[0] + random_range(-4, 4), _ob4[1], random_range(-5, 5), -random_range(12, 35), random_range(0.6, 1.1), TOP[irandom(2)], (random(1) < 0.25) ? 1 : 0);
            _s2.front = random(1) < 0.5;
            _s2.mx = 1.1;
        }
    }
    for (var _i = array_length(P) - 1; _i >= 0; _i--)
    {
        var _m2 = P[_i];
        _m2.life -= _dt;
        if (_m2.life <= 0) { array_delete(P, _i, 1); continue; }
        var _drag = (_m2.k == 1) ? 3.5 : ((_m2.k == 3) ? 1.4 : 0);
        _m2.vx -= _m2.vx * _drag * _dt;
        _m2.vy -= _m2.vy * _drag * _dt;
        if (_m2.k == 3) _m2.vy -= 9 * _dt;
        _m2.x += _m2.vx * _dt;
        _m2.y += _m2.vy * _dt;
    }
    if (t > T_END && array_length(P) == 0) finished = true;
}

function kd_vfx_powerup_mote(_m)
{
    var _k = _m.life / _m.mx;
    switch (_m.k)
    {
        case 0:     // pulled-in energy
            var _sp = max(1, point_distance(0, 0, _m.vx, _m.vy));
            var _ux = _m.vx / _sp;
            var _uy = _m.vy / _sp;
            kd_seg(_m.x - _ux * 7, _m.y - _uy * 7, _m.x - _ux * 3, _m.y - _uy * 3, _m.col, 1, 1);
            kd_seg(_m.x - _ux * 2.5, _m.y - _uy * 2.5, _m.x, _m.y, c_white, 1, 1);
            break;
        case 2:     // rising streak
            var _l = _m.size * (0.5 + 0.5 * _k);
            kd_px(_m.x, _m.y, 1, 2, c_white, 1);
            kd_px(_m.x, _m.y + 1.5, 1, max(1, _l * 0.5), _m.col, 1);
            kd_px(_m.x, _m.y + 1.5 + _l * 0.5, 1, max(1, _l * 0.5), _m.col, 0.6);
            kd_glow(_m.x, _m.y + _l * 0.3, 4, _m.col, 0.3 * _k);
            break;
        case 4:     // wisp
            var _r = _m.size * (0.35 + 0.65 * _k);
            kd_disc(_m.x, _m.y, _r + 0.7, (_k > 0.5) ? _m.col : kd_scale_col(_m.col, 0.7), 1);
            if (_k > 0.35) kd_disc(_m.x - 0.3, _m.y - 0.4, _r * 0.55, (_k > 0.7) ? c_white : _m.col, 1);
            kd_glow(_m.x, _m.y, 5 + _r * 2, _m.col, 0.3 * _k);
            break;
        case 3:     // star
            var _tw = 0.6 + 0.4 * sin(_m.life * 26 + _m.x);
            if (_tw * _k < 0.2) break;
            kd_vfx_star_draw(floor(_m.x), floor(_m.y), max(1, _m.size), _m.col, _k, _tw);
            break;
    }
}

/// behind the character: dust, the flickering aura and back motes
function kd_vfx_powerup_back_draw()
{
    if (!instance_exists(main)) return;
    with (main)
    {
        for (var _i = 0; _i < array_length(P); _i++)
        {
            var _m = P[_i];
            if (_m.k == 1) kd_disc(_m.x, _m.y, _m.size * (1.6 - (_m.life / _m.mx) * 0.6), _m.col, (_m.life / _m.mx) * 0.6);
        }
        var _au = kd_vfx_powerup_aura();
        var _fl = kd_vfx_powerup_flare();
        if (_au > 0.02 && instance_exists(owner) && variable_instance_exists(owner, "look"))
        {
            // the aura: the character's own shape, blown up and tinted, flickering like flame
            var _st = "idle";
            var _fr = 0;
            if (variable_instance_exists(owner, "state")) { _st = owner.state; _fr = owner.anim_frame; }
            var _fc = owner.facing;
            var _n1 = 0.5 + 0.5 * kd_noise(t * 9, 3);
            var _n2 = 0.5 + 0.5 * kd_noise(t * 11, 8);
            gpu_set_fog(true, C[4], 0, 1);
            kd_draw(x, y + 1, _fc, _st, _fr, owner.look, 1.32 + 0.08 * _n1 + 0.1 * _fl, c_white, 0.35 * _au, false, KD_ARM_NONE);
            gpu_set_fog(true, C[3], 0, 1);
            kd_draw(x, y + 0.5, _fc, _st, _fr, owner.look, 1.18 + 0.06 * _n2 + 0.06 * _fl, c_white, 0.55 * _au, false, KD_ARM_NONE);
            gpu_set_fog(true, C[1], 0, 1);
            kd_draw(x, y, _fc, _st, _fr, owner.look, 1.07, c_white, 0.7 * _au, false, KD_ARM_NONE);
            gpu_set_fog(false, c_white, 0, 0);
        }
        for (var _i = 0; _i < array_length(P); _i++) if (!P[_i].front && P[_i].k != 1) kd_vfx_powerup_mote(P[_i]);
        kd_glow(x, mid_y, 17 + 10 * _fl, C[3], 0.35 * _au + 0.3 * _fl);
        kd_glow(x, y - 1, 15, C[2], 0.25 * _au);
    }
}

/// in front: the burst ring at the feet, body flashes on each pulse, front motes
function kd_vfx_powerup_draw()
{
    if (burst)
    {
        var _k = (t - T_BURST) / 0.45;
        if (_k >= 0 && _k < 1)
        {
            var _rx = 4 + 30 * (1 - power(2, -10 * _k));
            draw_set_alpha(1 - _k);
            draw_set_colour(C[1]);
            draw_ellipse(x - _rx, y - _rx * 0.22, x + _rx, y + _rx * 0.22, true);
            draw_set_colour(C[3]);
            draw_ellipse(x - _rx * 0.8, y - _rx * 0.18, x + _rx * 0.8, y + _rx * 0.18, true);
            draw_set_alpha(1);
        }
        var _e = max(exp(-sqr((t - T_BURST) / 0.07)), exp(-sqr((t - T_BURST - 0.55) / 0.07)), exp(-sqr((t - T_BURST - 1.0) / 0.07)));
        if (_e > 0.03 && instance_exists(owner) && variable_instance_exists(owner, "look"))
        {
            var _st = "idle";
            var _fr = 0;
            if (variable_instance_exists(owner, "state")) { _st = owner.state; _fr = owner.anim_frame; }
            gpu_set_fog(true, (_e > 0.75) ? C[0] : C[1], 0, 1);
            kd_draw(x, y, owner.facing, _st, _fr, owner.look, 1, c_white, min(1, _e * 0.9), false, KD_ARM_NONE);
            gpu_set_fog(false, c_white, 0, 0);
            kd_glow(x, y - 13, 26, C[3], 0.45 * _e);
        }
    }
    for (var _i = 0; _i < array_length(P); _i++) if (P[_i].front && P[_i].k != 1) kd_vfx_powerup_mote(P[_i]);
    draw_set_colour(c_white);
}

// ================================================================ HEAL (heal.ts)
/// green light column, rising crosses and sparkles, a glowing ring on the floor
function kd_vfx_heal(_who)
{
    var _v = kd_vfx("heal", _who.x, _who.y, _who);
    with (_v)
    {
        depth = _who.depth - 4;
        L = kd_pal().heal;
        glyphs = [];
        for (var _i = 0; _i < 18; _i++)
        {
            var _life = random_range(1, 1.4);
            array_push(glyphs, { x : x + random_range(-23, 23), y : y - random_range(2, 35), vy : -random_range(25, 45),
                                 life : _life, mx : _life, delay : 0.06 + _i * 0.085 + random(0.05),
                                 s : (random(1) < 0.45) ? 1 : 0, seed : random(1000) });
        }
    }
    kd_sfx_p(snd_exp, 1.3, 0.03, 0.7);
    return _v;
}
function kd_vfx_heal_fade(_t) { return 1 - kd_smooth(1.9, 2.7, _t); }

function kd_vfx_heal_step()
{
    var _dt = KD_DT;
    var _ox = x;
    if (instance_exists(owner)) { x = owner.x; y = owner.y; }
    for (var _i = array_length(glyphs) - 1; _i >= 0; _i--)
    {
        var _b = glyphs[_i];
        _b.x += x - _ox;                      // crosses travel with the person
        if (_b.delay > 0) { _b.delay -= _dt; continue; }
        _b.life -= _dt;
        if (_b.life <= 0) { array_delete(glyphs, _i, 1); continue; }
        _b.y += _b.vy * _dt;
        _b.x += sin((_b.mx - _b.life) * 4.5 + _b.seed) * 8 * _dt;
    }
    if (t < 2 && random(1) < 0.45)
        kd_vfx_part(0, x + random_range(-17, 17), y - random(38), random_range(-4, 4), -random_range(15, 40), random_range(0.5, 0.95),
                    (random(1) < 0.5) ? L[1] : L[2], (random(1) < 0.3) ? random_range(1.6, 2.6) : random_range(0.4, 0.9));
    for (var _i = array_length(P) - 1; _i >= 0; _i--)
    {
        var _p = P[_i];
        _p.life -= _dt;
        if (_p.life <= 0) { array_delete(P, _i, 1); continue; }
        _p.vx -= _p.vx * 1.6 * _dt;
        _p.vy -= _p.vy * 1.6 * _dt + 5 * _dt;
        _p.x += _p.vx * _dt;
        _p.y += _p.vy * _dt;
    }
    if (t > 2.8 && array_length(P) == 0) finished = true;
}

function kd_vfx_heal_cross(_x, _y, _L, _w, _a, _glint)
{
    var _px = round(_x);
    var _py = round(_y);
    var _o = kd_pal().outline;
    kd_px(_px - _w - 1, _py - _L - 1, 2 * _w + 3, 2 * _L + 3, _o, _a);
    kd_px(_px - _L - 1, _py - _w - 1, 2 * _L + 3, 2 * _w + 3, _o, _a);
    kd_px(_px - _w, _py - _L, 2 * _w + 1, 2 * _L + 1, L[2], _a);
    kd_px(_px - _L, _py - _w, 2 * _L + 1, 2 * _w + 1, L[2], _a);
    kd_px(_px - _w, _py - _L, 2 * _w + 1, 1, L[1], _a);          // lit top / left
    kd_px(_px - _L, _py - _w, 1, 2 * _w + 1, L[1], _a);
    kd_px(_px - _w, _py + _L, 2 * _w + 1, 1, L[4], _a);          // shaded bottom / right
    kd_px(_px + _L, _py - _w, 1, 2 * _w + 1, L[4], _a);
    if (_glint) kd_px(_px, _py, 1, 1, c_white, _a);
}

function kd_vfx_heal_draw()
{
    var _fd = kd_vfx_heal_fade(t);
    var _k = _fd * kd_smooth(0, 0.2, t);
    // column of light + rising rays
    for (var _h = 0; _h < 39; _h += 3) kd_glow(x, y - _h, 11, L[3], 0.13 * _k * (1 - _h / 45));
    for (var _i = 0; _i < 22; _i++)
    {
        var _ph = kd_frac(t * (1.1 + kd_hash(_i, 3) * 0.8) + kd_hash(_i, 1));
        var _sx = x + (kd_hash(_i, 2) - 0.5) * 17 * (1 - _ph * 0.3);
        var _sy = y - 1 - _ph * 37;
        var _a = sin(_ph * pi) * _k;
        kd_px(_sx, _sy, 1, 1, L[1], _a);
        kd_px(_sx, _sy + 1, 1, 2, L[2], _a * 0.8);
        kd_px(_sx, _sy + 3, 1, 2, L[4], _a * 0.45);
    }
    // ring of light on the floor
    var _w = 9.75 * (1 - power(1 - clamp(t / 0.45, 0, 1), 3));
    for (var _dx = -ceil(_w); _dx <= _w; _dx++)
    {
        var _u = abs(_dx) / max(1, _w);
        var _a2 = _fd * sqrt(1 - min(1, _u)) * 1.04;
        kd_px(x + _dx, y - 1, 1, 1, (_u < 0.3) ? L[1] : ((_u < 0.65) ? L[2] : L[3]), _a2);
        if (_u < 0.75) kd_px(x + _dx, y - 2, 1, 1, (_u < 0.35) ? L[2] : L[3], _a2 * 0.35);
        if ((_dx mod 5) == 0) kd_glow(x + _dx, y - 1, 5, L[3], 0.22 * _fd * (1 - _u));
    }
    for (var _i = 0; _i < 8; _i++)
    {
        var _ph2 = kd_frac(t * (0.9 + kd_hash(_i, 1) * 0.6) + kd_hash(_i, 2));
        var _mx = x + (kd_hash(_i, 3) - 0.5) * 2 * _w;
        var _a3 = sin(_ph2 * pi) * _fd;
        kd_px(_mx, y - 2 - _ph2 * 11, 1, 1, (_ph2 < 0.25) ? c_white : L[1], _a3);
    }
    // light bands sweeping up the body
    var _sweeps = [0.1, 0.65, 1.2];
    for (var _i = 0; _i < 3; _i++)
    {
        var _q = (t - _sweeps[_i]) / 0.4;
        if (_q < 0 || _q > 1.3) continue;
        var _yb = y + 1 - _q * 32;
        kd_px(x - 5, _yb, 11, 1, c_white, _k * 0.9);
        kd_px(x - 6, _yb + 1, 13, 3, L[1], _k * 0.45);
        kd_px(x - 6, _yb + 4, 13, 4, L[2], _k * 0.25);
        kd_glow(x, _yb, 9, L[2], 0.5 * _k * (1 - _q / 1.3));
    }
    // crosses
    for (var _i = 0; _i < array_length(glyphs); _i++)
    {
        var _b = glyphs[_i];
        if (_b.delay > 0) continue;
        var _age = _b.mx - _b.life;
        var _kk = _b.life / _b.mx;
        var _glint = sin(_age * 14 + _b.seed) > 0.75;
        var _big = _b.s ? 3 : 2;
        var _Lc = (_age < 0.05) ? _big - 1 : ((_age < 0.1) ? _big + 1 : _big);
        kd_vfx_heal_cross(_b.x, _b.y, _Lc, _b.s, (_kk < 0.4) ? _kk / 0.4 : 1, _glint);
        kd_glow(_b.x, _b.y, 5 + _b.s * 1.5, L[2], 0.4 * min(1, _kk * 2));
    }
    // sparkles
    for (var _i = 0; _i < array_length(P); _i++)
    {
        var _p = P[_i];
        kd_vfx_star_draw(floor(_p.x), floor(_p.y), _p.size, _p.col, _p.life / _p.mx, 0.6 + 0.4 * sin(t * (8 + (_p.seed mod 5)) + _p.seed));
    }
    draw_set_colour(c_white);
}

// ================================================================ FOG (fog.ts)
/// fog banks (pre-baked from fog.ts into spr_fog_0..2) that drift across the bottom of a room
function kd_fog_bank(_bottom)
{
    var _spr = [spr_fog_0, spr_fog_1, spr_fog_2];
    var _top = [-40, -28, -16];          // where each strip starts above the bottom
    var _spd = [13.75, 22, 26.4];        // drift speed, pixels per second (near layers drift slower)
    var _dep = [-30, -30, 60];           // two layers in front of people, the far one behind
    var _alp = [0.6, 0.75, 1];
    for (var _i = 0; _i < 3; _i++)
    {
        var _f = instance_create_depth(0, 0, _dep[_i], obj_kd_fog);
        _f.spr     = _spr[_i];
        _f.top_off = _top[_i];
        _f.spd     = _spd[_i];
        _f.area_y  = _bottom;
        _f.layer_i = _i;
        _f.alpha_mul = _alp[_i];
    }
}

/// called at Room Start: ambient effects for the room
function kd_room_fx_setup()
{
    if (room == rm_rooftop) kd_fog_bank(153);    // night fog rolling over the roof
    if (room == rm_main)    kd_fog_bank(360);    // fog in the basement
}
