/// <KD/> lab map - a little terminal window that shows the whole room as a green blueprint.
/// M cycles: corner map -> big map -> minimised (a small tab).
///
/// kd_minimap_draw(x2, y2, max_w, max_h, big)
///   small: the map's bottom-right corner sits at (x2, y2)
///   big  : centred on the screen (x2 / y2 are ignored)
/// returns the top edge of the window (so the weapon bar can sit above it)

/// named areas of each room, in room pixels: [label, x1, y1, x2, y2]
function kd_minimap_zones()
{
    if (room == rm_main)
    {
        return [
            ["OFFICE",       0, 150, 498, 246],
            ["CONTROL ROOM", 523, 60, 721, 170],
            ["BASEMENT",     0, 257, 721, 357]
        ];
    }
    if (room == rm_range)   return [["TRAINING RANGE", 0, 20, 480, 150]];
    if (room == rm_showcase) return [["SHOWCASE HALL", 4, 20, 1069, 332]];
    if (room == rm_lobby)   return [["KD LOBBY", 4, 20, 759, 308]];
    if (room == rm_dungeon) return [["NEON DUNGEON", 8, 8, 472, 208]];
    if (room == rm_kl)      return [["JALAN BUKIT BINTANG", 8, 60, 470, 208], ["LRT TERRACE", 480, 90, 660, 120], ["KD LAB HQ", 700, 40, 940, 208]];
    if (room == rm_rooftop) return [["ROOFTOP", 0, 60, 480, 150]];
    return [["CHARACTER LAB", 0, 20, 320, 150]];
}

