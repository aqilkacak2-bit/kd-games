/// obj_player - Step
var _blocked = variable_global_exists("ui_block") && global.ui_block;   // typing / panel open

// health: regenerates after 2 seconds without damage
hurt_t += 1;
if (invul > 0) invul -= 1;
if (hit_flash > 0) hit_flash -= 1;
if (hurt_t > 120 && hp < hp_max) hp = min(hp_max, hp + 0.25 * kd_regen_mult());   // skill: Second Wind

// abilities: F = shield dome for ~3 s (blocks explosions), H = heal 40 HP
if (shield_cd > 0) shield_cd -= 1;
if (heal_cd > 0) heal_cd -= 1;
if (!_blocked && keyboard_check_pressed(ord("F")) && shield_cd <= 0)
{
    shield_fx = kd_vfx_shield(id);
    shield_cd = kd_shield_cd();          // skill: Firewall
}
if (!_blocked && keyboard_check_pressed(ord("H")) && heal_cd <= 0)
{
    hp = min(hp_max, hp + kd_heal_amount());   // skill: Field Medic
    kd_vfx_heal(id);
    heal_cd = kd_heal_cd();
}

// G = throw a grenade at the mouse; recoil spring from shooting downward
if (!_blocked && keyboard_check_pressed(ord("G"))) kd_grenade_try_throw(id);
kd_grenade_throw_step(id);
kd_recoil_step(id);

// Q = holster / draw the weapon
if (!_blocked && keyboard_check_pressed(ord("Q")) && instance_exists(gun))
{
    global.kd_weapon_out = !global.kd_weapon_out;
    kd_sfx(snd_holster, 0.05);
}

// 1-9, 0, -, = : switch to a weapon you own. Mouse wheel = next / previous
if (!_blocked && array_length(global.kd_owned) > 0)
{
    var _order = kd_weapon_order();
    var _keys  = kd_weapon_keys();
    for (var _n = 0; _n < array_length(_order); _n++)
    {
        if (keyboard_check_pressed(_keys[_n]) && kd_weapon_owned(_order[_n]) && global.kd_weapon != _order[_n])
        {
            kd_equip(id, _order[_n]);
            kd_sfx(snd_holster, 0.05);
        }
    }
    if (array_length(global.kd_owned) > 1)
    {
        if (mouse_wheel_up())   kd_weapon_cycle(id, -1);
        if (mouse_wheel_down()) kd_weapon_cycle(id, 1);
    }
}

// ---------- input ----------
var _right = keyboard_check(vk_right) || keyboard_check(ord("D"));
var _left  = keyboard_check(vk_left)  || keyboard_check(ord("A"));
var _down  = keyboard_check(vk_down)  || keyboard_check(ord("S"));
var _up    = keyboard_check(vk_up)    || keyboard_check(ord("W"));
var _jump  = keyboard_check_pressed(vk_space);

if (_blocked)
{
    _right = false; _left = false; _down = false; _up = false; _jump = false;
}

var _h = _right - _left;
var _v = _down - _up;

var _spd = move_speed;
if (keyboard_check(vk_shift)) _spd = run_speed;   // hold SHIFT to run

var _moving = false;
var _dt = 1 / game_get_speed(gamespeed_fps);

// ================= DASH (R) - movement.ts port, VFX in obj_dash_fx =================
if (dash_cool > 0) dash_cool -= _dt;
if (mode == "normal" && on_ground) dash_air_used = false;
if (!_blocked && mode == "normal" && keyboard_check_pressed(ord("R")) && dash_cool <= 0 && !(dash_air_used && !on_ground))
{
    var _ddir = facing;
    if (_h != 0) _ddir = sign(_h);
    mode      = "dash";
    dash_t    = 0;
    dash_dir  = _ddir;
    dash_x0   = x;
    dash_cool = dash_cooldown;
    hsp = 0;
    vsp = 0;
    skid_v = 0;
    if (!on_ground) dash_air_used = true;
    kd_sfx(snd_dash, 0.06);
    var _fx = instance_create_depth(x, y, depth + 1, obj_dash_fx);
    _fx.owner    = id;
    _fx.dir      = _ddir;
    _fx.x0       = x;
    _fx.g        = y;
    _fx.grounded = on_ground;
    _fx.dist     = dash_distance;
    _fx.d0       = dash_windup;
    _fx.d1       = dash_windup + dash_time;
}

