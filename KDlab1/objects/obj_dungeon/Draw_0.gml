/// obj_dungeon - Draw: neon backdrop, platforms, spawn portals, exit gate
if (!kd_run_active()) exit;
var _neon  = make_colour_hsv((hue + t * 0.15) mod 256, 200, 255);
var _neon2 = make_colour_hsv((hue + 90 + t * 0.15) mod 256, 200, 255);
var _cx = camera_get_view_x(view_camera[0]);
var _cy = camera_get_view_y(view_camera[0]);

// ---------- backdrop: dark gradient, grid, far neon shapes ----------
draw_rectangle_colour(0, 0, room_width, room_height, make_colour_rgb(18, 10, 44), make_colour_rgb(18, 10, 44), make_colour_rgb(6, 4, 18), make_colour_rgb(6, 4, 18), false);
draw_set_alpha(0.12);
draw_set_colour(_neon);
for (var _gx = 0; _gx < room_width; _gx += 16) draw_line(_gx, 0, _gx, KD_FLOOR_Y);
for (var _gy = 0; _gy < KD_FLOOR_Y; _gy += 16) draw_line(0, _gy, room_width, _gy);
draw_set_alpha(1);
gpu_set_blendmode(bm_add);
for (var _k = 0; _k < 5; _k++)
{
    var _sx = 60 + _k * 100 + _cx * 0.4;       // parallax: these move slower than the walls
    var _sy = 60 + (_k mod 2) * 40 + _cy * 0.4;
    var _c  = merge_colour(c_black, (_k mod 2 == 0) ? _neon : _neon2, 0.25);
    draw_circle_colour(_sx, _sy, 40 + 6 * sin(t / 40 + _k), _c, c_black, false);
}
gpu_set_blendmode(bm_normal);

// ---------- walls + platforms with a glowing top edge ----------
for (var _i = 0; _i < array_length(solids); _i++)
{
    var _s = solids[_i];
    draw_set_colour(make_colour_rgb(22, 14, 50));
    draw_rectangle(_s[0], _s[1], _s[0] + _s[2] - 1, _s[1] + _s[3] - 1, false);
    gpu_set_blendmode(bm_add);
    draw_set_alpha(0.35);
    draw_set_colour(_neon);
    draw_rectangle(_s[0], _s[1] - 2, _s[0] + _s[2] - 1, _s[1] + 1, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
    draw_set_colour(_neon);
    draw_line(_s[0], _s[1], _s[0] + _s[2] - 1, _s[1]);
}

// ---------- portals where enemies are about to appear ----------
for (var _q = 0; _q < array_length(queue); _q++)
{
    var _e = queue[_q];
    if (_e.t > 50) continue;
    var _k2 = 1 - _e.t / 50;
    var _ey = (_e.kind == "flyer") ? _e.y : _e.y - 14;
    var _r  = (_e.kind == "boss") ? 26 : 12;
    gpu_set_blendmode(bm_add);
    draw_circle_colour(_e.x, _ey, _r * 1.8 * _k2, merge_colour(c_black, make_colour_rgb(255, 60, 140), 0.6), c_black, false);
    gpu_set_blendmode(bm_normal);
    draw_set_colour(make_colour_rgb(255, 120, 200));
    draw_circle(_e.x, _ey, _r * _k2, true);
    draw_circle(_e.x, _ey, _r * _k2 * 0.6, true);
}

// ---------- exit gate (right) ----------
var _gx1 = room_width - 26;
var _gy1 = KD_FLOOR_Y - 44;
if (cleared)
{
    var _gc = (type == "boss") ? make_colour_rgb(255, 214, 90) : make_colour_rgb(64, 226, 110);
    gpu_set_blendmode(bm_add);
    draw_circle_colour(_gx1 + 9, _gy1 + 22, 26 + 3 * sin(t / 6), merge_colour(c_black, _gc, 0.55), c_black, false);
    gpu_set_blendmode(bm_normal);
    draw_set_colour(_gc);
    draw_roundrect_ext(_gx1, _gy1, _gx1 + 18, KD_FLOOR_Y, 6, 6, true);
    draw_set_halign(fa_center);
    draw_text_transformed(_gx1 + 9, _gy1 - 12 + 2 * sin(t / 8), ">", 0.6, 0.6, 0);
    draw_set_halign(fa_left);
}
else
{
    draw_set_colour(make_colour_rgb(40, 16, 30));
    draw_rectangle(_gx1, _gy1, _gx1 + 18, KD_FLOOR_Y - 1, false);
    draw_set_colour(make_colour_rgb(255, 50, 70));
    for (var _b = 0; _b < 4; _b++) draw_line(_gx1 + 2 + _b * 5, _gy1, _gx1 + 2 + _b * 5, KD_FLOOR_Y - 1);
    draw_rectangle(_gx1, _gy1, _gx1 + 18, KD_FLOOR_Y - 1, true);
}
draw_set_colour(c_white);
draw_set_alpha(1);
