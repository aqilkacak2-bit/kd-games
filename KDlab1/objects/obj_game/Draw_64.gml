/// obj_game - Draw GUI   (GUI is 1280 x 720)
draw_set_font(KD_FONT_TEXT);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
var _green = make_colour_rgb(64, 226, 110);
var _dark  = make_colour_rgb(18, 22, 30);
var _grey  = make_colour_rgb(160, 168, 180);
var _mx = device_mouse_x_to_gui(0);
var _my = device_mouse_y_to_gui(0);

// ---------- speech bubbles ----------
if (global.kd_show_bubbles)
{
    with (obj_kd_npc)
    {
        if (bubble_timer > 0) kd_draw_bubble(x, y - 36, bubble_text, min(1, bubble_timer / 20));
    }
    with (obj_player)
    {
        if (bubble_timer > 0) kd_draw_bubble(x, y - 36, bubble_text, min(1, bubble_timer / 20));
    }
}

// ---------- name plates under everyone's feet: face, name, health ----------
with (obj_kd_npc) kd_draw_nameplate(x, y, npc_name, look, hp, hp_max, make_colour_rgb(150, 200, 255), ko > 0);
with (obj_player) kd_draw_nameplate(x, y, global.kd_name, look, hp, hp_max, make_colour_rgb(64, 226, 110), false);

// ---------- HUD: level + EXP (top left) ----------
var _lvl  = kd_level_from_exp(global.kd_exp);
var _cur  = kd_exp_for_level(_lvl);
var _next = kd_exp_for_level(_lvl + 1);
var _frac = (global.kd_exp - _cur) / (_next - _cur);

draw_set_alpha(0.85);
draw_set_colour(_dark);
draw_roundrect_ext(16, 16, 336, 78, 12, 12, false);
draw_set_alpha(1);
draw_set_colour(_green);
draw_roundrect_ext(16, 16, 336, 78, 12, 12, true);
kd_title_text(30, 24, "<KD/>", 1.6, 1.6, 0);
draw_set_colour(c_white);
draw_text(110, 24, global.kd_name + "   Lv " + string(_lvl));
draw_set_colour(make_colour_rgb(40, 46, 58));
draw_rectangle(110, 50, 322, 62, false);
draw_set_colour(_green);
draw_rectangle(110, 50, 110 + 212 * clamp(_frac, 0, 1), 62, false);
draw_set_colour(_grey);
draw_text_transformed(110, 63, string(global.kd_exp) + " / " + string(_next) + " EXP", 0.8, 0.8, 0);

// date + time under the HUD
draw_set_alpha(0.85);
draw_set_colour(_dark);
draw_roundrect_ext(16, 84, 336, 110, 10, 10, false);
draw_set_alpha(1);
draw_set_colour(_grey);
draw_text(28, 89, kd_date_text());
draw_set_colour(_green);
draw_set_halign(fa_right);
draw_text(326, 89, kd_time_text());
draw_set_halign(fa_left);

// ---------- your face + health ----------
if (instance_exists(obj_player))
{
    var _pl = instance_find(obj_player, 0);
    draw_set_alpha(0.85);
    draw_set_colour(_dark);
    draw_roundrect_ext(16, 116, 336, 164, 10, 10, false);
    draw_set_alpha(1);
    draw_set_colour(_green);
    draw_roundrect_ext(16, 116, 336, 164, 10, 10, true);
    draw_set_colour(make_colour_rgb(34, 42, 56));
    draw_roundrect_ext(24, 120, 64, 160, 8, 8, false);
    kd_draw_face_icon(26, 122, _pl.look, 36);
    draw_set_colour(_green);
    draw_roundrect_ext(24, 120, 64, 160, 8, 8, true);
    var _hpf = clamp(_pl.hp / _pl.hp_max, 0, 1);
    draw_set_colour(c_white);
    draw_text_transformed(76, 121, "HP", 0.8, 0.8, 0);
    draw_set_halign(fa_right);
    draw_set_colour(_grey);
    draw_text_transformed(326, 121, string(ceil(_pl.hp)) + " / " + string(_pl.hp_max), 0.8, 0.8, 0);
    draw_set_halign(fa_left);
    draw_set_colour(make_colour_rgb(40, 46, 58));
    draw_rectangle(76, 140, 326, 154, false);
    draw_set_colour(kd_hp_colour(_hpf));
    draw_rectangle(76, 140, 76 + 250 * _hpf, 154, false);
    if (_pl.hit_flash > 0)
    {
        draw_set_alpha(_pl.hit_flash / 10);
        draw_set_colour(c_white);
        draw_rectangle(76, 140, 326, 154, true);
        draw_set_alpha(1);
    }
}

