/// obj_kd_fx - Draw
var _k = t / max(1, life);      // 0 -> 1 over its life
switch (kind)
{
    case "boom":
        // hot core + orange fireball (additive), then a white shockwave ring
        gpu_set_blendmode(bm_add);
        draw_set_alpha((1 - _k) * 0.6);
        draw_set_colour(make_colour_rgb(255, 90, 30));
        draw_circle(x, y, r * (0.6 + 0.4 * _k), false);
        draw_set_alpha(1 - _k);
        draw_set_colour(merge_colour(c_white, make_colour_rgb(255, 160, 50), min(1, _k * 3)));
        draw_circle(x, y, r * (0.3 + 0.35 * _k), false);
        gpu_set_blendmode(bm_normal);
        draw_set_alpha((1 - _k) * 0.8);
        draw_set_colour(c_white);
        draw_circle(x, y, r * (0.4 + 0.9 * _k), true);
        break;

    case "smoke":
        draw_set_alpha(0.55 * (1 - _k));
        draw_set_colour(merge_colour(make_colour_rgb(120, 110, 115), make_colour_rgb(50, 46, 54), _k));
        draw_circle(x, y, r * (0.6 + 0.6 * _k), false);
        break;

    case "ember":
        draw_set_alpha(1 - _k);
        draw_set_colour(merge_colour(make_colour_rgb(255, 220, 90), make_colour_rgb(235, 70, 30), _k));
        draw_circle(x, y, 1, false);
        break;

    case "bolt":
        // jagged lightning: the same random shape for the glow and the core, re-rolled every 2 steps
        var _n    = array_length(pts) div 2;
        var _seed = seed + (t div 2) * 7919;
        gpu_set_blendmode(bm_add);
        for (var _pass = 0; _pass < 2; _pass++)
        {
            random_set_seed(_seed);
            var _w = 1;
            if (_pass == 0)
            {
                _w = 3;
                draw_set_colour(col);
                draw_set_alpha((1 - _k) * 0.6);
            }
            else
            {
                draw_set_colour(c_white);
                draw_set_alpha(1 - _k);
            }
            for (var _i = 0; _i < _n - 1; _i++)
            {
                var _x1 = pts[_i * 2];
                var _y1 = pts[_i * 2 + 1];
                var _x2 = pts[_i * 2 + 2];
                var _y2 = pts[_i * 2 + 3];
                var _d  = point_direction(_x1, _y1, _x2, _y2);
                var _px = _x1;
                var _py = _y1;
                var _seg = 6;
                for (var _s = 1; _s <= _seg; _s++)
                {
                    var _qx = lerp(_x1, _x2, _s / _seg);
                    var _qy = lerp(_y1, _y2, _s / _seg);
                    if (_s < _seg)
                    {
                        var _o = random_range(-4, 4);
                        _qx += lengthdir_x(_o, _d + 90);
                        _qy += lengthdir_y(_o, _d + 90);
                    }
                    draw_line_width(_px, _py, _qx, _qy, _w);
                    _px = _qx;
                    _py = _qy;
                }
            }
        }
        randomise();
        gpu_set_blendmode(bm_normal);
        break;
}
draw_set_alpha(1);
draw_set_colour(c_white);
