/// obj_title - Draw GUI  (the sunset skyline is the room background)
var _green = make_colour_rgb(64, 226, 110);
var _dark  = make_colour_rgb(18, 22, 30);
var _grey  = make_colour_rgb(160, 168, 180);
draw_set_font(KD_FONT_TEXT);
draw_set_valign(fa_top);

// darken the top so the logo reads well
draw_set_alpha(0.35);
draw_set_colour(c_black);
draw_rectangle(0, 0, 1280, 380, false);
draw_set_alpha(1);

// ---------- logo ----------
var _bob = sin(t / 40) * 6;
draw_set_halign(fa_center);
// glow: the logo drawn a few times, offset, in soft green
draw_set_colour(_green);
draw_set_alpha(0.18);
for (var _a = 0; _a < 360; _a += 45)
{
    kd_title_text(640 + lengthdir_x(5, _a), 120 + _bob + lengthdir_y(5, _a), "<KD/>", 7, 7, 0);
}
draw_set_alpha(1);
draw_set_colour(make_colour_rgb(16, 60, 34));
kd_title_text(640 + 5, 120 + _bob + 5, "<KD/>", 7, 7, 0);       // drop shadow
draw_set_colour(_green);
kd_title_text(640, 120 + _bob, "<KD/>", 7, 7, 0);
draw_set_colour(c_white);
kd_title_text(640, 262 + _bob, "K R A C K E D D E V S   L A B", 2, 2, 0);
draw_set_colour(_grey);
kd_title_text(640, 312, "Learn. Build. Ship.", 1.3, 1.3, 0);

// ---------- menu ----------
for (var _i = 0; _i < array_length(menu); _i++)
{
    var _by = 420 + _i * 64;
    var _on = (_i == sel);
    draw_set_alpha(0.9);
    draw_set_colour(_dark);
    if (_on) draw_set_colour(make_colour_rgb(30, 70, 46));
    draw_roundrect_ext(640 - 150, _by, 640 + 150, _by + 52, 14, 14, false);
    draw_set_alpha(1);
    draw_set_colour(_grey);
    if (_on) draw_set_colour(_green);
    draw_roundrect_ext(640 - 150, _by, 640 + 150, _by + 52, 14, 14, true);
    var _label = menu[_i];
    if (_on && (t div 20) mod 2 == 0) _label = "> " + _label + " <";
    draw_set_colour(c_white);
    if (_on) draw_set_colour(_green);
    kd_title_text(640, _by + 14, _label, 1.5, 1.5, 0);
}
draw_set_colour(_grey);
draw_text_transformed(640, 616, "W / S or arrows to choose   -   ENTER or click to select", 0.9, 0.9, 0);
draw_set_halign(fa_left);

// ---------- builders walking along the rooftop ----------
for (var _i = 0; _i < array_length(walkers); _i++)
{
    var _w = walkers[_i];
    kd_draw(_w.x, 712, 1, "walk", (t div 6) + _i, _w.look, 3, c_white, 1, true);
}

// version line
draw_set_colour(_grey);
draw_text_transformed(16, 16, "KDlab1   |   12 weapons   |   7 rooms", 0.8, 0.8, 0);

// ---------- controls panel ----------
if (show_controls)
{
    draw_set_alpha(0.6);
    draw_set_colour(c_black);
    draw_rectangle(0, 0, 1280, 720, false);
    draw_set_alpha(0.97);
    draw_set_colour(_dark);
    draw_roundrect_ext(240, 40, 1040, 690, 16, 16, false);
    draw_set_alpha(1);
    draw_set_colour(_green);
    draw_roundrect_ext(240, 40, 1040, 690, 16, 16, true);
    kd_title_text(270, 56, "Controls", 2, 2, 0);
    var _rows = [
        ["A / D  or  arrows", "Walk   (hold SHIFT to run)"],
        ["SPACE", "Jump"],
        ["W / S", "Climb ladders and stairs"],
        ["R", "Dash"],
        ["E", "Use a station / go through a door"],
        ["MOUSE + LEFT CLICK", "Aim and shoot / swing"],
        ["1 - 9, 0, -, =", "Pick one of the 12 weapons"],
        ["MOUSE WHEEL", "Next / previous weapon"],
        ["Q", "Holster or draw your weapon"],
        ["F", "Shield dome - blocks explosions (8 s cooldown)"],
        ["H", "Heal 40 HP (10 s cooldown)"],
        ["G", "Throw a grenade at the mouse (find more in boxes)"],
        ["M", "Lab map: corner / big / hidden"],
        ["T  or  ENTER", "Chat"],
        ["F2", "Change the screen shader"]
    ];
    for (var _r = 0; _r < array_length(_rows); _r++)
    {
        draw_set_colour(_green);
        draw_text(280, 112 + _r * 34, _rows[_r][0]);
        draw_set_colour(c_white);
        draw_text(560, 112 + _r * 34, _rows[_r][1]);
    }
    draw_set_colour(_grey);
    draw_set_halign(fa_right);
    draw_text(1016, 656, "click or ESC to go back");
    draw_set_halign(fa_left);
}

// fade to black on START
if (fade > 0)
{
    draw_set_alpha(fade);
    draw_set_colour(c_black);
    draw_rectangle(0, 0, 1280, 720, false);
}
draw_set_alpha(1);
draw_set_colour(c_white);