// ---------- abilities under the health bar: F shield, H heal, G grenades ----------
if (instance_exists(obj_player))
{
    var _pa = instance_find(obj_player, 0);
    var _ab = [["F", "Shield", _pa.shield_cd, 8 * 60, make_colour_rgb(98, 200, 244)],
               ["H", "Heal",   _pa.heal_cd,   10 * 60, make_colour_rgb(98, 226, 106)],
               ["G", "x" + string(global.kd_grenades), _pa.grenade_cd, 50, make_colour_rgb(150, 220, 120)]];
    for (var _ai = 0; _ai < 3; _ai++)
    {
        var _ax1 = 16 + _ai * 108;
        var _ay1 = 170;
        var _aw  = 104;
        var _ready = (_ab[_ai][2] <= 0);
        if (_ai == 2 && global.kd_grenades <= 0) _ready = false;
        draw_set_alpha(0.85);
        draw_set_colour(_dark);
        draw_roundrect_ext(_ax1, _ay1, _ax1 + _aw, _ay1 + 30, 10, 10, false);
        draw_set_alpha(1);
        if (_ab[_ai][2] > 0)
        {
            // cooldown fills up from the left
            var _cf = 1 - _ab[_ai][2] / _ab[_ai][3];
            draw_set_colour(merge_colour(_dark, _ab[_ai][4], 0.35));
            draw_roundrect_ext(_ax1, _ay1, _ax1 + max(20, _aw * _cf), _ay1 + 30, 10, 10, false);
        }
        draw_set_colour(_grey);
        if (_ready) draw_set_colour(_ab[_ai][4]);
        draw_roundrect_ext(_ax1, _ay1, _ax1 + _aw, _ay1 + 30, 10, 10, true);
        draw_roundrect_ext(_ax1 + 6, _ay1 + 5, _ax1 + 26, _ay1 + 25, 6, 6, true);
        draw_set_halign(fa_center);
        draw_text_transformed(_ax1 + 16, _ay1 + 7, _ab[_ai][0], 0.8, 0.8, 0);
        draw_set_halign(fa_left);
        var _lbl = _ab[_ai][1];
        if (_ai == 0 && kd_shield_up(_pa.shield_fx)) _lbl = "ON";
        else if (_ai < 2 && _ab[_ai][2] > 0) _lbl += " " + string(ceil(_ab[_ai][2] / 60)) + "s";
        if (_ai == 2) draw_sprite_ext(spr_item, 1, _ax1 + 40, _ay1 + 25, 1.2, 1.2, 0, c_white, 1);
        draw_text_transformed(_ax1 + ((_ai == 2) ? 52 : 32), _ay1 + 7, _lbl, 0.8, 0.8, 0);
    }
    draw_set_colour(c_white);
}

// ---------- skill tree hint + chips ----------
if (instance_exists(obj_player)) kd_skill_hud_draw();

// ---------- corner buttons: chat + settings (top right) ----------
var _hc = point_in_rectangle(_mx, _my, chat_btn[0], chat_btn[1], chat_btn[2], chat_btn[3]) || chat_typing;
var _hg = point_in_rectangle(_mx, _my, gear_btn[0], gear_btn[1], gear_btn[2], gear_btn[3]) || settings_open;

draw_set_alpha(0.85);
draw_set_colour(_dark);
draw_roundrect_ext(chat_btn[0], chat_btn[1], chat_btn[2], chat_btn[3], 10, 10, false);
draw_roundrect_ext(gear_btn[0], gear_btn[1], gear_btn[2], gear_btn[3], 10, 10, false);
draw_set_alpha(1);

// chat icon
var _cx = (chat_btn[0] + chat_btn[2]) / 2;
var _cy = (chat_btn[1] + chat_btn[3]) / 2;
draw_set_colour(c_white);
if (_hc) draw_set_colour(_green);
draw_roundrect_ext(chat_btn[0], chat_btn[1], chat_btn[2], chat_btn[3], 10, 10, true);
draw_roundrect_ext(_cx - 14, _cy - 11, _cx + 14, _cy + 7, 8, 8, false);
draw_triangle(_cx - 8, _cy + 5, _cx - 1, _cy + 5, _cx - 10, _cy + 13, false);
draw_set_colour(_dark);
draw_circle(_cx - 7, _cy - 2, 2, false);
draw_circle(_cx,     _cy - 2, 2, false);
draw_circle(_cx + 7, _cy - 2, 2, false);

// gear icon
var _gx = (gear_btn[0] + gear_btn[2]) / 2;
var _gy = (gear_btn[1] + gear_btn[3]) / 2;
draw_set_colour(c_white);
if (_hg) draw_set_colour(_green);
draw_roundrect_ext(gear_btn[0], gear_btn[1], gear_btn[2], gear_btn[3], 10, 10, true);
for (var _a = 0; _a < 360; _a += 45)
{
    draw_line_width(_gx, _gy, _gx + lengthdir_x(13, _a), _gy + lengthdir_y(13, _a), 6);
}
draw_circle(_gx, _gy, 10, false);
draw_set_colour(_dark);
draw_circle(_gx, _gy, 4, false);

// Discord button (opens the KD channel)
var _dc = (discord_btn[0] + discord_btn[2]) / 2;
var _dcy = (discord_btn[1] + discord_btn[3]) / 2;
var _hd = point_in_rectangle(_mx, _my, discord_btn[0], discord_btn[1], discord_btn[2], discord_btn[3]);
var _blurple = make_colour_rgb(88, 101, 242);
draw_set_alpha(0.85);
draw_set_colour(_dark);
draw_roundrect_ext(discord_btn[0], discord_btn[1], discord_btn[2], discord_btn[3], 10, 10, false);
draw_set_alpha(1);
draw_set_colour(c_white);
if (_hd) draw_set_colour(_blurple);
draw_roundrect_ext(discord_btn[0], discord_btn[1], discord_btn[2], discord_btn[3], 10, 10, true);
draw_set_colour(_blurple);
if (_hd) draw_set_colour(c_white);
draw_roundrect_ext(_dc - 14, _dcy - 10, _dc + 14, _dcy + 10, 9, 9, false);     // little "controller" face
draw_triangle(_dc - 14, _dcy + 2, _dc - 8, _dcy + 10, _dc - 16, _dcy + 12, false);
draw_triangle(_dc + 14, _dcy + 2, _dc + 8, _dcy + 10, _dc + 16, _dcy + 12, false);
draw_set_colour(_dark);
draw_ellipse(_dc - 8, _dcy - 3, _dc - 3, _dcy + 3, false);
draw_ellipse(_dc + 3, _dcy - 3, _dc + 8, _dcy + 3, false);
if (_hd)
{
    draw_set_colour(_grey);
    draw_set_halign(fa_center);
    draw_text(_dc, 66, "KD Discord");
    draw_set_halign(fa_left);
}

