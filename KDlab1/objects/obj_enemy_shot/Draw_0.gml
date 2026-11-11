/// obj_enemy_shot - Draw: glowing orb
gpu_set_blendmode(bm_add);
draw_circle_colour(x, y, 7, merge_colour(c_black, col, 0.7), c_black, false);
gpu_set_blendmode(bm_normal);
draw_set_colour(col);
draw_circle(x, y, 2.5 + 0.5 * sin(t / 3), false);
draw_set_colour(c_white);
draw_circle(x, y, 1.2, false);
