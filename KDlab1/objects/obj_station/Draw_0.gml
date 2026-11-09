/// obj_station - Draw
// floating marker above the station: yellow "!" = new, green = visited
var _f = 0;
if (visited) _f = 1;
draw_sprite(spr_kd_marker, _f, x, y - 42 + round(sin(degtorad(bob)) * 2));