// tooltips
draw_set_colour(_grey);
draw_set_halign(fa_center);
if (point_in_rectangle(_mx, _my, chat_btn[0], chat_btn[1], chat_btn[2], chat_btn[3])) draw_text(_cx, 66, "Chat (T)");
if (point_in_rectangle(_mx, _my, gear_btn[0], gear_btn[1], gear_btn[2], gear_btn[3])) draw_text(_gx - 20, 66, "Chat settings");
draw_set_halign(fa_left);

// ---------- chat log (bottom left) ----------
var _log_alpha = 0;
if (chat_typing) _log_alpha = 1;
else if (global.kd_chat_log_timer > 0) _log_alpha = min(1, global.kd_chat_log_timer / 60);
if (global.kd_show_log && _log_alpha > 0)
{
    var _n = array_length(global.kd_chat_log);
    var _show = min(_n, 6);
    var _ly = 720 - 76 - _show * 22;
    draw_set_alpha(0.55 * _log_alpha);
    draw_set_colour(_dark);
    draw_roundrect_ext(16, _ly - 8, 660, 720 - 70, 10, 10, false);
    draw_set_alpha(_log_alpha);
    for (var _i = _n - _show; _i < _n; _i++)
    {
        var _e = global.kd_chat_log[_i];
        draw_set_colour(_e.col);
        draw_text(28, _ly, _e.name + ": ");
        var _nw = string_width(_e.name + ": ");
        draw_set_colour(c_white);
        draw_text(28 + _nw, _ly, _e.text);
        _ly += 22;
    }
    draw_set_alpha(1);
}

// ---------- chat input ----------
if (chat_typing)
{
    draw_set_alpha(0.9);
    draw_set_colour(_dark);
    draw_roundrect_ext(16, 720 - 64, 660, 720 - 16, 10, 10, false);
    draw_set_alpha(1);
    draw_set_colour(_green);
    draw_roundrect_ext(16, 720 - 64, 660, 720 - 16, 10, 10, true);
    var _cursor = "";
    if ((blink div 30) mod 2 == 0) _cursor = "|";
    draw_text(30, 720 - 50, "Say:");
    draw_set_colour(c_white);
    draw_text(72, 720 - 50, chat_text + _cursor);
    draw_set_colour(_grey);
    draw_set_halign(fa_right);
    draw_text(650, 720 - 50, "Enter = send   Esc = cancel");
    draw_set_halign(fa_left);
}

// ---------- interaction prompt (uses the E key icon) ----------
var _prompt = "";
if (!global.ui_block && near_station != noone) _prompt = kd_station_name(near_station.station);
else if (!global.ui_block && near_gun != noone)
{
    var _gw = kd_weapon_get(near_gun.weapon_key);
    _prompt = "Pick up " + _gw.name;
}
if (_prompt != "")
{
    var _w = string_width(_prompt) * 1.3 + 30 + 40;
    var _px1 = 640 - _w / 2;
    draw_set_alpha(0.85);
    draw_set_colour(_dark);
    draw_roundrect_ext(_px1, 596, 640 + _w / 2, 644, 10, 10, false);
    draw_set_alpha(1);
    draw_set_colour(_green);
    draw_roundrect_ext(_px1, 596, 640 + _w / 2, 644, 10, 10, true);
    draw_sprite_ext(spr_key_e, 0, _px1 + 26, 620, 2, 2, 0, c_white, 1);
    draw_set_colour(c_white);
    kd_title_text(_px1 + 50, 610, _prompt, 1.3, 1.3, 0);
}