// ================= NORMAL: walk / jump / fall =================
if (mode == "normal")
{
    on_ground = place_meeting(x, y + 1, obj_solid);

    // --- grab a ladder (UP while in front of it, or DOWN while standing on top of it) ---
    var _lad = instance_place(x, y, obj_ladder);
    if (_lad == noone && _down) _lad = instance_place(x, y + 2, obj_ladder);
    if (_lad != noone)
    {
        var _cx = (_lad.bbox_left + _lad.bbox_right + 1) / 2;
        if (abs(x - _cx) <= 8)
        {
            if ((_up && y > _lad.bbox_top) || (_down && y < _lad.bbox_bottom + 1))
            {
                mode = "ladder";
                ladder = _lad;
                x = _cx;
                hsp = 0;
                vsp = 0;
            }
        }
    }

    // --- step onto stairs (DOWN at the top, UP at the bottom) ---
    if (mode == "normal" && on_ground)
    {
        var _st = instance_nearest(x, y, obj_stairs);
        if (_st != noone)
        {
            if (_down && abs(x - _st.top_x) <= 6 && abs(y - _st.top_y) <= 2)
            {
                mode = "stairs"; stairs = _st; x = _st.top_x; y = _st.top_y;
            }
            else if (_up && abs(x - _st.bottom_x) <= 6 && abs(y - _st.bottom_y) <= 2)
            {
                mode = "stairs"; stairs = _st; x = _st.bottom_x; y = _st.bottom_y;
            }
        }
    }
}

if (mode == "normal")
{
    hsp = _h * _spd;
    if (_h != 0) facing = sign(_h);

    // skid after a dash
    if (skid_v > 0)
    {
        hsp += dash_dir * skid_v * _dt;
        skid_v = max(0, skid_v - 2300 * (dash_distance / 200) * _dt);
    }

    if (on_ground && _jump) { vsp = -jump_speed; kd_sfx(snd_jump, 0.05, 0.8); }
    var _was_ground = on_ground;
    var _fall_speed = vsp;
    // jetpack: hold SPACE in the air to fly (unlocked in the skill tree)
    jet_on = false;
    if (kd_skill_has("jetpack") && !on_ground && !_blocked && !_jump && keyboard_check(vk_space) && jet_fuel > 0)
    {
        jet_on   = true;
        vsp      = max(vsp - 0.55, -2.4);
        jet_fuel = max(0, jet_fuel - 1);
    }
    if (on_ground) jet_fuel = min(jet_fuel_max, jet_fuel + 2);
    vsp = min(vsp + grav, max_fall);

    // horizontal collision
    if (hsp != 0)
    {
        if (place_meeting(x + hsp, y, obj_solid))
        {
            while (!place_meeting(x + sign(hsp), y, obj_solid)) x += sign(hsp);
            hsp = 0;
        }
        x += hsp;
    }

    // vertical collision
    if (place_meeting(x, y + vsp, obj_solid))
    {
        while (!place_meeting(x, y + sign(vsp), obj_solid)) y += sign(vsp);
        vsp = 0;
        y = round(y);
        while (place_meeting(x, y, obj_solid)) y -= 1;
    }
    y += vsp;

    on_ground = place_meeting(x, y + 1, obj_solid);
    _moving = (hsp != 0);
    if (on_ground && !_was_ground && _fall_speed > 2) kd_sfx(snd_land, 0.08, 0.7);
}
// ================= LADDER =================
else if (mode == "ladder")
{
    hsp = 0;
    vsp = 0;
    y += _v * climb_speed;
    _moving = (_v != 0);

    var _top = ladder.bbox_top;
    var _bot = ladder.bbox_bottom + 1;
    if (y <= _top)
    {
        y = _top;            // reached the floor above
        mode = "normal";
    }
    else if (y >= _bot)
    {
        y = _bot;            // reached the floor below
        mode = "normal";
    }

    if (mode == "ladder")
    {
        if (_jump && !place_meeting(x, y, obj_solid))
        {
            mode = "normal";             // jump off
            vsp = -jump_speed * 0.7;
        }
        else if (_h != 0 && !place_meeting(x + _h * 2, y, obj_solid))
        {
            mode = "normal";             // step off sideways
            facing = sign(_h);
        }
    }
}
// ================= STAIRS =================
else if (mode == "stairs")
{
    hsp = 0;
    vsp = 0;
    // right / up = climb, left / down = descend (stairs rise to the right)
    var _dir = _h;
    if (_dir == 0) _dir = -_v;

    var _slope = (stairs.top_y - stairs.bottom_y) / (stairs.top_x - stairs.bottom_x);
    x += _dir * stairs_speed;
    if (_dir != 0) facing = _dir;
    _moving = (_dir != 0);

    if (x >= stairs.top_x)
    {
        x = stairs.top_x; y = stairs.top_y; mode = "normal";
    }
    else if (x <= stairs.bottom_x)
    {
        x = stairs.bottom_x; y = stairs.bottom_y; mode = "normal";
    }
    else
    {
        y = stairs.bottom_y + (x - stairs.bottom_x) * _slope;
    }
}