function kd_minimap_draw(_x2, _y2, _maxw, _maxh, _big)
{
    var _green  = make_colour_rgb(64, 226, 110);
    var _dim    = make_colour_rgb(28, 92, 58);
    var _bg     = make_colour_rgb(8, 17, 14);
    var _grey   = make_colour_rgb(150, 160, 170);
    var _gold   = make_colour_rgb(214, 170, 80);
    var _orange = make_colour_rgb(255, 138, 42);
    var _blue   = make_colour_rgb(150, 200, 255);

    var _sc  = min(_maxw / room_width, _maxh / room_height);
    var _w   = room_width * _sc;
    var _h   = room_height * _sc;
    var _pad = 8;
    var _bar = 24;
    var _foot = 0;
    if (_big) _foot = 26;
    var _x1 = _x2 - _w;
    var _y1 = _y2 - _h;
    if (_big)
    {
        _x1 = 640 - _w / 2;
        _y1 = 360 - _h / 2 + (_bar - _foot) / 2;
        _x2 = _x1 + _w;
        _y2 = _y1 + _h;
        draw_set_alpha(0.45);
        draw_set_colour(c_black);
        draw_rectangle(0, 0, 1280, 720, false);
    }
    var _txs = 0.75;            // text scale
    if (_big) _txs = 1;
    var _top = _y1 - _pad - _bar;

    // ---------- window ----------
    draw_set_alpha(0.92);
    draw_set_colour(_bg);
    draw_roundrect_ext(_x1 - _pad, _top, _x2 + _pad, _y2 + _pad + _foot, 10, 10, false);
    draw_set_alpha(1);
    draw_set_colour(_green);
    draw_roundrect_ext(_x1 - _pad, _top, _x2 + _pad, _y2 + _pad + _foot, 10, 10, true);
    // title bar: traffic lights + file name + your grid position
    var _ty = _top + _bar / 2 + 2;
    draw_set_colour(make_colour_rgb(235, 64, 80));  draw_circle(_x1 + 2, _ty, 3, false);
    draw_set_colour(make_colour_rgb(255, 196, 60)); draw_circle(_x1 + 11, _ty, 3, false);
    draw_set_colour(_green);                        draw_circle(_x1 + 20, _ty, 3, false);
    var _file = "char_lab.map";
    if (room == rm_main)    _file = "kd_lab.map";
    if (room == rm_range)   _file = "range.map";
    if (room == rm_rooftop) _file = "rooftop.map";
    if (room == rm_kl)      _file = "kuala_lumpur.map";
    if (room == rm_dungeon) _file = "neon_dungeon.map";
    if (room == rm_showcase) _file = "showcase.map";
    if (room == rm_lobby)   _file = "lobby.map";
    draw_set_valign(fa_middle);
    draw_set_colour(_green);
    draw_text_transformed(_x1 + 30, _ty, "<KD/> " + _file, _txs, _txs, 0);
    if (instance_exists(obj_player))
    {
        var _gx = floor(obj_player.x / 16);
        var _gy = floor(obj_player.y / 16);
        draw_set_halign(fa_right);
        draw_set_colour(_grey);
        draw_text_transformed(_x2, _ty, "[" + string(_gx) + "," + string(_gy) + "]  M", _txs * 0.9, _txs * 0.9, 0);
        draw_set_halign(fa_left);
    }
    draw_set_valign(fa_top);
    draw_set_colour(_dim);
    draw_line(_x1 - _pad, _top + _bar, _x2 + _pad, _top + _bar);

    // ---------- blueprint grid ----------
    draw_set_colour(_dim);
    draw_set_alpha(0.35);
    for (var _gxl = 0; _gxl <= room_width; _gxl += 32) draw_line(_x1 + _gxl * _sc, _y1, _x1 + _gxl * _sc, _y2);
    for (var _gyl = 0; _gyl <= room_height; _gyl += 32) draw_line(_x1, _y1 + _gyl * _sc, _x2, _y1 + _gyl * _sc);
    draw_set_alpha(1);

    // ---------- zone labels ----------
    var _zones = kd_minimap_zones();
    for (var _z = 0; _z < array_length(_zones); _z++)
    {
        var _zn = _zones[_z];
        draw_set_colour(_dim);
        draw_set_alpha(0.25);
        draw_rectangle(_x1 + _zn[1] * _sc, _y1 + _zn[2] * _sc, _x1 + _zn[3] * _sc, _y1 + _zn[4] * _sc, false);
        draw_set_alpha(0.9);
        draw_set_colour(make_colour_rgb(90, 170, 120));
        draw_text_transformed(_x1 + _zn[1] * _sc + 4, _y1 + _zn[2] * _sc + 2, _zn[0], _txs * 0.7, _txs * 0.7, 0);
    }
    draw_set_alpha(1);

    // ---------- floors + walls: dim fill with a bright top edge ----------
    var _lw = 1;
    if (_big) _lw = 2;
    with (obj_solid)
    {
        var _l = _x1 + bbox_left * _sc;
        var _t = _y1 + bbox_top * _sc;
        var _r = _x1 + (bbox_right + 1) * _sc;
        var _b = _y1 + (bbox_bottom + 1) * _sc;
        draw_set_colour(_dim);
        draw_set_alpha(0.8);
        draw_rectangle(_l, _t, _r, _b, false);
        draw_set_alpha(1);
        draw_set_colour(_green);
        draw_line_width(_l, _t, _r, _t, _lw);
    }

    // ---------- ladders (dashed) + stairs ----------
    draw_set_colour(_gold);
    with (obj_ladder)
    {
        var _lx  = _x1 + ((bbox_left + bbox_right + 1) / 2) * _sc;
        var _la  = _y1 + bbox_top * _sc;
        var _lb  = _y1 + (bbox_bottom + 1) * _sc;
        var _dash = 4;
        if (_big) _dash = 8;
        for (var _ly = _la; _ly < _lb; _ly += _dash * 2) draw_line_width(_lx, _ly, _lx, min(_ly + _dash, _lb), _lw + 1);
    }
    with (obj_stairs)
    {
        draw_line_width(_x1 + bbox_left * _sc, _y1 + (bbox_bottom + 1) * _sc, _x1 + (bbox_right + 1) * _sc, _y1 + bbox_top * _sc, _lw + 1);
    }

    // ---------- camera view: corner brackets ----------
    var _cam = view_camera[0];
    var _vl = _x1 + camera_get_view_x(_cam) * _sc;
    var _vt = _y1 + camera_get_view_y(_cam) * _sc;
    var _vr = _vl + camera_get_view_width(_cam) * _sc;
    var _vb = _vt + camera_get_view_height(_cam) * _sc;
    var _cl = 6;
    if (_big) _cl = 14;
    draw_set_colour(c_white);
    draw_set_alpha(0.55);
    draw_line(_vl, _vt, _vl + _cl, _vt); draw_line(_vl, _vt, _vl, _vt + _cl);
    draw_line(_vr, _vt, _vr - _cl, _vt); draw_line(_vr, _vt, _vr, _vt + _cl);
    draw_line(_vl, _vb, _vl + _cl, _vb); draw_line(_vl, _vb, _vl, _vb - _cl);
    draw_line(_vr, _vb, _vr - _cl, _vb); draw_line(_vr, _vb, _vr, _vb - _cl);
    draw_set_alpha(1);

    var _pulse = 0.5 + 0.5 * sin(current_time / 200);

    // ---------- stations ----------
    with (obj_station)
    {
        var _sx = _x1 + x * _sc;
        var _sy = _y1 + (y - 10) * _sc;
        var _door = (station == "door_lab" || station == "door_select");
        if (_door)
        {
            draw_set_colour(_blue);
            draw_rectangle(_sx - 2, _sy - 4, _sx + 2, _sy + 3, false);
        }
        else if (!visited)
        {
            // new: pulsing yellow diamond
            var _ds = 3 + _pulse;
            draw_set_colour(make_colour_rgb(255, 204, 64));
            draw_triangle(_sx, _sy - _ds, _sx - _ds, _sy, _sx + _ds, _sy, false);
            draw_triangle(_sx, _sy + _ds, _sx - _ds, _sy, _sx + _ds, _sy, false);
        }
        else
        {
            draw_set_colour(_grey);
            draw_rectangle(_sx - 1.5, _sy - 1.5, _sx + 1.5, _sy + 1.5, false);
        }
        if (_big)
        {
            draw_set_colour(_grey);
            draw_set_halign(fa_center);
            draw_text_transformed(_sx, _sy + 6, kd_station_name(station), 0.6, 0.6, 0);
            draw_set_halign(fa_left);
        }
    }

    // ---------- weapons lying around ----------
    with (obj_gun)
    {
        if (equipped) continue;
        var _wx = _x1 + x * _sc;
        var _wy = _y1 + (y - 4) * _sc;
        draw_set_colour(_orange);
        draw_set_alpha(0.35 + 0.4 * _pulse);
        draw_circle(_wx, _wy, 5, true);
        draw_set_alpha(1);
        draw_triangle(_wx - 3, _wy - 2, _wx + 3, _wy - 2, _wx, _wy + 3, false);
        if (_big && !is_undefined(weapon))
        {
            draw_set_halign(fa_center);
            draw_text_transformed(_wx, _wy + 7, weapon.name, 0.6, 0.6, 0);
            draw_set_halign(fa_left);
        }
    }

    // ---------- item boxes (brown) ----------
    with (obj_item_box)
    {
        draw_set_colour(make_colour_rgb(176, 124, 70));
        draw_rectangle(_x1 + x * _sc, _y1 + y * _sc, _x1 + (x + 16) * _sc, _y1 + (y + 16) * _sc, false);
    }

    // ---------- people (colour shows their state) ----------
    with (obj_kd_npc)
    {
        var _nc = _blue;
        if (burn > 0) _nc = _orange;
        if (freeze > 0) _nc = c_white;
        if (shock > 0) _nc = make_colour_rgb(255, 255, 140);
        draw_set_colour(_nc);
        draw_circle(_x1 + x * _sc, _y1 + (y - 12) * _sc, 2.5, false);
    }

    // ---------- you: radar sweep + arrow pointing where you face ----------
    with (obj_player)
    {
        var _px = _x1 + x * _sc;
        var _py = _y1 + (y - 12) * _sc;
        var _rad = 16;
        if (_big) _rad = 34;
        var _ang = current_time / 6;
        for (var _k = 0; _k < 8; _k++)
        {
            draw_set_alpha(0.35 * (1 - _k / 8));
            draw_set_colour(_green);
            draw_line(_px, _py, _px + lengthdir_x(_rad, _ang - _k * 5), _py + lengthdir_y(_rad, _ang - _k * 5));
        }
        draw_set_alpha(0.25);
        draw_circle(_px, _py, _rad, true);
        draw_set_alpha(1);
        var _f = facing;
        var _as = 5;
        if (_big) _as = 8;
        draw_set_colour(_green);
        draw_triangle(_px + _f * _as, _py, _px - _f * _as * 0.6, _py - _as * 0.8, _px - _f * _as * 0.6, _py + _as * 0.8, false);
        draw_set_colour(c_white);
        draw_triangle(_px + _f * _as, _py, _px - _f * _as * 0.6, _py - _as * 0.8, _px - _f * _as * 0.6, _py + _as * 0.8, true);
    }

    // ---------- scanlines over the map ----------
    draw_set_colour(c_black);
    draw_set_alpha(0.12);
    for (var _sl = _y1; _sl < _y2; _sl += 3) draw_line(_x1, _sl, _x2, _sl);
    draw_set_alpha(1);

    // ---------- legend (big map only) ----------
    if (_big)
    {
        var _ly2 = _y2 + _pad + 4;
        var _lx2 = _x1;
        draw_set_colour(make_colour_rgb(255, 204, 64)); draw_text_transformed(_lx2, _ly2, "* new station", 0.8, 0.8, 0); _lx2 += 140;
        draw_set_colour(_grey);   draw_text_transformed(_lx2, _ly2, "# visited", 0.8, 0.8, 0);        _lx2 += 110;
        draw_set_colour(_blue);   draw_text_transformed(_lx2, _ly2, "| door", 0.8, 0.8, 0);           _lx2 += 90;
        draw_set_colour(_orange); draw_text_transformed(_lx2, _ly2, "v weapon", 0.8, 0.8, 0);         _lx2 += 110;
        draw_set_colour(_blue);   draw_text_transformed(_lx2, _ly2, "o people", 0.8, 0.8, 0);         _lx2 += 100;
        draw_set_colour(_green);  draw_text_transformed(_lx2, _ly2, "> you", 0.8, 0.8, 0);
        draw_set_halign(fa_right);
        draw_set_colour(_grey);
        draw_text_transformed(_x2, _ly2, "M = close", 0.8, 0.8, 0);
        draw_set_halign(fa_left);
    }

    draw_set_colour(c_white);
    draw_set_alpha(1);
    return _top;
}

/// the minimised map: a small tab in the corner. Returns the y of its top edge.
function kd_minimap_mini_draw(_x2, _y2)
{
    var _green = make_colour_rgb(64, 226, 110);
    var _w = 96;
    var _h = 24;
    var _x1 = _x2 - _w;
    var _y1 = _y2 - _h;
    draw_set_alpha(0.92);
    draw_set_colour(make_colour_rgb(8, 17, 14));
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 10, 10, false);
    draw_set_alpha(1);
    draw_set_colour(_green);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 10, 10, true);
    var _ty = _y1 + _h / 2;
    draw_set_colour(make_colour_rgb(235, 64, 80));  draw_circle(_x1 + 12, _ty, 3, false);
    draw_set_colour(make_colour_rgb(255, 196, 60)); draw_circle(_x1 + 21, _ty, 3, false);
    draw_set_colour(_green);                        draw_circle(_x1 + 30, _ty, 3, false);
    draw_set_halign(fa_right);
    draw_set_valign(fa_middle);
    draw_text_transformed(_x2 - 10, _ty + 1, "MAP  M", 0.75, 0.75, 0);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_colour(c_white);
    return _y1;
}
