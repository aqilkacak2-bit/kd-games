/// obj_dungeon - Draw GUI: run progress, coins, items, boss bar, banner
if (!kd_run_active()) exit;
draw_set_font(KD_FONT_TEXT);
draw_set_valign(fa_top);
kd_run_hud();
if (banner_t > 0)
{
    var _a = min(1, banner_t / 30);
    draw_set_alpha(_a);
    draw_set_halign(fa_center);
    draw_set_colour(c_black);
    kd_title_text(643, 183, banner, 2, 2, 0);
    draw_set_colour(cleared ? make_colour_rgb(64, 226, 110) : make_colour_rgb(255, 84, 170));
    kd_title_text(640, 180, banner, 2, 2, 0);
    draw_set_halign(fa_left);
    draw_set_alpha(1);
}
draw_set_colour(c_white);