// ================= DASHING =================
else if (mode == "dash")
{
    hsp = 0;
    vsp = 0;
    dash_t += _dt;
    if (dash_t >= dash_windup)
    {
        // eased burst (same curve as movement.ts)
        var _u  = clamp((dash_t - dash_windup) / dash_time, 0, 1);
        var _tx = dash_x0 + dash_dir * dash_distance * (1 - power(1 - _u, 1.6));
        var _st = _tx - x;
        if (_st != 0)
        {
            if (place_meeting(x + _st, y, obj_solid))
            {
                while (!place_meeting(x + sign(_st), y, obj_solid)) x += sign(_st);
                dash_t = dash_windup + dash_time;          // hit a wall: stop
            }
            else x += _st;
        }
    }
    if (!(instance_exists(gun) && gun.visible)) facing = dash_dir;
    if (dash_t >= dash_windup + dash_time)
    {
        mode   = "normal";
        skid_v = 350 * (dash_distance / 200);              // skid speed (px/s)
        if (place_meeting(x, y + 1, obj_solid)) kd_sfx(snd_skid, 0.1, 0.7);
    }
}

// keep inside the room
x = clamp(x, 8, room_width - 8);

// with a gun out, the character faces the mouse (aim) instead of the walking direction
if (instance_exists(gun) && gun.visible && mode != "ladder")
{
    if (mouse_x > x + 1) facing = 1;
    else if (mouse_x < x - 1) facing = -1;
}

// ---------- animation ----------
var _new_state = "idle";
if (_moving || mode == "ladder") _new_state = "walk";
if (_new_state != state)
{
    state = _new_state;
    anim_frame = 0;
    anim_timer = 0;
}

var _advance = true;
if (mode == "ladder" && !_moving) _advance = false;      // hold still on the ladder
if (mode == "normal" && !on_ground)
{
    state = "walk";                                       // in the air: legs apart
    anim_frame = 2;
    _advance = false;
}
if (mode == "dash")
{
    state = "walk";                                       // dash pose: long stride
    anim_frame = 2;
    _advance = false;
}

if (_advance)
{
    var _fps = kd_anim_fps(state);
    if (state == "walk" && _spd == run_speed && mode == "normal") _fps = _fps * 1.5;
    anim_timer += _fps / game_get_speed(gamespeed_fps);
    if (anim_timer >= 1)
    {
        anim_timer -= 1;
        anim_frame = (anim_frame + 1) mod kd_anim_length(state);
    }
}

// body bob for this frame (used by obj_gun / obj_hand to stay in the hand)
draw_bob = kd_anim_bob(state, anim_frame);

// front arm swing (used by obj_hand when no gun is out)
var _target = 0;
if (mode == "ladder")
{
    _target = 150;                                    // arm up, holding the ladder
    if (_moving) _target = 150 + sin(current_time / 90) * 20;
}
else if (mode == "dash") _target = -60;                // arm thrown back while dashing
else if (mode == "normal" && !on_ground) _target = -40;  // arm back while in the air
else if (state == "walk") _target = kd_arm_swing("walk", anim_frame, anim_timer);
else _target = sin(current_time / 450) * 3;            // tiny idle sway
arm_swing = lerp(arm_swing, _target, 0.35);
// back arm: opposite swing while walking, same pose otherwise
var _target_back = _target;
if (mode == "normal" && on_ground && state == "walk") _target_back = -_target * KD_BACK_SWING;
if (mode == "ladder") _target_back = 300 - _target;          // other hand on the next rung
arm_swing_back = lerp(arm_swing_back, _target_back, 0.35);

// footsteps on the two "foot down" frames of the walk cycle (also on stairs / ladders, quieter)
if (state == "walk" && anim_frame != step_prev_frame && (anim_frame == 1 || anim_frame == 4))
{
    if (mode == "normal" && on_ground) kd_sfx(snd_step, 0.15, 0.55);
    else if (mode == "stairs")         kd_sfx(snd_step, 0.15, 0.45);
    else if (mode == "ladder")         kd_sfx(snd_step, 0.25, 0.3);
}
step_prev_frame = anim_frame;

// dust / colour trail behind the feet
kd_trail_step(id);

// jetpack flame: smoke puffs + engine sound
if (mode != "normal") jet_on = false;
jet_t += 1;
if (jet_on)
{
    if (jet_t mod 3 == 0)
    {
        var _jp = instance_create_depth(x - facing * 6 + random_range(-2, 2), y - 4, depth + 1, obj_trail);
        _jp.image_xscale = choose(-0.8, 0.8);
        _jp.image_yscale = 0.8;
        _jp.col  = choose(make_colour_rgb(160, 240, 80), make_colour_rgb(90, 200, 70), make_colour_rgb(170, 180, 170));
        _jp.glow = true;
    }
    if (jet_t mod 7 == 0) kd_sfx_p(snd_dash, 0.45, 0.1, 0.22);
}
