/// KDlab1 world: the rooms, doors between them, health, face icons and name plates.
///
///   rm_title    title screen (room 1)
///   rm_select   Character Lab
///   rm_main     KD Lab (office, control room, basement)
///   rm_range    Training Range (test dummies)
///   rm_rooftop  Rooftop
///   rm_showcase Showcase Hall (after choosing your character): statues link to the games
///   rm_kl       Kuala Lumpur street

// ---------------- DOORS ----------------
/// which room a door station leads to
function kd_door_dest(_station)
{
    switch (_station)
    {
        case "door_lab":                                   // Character Lab -> Showcase -> street -> KD Lab
            if (room == rm_select)   return rm_showcase;
            if (room == rm_showcase) return rm_kl;
            return rm_main;
        case "door_select":                                // KD Lab -> street -> Showcase -> Character Lab
            if (room == rm_main) return rm_kl;
            if (room == rm_kl)   return rm_showcase;
            return rm_select;
        case "door_range":  return rm_range;
        case "door_roof":   return rm_rooftop;
        case "door_back":   return rm_main;
    }
    return -1;
}

function kd_is_door(_station)
{
    return string_copy(_station, 1, 5) == "door_";
}

/// go through a door (remembers where you came from, so you arrive at the matching door)
function kd_use_door(_station)
{
    var _dest = kd_door_dest(_station);
    if (_dest == -1) return;
    global.kd_prev_room = room;
    kd_sfx(snd_door, 0.03);
    room_goto(_dest);
}

/// called at Room Start: put the player at the door that leads back to the room they came from
function kd_place_player_at_door()
{
    if (global.kd_prev_room == -1 || !instance_exists(obj_player)) return;
    var _from = global.kd_prev_room;
    var _door = noone;
    with (obj_station) if (kd_is_door(station) && kd_door_dest(station) == _from) _door = id;
    if (_door != noone)
    {
        with (obj_player)
        {
            x = _door.x;
            y = _door.y;
            xstart = x;            // respawn here if knocked out
            ystart = y;
        }
    }
    global.kd_prev_room = -1;
    // just chose a character: arrive with a power-up burst
    if (variable_global_exists("kd_arrive_fx") && global.kd_arrive_fx)
    {
        global.kd_arrive_fx = false;
        with (obj_player) kd_vfx_powerup(id);
    }
}

/// a simple pixel door (used by the doors that are not painted in the room background)
function kd_draw_door(_x, _y, _light)
{
    var _x1 = _x - 9;
    var _y1 = _y - 31;
    draw_set_colour(make_colour_rgb(24, 28, 32));
    draw_rectangle(_x1 - 1, _y1 - 1, _x + 9, _y - 1, false);          // frame
    draw_set_colour(make_colour_rgb(70, 81, 106));
    draw_rectangle(_x1 + 1, _y1 + 1, _x + 7, _y - 1, false);          // door
    draw_set_colour(make_colour_rgb(98, 110, 140));
    draw_rectangle(_x1 + 3, _y1 + 3, _x + 5, _y1 + 13, true);         // upper panel
    draw_rectangle(_x1 + 3, _y1 + 16, _x + 5, _y - 4, true);          // lower panel
    draw_set_colour(make_colour_rgb(203, 189, 188));
    draw_rectangle(_x + 4, _y - 16, _x + 5, _y - 15, false);          // handle
    draw_set_colour(_light);
    draw_rectangle(_x1 + 2, _y1 - 5, _x + 6, _y1 - 3, false);         // exit light
    draw_set_colour(c_white);
}

// ---------------- HEALTH ----------------
/// damage a person; at 0 HP they are "knocked out" for a few seconds, then get back up
function kd_npc_damage(_npc, _dmg)
{
    with (_npc)
    {
        if (ko > 0) return;
        hp = max(0, hp - _dmg);
        if (hp <= 0)
        {
            ko     = 240;
            burn   = 0;
            freeze = 0;
            shock  = 0;
            walking = false;
            bubble_text  = choose("I need a coffee break...", "Going offline...", "404: energy not found", "Brb, rebooting");
            bubble_timer = 120;
        }
    }
}

/// damage the player (explosions). Regenerates after a short rest; at 0 HP you respawn.
/// (_sx, _sy) = where the hit came from: the shield (F) blocks it and ripples there.
function kd_player_damage(_dmg, _sx, _sy)
{
    with (obj_player)
    {
        if (kd_shield_up(shield_fx))
        {
            if (!is_undefined(_sx)) kd_shield_hit(shield_fx, _sx, _sy);
            return;
        }
        if (invul > 0) return;
        hp = max(0, hp - _dmg);
        hurt_t    = 0;
        invul     = 20;
        hit_flash = 10;
        global.kd_flash = max(global.kd_flash, 0.15);
        if (hp <= 0)
        {
            hp  = hp_max;
            x   = xstart;
            y   = ystart;
            vsp = 0;
            hsp = 0;
            mode = "normal";
            kd_toast("You got knocked out and respawned. Careful with explosives!", make_colour_rgb(255, 110, 110));
            global.kd_flash = 0.5;
        }
    }
}