// ---------- weapon bar + lab map (bottom right) ----------
if (!select_open)
{
    var _bar_y2 = 720 - 16;                  // weapon bar sits on the bottom when the map is not in the corner
    if (global.kd_minimap == 1) _bar_y2 = kd_minimap_draw(1280 - 24, 720 - 24, 240, 130, false) - 8;
    if (global.kd_minimap == 0) _bar_y2 = kd_minimap_mini_draw(1280 - 16, 720 - 16) - 8;      // minimised: just a small tab

    // ----- weapon slot: only the weapon in your hand (keys 1-9, 0, -, = still switch) -----
    if (global.kd_weapon != "")
    {
        var _wp2    = kd_weapon_get(global.kd_weapon);
        var _wb_s   = 48;
        var _wb_bx  = 1280 - 16 - _wb_s;
        var _wb_by  = _bar_y2 - _wb_s;
        var _wb_a   = 1;
        if (!global.kd_weapon_out) _wb_a = 0.45;          // holstered
        draw_set_alpha(0.88);
        draw_set_colour(make_colour_rgb(34, 58, 46));
        draw_roundrect_ext(_wb_bx, _wb_by, _wb_bx + _wb_s, _wb_by + _wb_s, 8, 8, false);
        draw_set_alpha(1);
        draw_set_colour(_green);
        draw_roundrect_ext(_wb_bx, _wb_by, _wb_bx + _wb_s, _wb_by + _wb_s, 8, 8, true);
        // centre the weapon's visible pixels in the slot
        var _wb_spr = _wp2.sprite;
        var _wb_bw  = sprite_get_bbox_right(_wb_spr) - sprite_get_bbox_left(_wb_spr) + 1;
        var _wb_bh  = sprite_get_bbox_bottom(_wb_spr) - sprite_get_bbox_top(_wb_spr) + 1;
        var _wb_ss  = min(1.5, (_wb_s - 8) / _wb_bw);
        var _wb_ox  = (sprite_get_bbox_left(_wb_spr) + _wb_bw / 2 - sprite_get_xoffset(_wb_spr)) * _wb_ss;
        var _wb_oy  = (sprite_get_bbox_top(_wb_spr) + _wb_bh / 2 - sprite_get_yoffset(_wb_spr)) * _wb_ss;
        draw_sprite_ext(_wb_spr, 0, _wb_bx + _wb_s / 2 - _wb_ox, _wb_by + _wb_s / 2 + 3 - _wb_oy, _wb_ss, _wb_ss, 0, c_white, _wb_a);
        // its key in the corner of the slot
        var _wb_order = kd_weapon_order();
        var _wb_lab   = kd_weapon_key_labels();
        for (var _wi = 0; _wi < array_length(_wb_order); _wi++)
        {
            if (_wb_order[_wi] == global.kd_weapon) draw_text_transformed(_wb_bx + 5, _wb_by + 2, _wb_lab[_wi], 0.65, 0.65, 0);
        }
        // name to the left of the slot
        var _wtxt = _wp2.name;
        if (!global.kd_weapon_out) _wtxt += "  (holstered - Q)";
        draw_set_halign(fa_right);
        draw_set_valign(fa_middle);
        draw_set_colour(c_white);
        draw_text_transformed(_wb_bx - 10, _wb_by + _wb_s / 2, _wtxt, 0.9, 0.9, 0);
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
    }

    // big map goes over everything else in the HUD
    if (global.kd_minimap == 2) kd_minimap_draw(0, 0, 900, 440, true);
    draw_set_colour(c_white);
    draw_set_alpha(1);
}

