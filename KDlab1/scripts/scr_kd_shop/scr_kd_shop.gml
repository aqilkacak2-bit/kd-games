/// ROBOT PET BAY (Character Lab) + KD ITEM SHOP (Training Range)
///
///   Pet Bay   pick one companion for free. It follows you in every room and fights in the Neon Dungeon.
///   Shop      spend chips on run items. They go in your backpack and you start your next dungeon run with them.

// ================================================================ data
function kd_companion()
{
    return variable_global_exists("kd_companion") ? global.kd_companion : "";
}

function kd_backpack()
{
    if (!variable_global_exists("kd_backpack") || !is_struct(global.kd_backpack)) global.kd_backpack = {};
    return global.kd_backpack;
}

function kd_backpack_count(_key)
{
    var _b = kd_backpack();
    return variable_struct_exists(_b, _key) ? variable_struct_get(_b, _key) : 0;
}

/// chips for each item in the KD Item Shop
function kd_shop_price(_key)
{
    switch (_key)
    {
        case "coffee":   return 3;
        case "heap":     return 4;
        case "bouncy":   return 5;
        case "fire":     return 5;
        case "cryo":     return 5;
        case "multi":    return 8;
        case "pet":      return 6;
        case "laserbot": case "shieldbot": case "rocketbot": case "coinbot": return 8;
    }
    return 6;
}

/// the pets you can pick in the Pet Bay: [kind, name, what it does, sprite frame (-1 = bug)]
function kd_pet_choices()
{
    static _c = [
        ["",          "No pet",     "Go solo.",                                         -2],
        ["pet",       "Bug Pet",    "Shoots little green bullets at enemies.",          -1],
        ["laserbot",  "Laser Bot",  "Zaps the nearest enemy with a laser.",              0],
        ["shieldbot", "Shield Bot", "Circles you and blocks enemy bullets.",             2],
        ["rocketbot", "Rocket Bot", "Fires homing mini rockets that never hurt you.",    4],
        ["coinbot",   "Coin Bot",   "Flies off to grab coins and brings them to you.",   6]
    ];
    return _c;
}

/// remove every pet and create the right ones again (companion + run items)
function kd_pets_refresh()
{
    with (obj_pet) instance_destroy();
    kd_pets_sync();
}

// small drawing helpers shared by both panels
function kd_neon_panel(_x1, _y1, _x2, _y2, _title)
{
    draw_set_alpha(0.55);
    draw_set_colour(c_black);
    draw_rectangle(0, 0, 1280, 720, false);
    draw_set_alpha(0.97);
    draw_set_colour(make_colour_rgb(8, 30, 20));
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 18, 18, false);
    draw_set_alpha(0.18);
    draw_set_colour(make_colour_rgb(40, 130, 80));
    for (var _gx = _x1 + 24; _gx < _x2; _gx += 24) draw_line(_gx, _y1 + 4, _gx, _y2 - 4);
    for (var _gy = _y1 + 24; _gy < _y2; _gy += 24) draw_line(_x1 + 4, _gy, _x2 - 4, _gy);
    draw_set_alpha(1);
    draw_set_colour(make_colour_rgb(40, 170, 90));
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 18, 18, true);
    draw_roundrect_ext(_x1 + 1, _y1 + 1, _x2 - 1, _y2 - 1, 18, 18, true);
    draw_set_halign(fa_center);
    draw_set_colour(make_colour_rgb(64, 226, 110));
    kd_title_text((_x1 + _x2) / 2, _y1 + 18, _title, 1.4, 1.4, 0);
    draw_set_halign(fa_left);
}

function kd_neon_card(_x1, _y1, _x2, _y2, _on, _hover, _col)
{
    if (_on || _hover)
    {
        gpu_set_blendmode(bm_add);
        draw_set_alpha(_on ? 0.35 : 0.2);
        draw_set_colour(_col);
        draw_roundrect_ext(_x1 - 4, _y1 - 4, _x2 + 4, _y2 + 4, 16, 16, false);
        draw_set_alpha(1);
        gpu_set_blendmode(bm_normal);
    }
    draw_set_colour(_on ? make_colour_rgb(20, 80, 50) : make_colour_rgb(14, 48, 32));
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 12, 12, false);
    draw_set_colour(_on ? _col : (_hover ? merge_colour(_col, c_white, 0.3) : make_colour_rgb(50, 96, 70)));
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 12, 12, true);
}

