/// obj_select_lineup - Draw   (the 6 preset characters on the display pods)
var _n = min(kd_preset_count(), array_length(pods_x));
var _frame = t div 15;
for (var _i = 0; _i < _n; _i++)
{
    kd_draw(pods_x[_i], pod_y, 1, "idle", _frame + _i, kd_preset_get(_i).look, 1, c_white, 1, false);
}