// ---------- info panel ----------
if (panel_open && !is_undefined(panel) && panel.feed && array_length(feed_events) > 0)
{
    var _ev = feed_events[feed_index];
    var _st = kd_event_status(_ev);

    draw_set_alpha(0.55);
    draw_set_colour(c_black);
    draw_rectangle(0, 0, 1280, 720, false);
    draw_set_alpha(0.97);
    draw_set_colour(_dark);
    draw_roundrect_ext(pan_x1, pan_y1, pan_x2, pan_y2, 16, 16, false);
    draw_set_alpha(1);
    draw_set_colour(_green);
    draw_roundrect_ext(pan_x1, pan_y1, pan_x2, pan_y2, 16, 16, true);

    // header: feed name + today's date
    kd_title_text(pan_x1 + 30, pan_y1 + 20, "KD Feed", 2, 2, 0);
    draw_set_colour(_grey);
    draw_text(pan_x1 + 30, pan_y1 + 58, "@krackeddev   |   events");
    draw_set_halign(fa_right);
    draw_set_colour(c_white);
    draw_text_transformed(pan_x2 - 30, pan_y1 + 22, "Today: " + kd_date_text(), 1.2, 1.2, 0);
    draw_set_colour(_green);
    draw_text(pan_x2 - 30, pan_y1 + 52, kd_time_text());
    draw_set_halign(fa_left);
    draw_set_colour(_green);
    draw_rectangle(pan_x1 + 30, pan_y1 + 84, pan_x2 - 30, pan_y1 + 85, false);

    // poster (any image size, scaled to fit 280 x 350)
    var _bx = pan_x1 + 30;
    var _byy = pan_y1 + 100;
    draw_set_colour(make_colour_rgb(30, 38, 50));
    draw_rectangle(_bx, _byy, _bx + 280, _byy + 350, false);
    var _spr = _ev.img;
    var _sc = min(280 / sprite_get_width(_spr), 350 / sprite_get_height(_spr));
    var _dw = sprite_get_width(_spr) * _sc;
    var _dh = sprite_get_height(_spr) * _sc;
    gpu_set_texfilter(true);
    draw_sprite_ext(_spr, 0, _bx + (280 - _dw) / 2, _byy + (350 - _dh) / 2, _sc, _sc, 0, c_white, 1);
    gpu_set_texfilter(false);

    // prev / next + page number
    var _hp = point_in_rectangle(_mx, _my, feed_prev_btn[0], feed_prev_btn[1], feed_prev_btn[2], feed_prev_btn[3]);
    var _hn = point_in_rectangle(_mx, _my, feed_next_btn[0], feed_next_btn[1], feed_next_btn[2], feed_next_btn[3]);
    draw_set_colour(make_colour_rgb(34, 42, 56));
    draw_roundrect_ext(feed_prev_btn[0], feed_prev_btn[1], feed_prev_btn[2], feed_prev_btn[3], 8, 8, false);
    draw_roundrect_ext(feed_next_btn[0], feed_next_btn[1], feed_next_btn[2], feed_next_btn[3], 8, 8, false);
    draw_set_colour(_grey);
    if (_hp) draw_set_colour(_green);
    draw_triangle(feed_prev_btn[0] + 20, feed_prev_btn[1] + 20, feed_prev_btn[0] + 38, feed_prev_btn[1] + 10, feed_prev_btn[0] + 38, feed_prev_btn[1] + 30, false);
    draw_set_colour(_grey);
    if (_hn) draw_set_colour(_green);
    draw_triangle(feed_next_btn[2] - 20, feed_next_btn[1] + 20, feed_next_btn[2] - 38, feed_next_btn[1] + 10, feed_next_btn[2] - 38, feed_next_btn[1] + 30, false);
    draw_set_colour(c_white);
    draw_set_halign(fa_center);
    draw_text(_bx + 140, feed_prev_btn[1] + 12, string(feed_index + 1) + " / " + string(array_length(feed_events)));
    draw_set_halign(fa_left);

    // right column: status, title, details
    var _tx = pan_x1 + 340;
    var _ty2 = pan_y1 + 104;
    var _wrap = pan_x2 - 30 - _tx;

    var _bcol = make_colour_rgb(110, 116, 128);
    if (_st == "LIVE TODAY") _bcol = make_colour_rgb(235, 64, 80);
    if (_st == "UPCOMING") _bcol = make_colour_rgb(255, 196, 60);
    var _bw = string_width(_st) + 28;
    draw_set_colour(_bcol);
    draw_roundrect_ext(_tx, _ty2, _tx + _bw, _ty2 + 28, 14, 14, false);
    draw_set_colour(_dark);
    if (_st == "LIVE TODAY") draw_set_colour(c_white);
    draw_text(_tx + 14, _ty2 + 6, _st);
    draw_set_colour(_green);
    draw_text(_tx + _bw + 14, _ty2 + 6, _ev.tag);
    _ty2 += 44;

    draw_set_colour(c_white);
    draw_text_ext_transformed(_tx, _ty2, _ev.title, -1, _wrap / 1.6, 1.6, 1.6, 0);
    _ty2 += string_height_ext(_ev.title, -1, _wrap / 1.6) * 1.6 + 16;

    var _rows = [ ["Date", _ev.date], ["Time", _ev.time], ["Where", _ev.place], ["Host", _ev.host] ];
    for (var _r = 0; _r < array_length(_rows); _r++)
    {
        if (_rows[_r][1] == "") continue;
        draw_set_colour(_grey);
        draw_text(_tx, _ty2, _rows[_r][0]);
        draw_set_colour(c_white);
        draw_text(_tx + 70, _ty2, _rows[_r][1]);
        _ty2 += 26;
    }
    _ty2 += 10;
    draw_set_colour(make_colour_rgb(200, 206, 216));
    draw_text_ext(_tx, _ty2, _ev.desc, 24, _wrap);

    draw_set_colour(_grey);
    draw_set_halign(fa_right);
    draw_text(pan_x2 - 24, pan_y2 - 34, "A / D or arrows = browse     E / Esc = close");
    draw_set_halign(fa_left);
}
else if (panel_open && !is_undefined(panel))
{
    draw_set_alpha(0.55);
    draw_set_colour(c_black);
    draw_rectangle(0, 0, 1280, 720, false);
    draw_set_alpha(0.97);
    draw_set_colour(_dark);
    draw_roundrect_ext(pan_x1, pan_y1, pan_x2, pan_y2, 16, 16, false);
    draw_set_alpha(1);
    draw_set_colour(_green);
    draw_roundrect_ext(pan_x1, pan_y1, pan_x2, pan_y2, 16, 16, true);
    draw_rectangle(pan_x1 + 30, pan_y1 + 84, pan_x2 - 30, pan_y1 + 85, false);

    kd_title_text(pan_x1 + 30, pan_y1 + 22, panel.title, 2, 2, 0);
    draw_set_colour(_grey);
    draw_text(pan_x1 + 30, pan_y1 + 58, panel.sub);

    var _y = pan_y1 + 104;

    // stat tiles
    var _nt = array_length(panel.tiles);
    if (_nt > 0)
    {
        var _tw = (pan_x2 - pan_x1 - 60 - (_nt - 1) * 16) / _nt;
        for (var _i = 0; _i < _nt; _i++)
        {
            var _tx = pan_x1 + 30 + _i * (_tw + 16);
            draw_set_colour(make_colour_rgb(30, 38, 50));
            draw_roundrect_ext(_tx, _y, _tx + _tw, _y + 92, 10, 10, false);
            draw_set_colour(_green);
            draw_set_halign(fa_center);
            kd_title_text(_tx + _tw / 2, _y + 14, panel.tiles[_i][0], 2.4, 2.4, 0);
            draw_set_colour(_grey);
            draw_text(_tx + _tw / 2, _y + 62, panel.tiles[_i][1]);
            draw_set_halign(fa_left);
        }
        _y += 112;
    }

    // two-column list
    var _nc = array_length(panel.cols);
    if (_nc > 0)
    {
        var _half = ceil(_nc / 2);
        for (var _i = 0; _i < _nc; _i++)
        {
            var _col = _i div _half;
            var _row = _i mod _half;
            var _lx = pan_x1 + 40 + _col * 420;
            var _ly2 = _y + _row * 28;
            draw_set_colour(_green);
            draw_circle(_lx, _ly2 + 8, 3, false);
            draw_set_colour(c_white);
            draw_text(_lx + 14, _ly2, panel.cols[_i]);
        }
        _y += _half * 28;
    }

    // text lines ("## " = heading)
    for (var _i = 0; _i < array_length(panel.lines); _i++)
    {
        var _ln = panel.lines[_i];
        if (string_copy(_ln, 1, 3) == "## ")
        {
            draw_set_colour(_green);
            draw_text_transformed(pan_x1 + 30, _y, string_delete(_ln, 1, 3), 1.15, 1.15, 0);
            _y += 28;
        }
        else
        {
            draw_set_colour(c_white);
            draw_text(pan_x1 + 30, _y, _ln);
            _y += 24;
        }
    }

    draw_set_colour(_grey);
    draw_set_halign(fa_right);
    draw_text(pan_x2 - 24, pan_y2 - 34, "[E] / [Esc] / click to close");
    draw_set_halign(fa_left);
}

