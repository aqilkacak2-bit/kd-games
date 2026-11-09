/// obj_game - Post Draw
// Draws the game (application_surface) to the window through the post-process shader.
// Draw GUI happens after this, so the HUD / menus are never affected by the shader.
var _ww = window_get_width();
var _wh = window_get_height();
if (global.kd_shader == 0 || !shader_is_compiled(sh_kd_post))
{
    draw_surface_stretched(application_surface, 0, 0, _ww, _wh);
    exit;
}
var _tex = surface_get_texture(application_surface);
var _uvs = texture_get_uvs(_tex);
shader_set(sh_kd_post);
shader_set_uniform_f(u_time, current_time / 1000);
shader_set_uniform_f(u_texel, texture_get_texel_width(_tex), texture_get_texel_height(_tex));
shader_set_uniform_f(u_uvmax, _uvs[2], _uvs[3]);
shader_set_uniform_f(u_mode, global.kd_shader);
shader_set_uniform_f(u_pix, max(2, floor(_wh / 180)));
shader_set_uniform_f(u_flash, global.kd_flash);
draw_surface_stretched(application_surface, 0, 0, _ww, _wh);
shader_reset();
