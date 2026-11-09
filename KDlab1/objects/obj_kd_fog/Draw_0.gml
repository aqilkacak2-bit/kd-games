/// obj_kd_fog - Draw
// the strip tiles seamlessly: draw just enough copies to cover the camera
var _w   = sprite_get_width(spr);
var _off = (t * spd) mod _w;
var _yy  = area_y + top_off + round(sin(t * 0.35 + layer_i * 1.7) * 1.5);
var _cam = view_camera[0];
var _vx  = camera_get_view_x(_cam);
var _vw  = camera_get_view_width(_cam);
var _start = _off + floor((_vx - _off) / _w) * _w;
for (var _xx = _start; _xx < _vx + _vw; _xx += _w)
{
    draw_sprite_ext(spr, 0, _xx, _yy, 1, 1, 0, c_white, alpha_mul);
}
