/// Skill tree (K) + foot trails.
///
///   CHIPS   the yellow coins you spend here. You start with 10 and earn more:
///           +1 for every knock-out, +3 for a level-up, +2 from the EXP item in boxes.
///   SKILLS  page 1 - permanent upgrades (health, movement, weapons, abilities)
///   TRAILS  page 2 - the dust trail behind your feet (spr_trail) in different colours
///
/// To add a skill: add a line to kd_skill_defs() and read it with kd_skill_has("key").

#macro KD_ST_X1 40
#macro KD_ST_Y1 72
#macro KD_ST_X2 1240
#macro KD_ST_Y2 696
#macro KD_ST_R  30

// trail tuning
#macro KD_TRAIL_FRAME_STEPS 15    // steps each of the 4 smoke frames stays on screen (bigger = slower animation)
#macro KD_TRAIL_GAP_DASH    5     // steps between puffs while dashing (walking = 1 puff per footstep)

// ---------------- data ----------------
function kd_skills_init()
{
    if (!variable_global_exists("kd_chips"))      global.kd_chips = 10;
    if (!variable_global_exists("kd_skills"))     global.kd_skills = { core : true, trail_dust : true };
    if (!variable_global_exists("kd_trail"))      global.kd_trail = "trail_dust";
    if (!variable_global_exists("kd_chip_flash")) global.kd_chip_flash = 0;
}

/// every node: key, page (0 skills / 1 trails), name, description, cost, the node it hangs from,
/// position on the screen (gx, gy), icon frame in spr_skill_icons, oct = square "capstone" node
function kd_skill_defs()
{
    static _defs = [
        // ----- page 0: skills -----
        { key : "core",   page : 0, name : "Builder Core",   desc : "Where every build starts.",                         cost : 0, req : "",       gx : 600,  gy : 400, icon : 0,  oct : true  },
        { key : "hp1",    page : 0, name : "Thick Skin",     desc : "+25 max health.",                                   cost : 3, req : "core",   gx : 460,  gy : 320, icon : 1,  oct : false },
        { key : "hp2",    page : 0, name : "Iron Body",      desc : "+25 more max health.",                              cost : 5, req : "hp1",    gx : 460,  gy : 200, icon : 2,  oct : false },
        { key : "regen",  page : 0, name : "Second Wind",    desc : "Health regenerates twice as fast.",                 cost : 4, req : "hp2",    gx : 600,  gy : 200, icon : 3,  oct : false },
        { key : "medic",  page : 0, name : "Field Medic",    desc : "Heal (H) restores 60 HP and recharges in 7 s.",     cost : 4, req : "hp1",    gx : 320,  gy : 320, icon : 4,  oct : true  },
        { key : "speed",  page : 0, name : "Quick Feet",     desc : "Walk and run 15% faster.",                          cost : 3, req : "core",   gx : 460,  gy : 480, icon : 5,  oct : false },
        { key : "jump",   page : 0, name : "Spring Legs",    desc : "Jump higher.",                                      cost : 3, req : "speed",  gx : 320,  gy : 480, icon : 6,  oct : true  },
        { key : "jetpack",page : 0, name : "Jetpack",        desc : "Hold SPACE in the air to fly. Fuel refills when you land.", cost : 5, req : "speed", gx : 460, gy : 610, icon : 13, oct : true },
        { key : "dash",   page : 0, name : "Hot Path",       desc : "Dash (R) recharges 40% faster.",                    cost : 4, req : "speed",  gx : 600,  gy : 580, icon : 7,  oct : false },
        { key : "dmg",    page : 0, name : "Sharp Shooter",  desc : "All weapons deal 20% more damage.",                 cost : 4, req : "core",   gx : 740,  gy : 400, icon : 8,  oct : false },
        { key : "rate",   page : 0, name : "Rapid Deploy",   desc : "Weapons fire and swing 15% faster.",                cost : 5, req : "dmg",    gx : 880,  gy : 330, icon : 9,  oct : false },
        { key : "blast",  page : 0, name : "Big Bang",       desc : "Explosions are 25% bigger.",                        cost : 4, req : "rate",   gx : 1020, gy : 400, icon : 10, oct : true  },
        { key : "shield", page : 0, name : "Firewall",       desc : "Shield (F) recharges in 5 s instead of 8.",         cost : 4, req : "dmg",    gx : 880,  gy : 500, icon : 12, oct : false },
        { key : "nades",  page : 0, name : "Deep Pockets",   desc : "Carry 3 more grenades (and get 3 now).",            cost : 3, req : "shield", gx : 1020, gy : 560, icon : 11, oct : true  },
        // ----- page 1: trails (click an unlocked trail to wear it) -----
        { key : "trail_dust",    page : 1, name : "Dust",        desc : "Plain dust behind your feet.",            cost : 0, req : "",            gx : 240,  gy : 380, icon : -1, oct : true },
        { key : "trail_neon",    page : 1, name : "Neon",        desc : "Glowing cyan trail.",                     cost : 3, req : "trail_dust",  gx : 400,  gy : 380, icon : -1, oct : true },
        { key : "trail_ember",   page : 1, name : "Ember",       desc : "Hot orange sparks.",                      cost : 3, req : "trail_neon",  gx : 560,  gy : 380, icon : -1, oct : true },
        { key : "trail_toxic",   page : 1, name : "Toxic",       desc : "KD green fumes.",                         cost : 3, req : "trail_ember", gx : 720,  gy : 380, icon : -1, oct : true },
        { key : "trail_gold",    page : 1, name : "Gold Rush",   desc : "Shiny golden dust.",                      cost : 5, req : "trail_toxic", gx : 880,  gy : 380, icon : -1, oct : true },
        { key : "trail_rainbow", page : 1, name : "Rainbow",     desc : "Every colour, always changing.",          cost : 8, req : "trail_gold",  gx : 1040, gy : 380, icon : -1, oct : true }
    ];
    return _defs;
}

