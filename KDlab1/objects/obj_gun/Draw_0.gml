/// obj_gun - Draw
if (!equipped)
{
    // lying in the room: gentle float + glow (orange glow = not picked up yet)
    var _oy = round(sin(degtorad(bob)) * 1.5) - 2;
    draw_set_alpha(0.25 + 0.1 * sin(degtorad(bob * 2)));
    draw_set_colour(make_colour_rgb(64, 226, 110));
    if (!is_undefined(weapon) && weapon.type == "melee") draw_set_colour(make_colour_rgb(255, 196, 80));
    draw_ellipse(x - 11, y + 1, x + 11, y + 4, false);
    draw_set_alpha(1);
    draw_set_colour(c_white);
    draw_sprite_ext(sprite_index, 0, x, y + _oy, 1, 1, 0, c_white, 1);
    exit;
}
if (!visible) exit;

if (weapon.type == "melee")
{
    // slash trail: a fading arc from where the swing started to the blade now
    if (swing_t > 0)
    {
        var _k  = swing_t / weapon.swing_time;       // 1 -> 0
        var _r  = weapon.muzzle_x;
        var _n  = 10;
        var _px = x + lengthdir_x(_r, swing_from);
        var _py = y + lengthdir_y(_r, swing_from);
        for (var _i = 1; _i <= _n; _i++)
        {
            var _a  = swing_from + angle_difference(image_angle, swing_from) * (_i / _n);
            var _nx = x + lengthdir_x(_r, _a);
            var _ny = y + lengthdir_y(_r, _a);
            draw_set_alpha((_i / _n) * 0.75 * _k);
            draw_set_colour(merge_colour(make_colour_rgb(90, 176, 255), c_white, _i / _n));
            draw_line_width(_px, _py, _nx, _ny, 1 + 2 * (_i / _n));
            _px = _nx;
            _py = _ny;
        }
        draw_set_alpha(1);
        draw_set_colour(c_white);
    }
    draw_sprite_ext(sprite_index, 0, round(x), round(y), 1, image_yscale, image_angle, c_white, 1);
    exit;
}

draw_sprite_ext(sprite_index, 0, round(x), round(y), 1, image_yscale, image_angle, c_white, 1);

// laser beam: soft glow + bright core + flickering hit point
if (weapon.type == "beam" && beam_on > 0)
{
    gpu_set_blendmode(bm_add);
    draw_set_colour(weapon.colour);
    draw_set_alpha(0.3 + random(0.15));
    draw_line_width(beam_x1, beam_y1, beam_x2, beam_y2, 5);
    draw_set_alpha(0.8);
    draw_line_width(beam_x1, beam_y1, beam_x2, beam_y2, 2);
    draw_set_colour(c_white);
    draw_set_alpha(1);
    draw_line_width(beam_x1, beam_y1, beam_x2, beam_y2, 1);
    draw_set_colour(weapon.colour);
    draw_set_alpha(0.7);
    draw_circle(beam_x2, beam_y2, random_range(2, 4), false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
    draw_set_colour(c_white);
}

if (flash > 0)
{
    var _mx = x + lengthdir_x(weapon.muzzle_x + 1, aim_dir) + lengthdir_x(weapon.muzzle_y * image_yscale, aim_dir - 90);
    var _my = y + lengthdir_y(weapon.muzzle_x + 1, aim_dir) + lengthdir_y(weapon.muzzle_y * image_yscale, aim_dir - 90);
    draw_sprite_ext(spr_muzzle, 0, _mx, _my, 1, 1, aim_dir, weapon.colour, 1);
}
