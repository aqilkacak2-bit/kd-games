/// Shared globals + the six preset characters (presets live in scr_kd_custom -> kd_custom_data().presets)

function kd_globals_init()
{
    if (!variable_global_exists("kd_look"))       global.kd_look = kd_look_copy(kd_preset_get(0).look);   // what you wear
    if (!variable_global_exists("kd_weapon"))     global.kd_weapon = "smg";    // you start with all 12 weapons, SMG in hand
    if (!variable_global_exists("kd_weapon_out")) global.kd_weapon_out = true; // Q holsters / draws
    if (!variable_global_exists("kd_owned"))      global.kd_owned = kd_weapon_order();   // every weapon, from the start
    if (!variable_global_exists("kd_prev_room"))  global.kd_prev_room = -1;    // room you came from (doors)
    if (!variable_global_exists("kd_grenades"))   global.kd_grenades = 5;      // hand grenades (G), refill from item boxes
    if (!variable_global_exists("kd_arrive_fx"))  global.kd_arrive_fx = false; // power-up when you arrive after choosing a character
    if (!variable_global_exists("kd_minimap"))    global.kd_minimap = 1;       // M: 1 = corner map, 2 = big map, 0 = hidden
    if (!variable_global_exists("kd_shake"))      global.kd_shake = 0;         // screen shake from explosions
    if (!variable_global_exists("ui_block"))      global.ui_block = false;
    if (!variable_global_exists("mouse_over_ui")) global.mouse_over_ui = false;
}

function kd_preset_count()
{
    return array_length(kd_custom_data().presets);
}

function kd_preset_get(_i)
{
    var _p = kd_custom_data().presets;
    return _p[clamp(_i, 0, array_length(_p) - 1)];
}

/// put a look on a player (the hand + gun read owner.look, so they update too)
function kd_apply_look(_player, _look)
{
    with (_player) look = kd_look_copy(_look);
}
