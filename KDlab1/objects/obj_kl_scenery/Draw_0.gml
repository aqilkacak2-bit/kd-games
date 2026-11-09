/// obj_kl_scenery - Draw
// far skyline (Petronas Towers, KL Tower, Merdeka 118) moves slower than the camera = parallax
var _cam = view_camera[0];
var _cx  = camera_get_view_x(_cam);
var _cy  = camera_get_view_y(_cam);
draw_sprite(spr_kl_far, 0, _cx * 0.55 - 20, _cy * 0.6);
// the street: shophouses, Myvi, bus stop, KD Lab HQ
draw_sprite(spr_kl_near, 0, 0, 0);