// ================================================================ ROBOT PET BAY
#macro KD_PB_CW 116
#macro KD_PB_GAP 14
function kd_pets_card_x(_i)
{
    var _n = array_length(kd_pet_choices());
    return 640 - (_n * KD_PB_CW + (_n - 1) * KD_PB_GAP) / 2 + _i * (KD_PB_CW + KD_PB_GAP);
}

function kd_pets_open()
{
    pets_open = true;
    pb_t = 0;
    var _c = kd_pet_choices();
    pb_sel = 0;
    for (var _i = 0; _i < array_length(_c); _i++) if (_c[_i][0] == kd_companion()) pb_sel = _i;
    kd_sfx(snd_ui_open);
}

function kd_pets_choose(_i)
{
    var _c = kd_pet_choices();
    global.kd_companion = _c[_i][0];
    kd_pets_refresh();
    kd_sfx(snd_confirm);
    if (_c[_i][0] == "") kd_toast("No pet - going solo", c_white);
    else
    {
        kd_toast(_c[_i][1] + " joined you!  " + _c[_i][2], make_colour_rgb(64, 226, 110));
        with (obj_player) kd_vfx_powerup(id);
    }
}

function kd_pets_panel_step(_mx, _my, _click)
{
    pb_t += 1;
    var _c = kd_pet_choices();
    var _n = array_length(_c);
    if (keyboard_check_pressed(vk_escape)) { pets_open = false; kd_sfx(snd_ui_close); return; }
    if (keyboard_check_pressed(ord("A")) || keyboard_check_pressed(vk_left))  { pb_sel = (pb_sel - 1 + _n) mod _n; kd_sfx(snd_ui_click); }
    if (keyboard_check_pressed(ord("D")) || keyboard_check_pressed(vk_right)) { pb_sel = (pb_sel + 1) mod _n; kd_sfx(snd_ui_click); }
    for (var _i = 0; _i < _n; _i++)
    {
        var _x1 = kd_pets_card_x(_i);
        if (point_in_rectangle(_mx, _my, _x1, 200, _x1 + KD_PB_CW, 420))
        {
            if (pb_sel != _i) { pb_sel = _i; kd_sfx(snd_ui_click, 0.1, 0.4); }
            if (_click) { kd_pets_choose(_i); pets_open = false; return; }
        }
    }
    if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space) || keyboard_check_pressed(ord("E")))
    {
        kd_pets_choose(pb_sel);
        pets_open = false;
    }
}

function kd_pets_panel_draw()
{
    var _c = kd_pet_choices();
    kd_neon_panel(200, 110, 1080, 560, "ROBOT PET BAY");
    draw_set_halign(fa_center);
    draw_set_colour(make_colour_rgb(140, 200, 160));
    draw_text_transformed(640, 160, "Pick a companion. It follows you everywhere and fights in the Neon Dungeon.", 0.8, 0.8, 0);
    for (var _i = 0; _i < array_length(_c); _i++)
    {
        var _x1 = kd_pets_card_x(_i);
        var _cx = _x1 + KD_PB_CW / 2;
        var _on = (_c[_i][0] == kd_companion());
        var _hv = (_i == pb_sel);
        var _col = make_colour_rgb(64, 226, 110);
        kd_neon_card(_x1, 200, _x1 + KD_PB_CW, 420, _on, _hv, _col);
        var _bob = sin(pb_t / 12 + _i) * 4 * (_hv ? 1 : 0.4);
        var _fr = _c[_i][3];
        if (_fr >= 0) draw_sprite_ext(spr_robot_pets, _fr + (pb_t div 10) mod 2, _cx, 290 + _bob, 5, 5, 0, c_white, 1);
        else if (_fr == -1) draw_sprite_ext(spr_run_items, 9, _cx, 290 + _bob, 4, 4, 0, c_white, 1);
        else
        {
            draw_set_colour(make_colour_rgb(50, 96, 70));
            draw_circle(_cx, 290, 26, true);
            draw_line(_cx - 18, 308, _cx + 18, 272);
        }
        draw_set_colour(_hv ? c_white : make_colour_rgb(170, 220, 190));
        draw_text_transformed(_cx, 352, _c[_i][1], 0.85, 0.85, 0);
        if (_on)
        {
            draw_set_colour(make_colour_rgb(255, 214, 60));
            draw_text_transformed(_cx, 386, "SELECTED", 0.7, 0.7, 0);
        }
    }
    var _d = _c[pb_sel];
    draw_set_colour(c_white);
    draw_text_transformed(640, 450, _d[1] + "  -  " + _d[2], 0.95, 0.95, 0);
    draw_set_colour(make_colour_rgb(50, 140, 90));
    draw_text_transformed(640, 512, "click or E = choose     A / D = browse     ESC = close     (free, change any time)", 0.7, 0.7, 0);
    draw_set_halign(fa_left);
    draw_set_colour(c_white);
}

