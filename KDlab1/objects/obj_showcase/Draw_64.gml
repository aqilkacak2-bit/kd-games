/// obj_showcase - Draw GUI: info card on hover, small hint when you stand at it
if (!hover && !near) exit;
draw_set_font(KD_FONT_TEXT);
draw_set_valign(fa_top);
var _dark  = make_colour_rgb(14, 18, 24);
var _grey  = make_colour_rgb(160, 168, 180);
var _gw    = display_get_gui_width();
var _gh    = display_get_gui_height();

if (hover)
{
    // ---------- card next to the mouse ----------
    var _w   = 380;
    var _pad = 16;
    var _ts  = 0.8;
    var _sep = 24;
    var _tw  = (_w - _pad * 2) / _ts;
    var _dh  = string_height_ext(info.tag, _sep, _tw) * _ts;
    var _h   = _pad + 34 + _dh + 10;
    if (info.by != "") _h += 24;
    _h += array_length(info.social) * 22;
    _h += 30 + _pad;

    var _x1 = device_mouse_x_to_gui(0) + 22;
    var _y1 = device_mouse_y_to_gui(0) + 16;
    if (_x1 + _w > _gw - 8) _x1 = device_mouse_x_to_gui(0) - 22 - _w;
    _x1 = clamp(_x1, 8, _gw - _w - 8);
    _y1 = clamp(_y1, 8, _gh - _h - 8);

    draw_set_alpha(0.94);
    draw_set_colour(_dark);
    draw_roundrect_ext(_x1, _y1, _x1 + _w, _y1 + _h, 14, 14, false);
    draw_set_alpha(1);
    draw_set_colour(info.col);
    draw_roundrect_ext(_x1, _y1, _x1 + _w, _y1 + _h, 14, 14, true);
    draw_rectangle(_x1 + 1, _y1 + 12, _x1 + 4, _y1 + _h - 12, false);          // accent bar

    var _cy = _y1 + _pad;
    kd_title_text(_x1 + _pad, _cy, info.title, 1.3, 1.3, 0);
    _cy += 34;
    draw_set_colour(c_white);
    draw_text_ext_transformed(_x1 + _pad, _cy, info.tag, _sep, _tw, _ts, _ts, 0);
    _cy += _dh + 10;
    if (info.by != "")
    {
        draw_set_colour(_grey);
        draw_text_transformed(_x1 + _pad, _cy, "Created by", 0.75, 0.75, 0);
        draw_set_colour(c_white);
        draw_text_transformed(_x1 + _pad + string_width("Created by ") * 0.75, _cy, info.by, 0.75, 0.75, 0);
        _cy += 24;
    }
    for (var _i = 0; _i < array_length(info.social); _i++)
    {
        draw_set_colour(info.col);
        draw_text_transformed(_x1 + _pad, _cy, info.social[_i], 0.75, 0.75, 0);
        _cy += 22;
    }
    // link line
    draw_set_colour(make_colour_rgb(40, 46, 58));
    draw_line(_x1 + _pad, _cy + 2, _x1 + _w - _pad, _cy + 2);
    draw_set_colour(_grey);
    draw_text_transformed(_x1 + _pad, _cy + 8, string_replace(info.url, "https://", ""), 0.75, 0.75, 0);
    draw_set_halign(fa_right);
    draw_set_colour(make_colour_rgb(64, 226, 110));
    if ((t div 20) mod 2 == 0) draw_set_colour(c_white);
    draw_text_transformed(_x1 + _w - _pad, _cy + 8, "CLICK TO OPEN >", 0.75, 0.75, 0);
    draw_set_halign(fa_left);
}
else
{
    // ---------- standing at it: small hint above the exhibit ----------
    var _cam = view_camera[0];
    var _s   = _gw / camera_get_view_width(_cam);
    var _gx  = ((bbox_left + bbox_right) / 2 - camera_get_view_x(_cam)) * _s;
    var _gy  = (bbox_top - camera_get_view_y(_cam)) * _s - 30 + sin(t / 15) * 3;
    var _txt = "[E] or click:  " + info.title;
    var _tw2 = string_width(_txt) * 0.75;
    draw_set_alpha(0.85);
    draw_set_colour(_dark);
    draw_roundrect_ext(_gx - _tw2 / 2 - 10, _gy, _gx + _tw2 / 2 + 10, _gy + 24, 10, 10, false);
    draw_set_alpha(1);
    draw_set_colour(info.col);
    draw_roundrect_ext(_gx - _tw2 / 2 - 10, _gy, _gx + _tw2 / 2 + 10, _gy + 24, 10, 10, true);
    draw_set_halign(fa_center);
    draw_text_transformed(_gx, _gy + 4, _txt, 0.75, 0.75, 0);
    draw_set_halign(fa_left);
}
draw_set_colour(c_white);