function kd_skill_def(_key)
{
    var _d = kd_skill_defs();
    for (var _i = 0; _i < array_length(_d); _i++) if (_d[_i].key == _key) return _d[_i];
    return undefined;
}

function kd_skill_has(_key)
{
    if (!variable_global_exists("kd_skills")) return false;
    return variable_struct_exists(global.kd_skills, _key);
}

function kd_chips_add(_n)
{
    kd_skills_init();
    global.kd_chips += _n;
    global.kd_chip_flash = 30;
}

// ---------------- what the skills do ----------------
function kd_dmg_mult()   { return (kd_skill_has("dmg")  ? 1.2  : 1) * (1 + 0.2 * kd_item_count("hollow")); }
function kd_rate_mult()  { return (kd_skill_has("rate") ? 0.85 : 1) * power(0.85, kd_item_count("overclock")); }
function kd_blast_mult() { return kd_skill_has("blast") ? 1.25 : 1; }
function kd_regen_mult() { return kd_skill_has("regen") ? 2    : 1; }
function kd_shield_cd()  { return (kd_skill_has("shield") ? 5 : 8) * 60; }
function kd_heal_cd()    { return (kd_skill_has("medic") ? 7 : 10) * 60; }
function kd_heal_amount(){ return kd_skill_has("medic") ? 60 : 40; }
function kd_grenade_max(){ return 9 + (kd_skill_has("nades") ? 3 : 0); }

/// set the player's stats from the skills (called when the player is created and after buying)
function kd_skills_apply(_p)
{
    with (_p)
    {
        var _old = hp_max;
        hp_max = 100 + (kd_skill_has("hp1") ? 25 : 0) + (kd_skill_has("hp2") ? 25 : 0) + 25 * kd_item_count("heap");
        hp = clamp(hp + max(0, hp_max - _old), 0, hp_max);
        var _m = (kd_skill_has("speed") ? 1.15 : 1) * (1 + 0.1 * kd_item_count("coffee"));
        move_speed    = 1.2 * _m;
        run_speed     = 2.0 * _m;
        jump_speed    = 3.6 * (kd_skill_has("jump") ? 1.12 : 1);
        dash_cooldown = 0.45 * (kd_skill_has("dash") ? 0.6 : 1);
    }
}

