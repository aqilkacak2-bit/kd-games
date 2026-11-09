/// obj_showcase - Step
t += 1;
if (opened > 0) opened -= 1;
hover = (kd_showcase_hovered() == id);
glow  = lerp(glow, hover ? 1 : 0, 0.25);

near = false;
if (instance_exists(obj_player))
{
    var _p = instance_find(obj_player, 0);
    near = (kd_showcase_nearest(_p) == id);
}

// click it (mouse or tap) -> open the website
if (hover && mouse_check_button_pressed(mb_left)) kd_showcase_open(id);

// or stand at it and press E (doors keep E when you are next to one)
var _free = !variable_global_exists("ui_block") || !global.ui_block;
var _no_station = !instance_exists(obj_game) || obj_game.near_station == noone;
if (near && _free && _no_station && keyboard_check_pressed(ord("E"))) kd_showcase_open(id);