// ---------- settings panel ----------
if (settings_open)
{
    draw_set_alpha(0.55);
    draw_set_colour(c_black);
    draw_rectangle(0, 0, 1280, 720, false);
    draw_set_alpha(0.97);
    draw_set_colour(_dark);
    draw_roundrect_ext(set_x1, set_y1, set_x1 + set_w, set_y1 + set_h, 16, 16, false);
    draw_set_alpha(1);
    draw_set_colour(_green);
    draw_roundrect_ext(set_x1, set_y1, set_x1 + set_w, set_y1 + set_h, 16, 16, true);
    kd_title_text(set_x1 + 26, set_y1 + 20, "Chat Settings", 1.8, 1.8, 0);

    for (var _r = 0; _r < array_length(set_rows); _r++)
    {
        var _label = "";
        var _value = "";
        switch (set_rows[_r])
        {
            case "name":
                _label = "Your name";
                _value = global.kd_name;
                if (name_editing)
                {
                    _value = chat_text;
                    if ((blink div 30) mod 2 == 0) _value += "|";
                }
                break;
            case "bubbles": _label = "Speech bubbles"; if (global.kd_show_bubbles) _value = "ON"; else _value = "OFF"; break;
            case "log":     _label = "Chat log";       if (global.kd_show_log) _value = "ON"; else _value = "OFF"; break;
            case "time":    _label = "Bubble time";    _value = string(global.kd_bubble_time) + " sec"; break;
            case "npc":     _label = "NPC replies";    if (global.kd_npc_replies) _value = "ON"; else _value = "OFF"; break;
            case "shader":  _label = "Shader (F2)";    _value = shader_names[global.kd_shader]; break;
            case "sfx":     _label = "Sound volume";   _value = string(round(global.kd_sfx_vol * 100)) + "%"; break;
            case "hum":     _label = "Lab hum";        if (global.kd_hum_on) _value = "ON"; else _value = "OFF"; break;
            case "close":   _label = "";               _value = "Close"; break;
        }
        var _by1 = set_y1 + 76 + _r * 46;
        var _bx1 = set_x1 + set_w - 190;
        draw_set_colour(c_white);
        draw_text(set_x1 + 30, _by1 + 8, _label);

        var _hover = point_in_rectangle(_mx, _my, _bx1, _by1, _bx1 + 160, _by1 + 34);
        draw_set_colour(make_colour_rgb(34, 42, 56));
        if (_hover) draw_set_colour(make_colour_rgb(44, 70, 56));
        draw_roundrect_ext(_bx1, _by1, _bx1 + 160, _by1 + 34, 8, 8, false);
        draw_set_colour(_grey);
        if (_value == "ON" || _hover || (set_rows[_r] == "name" && name_editing)) draw_set_colour(_green);
        draw_roundrect_ext(_bx1, _by1, _bx1 + 160, _by1 + 34, 8, 8, true);
        draw_set_halign(fa_center);
        draw_text(_bx1 + 80, _by1 + 8, _value);
        draw_set_halign(fa_left);
    }
    draw_set_colour(_grey);
    var _hint = "Click a button to change it.";
    if (name_editing) _hint = "Type your name, Enter to save, Esc to cancel.";
    draw_text(set_x1 + 30, set_y1 + set_h - 30, _hint);
}