/// try to unlock a node (or wear an unlocked trail)
function kd_skill_buy(_d)
{
    var _is_trail = (_d.page == 1);
    if (kd_skill_has(_d.key))
    {
        if (_is_trail && global.kd_trail != _d.key)
        {
            global.kd_trail = _d.key;
            kd_sfx(snd_holster, 0.05);
            kd_toast("Trail: " + _d.name, kd_trail_colour(_d.key, 0));
        }
        return false;
    }
    if (_d.req != "" && !kd_skill_has(_d.req))
    {
        kd_toast("Unlock " + kd_skill_def(_d.req).name + " first", make_colour_rgb(255, 110, 110));
        kd_sfx(snd_ui_close);
        return false;
    }
    if (global.kd_chips < _d.cost)
    {
        kd_toast("Not enough chips (" + string(_d.cost) + " needed). Knock people out or level up to earn more.", make_colour_rgb(255, 110, 110));
        kd_sfx(snd_ui_close);
        return false;
    }
    global.kd_chips -= _d.cost;
    variable_struct_set(global.kd_skills, _d.key, true);
    if (_d.key == "nades") global.kd_grenades = min(kd_grenade_max(), global.kd_grenades + 3);
    if (_is_trail) global.kd_trail = _d.key;
    with (obj_player) kd_skills_apply(id);
    kd_sfx(snd_confirm);
    kd_sfx(snd_levelup, 0);
    kd_toast("Unlocked: " + _d.name, make_colour_rgb(64, 226, 110));
    return true;
}

/// give every chip back
function kd_skills_reset()
{
    var _d = kd_skill_defs();
    var _back = 0;
    for (var _i = 0; _i < array_length(_d); _i++) if (kd_skill_has(_d[_i].key)) _back += _d[_i].cost;
    global.kd_chips += _back;
    global.kd_skills = { core : true, trail_dust : true };
    global.kd_trail = "trail_dust";
    global.kd_grenades = min(global.kd_grenades, kd_grenade_max());
    with (obj_player) kd_skills_apply(id);
    kd_sfx(snd_ui_close);
    kd_toast("Skill tree reset: " + string(_back) + " chips returned", make_colour_rgb(255, 214, 90));
}

// ---------------- the screen (runs inside obj_game) ----------------
function kd_skilltree_tab_rect(_i)
{
    var _x = 640 - 118 + _i * 122;
    return [_x, KD_ST_Y1 + 14, _x + 114, KD_ST_Y1 + 46];
}

function kd_skilltree_step(_mx, _my, _click)
{
    st_t += 1;
    if (st_pulse > 0) st_pulse -= 1;

    if (keyboard_check_pressed(vk_escape)) { skills_open = false; kd_sfx(snd_ui_close); return; }
    // 1 / 2 (or click a tab) = change page
    var _page = st_page;
    if (keyboard_check_pressed(ord("1"))) _page = 0;
    if (keyboard_check_pressed(ord("2"))) _page = 1;
    for (var _t = 0; _t < 2; _t++)
    {
        var _r = kd_skilltree_tab_rect(_t);
        if (_click && point_in_rectangle(_mx, _my, _r[0], _r[1], _r[2], _r[3])) _page = _t;
    }
    if (_page != st_page) { st_page = _page; kd_sfx(snd_ui_click); }

    // Q (or the button) = reset
    var _reset = keyboard_check_pressed(ord("Q"));
    if (_click && point_in_rectangle(_mx, _my, KD_ST_X2 - 150, KD_ST_Y2 - 54, KD_ST_X2 - 20, KD_ST_Y2 - 18)) _reset = true;
    if (_reset) { kd_skills_reset(); return; }

    // hover + click a node
    var _d = kd_skill_defs();
    var _hover = "";
    for (var _i = 0; _i < array_length(_d); _i++)
    {
        if (_d[_i].page != st_page) continue;
        if (point_distance(_mx, _my, _d[_i].gx, _d[_i].gy) <= KD_ST_R + 4) _hover = _d[_i].key;
    }
    if (_hover != st_hover) { st_hover = _hover; if (_hover != "") kd_sfx(snd_ui_click, 0.1, 0.4); }
    if (_click && st_hover != "")
    {
        if (kd_skill_buy(kd_skill_def(st_hover))) { st_pulse = 24; st_pulse_key = st_hover; }
    }
}

/// yellow chip coin
function kd_draw_chip(_x, _y, _r)
{
    draw_set_circle_precision(6);
    draw_set_colour(make_colour_rgb(120, 84, 10));
    draw_circle(_x, _y, _r + 2, false);
    draw_set_colour(make_colour_rgb(255, 214, 60));
    draw_circle(_x, _y, _r, false);
    draw_set_colour(make_colour_rgb(120, 84, 10));
    draw_circle(_x, _y, _r * 0.42, false);
    draw_set_circle_precision(24);
}

