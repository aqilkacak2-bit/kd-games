/// KDlab1 fonts - the WHOLE game reads these two lines.
/// To use another font asset, just put its name here (e.g. #macro KD_FONT_TITLE fnt_my_pixel).
#macro KD_FONT_TITLE fnt_name      // titles and big text (logo, panel titles, menu buttons, card titles)
#macro KD_FONT_TEXT  fnt_name_2    // normal text (HUD, chat, prompts, name plates, minimap)

/// draw a title with fnt_name, then go back to fnt_name_2
function kd_title_text(_x, _y, _str, _xs, _ys, _ang)
{
    draw_set_font(KD_FONT_TITLE);
    draw_text_transformed(_x, _y, _str, _xs, _ys, _ang);
    draw_set_font(KD_FONT_TEXT);
}