// ================================================================ KD ITEM SHOP
#macro KD_SH_COLS 7
#macro KD_SH_CW 118
#macro KD_SH_GAP 12
function kd_shop_card_pos(_i)
{
    var _x0 = 640 - (KD_SH_COLS * KD_SH_CW + (KD_SH_COLS - 1) * KD_SH_GAP) / 2;
    return [_x0 + (_i mod KD_SH_COLS) * (KD_SH_CW + KD_SH_GAP), 180 + (_i div KD_SH_COLS) * (KD_SH_CW + KD_SH_GAP)];
}

function kd_shop_open()
{
    shop_open = true;
    sh_t = 0;
    sh_hover = -1;
    kd_sfx(snd_ui_open);
}

function kd_shop_buy(_i)
{
    var _d = kd_run_items();
    var _it = _d[_i];
    var _p = kd_shop_price(_it.key);
    kd_skills_init();
    if (global.kd_chips < _p)
    {
        kd_toast("Not enough chips (" + string(_p) + " needed). Earn them in the Neon Dungeon.", make_colour_rgb(255, 110, 110));
        kd_sfx(snd_ui_close);
        return;
    }
    global.kd_chips -= _p;
    variable_struct_set(kd_backpack(), _it.key, kd_backpack_count(_it.key) + 1);
    sh_pulse = 20;
    sh_pulse_i = _i;
    kd_sfx(snd_confirm);
    kd_sfx_p(snd_pickup, 1.2, 0.05, 0.6);
    kd_toast("Bought " + _it.name + " - it's in your backpack for the next run", _it.col);
}

function kd_shop_panel_step(_mx, _my, _click)
{
    sh_t += 1;
    if (sh_pulse > 0) sh_pulse -= 1;
    if (keyboard_check_pressed(vk_escape) || keyboard_check_pressed(ord("E"))) { shop_open = false; kd_sfx(snd_ui_close); return; }
    var _d = kd_run_items();
    var _h = -1;
    for (var _i = 0; _i < array_length(_d); _i++)
    {
        var _p = kd_shop_card_pos(_i);
        if (point_in_rectangle(_mx, _my, _p[0], _p[1], _p[0] + KD_SH_CW, _p[1] + KD_SH_CW)) _h = _i;
    }
    if (_h != sh_hover) { sh_hover = _h; if (_h >= 0) kd_sfx(snd_ui_click, 0.1, 0.35); }
    if (_click && sh_hover >= 0) kd_shop_buy(sh_hover);
}