// ---------- Character Customiser ----------
if (select_open && !is_undefined(cz_look))
{
    var _d = kd_custom_data();
    var _slots = kd_custom_slots();
    draw_set_alpha(0.6);
    draw_set_colour(c_black);
    draw_rectangle(0, 0, 1280, 720, false);
    draw_set_alpha(0.97);
    draw_set_colour(_dark);
    draw_roundrect_ext(cz_x1, cz_y1, cz_x2, cz_y2, 16, 16, false);
    draw_set_alpha(1);
    draw_set_colour(_green);
    draw_roundrect_ext(cz_x1, cz_y1, cz_x2, cz_y2, 16, 16, true);
    kd_title_text(100, 54, "Character Customiser", 2, 2, 0);
    draw_set_colour(_grey);
    draw_set_halign(fa_right);
    draw_text(cz_x2 - 30, 64, "<KD/>  mix any hair, face, skin and outfit");
    draw_set_halign(fa_left);

    // ----- preview: walks + turns so you see both sides -----
    var _bx1 = 100, _by1 = 108, _bx2 = 440, _by2 = 580;
    var _skin_c = _d.skin_cols[cz_look.skin];
    var _top_c  = _d.top_cols[cz_look.top_col];
    draw_set_colour(merge_colour(_dark, _top_c, 0.16));
    draw_roundrect_ext(_bx1, _by1, _bx2, _by2, 12, 12, false);
    draw_set_colour(merge_colour(_dark, _top_c, 0.5));
    draw_roundrect_ext(_bx1, _by1, _bx2, _by2, 12, 12, true);
    var _cx = (_bx1 + _bx2) / 2;
    var _fy = 520;
    draw_set_colour(merge_colour(_dark, _top_c, 0.4));
    draw_ellipse(_cx - 100, _fy - 14, _cx + 100, _fy + 14, false);

    var _phase = (select_t div 150) mod 4;
    var _state = "idle";
    var _frame = select_t div 15;
    if (_phase == 0 || _phase == 2) { _state = "walk"; _frame = select_t div 6; }
    var _face = 1;
    if (_phase >= 2) _face = -1;
    var _S = 9;
    var _armed = global.kd_weapon != "" && global.kd_weapon_out;
    var _arm_arg = undefined;
    if (_armed) _arm_arg = KD_ARM_NONE;
    kd_draw(_cx, _fy, _face, _state, _frame, cz_look, _S, c_white, 1, false, _arm_arg);
    if (_armed)
    {
        var _wp = kd_weapon_get(global.kd_weapon);
        var _gx = _cx + _face * _S * (KD_AIM_X + _wp.hold_dist);
        var _gy = _fy + _S * (KD_AIM_Y + kd_anim_bob(_state, _frame));
        var _ang = 0;
        var _ys = 1;
        if (_face < 0) { _ang = 180; _ys = -1; }
        if (_wp.type == "melee")
        {
            // keris raised over the shoulder in the front hand
            var _sang = _ang + _ys * 55;
            draw_sprite_ext(_wp.sprite, 0, _gx, _gy, _S, _S * _ys, _sang, c_white, 1);
            kd_draw_hand(_gx, _gy, _ys, 1, _sang + 90, cz_look, _S);
        }
        else
        {
            // back arm hanging behind is skipped while holding: support hand on the gun instead
            draw_sprite_ext(_wp.sprite, 0, _gx, _gy, _S, _S * _ys, _ang, c_white, 1);
            var _sup = kd_support_hand(_gx, _gy, _ang, _ys, _wp, _cx, _fy + _S * kd_anim_bob(_state, _frame), _face, _S);
            kd_draw_hand(_sup[0], _sup[1], _ys, 1, _sup[2], cz_look, _S, KD_BACK_SHADE);
            kd_draw_hand(_gx, _gy, _ys, 1, _ang + 90, cz_look, _S);
        }
    }

    // ----- slot rows -----
    for (var _i = 0; _i < array_length(_slots); _i++)
    {
        var _sl = _slots[_i];
        var _ry = cz_rows_y + _i * cz_row_h;
        var _v  = kd_look_get(cz_look, _sl.key);
        var _hover = point_in_rectangle(_mx, _my, cz_rows_x1, _ry, cz_rows_x2, _ry + cz_row_h - 6);
        draw_set_colour(make_colour_rgb(26, 32, 44));
        if (_hover) draw_set_colour(make_colour_rgb(32, 40, 54));
        if (_i == cz_row) draw_set_colour(make_colour_rgb(34, 58, 46));
        draw_roundrect_ext(cz_rows_x1, _ry, cz_rows_x2, _ry + cz_row_h - 6, 10, 10, false);
        if (_i == cz_row)
        {
            draw_set_colour(_green);
            draw_roundrect_ext(cz_rows_x1, _ry, cz_rows_x2, _ry + cz_row_h - 6, 10, 10, true);
        }
        draw_set_colour(c_white);
        draw_text(cz_rows_x1 + 18, _ry + 7, _sl.label);
        draw_set_colour(_grey);
        draw_text_transformed(cz_rows_x1 + 18, _ry + 25, _sl.names[_v], 0.8, 0.8, 0);

        if (is_array(_sl.cols))
        {
            for (var _j = 0; _j < array_length(_sl.cols); _j++)
            {
                var _sx = 700 + _j * 46;
                draw_set_colour(_sl.cols[_j]);
                draw_roundrect_ext(_sx, _ry + 3, _sx + 38, _ry + 41, 8, 8, false);
                draw_set_colour(make_colour_rgb(12, 14, 20));
                draw_roundrect_ext(_sx, _ry + 3, _sx + 38, _ry + 41, 8, 8, true);
                if (_j == _v)
                {
                    draw_set_colour(c_white);
                    draw_roundrect_ext(_sx - 2, _ry + 1, _sx + 40, _ry + 43, 9, 9, true);
                    draw_roundrect_ext(_sx - 3, _ry, _sx + 41, _ry + 44, 10, 10, true);
                }
            }
        }
        else
        {
            var _hl = point_in_rectangle(_mx, _my, 700, _ry + 4, 740, _ry + 40);
            var _hr = point_in_rectangle(_mx, _my, 980, _ry + 4, 1020, _ry + 40);
            draw_set_colour(c_white);
            if (_hl) draw_set_colour(_green);
            draw_triangle(706, _ry + 22, 734, _ry + 8, 734, _ry + 36, false);
            draw_set_colour(c_white);
            if (_hr) draw_set_colour(_green);
            draw_triangle(1014, _ry + 22, 986, _ry + 8, 986, _ry + 36, false);
            draw_set_colour(c_white);
            draw_set_halign(fa_center);
            kd_title_text(860, _ry + 11, _sl.names[_v], 1.3, 1.3, 0);
            draw_set_halign(fa_left);
            draw_set_colour(_grey);
            draw_text(1040, _ry + 13, string(_v + 1) + " / " + string(array_length(_sl.names)));
        }
    }

    // ----- presets -----
    draw_set_colour(_grey);
    draw_text(cz_rows_x1, 541, "Presets");
    for (var _p = 0; _p < kd_preset_count(); _p++)
    {
        var _px = 560 + _p * 104;
        var _pr = kd_preset_get(_p);
        var _hp = point_in_rectangle(_mx, _my, _px, 532, _px + 96, 570);
        draw_set_colour(make_colour_rgb(30, 38, 50));
        if (_hp) draw_set_colour(make_colour_rgb(44, 70, 56));
        draw_roundrect_ext(_px, 532, _px + 96, 570, 10, 10, false);
        draw_set_colour(_d.top_cols[_pr.look.top_col]);
        draw_roundrect_ext(_px, 532, _px + 96, 570, 10, 10, true);
        draw_set_colour(c_white);
        draw_set_halign(fa_center);
        draw_text(_px + 48, 542, _pr.name);
        draw_set_halign(fa_left);
    }

    // ----- buttons -----
    var _btns = [ [cz_btn_random, "Randomise (R)", false], [cz_btn_reset, "Reset", false],
                  [cz_btn_cancel, "Cancel", false], [cz_btn_wear, "WEAR (Enter)", true] ];
    for (var _b = 0; _b < 4; _b++)
    {
        var _r = _btns[_b][0];
        var _hb = point_in_rectangle(_mx, _my, _r[0], _r[1], _r[2], _r[3]);
        if (_btns[_b][2])
        {
            draw_set_colour(_green);
            if (_hb) draw_set_colour(merge_colour(_green, c_white, 0.3));
        }
        else
        {
            draw_set_colour(make_colour_rgb(34, 42, 56));
            if (_hb) draw_set_colour(make_colour_rgb(48, 60, 78));
        }
        draw_roundrect_ext(_r[0], _r[1], _r[2], _r[3], 12, 12, false);
        draw_set_colour(c_white);
        if (_btns[_b][2]) draw_set_colour(_dark);
        draw_set_halign(fa_center);
        draw_text_transformed((_r[0] + _r[2]) / 2, _r[1] + 15, _btns[_b][1], 1.2, 1.2, 0);
        draw_set_halign(fa_left);
    }
    draw_set_colour(_grey);
    draw_text(100, 654, "W/S = choose row    A/D = change    click swatches / arrows / presets    Esc = cancel");
}

