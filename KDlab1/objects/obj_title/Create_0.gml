/// obj_title - Create  (room 1: title screen)
kd_globals_init();
display_set_gui_size(1280, 720);
draw_set_font(KD_FONT_TEXT);
if (!variable_global_exists("kd_sfx_vol")) global.kd_sfx_vol = 1;

menu = ["START", "CONTROLS", "QUIT"];
sel  = 0;
t    = 0;
show_controls = false;
fade = 0;                  // fades to black when you press START
starting = false;
mx_prev = 0;               // mouse only changes the selection when it actually moves
my_prev = 0;

// the six preset builders walk across the bottom of the screen
walkers = [];
for (var _i = 0; _i < kd_preset_count(); _i++)
{
    array_push(walkers, {
        look : kd_look_copy(kd_preset_get(_i).look),
        x    : -80 - _i * 150,
        spd  : random_range(1.6, 2.2)
    });
}
