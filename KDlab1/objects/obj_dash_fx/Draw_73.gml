/// obj_dash_fx - Draw End   (FRONT layer: in front of the player)
// launch flash at the feet
if (t >= d0 && t < d0 + 0.08 && grounded)
{
    var _k = (t - d0) / 0.08;
    draw_set_alpha(1 - _k);
    draw_set_colour(C[0]);
    draw_ellipse(x0 - 10 * (0.5 + _k), g - 2.5, x0 + 10 * (0.5 + _k), g + 2.5, false);
    draw_set_colour(C[2]);
    draw_ellipse(x0 - (6 + 18 * _k), g - (2 + 3 * _k), x0 + (6 + 18 * _k), g + (2 + 3 * _k), true);
}

// glow around the player while dashing
if (t >= d0 && t < d1 + 0.1 && instance_exists(owner))
{
    gpu_set_blendmode(bm_add);
    draw_set_alpha(0.35);
    draw_circle_colour(owner.x, owner.y - 10, 20, C[3], c_black, false);
    gpu_set_blendmode(bm_normal);
}

// sparks (in front)
kd_fx_draw(parts, true, id);
draw_set_alpha(1);
draw_set_colour(c_white);
