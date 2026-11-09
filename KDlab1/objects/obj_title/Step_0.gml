/// obj_title - Step
t += 1;
var _mx = device_mouse_x_to_gui(0);
var _my = device_mouse_y_to_gui(0);
var _click = mouse_check_button_pressed(mb_left);

// walkers loop across the screen
for (var _i = 0; _i < array_length(walkers); _i++)
{
    walkers[_i].x += walkers[_i].spd;
    if (walkers[_i].x > 1380) walkers[_i].x = -80 - irandom(200);
}

if (starting)
{
    fade = min(1, fade + 0.05);
    if (fade >= 1) room_goto(rm_select);
    exit;
}

if (show_controls)
{
    if (_click || keyboard_check_pressed(vk_escape) || keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space))
    {
        show_controls = false;
        kd_sfx(snd_ui_close);
    }
    exit;
}

// keyboard
var _n = array_length(menu);
if (keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W")))   { sel = (sel - 1 + _n) mod _n; kd_sfx(snd_ui_click); }
if (keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S"))) { sel = (sel + 1) mod _n; kd_sfx(snd_ui_click); }
var _go = keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space) || keyboard_check_pressed(ord("E"));

// mouse: hover selects, click activates
for (var _i = 0; _i < _n; _i++)
{
    var _by = 420 + _i * 64;
    if (point_in_rectangle(_mx, _my, 640 - 150, _by, 640 + 150, _by + 52))
    {
        if (sel != _i && (_mx != mx_prev || _my != my_prev)) { sel = _i; kd_sfx(snd_ui_click, 0.1, 0.5); }
        if (_click) { sel = _i; _go = true; }
    }
}

mx_prev = _mx;
my_prev = _my;

if (_go)
{
    switch (menu[sel])
    {
        case "START":
            kd_sfx(snd_confirm);
            starting = true;
            break;
        case "CONTROLS":
            kd_sfx(snd_ui_open);
            show_controls = true;
            break;
        case "QUIT":
            game_end();
            break;
    }
}
