/// obj_run_item - Step: stand next to it and press E
t += 1;
near = false;
if (!kd_run_active() || !instance_exists(obj_player)) exit;
var _p = instance_find(obj_player, 0);
near = abs(_p.x - x) < 18 && abs(_p.y - y) < 24;
if (near && !global.ui_block && keyboard_check_pressed(ord("E")))
{
    if (price > global.kd_run.coins)
    {
        kd_toast("Not enough coins (" + string(price) + " needed)", make_colour_rgb(255, 110, 110));
        kd_sfx(snd_ui_close);
        exit;
    }
    global.kd_run.coins -= price;
    kd_item_give(key);
    instance_destroy();
}
