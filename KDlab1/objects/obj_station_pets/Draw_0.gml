/// obj_station_pets - Draw: a charging pad with a hologram of your pet
#macro KD_LOBBY_PETS_X 205      // where the Robot Pet Bay stands in the lobby
t += 1;
var _g = make_colour_rgb(64, 226, 110);
var _k = kd_companion();
if (room == rm_lobby)
{
    // lobby: all four robots hover on their own pads; yours is lit, press E to choose
    var _kinds = ["laserbot", "shieldbot", "rocketbot", "coinbot"];
    for (var _i = 0; _i < 4; _i++)
    {
        var _px  = x - 45 + _i * 30;
        var _mine = (_k == _kinds[_i]);
        draw_set_colour(make_colour_rgb(20, 28, 34));
        draw_rectangle(_px - 10, y - 4, _px + 10, y - 1, false);
        draw_set_colour(_g);
        draw_line(_px - 10, y - 4, _px + 10, y - 4);
        gpu_set_blendmode(bm_add);
        draw_set_alpha((_mine ? 0.26 : 0.12) + 0.05 * sin((t + _i * 20) / 10));
        draw_triangle(_px - 8, y - 4, _px + 8, y - 4, _px, y - 36, false);
        draw_set_alpha(1);
        gpu_set_blendmode(bm_normal);
        var _pb = sin((t + _i * 25) / 14) * 2;
        draw_sprite_ext(spr_robot_pets, _i * 2 + (t div 8) mod 2, _px, y - 24 + _pb, 1, 1, 0, c_white, _mine ? 1 : 0.75);
        if (_mine)
        {
            draw_set_colour(_g);
            draw_triangle(_px - 3, y - 44, _px + 3, y - 44, _px, y - 40, false);
        }
    }
    draw_set_colour(c_white);
    exit;
}
draw_set_colour(make_colour_rgb(20, 28, 34));
draw_rectangle(x - 12, y - 4, x + 12, y - 1, false);
draw_set_colour(_g);
draw_line(x - 12, y - 4, x + 12, y - 4);
gpu_set_blendmode(bm_add);
draw_set_alpha(0.18 + 0.06 * sin(t / 10));
draw_triangle(x - 10, y - 4, x + 10, y - 4, x, y - 34, false);
draw_set_alpha(1);
draw_circle_colour(x, y - 22, 12, make_colour_rgb(20, 70, 40), c_black, false);
gpu_set_blendmode(bm_normal);
var _bob = sin(t / 14) * 2;
var _fr = -1;
switch (_k)
{
    case "laserbot":  _fr = 0; break;
    case "shieldbot": _fr = 2; break;
    case "rocketbot": _fr = 4; break;
    case "coinbot":   _fr = 6; break;
}
if (_fr >= 0) draw_sprite_ext(spr_robot_pets, _fr + (t div 8) mod 2, x, y - 22 + _bob, 1, 1, 0, c_white, 0.85);
else if (_k == "pet") draw_sprite_ext(spr_run_items, 9, x, y - 22 + _bob, 1, 1, 0, c_white, 0.85);
else draw_sprite_ext(spr_robot_pets, (t div 30) mod 8, x, y - 22 + _bob, 1, 1, 0, c_white, 0.5);   // cycles through them
draw_set_colour(c_white);
