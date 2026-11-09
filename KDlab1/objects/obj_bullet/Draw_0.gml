/// obj_bullet - Draw
switch (kind)
{
    case "flame":
        // yellow -> orange -> smoky as it burns out, growing as it goes
        var _k = life / max(1, life_max);
        var _c = merge_colour(make_colour_rgb(255, 240, 160), make_colour_rgb(255, 120, 30), clamp((1 - _k) * 1.8, 0, 1));
        if (_k < 0.3) _c = merge_colour(make_colour_rgb(80, 72, 80), make_colour_rgb(255, 120, 30), _k / 0.3);
        draw_set_alpha(clamp(_k * 2, 0, 1) * 0.85);
        draw_set_colour(_c);
        draw_circle(x, y, 1.2 + (1 - _k) * 4, false);
        break;

    case "rocket":
        // exhaust flame + rocket body
        draw_set_colour(choose(make_colour_rgb(255, 220, 90), make_colour_rgb(255, 130, 40)));
        draw_circle(x - lengthdir_x(4, direction), y - lengthdir_y(4, direction), random_range(1.5, 2.5), false);
        draw_sprite_ext(spr_bullet, 0, x, y, 2, 1.6, direction, make_colour_rgb(110, 200, 120), 1);
        break;

    case "grenade":
        // green bomb with a blinking light (blinks faster just before it goes off)
        draw_set_colour(make_colour_rgb(24, 28, 32));
        draw_circle(x, y, 3, false);
        draw_set_colour(make_colour_rgb(64, 226, 110));
        draw_circle(x, y, 2, false);
        var _blink = 6;
        if (life < 25) _blink = 2;
        if ((life div _blink) mod 2 == 0)
        {
            draw_set_colour(make_colour_rgb(255, 60, 60));
            draw_circle(x + lengthdir_x(1, image_angle), y + lengthdir_y(1, image_angle), 1, false);
        }
        break;

    case "ice":
        draw_set_alpha(0.5);
        draw_set_colour(make_colour_rgb(150, 220, 255));
        draw_circle(x, y, 3, false);
        draw_set_alpha(1);
        draw_set_colour(c_white);
        draw_circle(x, y, 1.5, false);
        break;

    default:
        draw_self();
}
draw_set_alpha(1);
draw_set_colour(c_white);