function kd_shop_panel_draw()
{
    var _d = kd_run_items();
    kd_neon_panel(80, 90, 1200, 650, "KD ITEM SHOP");
    // chips (top right of the panel)
    kd_draw_chip(1110, 120, 10);
    draw_set_colour(make_colour_rgb(255, 214, 60));
    draw_text_transformed(1126, 110, string(global.kd_chips), 1, 1, 0);
    draw_set_halign(fa_center);
    draw_set_colour(make_colour_rgb(140, 200, 160));
    draw_text_transformed(640, 146, "Items you buy go in your backpack. You start your next Neon Dungeon run with them.", 0.78, 0.78, 0);
    draw_set_halign(fa_left);

    for (var _i = 0; _i < array_length(_d); _i++)
    {
        var _it = _d[_i];
        var _p = kd_shop_card_pos(_i);
        var _x1 = _p[0];
        var _y1 = _p[1];
        var _hv = (_i == sh_hover);
        var _price = kd_shop_price(_it.key);
        var _can = (global.kd_chips >= _price);
        var _grow = (sh_pulse > 0 && sh_pulse_i == _i) ? sh_pulse / 5 : 0;
        kd_neon_card(_x1 - _grow, _y1 - _grow, _x1 + KD_SH_CW + _grow, _y1 + KD_SH_CW + _grow, false, _hv, _it.col);
        var _bob = _hv ? sin(sh_t / 8) * 3 : 0;
        draw_sprite_ext(spr_run_items, _it.icon, _x1 + KD_SH_CW / 2, _y1 + 44 + _bob, 3.5, 3.5, 0, c_white, _can ? 1 : 0.55);
        draw_set_halign(fa_center);
        draw_set_colour(_hv ? c_white : make_colour_rgb(170, 220, 190));
        draw_text_transformed(_x1 + KD_SH_CW / 2, _y1 + 74, _it.name, 0.62, 0.62, 0);
        kd_draw_chip(_x1 + KD_SH_CW / 2 - 12, _y1 + 104, 6);
        draw_set_colour(_can ? make_colour_rgb(255, 214, 60) : make_colour_rgb(235, 90, 100));
        draw_text_transformed(_x1 + KD_SH_CW / 2 + 8, _y1 + 95, string(_price), 0.75, 0.75, 0);
        draw_set_halign(fa_left);
        var _n = kd_backpack_count(_it.key);
        if (_n > 0)
        {
            draw_set_colour(make_colour_rgb(64, 226, 110));
            draw_roundrect_ext(_x1 + KD_SH_CW - 34, _y1 + 6, _x1 + KD_SH_CW - 6, _y1 + 26, 6, 6, false);
            draw_set_colour(make_colour_rgb(6, 40, 20));
            draw_set_halign(fa_center);
            draw_text_transformed(_x1 + KD_SH_CW - 20, _y1 + 8, "x" + string(_n), 0.6, 0.6, 0);
            draw_set_halign(fa_left);
        }
    }

    // description of the hovered item
    var _by = 460;
    if (sh_hover >= 0)
    {
        var _h = _d[sh_hover];
        var _pr = kd_shop_price(_h.key);
        draw_sprite_ext(spr_run_items, _h.icon, 150, _by + 30, 3, 3, 0, c_white, 1);
        draw_set_colour(_h.col);
        kd_title_text(190, _by + 6, _h.name, 1.2, 1.2, 0);
        draw_set_colour(c_white);
        draw_text_transformed(190, _by + 36, _h.desc, 0.85, 0.85, 0);
        draw_set_colour((global.kd_chips >= _pr) ? make_colour_rgb(64, 226, 110) : make_colour_rgb(235, 90, 100));
        draw_text_transformed(190, _by + 62, (global.kd_chips >= _pr) ? "Click to buy - " + string(_pr) + " chips" : "Needs " + string(_pr) + " chips - you have " + string(global.kd_chips), 0.8, 0.8, 0);
    }
    // backpack
    var _bx = 120;
    var _byy = 572;
    draw_set_colour(make_colour_rgb(140, 200, 160));
    draw_text_transformed(_bx, _byy, "Backpack:", 0.8, 0.8, 0);
    _bx += 100;
    var _any = false;
    for (var _k = 0; _k < array_length(_d); _k++)
    {
        var _n2 = kd_backpack_count(_d[_k].key);
        if (_n2 <= 0) continue;
        _any = true;
        draw_sprite_ext(spr_run_items, _d[_k].icon, _bx + 12, _byy + 10, 1.5, 1.5, 0, c_white, 1);
        draw_set_colour(c_white);
        if (_n2 > 1) draw_text_transformed(_bx + 22, _byy + 8, "x" + string(_n2), 0.55, 0.55, 0);
        _bx += 44;
    }
    if (!_any)
    {
        draw_set_colour(make_colour_rgb(50, 96, 70));
        draw_text_transformed(_bx, _byy, "empty", 0.8, 0.8, 0);
    }
    draw_set_halign(fa_right);
    draw_set_colour(make_colour_rgb(50, 140, 90));
    draw_text_transformed(1170, 612, "click = buy     E / ESC = close", 0.7, 0.7, 0);
    draw_set_halign(fa_left);
    draw_set_colour(c_white);
}