// ---------- skill tree (K) ----------
if (skills_open) kd_skilltree_draw();
if (pets_open)   kd_pets_panel_draw();
if (shop_open)   kd_shop_panel_draw();

// ---------- toasts (top centre) ----------
var _ty = 90;
for (var _i = 0; _i < array_length(global.kd_toasts); _i++)
{
    var _ts = global.kd_toasts[_i];
    var _a = min(1, _ts.t / 30);
    var _w2 = string_width(_ts.text) * 1.2 + 36;
    draw_set_alpha(0.85 * _a);
    draw_set_colour(_dark);
    draw_roundrect_ext(640 - _w2 / 2, _ty, 640 + _w2 / 2, _ty + 36, 10, 10, false);
    draw_set_alpha(_a);
    draw_set_colour(_ts.col);
    draw_set_halign(fa_center);
    draw_text_transformed(640, _ty + 8, _ts.text, 1.2, 1.2, 0);
    draw_set_halign(fa_left);
    _ty += 44;
}
draw_set_alpha(1);
draw_set_colour(c_white);


// ---------- circular aiming indicator (replaces the mouse cursor during gameplay) ----------
if (!global.ui_block)
{
    var _r = 9;
    var _armed = false;
    var _kick = 0;
    with (obj_gun)
    {
        if (equipped && visible) { _armed = true; _kick = recoil; }
    }
    _r += _kick * 1.5;
    draw_set_colour(make_colour_rgb(16, 20, 26));
    draw_set_alpha(0.7);
    draw_circle(_mx, _my, _r + 1, true);
    draw_circle(_mx, _my, _r - 1, true);
    draw_set_alpha(1);
    draw_set_colour(c_white);
    if (global.mouse_over_ui) draw_set_colour(_grey);
    draw_circle(_mx, _my, _r, true);
    if (_armed)
    {
        // aiming: small ticks + green centre dot
        draw_line_width(_mx - _r - 5, _my, _mx - _r + 2, _my, 2);
        draw_line_width(_mx + _r - 2, _my, _mx + _r + 5, _my, 2);
        draw_line_width(_mx, _my - _r - 5, _mx, _my - _r + 2, 2);
        draw_line_width(_mx, _my + _r - 2, _mx, _my + _r + 5, 2);
        draw_set_colour(_green);
        draw_circle(_mx, _my, 2, false);
    }
    else
    {
        draw_circle(_mx, _my, 1, false);
    }
    draw_set_colour(c_white);
}