function kd_skilltree_draw()
{
    var _mx = device_mouse_x_to_gui(0);
    var _my = device_mouse_y_to_gui(0);
    var _navy  = make_colour_rgb(8, 30, 20);          // panel background (dark green)
    var _grid  = make_colour_rgb(40, 130, 80);
    var _cyan  = make_colour_rgb(64, 226, 110);        // main glow colour (KD green)
    var _blue  = make_colour_rgb(40, 170, 90);         // panel border
    var _purp  = make_colour_rgb(20, 120, 70);         // unlocked round node
    var _dim   = make_colour_rgb(50, 96, 70);          // locked lines / labels
    var _gold  = make_colour_rgb(255, 204, 64);
    var _white = c_white;
    draw_set_valign(fa_top);
    draw_set_halign(fa_left);

    // ---------- panel: navy with a faint grid ----------
    draw_set_alpha(0.55);
    draw_set_colour(c_black);
    draw_rectangle(0, 0, 1280, 720, false);
    draw_set_alpha(0.97);
    draw_set_colour(_navy);
    draw_roundrect_ext(KD_ST_X1, KD_ST_Y1, KD_ST_X2, KD_ST_Y2, 18, 18, false);
    draw_set_alpha(0.22);
    draw_set_colour(_grid);
    for (var _gx = KD_ST_X1 + 24; _gx < KD_ST_X2; _gx += 24) draw_line(_gx, KD_ST_Y1 + 4, _gx, KD_ST_Y2 - 4);
    for (var _gy = KD_ST_Y1 + 24; _gy < KD_ST_Y2; _gy += 24) draw_line(KD_ST_X1 + 4, _gy, KD_ST_X2 - 4, _gy);
    draw_set_alpha(0.5);
    for (var _gx = KD_ST_X1 + 96; _gx < KD_ST_X2; _gx += 144)
    {
        for (var _gy = KD_ST_Y1 + 72; _gy < KD_ST_Y2; _gy += 120)
        {
            draw_line(_gx - 4, _gy, _gx + 4, _gy);
            draw_line(_gx, _gy - 4, _gx, _gy + 4);
        }
    }
    draw_set_alpha(1);
    draw_set_colour(_blue);
    draw_roundrect_ext(KD_ST_X1, KD_ST_Y1, KD_ST_X2, KD_ST_Y2, 18, 18, true);
    draw_roundrect_ext(KD_ST_X1 + 1, KD_ST_Y1 + 1, KD_ST_X2 - 1, KD_ST_Y2 - 1, 18, 18, true);

    // ---------- page tabs:  [1] ---- SKILLS  TRAILS ---- [2] ----------
    var _ty = KD_ST_Y1 + 30;
    draw_set_colour(make_colour_rgb(40, 130, 80));
    draw_line(640 - 230, _ty, 640 + 230, _ty);
    var _names = ["SKILLS", "TRAILS"];
    for (var _t = 0; _t < 2; _t++)
    {
        var _r = kd_skilltree_tab_rect(_t);
        var _on = (_t == st_page);
        draw_set_colour(_on ? _cyan : make_colour_rgb(20, 84, 50));
        draw_roundrect_ext(_r[0], _r[1], _r[2], _r[3], 8, 8, false);
        draw_set_colour(_on ? _white : make_colour_rgb(40, 130, 80));
        draw_roundrect_ext(_r[0], _r[1], _r[2], _r[3], 8, 8, true);
        draw_set_halign(fa_center);
        draw_set_colour(_on ? make_colour_rgb(6, 40, 20) : make_colour_rgb(150, 230, 180));
        draw_text_transformed((_r[0] + _r[2]) / 2, _r[1] + 8, _names[_t], 0.85, 0.85, 0);
    }
    for (var _k = 0; _k < 2; _k++)
    {
        var _kx = 640 + (_k == 0 ? -252 : 252);
        draw_set_colour(_white);
        draw_roundrect_ext(_kx - 12, _ty - 12, _kx + 12, _ty + 12, 4, 4, false);
        draw_set_colour(_navy);
        draw_text_transformed(_kx, _ty - 9, string(_k + 1), 0.85, 0.85, 0);
    }
    draw_set_halign(fa_left);

    // ---------- section labels ----------
    draw_set_colour(_dim);
    if (st_page == 0)
    {
        draw_text_transformed(250, 196, "BODY", 0.9, 0.9, 0);
        draw_text_transformed(250, 560, "MOVEMENT", 0.9, 0.9, 0);
        draw_text_transformed(1010, 300, "ARSENAL", 0.9, 0.9, 0);
    }
    else
    {
        draw_set_halign(fa_center);
        draw_text_transformed(640, 240, "Trails follow your feet when you run, land and dash.", 0.9, 0.9, 0);
        draw_text_transformed(640, 266, "Click an unlocked trail to wear it.", 0.8, 0.8, 0);
        draw_set_halign(fa_left);
    }

    // ---------- connecting lines ----------
    var _d = kd_skill_defs();
    for (var _i = 0; _i < array_length(_d); _i++)
    {
        var _n = _d[_i];
        if (_n.page != st_page || _n.req == "") continue;
        var _p = kd_skill_def(_n.req);
        var _lit = kd_skill_has(_n.key);
        draw_set_alpha(_lit ? 1 : 0.45);
        draw_set_colour(_lit ? _cyan : _dim);
        if (!_lit && kd_skill_has(_n.req)) { draw_set_colour(_cyan); draw_set_alpha(0.5 + 0.3 * sin(st_t / 10)); }
        draw_line_width(_p.gx, _p.gy, _n.gx, _n.gy, 4);
    }
    draw_set_alpha(1);

    // ---------- nodes ----------
    for (var _i = 0; _i < array_length(_d); _i++)
    {
        var _n = _d[_i];
        if (_n.page != st_page) continue;
        var _own   = kd_skill_has(_n.key);
        var _avail = !_own && (_n.req == "" || kd_skill_has(_n.req));
        var _hov   = (st_hover == _n.key);
        var _worn  = (_n.page == 1 && global.kd_trail == _n.key);
        var _r = KD_ST_R + (_hov ? 3 : 0);
        if (st_pulse > 0 && st_pulse_key == _n.key) _r += st_pulse / 3;
        var _x = _n.gx;
        var _y = _n.gy;

        // glow behind unlocked / available nodes
        if (_own || _avail)
        {
            gpu_set_blendmode(bm_add);
            draw_circle_colour(_x, _y, _r + 16 + (_avail ? 3 * sin(st_t / 8) : 0), merge_colour(c_black, _worn ? _gold : _cyan, _own ? 0.45 : 0.25), c_black, false);
            gpu_set_blendmode(bm_normal);
        }
        // body
        var _fill = _own ? (_n.oct ? make_colour_rgb(30, 160, 100) : _purp) : make_colour_rgb(14, 48, 32);
        var _ring = _own ? _cyan : (_avail ? merge_colour(_dim, _cyan, 0.5 + 0.5 * sin(st_t / 8)) : _dim);
        if (_worn) _ring = _gold;
        if (_n.oct)
        {
            draw_set_colour(_ring);
            draw_roundrect_ext(_x - _r, _y - _r, _x + _r, _y + _r, 16, 16, false);
            draw_set_colour(_fill);
            draw_roundrect_ext(_x - _r + 4, _y - _r + 4, _x + _r - 4, _y + _r - 4, 12, 12, false);
        }
        else
        {
            draw_set_colour(_ring);
            draw_circle(_x, _y, _r, false);
            draw_set_colour(_fill);
            draw_circle(_x, _y, _r - 4, false);
        }
        // icon
        var _ia = _own ? 1 : (_avail ? 0.85 : 0.3);
        if (_n.icon >= 0)
        {
            draw_sprite_ext(spr_skill_icons, _n.icon, _x, _y, 2.5, 2.5, 0, _own || _avail ? c_white : make_colour_rgb(140, 180, 150), _ia);
        }
        else
        {
            // trail preview: the dust puff, animated, in the trail's colour
            var _tc = kd_trail_colour(_n.key, st_t + _i * 9);
            var _fr = (_own || _avail) ? ((st_t div 6) + _i) mod 4 : 0;
            draw_sprite_ext(spr_trail, _fr, _x - 2.5 * 3, _y - 18.5 * 3, 3, 3, 0, _tc, _ia);
        }
        // cost under nodes you do not own yet
        if (!_own)
        {
            draw_set_halign(fa_center);
            kd_draw_chip(_x - 12, _y + _r + 14, 6);
            draw_set_colour(global.kd_chips >= _n.cost ? _gold : make_colour_rgb(235, 90, 100));
            if (!_avail) draw_set_colour(_dim);
            draw_text_transformed(_x + 6, _y + _r + 5, string(_n.cost), 0.8, 0.8, 0);
            draw_set_halign(fa_left);
        }
        else if (_worn)
        {
            draw_set_halign(fa_center);
            draw_set_colour(_gold);
            draw_text_transformed(_x, _y + _r + 5, "ON", 0.75, 0.75, 0);
            draw_set_halign(fa_left);
        }
    }

    // ---------- chips (bottom left) + reset (bottom right) ----------
    draw_set_colour(_white);
    draw_text_transformed(KD_ST_X1 + 26, KD_ST_Y2 - 74, string(global.kd_chips), 1, 1, 0);
    kd_draw_chip(KD_ST_X1 + 38, KD_ST_Y2 - 34, 11);
    draw_set_colour(_dim);
    draw_text_transformed(KD_ST_X1 + 62, KD_ST_Y2 - 44, "chips:  +1 knock-out   +3 level-up   +2 EXP box", 0.7, 0.7, 0);

    var _bx1 = KD_ST_X2 - 150;
    var _by1 = KD_ST_Y2 - 54;
    var _bh = point_in_rectangle(_mx, _my, _bx1, _by1, KD_ST_X2 - 20, KD_ST_Y2 - 18);
    draw_set_colour(make_colour_rgb(12, 44, 28));
    draw_roundrect_ext(_bx1, _by1, KD_ST_X2 - 20, KD_ST_Y2 - 18, 8, 8, false);
    draw_set_colour(_bh ? _white : make_colour_rgb(64, 190, 110));
    draw_roundrect_ext(_bx1, _by1, KD_ST_X2 - 20, KD_ST_Y2 - 18, 8, 8, true);
    draw_set_colour(_white);
    draw_roundrect_ext(_bx1 + 10, _by1 + 7, _bx1 + 32, _by1 + 29, 4, 4, false);
    draw_set_colour(_navy);
    draw_text_transformed(_bx1 + 15, _by1 + 10, "Q", 0.8, 0.8, 0);
    draw_set_colour(_bh ? _white : make_colour_rgb(140, 240, 170));
    draw_text_transformed(_bx1 + 44, _by1 + 9, "RESET", 0.9, 0.9, 0);

    draw_set_halign(fa_center);
    draw_set_colour(_dim);
    draw_text_transformed(640, KD_ST_Y2 - 34, "K or ESC = close", 0.75, 0.75, 0);
    draw_set_halign(fa_left);

    // ---------- tooltip for the node under the mouse ----------
    if (st_hover != "")
    {
        var _n = kd_skill_def(st_hover);
        var _own = kd_skill_has(_n.key);
        var _avail = !_own && (_n.req == "" || kd_skill_has(_n.req));
        var _w = 330;
        var _dh = string_height_ext(_n.desc, 22, (_w - 28) / 0.8) * 0.8;
        var _h = 14 + 28 + _dh + 10 + 22 + 12;
        var _tx = clamp(_n.gx + KD_ST_R + 18, KD_ST_X1 + 8, KD_ST_X2 - _w - 8);
        if (_n.gx > 900) _tx = _n.gx - KD_ST_R - 18 - _w;
        var _tyy = clamp(_n.gy - _h / 2, KD_ST_Y1 + 60, KD_ST_Y2 - _h - 60);
        draw_set_alpha(0.96);
        draw_set_colour(make_colour_rgb(4, 20, 12));
        draw_roundrect_ext(_tx, _tyy, _tx + _w, _tyy + _h, 10, 10, false);
        draw_set_alpha(1);
        draw_set_colour(_cyan);
        draw_roundrect_ext(_tx, _tyy, _tx + _w, _tyy + _h, 10, 10, true);
        draw_text_transformed(_tx + 14, _tyy + 12, _n.name, 1.1, 1.1, 0);
        draw_set_colour(_white);
        draw_text_ext_transformed(_tx + 14, _tyy + 42, _n.desc, 22, (_w - 28) / 0.8, 0.8, 0.8, 0);
        var _line = "";
        var _lc = _gold;
        if (_own)
        {
            _line = "Unlocked";
            _lc = make_colour_rgb(64, 226, 110);
            if (_n.page == 1) _line = (global.kd_trail == _n.key) ? "Wearing this trail" : "Click to wear";
        }
        else if (!_avail)
        {
            _line = "Needs: " + kd_skill_def(_n.req).name;
            _lc = make_colour_rgb(235, 90, 100);
        }
        else if (global.kd_chips < _n.cost)
        {
            _line = "Costs " + string(_n.cost) + " chips - you have " + string(global.kd_chips);
            _lc = make_colour_rgb(235, 90, 100);
        }
        else _line = "Click to unlock  -  " + string(_n.cost) + " chips";
        draw_set_colour(_lc);
        draw_text_transformed(_tx + 14, _tyy + 42 + _dh + 10, _line, 0.8, 0.8, 0);
    }
    draw_set_colour(c_white);
    draw_set_alpha(1);
}