function kd_hp_colour(_frac)
{
    if (_frac > 0.5)  return make_colour_rgb(64, 226, 110);
    if (_frac > 0.25) return make_colour_rgb(255, 204, 64);
    return make_colour_rgb(235, 64, 80);
}

// ---------------- FACE ICON ----------------
/// draws just the head of a look (hair, face, skin) into a square of _size pixels at (_x, _y) top-left
function kd_draw_face_icon(_x, _y, _look, _size)
{
    var _d = kd_custom_data();
    var _l = 6;         // head area inside the 32x32 character layers
    var _t = 0;
    var _w = 20;
    var _h = 20;
    var _s = _size / _w;
    var _hb = _d.hair_back_spr[_look.hair];
    if (_hb != -1) draw_sprite_part_ext(_hb, _look.hair_col * 2, _l, _t, _w, _h, _x, _y, _s, _s, c_white, 1);
    draw_sprite_part_ext(spr_cz_body, _look.skin, _l, _t, _w, _h, _x, _y, _s, _s, c_white, 1);
    draw_sprite_part_ext(_d.top_spr[_look.top], _look.top_col, _l, _t, _w, _h, _x, _y, _s, _s, c_white, 1);
    draw_sprite_part_ext(_d.face_spr[_look.face], _look.skin, _l, _t, _w, _h, _x, _y, _s, _s, c_white, 1);
    draw_sprite_part_ext(_d.hair_spr[_look.hair], _look.hair_col, _l, _t, _w, _h, _x, _y, _s, _s, c_white, 1);
}

// ---------------- NAME PLATE (under the feet) ----------------
/// GUI: [face] Name  +  health bar, centred just below a character's feet
function kd_draw_nameplate(_wx, _wy, _name, _look, _hp, _hp_max, _name_col, _ko)
{
    var _cam = view_camera[0];
    var _s   = display_get_gui_width() / camera_get_view_width(_cam);
    var _gx  = (_wx - camera_get_view_x(_cam)) * _s;
    var _gy  = (_wy - camera_get_view_y(_cam)) * _s + 6;
    if (_gx < -80 || _gx > display_get_gui_width() + 80 || _gy < -40 || _gy > display_get_gui_height() + 10) return;

    var _ts   = 0.7;
    var _icon = 22;
    var _tw   = string_width(_name) * _ts;
    var _bw   = max(54, _tw);
    var _w    = _icon + 6 + _bw;
    var _x1   = _gx - _w / 2 - 4;
    var _x2   = _gx + _w / 2 + 4;
    var _y1   = _gy;
    var _y2   = _gy + _icon + 6;

    draw_set_alpha(0.72);
    draw_set_colour(make_colour_rgb(14, 18, 24));
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 8, 8, false);
    draw_set_alpha(1);

    // face in a little rounded frame
    var _ix = _x1 + 4;
    var _iy = _y1 + 3;
    draw_set_colour(make_colour_rgb(34, 42, 56));
    draw_roundrect_ext(_ix - 1, _iy - 1, _ix + _icon + 1, _iy + _icon + 1, 6, 6, false);
    kd_draw_face_icon(_ix, _iy, _look, _icon);
    draw_set_colour(_name_col);
    draw_roundrect_ext(_ix - 1, _iy - 1, _ix + _icon + 1, _iy + _icon + 1, 6, 6, true);

    // name + health bar
    var _nx = _ix + _icon + 6;
    draw_set_colour(_name_col);
    draw_text_transformed(_nx, _y1 + 1, _name, _ts, _ts, 0);
    var _by = _y1 + 17;
    draw_set_colour(make_colour_rgb(40, 46, 58));
    draw_rectangle(_nx, _by, _nx + _bw, _by + 5, false);
    if (_ko)
    {
        draw_set_colour(make_colour_rgb(160, 168, 180));
        draw_text_transformed(_nx + _bw, _by - 4, "KO", 0.55, 0.55, 0);
    }
    else
    {
        var _f = clamp(_hp / _hp_max, 0, 1);
        draw_set_colour(kd_hp_colour(_f));
        draw_rectangle(_nx, _by, _nx + _bw * _f, _by + 5, false);
    }
    draw_set_colour(c_white);
}
