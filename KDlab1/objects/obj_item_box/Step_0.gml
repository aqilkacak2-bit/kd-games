/// obj_item_box - Step
if (hit_flash > 0) hit_flash -= 1;
// press E next to the box to open it
near = false;
if (instance_exists(obj_player))
{
    var _p = instance_find(obj_player, 0);
    near = abs(_p.x - (x + 8)) < 16 && abs(_p.y - (y + 16)) < 20;
    var _free = !variable_global_exists("ui_block") || !global.ui_block;
    var _no_station = !instance_exists(obj_game) || obj_game.near_station == noone;
    if (near && _free && _no_station && keyboard_check_pressed(ord("E"))) kd_box_break(id);
}