/// small "[K] Skills  (o) 12" pill under the ability buttons
function kd_skill_hud_draw()
{
    kd_skills_init();
    var _x1 = 16;
    var _y1 = 206;
    var _w  = 212;
    var _f  = global.kd_chip_flash / 30;
    draw_set_alpha(0.85);
    draw_set_colour(merge_colour(make_colour_rgb(18, 22, 30), make_colour_rgb(120, 90, 10), _f));
    draw_roundrect_ext(_x1, _y1, _x1 + _w, _y1 + 30, 10, 10, false);
    draw_set_alpha(1);
    draw_set_colour(merge_colour(make_colour_rgb(160, 168, 180), make_colour_rgb(255, 214, 60), _f));
    draw_roundrect_ext(_x1, _y1, _x1 + _w, _y1 + 30, 10, 10, true);
    draw_roundrect_ext(_x1 + 6, _y1 + 5, _x1 + 26, _y1 + 25, 6, 6, true);
    draw_set_halign(fa_center);
    draw_text_transformed(_x1 + 16, _y1 + 7, "K", 0.8, 0.8, 0);
    draw_set_halign(fa_left);
    draw_text_transformed(_x1 + 34, _y1 + 7, "Skill tree", 0.8, 0.8, 0);
    kd_draw_chip(_x1 + _w - 58, _y1 + 15, 7);
    draw_set_colour(make_colour_rgb(255, 214, 60));
    draw_text_transformed(_x1 + _w - 44, _y1 + 7, string(global.kd_chips), 0.8, 0.8, 0);
    draw_set_colour(c_white);
}

