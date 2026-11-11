/// obj_game - Create
// Controls the HUD (EXP / level), chat, chat settings, info panels, the Character Select
// screen, room doors, weapon pick-up and the mouse aiming circle.
// PERSISTENT: it is placed in every room, but only the first one survives.
if (instance_number(obj_game) > 1)
{
    instance_destroy();
    exit;
}
kd_globals_init();
display_set_gui_size(1280, 720);
draw_set_font(KD_FONT_TEXT);

// ---------- globals ----------
global.ui_block          = false;   // true = player can't move (typing / panel open)
global.kd_exp            = 0;
global.kd_toasts         = [];
global.kd_chat_log       = [];
global.kd_chat_log_timer = 0;

// chat settings
global.kd_name           = "Builder";
global.kd_show_bubbles   = true;
global.kd_show_log       = true;
global.kd_bubble_time    = 5;       // seconds
global.kd_npc_replies    = true;

// ---------- state ----------
chat_typing   = false;
chat_text     = "";
name_editing  = false;
settings_open = false;
panel_open    = false;
panel         = undefined;
near_station  = noone;
first_chat    = true;
pending       = [];                 // NPC replies waiting to be said
blink         = 0;

// ---------- GUI layout ----------
chat_btn = [1280 - 124, 16, 1280 - 72, 60];
discord_btn = [1280 - 186, 16, 1280 - 134, 60];
gear_btn = [1280 - 62,  16, 1280 - 16, 60];

set_w = 520; set_h = 520;
set_x1 = (1280 - set_w) / 2; set_y1 = (720 - set_h) / 2;
set_rows = ["name", "bubbles", "log", "time", "npc", "shader", "sfx", "hum", "close"];

pan_x1 = 200; pan_y1 = 100; pan_x2 = 1080; pan_y2 = 620;

// KD Feed (computer)
feed_events = [];
feed_index  = 0;
feed_prev_btn = [230, 562, 290, 602];
feed_next_btn = [450, 562, 510, 602];

// welcome
alarm_daily = 30;
kd_chat_add("KD", "Welcome to the KrackedDevs lab! Press T to chat, E to interact.", make_colour_rgb(80, 230, 120));


// ---------- Character Customiser ----------
select_open = false;          // customiser open
select_t    = 0;
cz_look     = undefined;      // the look being edited (copied from global.kd_look)
cz_row      = 0;              // highlighted row
cz_x1 = 70;  cz_y1 = 40;  cz_x2 = 1210; cz_y2 = 680;
cz_rows_x1 = 470; cz_rows_x2 = 1180; cz_rows_y = 108; cz_row_h = 50;
cz_btn_random = [100, 596, 290, 646];
cz_btn_reset  = [300, 596, 440, 646];
cz_btn_cancel = [860, 596, 1010, 646];
cz_btn_wear   = [1020, 596, 1180, 646];
first_select = true;

// ---------- weapon pick-up + aiming ----------
near_gun    = noone;
cursor_hidden = false;


// ---------- shader (post-process on the whole game) ----------
// 0 = off, 1 = Clean, 2 = CRT, 3 = Neon   (F2 or Chat settings to change)
global.kd_shader = 1;
global.kd_flash  = 0;
shader_names = ["Off", "Clean", "CRT", "Neon"];
u_time  = shader_get_uniform(sh_kd_post, "u_time");
u_texel = shader_get_uniform(sh_kd_post, "u_texel");
u_uvmax = shader_get_uniform(sh_kd_post, "u_uvmax");
u_mode  = shader_get_uniform(sh_kd_post, "u_mode");
u_pix   = shader_get_uniform(sh_kd_post, "u_pix");
u_flash = shader_get_uniform(sh_kd_post, "u_flash");
application_surface_draw_enable(false);    // obj_game draws it (with the shader) in Post Draw

// ---------- sound ----------
global.kd_sfx_vol = 1;       // 0 .. 1
global.kd_hum_on  = true;    // looping lab hum
kd_ambience_update();

// ---------- Discord ----------
discord_req = -1;

// skill tree (K)
skills_open  = false;
st_page      = 0;      // 0 = skills, 1 = trails
st_hover     = "";
st_t         = 0;
st_pulse     = 0;
st_pulse_key = "";

// Robot Pet Bay + KD Item Shop panels
pets_open  = false;
pb_sel     = 0;
pb_t       = 0;
shop_open  = false;
sh_t       = 0;
sh_hover   = -1;
sh_pulse   = 0;
sh_pulse_i = -1;
