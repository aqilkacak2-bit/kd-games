/// obj_enemy - Draw: the character art with a neon outline (flyers are drones)
var _st = (abs(hsp) > 0.1 && on_ground) ? "walk" : "idle";
var _fr = anim_t div 6;
var _cy = y - 14 * scale;

// glow
gpu_set_blendmode(bm_add);
draw_circle_colour(x, _cy, 18 * scale, merge_colour(c_black, neon, 0.3), c_black, false);
gpu_set_blendmode(bm_normal);

if (kind == "flyer")
{
    var _bob = sin(anim_t / 8) * 1.5;
    draw_set_colour(make_colour_rgb(30, 24, 50));
    draw_circle(x, _cy + _bob, 7, false);
    draw_set_colour(neon);
    draw_circle(x, _cy + _bob, 7, true);
    draw_line(x - 11, _cy + _bob - 6, x + 11, _cy + _bob - 6);               // rotor
    draw_line(x, _cy + _bob - 7, x, _cy + _bob - 6);
    draw_set_colour(c_white);
    draw_circle(x + facing * 2, _cy + _bob, 3, false);                        // eye
    draw_set_colour(make_colour_rgb(255, 50, 70));
    draw_circle(x + facing * 3, _cy + _bob, 1.5, false);
    if (hit_flash > 0) { draw_set_alpha(0.7); draw_set_colour(c_white); draw_circle(x, _cy + _bob, 7, false); draw_set_alpha(1); }
}
else
{
    // neon outline
    gpu_set_fog(true, neon, 0, 1);
    kd_draw(x - 1, y, facing, _st, _fr, look, scale, c_white, 0.9, false);
    kd_draw(x + 1, y, facing, _st, _fr, look, scale, c_white, 0.9, false);
    kd_draw(x, y - 1, facing, _st, _fr, look, scale, c_white, 0.9, false);
    gpu_set_fog(false, c_white, 0, 0);
    kd_draw(x, y, facing, _st, _fr, look, scale, merge_colour(c_white, neon, 0.35), 1, true);
    if (hit_flash > 0 || (fuse > 0 && (fuse div 4) mod 2 == 0))
    {
        gpu_set_fog(true, c_white, 0, 1);
        kd_draw(x, y, facing, _st, _fr, look, scale, c_white, 0.8, false);
        gpu_set_fog(false, c_white, 0, 0);
    }
    // glowing eyes
    draw_set_colour(neon);
    draw_rectangle(x + facing * 2 * scale, y - 22 * scale, x + facing * 2 * scale + scale, y - 22 * scale + scale, false);
}

// shooter aims before it fires
if (kind == "shooter" && atk_t < 20 && instance_exists(obj_player))
{
    draw_set_alpha(0.25 + 0.25 * sin(atk_t));
    draw_set_colour(neon);
    draw_line(x, y - 16, obj_player.x, obj_player.y - 13);
    draw_set_alpha(1);
}
kd_npc_status_draw(_st, _fr);
draw_set_colour(c_white);