// ---------------- foot trails (spr_trail) ----------------
function kd_trail_colour(_key, _t)
{
    switch (_key)
    {
        case "trail_neon":    return make_colour_rgb(90, 236, 250);
        case "trail_ember":   return make_colour_rgb(255, 150, 60);
        case "trail_toxic":   return make_colour_rgb(100, 240, 130);
        case "trail_gold":    return make_colour_rgb(255, 220, 100);
        case "trail_rainbow": return make_colour_hsv((_t * 5) mod 256, 190, 255);
    }
    return make_colour_rgb(214, 214, 220);   // dust
}

/// one puff at a character's feet (_dir = the way they are moving, _size 1 = normal)
function kd_trail_puff(_x, _feet_y, _dir, _size, _depth)
{
    kd_skills_init();
    var _t = instance_create_depth(_x - _dir * 2.5 * _size, _feet_y - 23 * _size, _depth, obj_trail);
    _t.image_xscale = _dir * _size;
    _t.image_yscale = _size;
    _t.col  = kd_trail_colour(global.kd_trail, current_time / 16);
    _t.glow = (global.kd_trail != "trail_dust");
    return _t;
}

/// call at the end of the player's Step: leaves puffs when running, landing and dashing
function kd_trail_step(_p)
{
    with (_p)
    {
        trail_t += 1;
        var _dir = (x != xprevious) ? sign(x - xprevious) : facing;
        // walking / running: one puff per footstep (the two "foot down" frames of the walk cycle)
        if (mode == "normal" && on_ground && state == "walk" && anim_frame != trail_frame && (anim_frame == 1 || anim_frame == 4))
        {
            kd_trail_puff(x - _dir * 6, y, _dir, 1, depth + 1);
        }
        trail_frame = anim_frame;
        // dashing: a few puffs along the dash
        if (mode == "dash" && trail_t >= KD_TRAIL_GAP_DASH)
        {
            trail_t = 0;
            kd_trail_puff(x - _dir * 6, y, _dir, 1.2, depth + 1);
        }
        // landing: a puff to each side
        if (mode == "normal" && on_ground && !trail_ground)
        {
            kd_trail_puff(x - 5, y, 1, 1.1, depth + 1);
            kd_trail_puff(x + 5, y, -1, 1.1, depth + 1);
        }
        trail_ground = on_ground || mode != "normal";
    }
}
