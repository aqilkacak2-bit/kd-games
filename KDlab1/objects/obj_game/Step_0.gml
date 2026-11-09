/// obj_game - Step
var _mx = device_mouse_x_to_gui(0);
var _my = device_mouse_y_to_gui(0);
var _click = mouse_check_button_pressed(mb_left);
var _was_blocked = global.ui_block;
blink += 1;
select_t += 1;

// is the mouse over a HUD button? (then the gun does not fire)
global.mouse_over_ui = point_in_rectangle(_mx, _my, discord_btn[0], discord_btn[1], gear_btn[2], gear_btn[3])
                    || (kd_showcase_hovered() != noone);     // showcase links are clickable

// shader flash fades out
if (global.kd_flash > 0) global.kd_flash = max(0, global.kd_flash - 0.04);

// F2 = next shader look (any time you are not typing)
if (keyboard_check_pressed(vk_f2) && !chat_typing && !name_editing)
{
    global.kd_shader = (global.kd_shader + 1) mod 4;
    kd_toast("Shader: " + shader_names[global.kd_shader] + "   (F2)", c_white);
    kd_sfx(snd_ui_click);
}

// M = lab map: corner -> big -> hidden
if (keyboard_check_pressed(ord("M")) && !chat_typing && !name_editing)
{
    global.kd_minimap = (global.kd_minimap + 1) mod 3;
    kd_sfx(snd_ui_click);
}

// screen shake from rockets / explosions (moves the view port a few pixels)
if (global.kd_shake > 0)
{
    global.kd_shake = max(0, global.kd_shake - 0.6);
    var _amp = global.kd_shake;
    view_set_xport(0, round(random_range(-_amp, _amp)));
    view_set_yport(0, round(random_range(-_amp, _amp)));
    if (global.kd_shake == 0) { view_set_xport(0, 0); view_set_yport(0, 0); }
}

// daily login bonus shortly after start
if (alarm_daily > 0)
{
    alarm_daily -= 1;
    if (alarm_daily == 0) kd_add_exp(10, "Daily login");
}

// ---------- timers ----------
for (var _i = array_length(global.kd_toasts) - 1; _i >= 0; _i--)
{
    global.kd_toasts[_i].t -= 1;
    if (global.kd_toasts[_i].t <= 0) array_delete(global.kd_toasts, _i, 1);
}
if (global.kd_chat_log_timer > 0) global.kd_chat_log_timer -= 1;
with (obj_player) if (bubble_timer > 0) bubble_timer -= 1;
with (obj_kd_npc) if (bubble_timer > 0) bubble_timer -= 1;

// NPC replies (small delay so it feels like they are typing)
for (var _i = array_length(pending) - 1; _i >= 0; _i--)
{
    var _p = pending[_i];
    _p.delay -= 1;
    if (_p.delay <= 0)
    {
        if (instance_exists(_p.npc))
        {
            _p.npc.bubble_text  = _p.text;
            _p.npc.bubble_timer = global.kd_bubble_time * 60;
            kd_chat_add(_p.npc.npc_name, _p.text, make_colour_rgb(150, 200, 255));
            kd_sfx(snd_chat_reply, 0.08);
        }
        array_delete(pending, _i, 1);
    }
}

