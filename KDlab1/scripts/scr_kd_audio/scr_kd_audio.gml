/// Sound effects. All sounds are in the "Sounds" folder (snd_*), generated for this project.
/// kd_sfx(snd, [pitch_variation], [gain]) plays a one-shot with a little random pitch so repeats don't sound robotic.

function kd_sfx(_snd, _var, _gain)
{
    if (!variable_global_exists("kd_sfx_vol") || global.kd_sfx_vol <= 0) return -1;
    if (is_undefined(_var))  _var = 0.05;
    if (is_undefined(_gain)) _gain = 1;
    var _i = audio_play_sound(_snd, 5, false);
    audio_sound_pitch(_i, 1 + random_range(-_var, _var));
    audio_sound_gain(_i, _gain * global.kd_sfx_vol, 0);
    return _i;
}

/// start / stop the looping lab hum to match the setting
function kd_ambience_update()
{
    var _want = global.kd_hum_on && global.kd_sfx_vol > 0;
    if (_want && !audio_is_playing(snd_lab_hum))
    {
        var _i = audio_play_sound(snd_lab_hum, 1, true);
        audio_sound_gain(_i, 0.35 * global.kd_sfx_vol, 0);
    }
    else if (!_want && audio_is_playing(snd_lab_hum))
    {
        audio_stop_sound(snd_lab_hum);
    }
}

/// like kd_sfx, but around a base pitch (deep shotgun boom, high blaster zap, ...)
function kd_sfx_p(_snd, _pitch, _var, _gain)
{
    var _i = kd_sfx(_snd, _var, _gain);
    if (_i >= 0) audio_sound_pitch(_i, _pitch * (1 + random_range(-_var, _var)));
    return _i;
}