// ================= INPUT =================
if (name_editing)
{
    // typing a new player name (from the settings panel)
    chat_text = string_copy(keyboard_string, 1, 16);
    keyboard_string = chat_text;
    if (keyboard_check_pressed(vk_enter))
    {
        if (string_replace_all(chat_text, " ", "") != "") global.kd_name = chat_text;
        name_editing = false;
        keyboard_string = "";
    }
    else if (keyboard_check_pressed(vk_escape))
    {
        name_editing = false;
        keyboard_string = "";
    }
}
else if (chat_typing)
{
    chat_text = string_copy(keyboard_string, 1, 60);
    keyboard_string = chat_text;

    if (keyboard_check_pressed(vk_enter))
    {
        chat_typing = false;
        keyboard_string = "";
        if (string_replace_all(chat_text, " ", "") != "")
        {
            var _msg = chat_text;
            with (obj_player)
            {
                bubble_text  = _msg;
                bubble_timer = global.kd_bubble_time * 60;
            }
            kd_chat_add(global.kd_name, _msg, c_white);
            kd_sfx(snd_chat_send, 0.03);
            if (kd_discord_bridge_on()) discord_req = kd_discord_post(global.kd_name, _msg);

            if (first_chat)
            {
                first_chat = false;
                kd_add_exp(10, "Said hi to the community");
            }

            // nearest NPC answers
            if (global.kd_npc_replies && instance_exists(obj_player))
            {
                var _npc = instance_nearest(obj_player.x, obj_player.y, obj_kd_npc);
                if (_npc != noone && point_distance(_npc.x, _npc.y, obj_player.x, obj_player.y) < 110)
                {
                    array_push(pending, { npc : _npc, text : kd_npc_reply(_msg, _npc.npc_name), delay : 45 });
                }
            }
        }
        chat_text = "";
    }
    else if (keyboard_check_pressed(vk_escape) || (_click && !point_in_rectangle(_mx, _my, 16, 720 - 64, 660, 720 - 16)))
    {
        chat_typing = false;
        chat_text = "";
        keyboard_string = "";
    }
}
else if (settings_open)
{
    if (keyboard_check_pressed(vk_escape)) { settings_open = false; kd_sfx(snd_ui_close); }
    if (_click)
    {
        for (var _r = 0; _r < array_length(set_rows); _r++)
        {
            var _bx1 = set_x1 + set_w - 190;
            var _by1 = set_y1 + 76 + _r * 46;
            if (point_in_rectangle(_mx, _my, _bx1, _by1, _bx1 + 160, _by1 + 34))
            {
                kd_sfx(snd_ui_click);
                switch (set_rows[_r])
                {
                    case "name":
                        name_editing = true;
                        keyboard_string = global.kd_name;
                        chat_text = global.kd_name;
                        break;
                    case "bubbles": global.kd_show_bubbles = !global.kd_show_bubbles; break;
                    case "log":     global.kd_show_log = !global.kd_show_log; break;
                    case "time":
                        if (global.kd_bubble_time == 3) global.kd_bubble_time = 5;
                        else if (global.kd_bubble_time == 5) global.kd_bubble_time = 8;
                        else global.kd_bubble_time = 3;
                        break;
                    case "npc":     global.kd_npc_replies = !global.kd_npc_replies; break;
                    case "shader":  global.kd_shader = (global.kd_shader + 1) mod 4; break;
                    case "sfx":
                        global.kd_sfx_vol -= 0.25;
                        if (global.kd_sfx_vol < 0) global.kd_sfx_vol = 1;
                        audio_sound_gain(snd_lab_hum, 0.35 * global.kd_sfx_vol, 0);
                        kd_ambience_update();
                        break;
                    case "hum":     global.kd_hum_on = !global.kd_hum_on; kd_ambience_update(); break;
                    case "close":   settings_open = false; break;
                }
            }
        }
        // click on the gear again also closes
        if (point_in_rectangle(_mx, _my, gear_btn[0], gear_btn[1], gear_btn[2], gear_btn[3])) settings_open = false;
    }
}
else if (select_open)
{
    // ---------- Character Customiser ----------
    var _slots = kd_custom_slots();
    var _ns = array_length(_slots);
    var _confirm = false;
    var _cancel  = false;

    if (keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W")) || keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S"))
        || keyboard_check_pressed(vk_left) || keyboard_check_pressed(ord("A")) || keyboard_check_pressed(vk_right) || keyboard_check_pressed(ord("D"))
        || keyboard_check_pressed(ord("R")) || _click) kd_sfx(snd_ui_click, 0.1);
    if (keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W")))   cz_row = (cz_row - 1 + _ns) mod _ns;
    if (keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S"))) cz_row = (cz_row + 1) mod _ns;
    if (keyboard_check_pressed(vk_left) || keyboard_check_pressed(ord("A")))  kd_look_step(cz_look, _slots[cz_row], -1);
    if (keyboard_check_pressed(vk_right) || keyboard_check_pressed(ord("D"))) kd_look_step(cz_look, _slots[cz_row], 1);
    if (keyboard_check_pressed(ord("R"))) cz_look = kd_look_random();
    if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(ord("E"))) _confirm = true;
    if (keyboard_check_pressed(vk_escape)) _cancel = true;

    if (_click)
    {
        // rows: arrows for styles, swatches for colours
        for (var _i = 0; _i < _ns; _i++)
        {
            var _ry = cz_rows_y + _i * cz_row_h;
            if (!point_in_rectangle(_mx, _my, cz_rows_x1, _ry, cz_rows_x2, _ry + cz_row_h - 6)) continue;
            cz_row = _i;
            var _sl = _slots[_i];
            if (is_array(_sl.cols))
            {
                for (var _j = 0; _j < array_length(_sl.cols); _j++)
                {
                    var _sx = 700 + _j * 46;
                    if (point_in_rectangle(_mx, _my, _sx, _ry + 3, _sx + 38, _ry + 41)) kd_look_set(cz_look, _sl.key, _j);
                }
            }
            else
            {
                if (point_in_rectangle(_mx, _my, 700, _ry + 4, 740, _ry + 40)) kd_look_step(cz_look, _sl, -1);
                if (point_in_rectangle(_mx, _my, 980, _ry + 4, 1020, _ry + 40)) kd_look_step(cz_look, _sl, 1);
            }
        }
        // presets
        for (var _p = 0; _p < kd_preset_count(); _p++)
        {
            var _px = 560 + _p * 104;
            if (point_in_rectangle(_mx, _my, _px, 532, _px + 96, 570)) cz_look = kd_look_copy(kd_preset_get(_p).look);
        }
        if (point_in_rectangle(_mx, _my, cz_btn_random[0], cz_btn_random[1], cz_btn_random[2], cz_btn_random[3])) cz_look = kd_look_random();
        if (point_in_rectangle(_mx, _my, cz_btn_reset[0], cz_btn_reset[1], cz_btn_reset[2], cz_btn_reset[3])) cz_look = kd_look_copy(global.kd_look);
        if (point_in_rectangle(_mx, _my, cz_btn_cancel[0], cz_btn_cancel[1], cz_btn_cancel[2], cz_btn_cancel[3])) _cancel = true;
        if (point_in_rectangle(_mx, _my, cz_btn_wear[0], cz_btn_wear[1], cz_btn_wear[2], cz_btn_wear[3])) _confirm = true;
    }

    if (_confirm)
    {
        global.kd_look = kd_look_copy(cz_look);
        with (obj_player) kd_apply_look(id, global.kd_look);
        kd_toast("New look saved!", make_colour_rgb(64, 226, 110));
        // character chosen: head out to the Kuala Lumpur street (power-up burst when you arrive)
        global.kd_arrive_fx = true;
        kd_use_door("door_lab");
        kd_sfx(snd_confirm);
        if (first_select)
        {
            first_select = false;
            kd_add_exp(20, "Customised your builder");
        }
        select_open = false;
    }
    else if (_cancel)
    {
        select_open = false;
        kd_sfx(snd_ui_close);
    }
}
else if (panel_open)
{
    if (panel.discord)
    {
        if (keyboard_check_pressed(vk_enter) || _click)
        {
            kd_sfx(snd_confirm);
            kd_discord_open();
            panel_open = false;
        }
        else if (keyboard_check_pressed(ord("E")) || keyboard_check_pressed(vk_escape))
        {
            panel_open = false;
            kd_sfx(snd_ui_close);
        }
    }
    else if (panel.feed)
    {
        // browse the feed
        var _n = array_length(feed_events);
        if (keyboard_check_pressed(vk_left) || keyboard_check_pressed(ord("A"))
            || (_click && point_in_rectangle(_mx, _my, feed_prev_btn[0], feed_prev_btn[1], feed_prev_btn[2], feed_prev_btn[3])))
        {
            feed_index = (feed_index - 1 + _n) mod _n;
            kd_sfx(snd_ui_click);
        }
        if (keyboard_check_pressed(vk_right) || keyboard_check_pressed(ord("D"))
            || (_click && point_in_rectangle(_mx, _my, feed_next_btn[0], feed_next_btn[1], feed_next_btn[2], feed_next_btn[3])))
        {
            feed_index = (feed_index + 1) mod _n;
            kd_sfx(snd_ui_click);
        }
        if (keyboard_check_pressed(ord("E")) || keyboard_check_pressed(vk_escape) || keyboard_check_pressed(vk_enter))
        {
            panel_open = false;
            kd_sfx(snd_ui_close);
        }
    }
    else if (keyboard_check_pressed(ord("E")) || keyboard_check_pressed(vk_escape) || keyboard_check_pressed(vk_enter) || _click)
    {
        panel_open = false;
        kd_sfx(snd_ui_close);
    }
}
else
{
    // open chat: T / Enter / click the chat button
    if (keyboard_check_pressed(ord("T")) || keyboard_check_pressed(vk_enter)
        || (_click && point_in_rectangle(_mx, _my, chat_btn[0], chat_btn[1], chat_btn[2], chat_btn[3])))
    {
        chat_typing = true;
        chat_text = "";
        keyboard_string = "";
        kd_sfx(snd_ui_click);
    }
    else if (_click && point_in_rectangle(_mx, _my, gear_btn[0], gear_btn[1], gear_btn[2], gear_btn[3]))
    {
        settings_open = true;
        kd_sfx(snd_ui_open);
    }
    else if (_click && point_in_rectangle(_mx, _my, discord_btn[0], discord_btn[1], discord_btn[2], discord_btn[3]))
    {
        kd_sfx(snd_confirm);
        kd_toast("Opening the KD Discord channel...", make_colour_rgb(150, 160, 255));
        kd_discord_open();
    }

    // stations
    near_station = noone;
    if (instance_exists(obj_player))
    {
        var _px = obj_player.x;
        var _py = obj_player.y;
        with (obj_station)
        {
            if (abs(_px - x) < 18 && abs(_py - y) < 10) other.near_station = id;
        }
    }
    // weapon lying in the room
    near_gun = noone;
    if (instance_exists(obj_player) && near_station == noone)
    {
        var _px2 = obj_player.x;
        var _py2 = obj_player.y;
        with (obj_gun)
        {
            if (!equipped && abs(_px2 - x) < 16 && abs(_py2 - y) < 24) other.near_gun = id;
        }
    }
    if (!chat_typing && near_gun != noone && keyboard_check_pressed(ord("E")))
    {
        var _wk = near_gun.weapon_key;
        kd_equip(instance_find(obj_player, 0), _wk);
        kd_sfx(snd_pickup, 0.02);
        instance_destroy(near_gun);
        near_gun = noone;
        var _wp = kd_weapon_get(_wk);
        if (_wp.type == "melee") kd_toast("Equipped: " + _wp.name + "   (LEFT CLICK to slash, number keys / mouse wheel to switch, Q to holster)", c_white);
        else kd_toast("Equipped: " + _wp.name + "   (aim with the mouse, LEFT CLICK to shoot, number keys / mouse wheel to switch)", c_white);
        kd_toast(_wp.desc, make_colour_rgb(255, 214, 90));
    }
    else if (!chat_typing && near_station != noone && keyboard_check_pressed(ord("E"))
        && (near_station.station == "select" || kd_is_door(near_station.station)))
    {
        // special stations: character select + doors between rooms
        var _s = near_station.station;
        near_station.visited = true;
        if (_s == "select")
        {
            kd_sfx(snd_ui_open);
            select_open = true;
            cz_look = kd_look_copy(global.kd_look);
            cz_row  = 0;
        }
        else kd_use_door(_s);     // door_lab, door_select, door_range, door_roof, door_back (scr_kd_world)
    }
    else if (!chat_typing && near_station != noone && keyboard_check_pressed(ord("E")))
    {
        panel = kd_station_info(near_station.station);
        panel_open = true;
        kd_sfx(snd_ui_open);
        if (panel.feed)
        {
            feed_events = kd_events();
            feed_index  = 0;
        }
        if (!near_station.visited)
        {
            near_station.visited = true;
            kd_add_exp(panel.xp, panel.reason);
        }
    }
}

global.ui_block = chat_typing || name_editing || settings_open || panel_open || select_open;
// a click that closed a menu should not also fire the gun: stay blocked until the button is released
if (_was_blocked && mouse_check_button(mb_left)) global.ui_block = true;

// hide the OS cursor during gameplay - the aiming circle replaces it
var _want_hidden = !global.ui_block;
if (_want_hidden != cursor_hidden)
{
    cursor_hidden = _want_hidden;
    if (cursor_hidden) window_set_cursor(cr_none);
    else window_set_cursor(cr_default);
}
