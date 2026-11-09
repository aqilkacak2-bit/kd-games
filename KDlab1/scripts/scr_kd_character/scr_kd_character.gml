/// KD Character - layered (paper-doll) drawing helpers
/// Draw order: hair_back -> legs -> skirt -> body -> cloth -> head -> hair
/// hair_back and skirt are optional (set to -1 when a character has none).
/// Swap any part for a new outfit/hairstyle, as long as it is 32x32 with origin (16,32).

/// @function kd_parts_default()
/// @desc Returns a struct with the default KD part sprites
function kd_parts_default()
{
    return {
        hair_back : -1,
        legs  : spr_kd_legs,
        skirt : -1,
        body  : spr_kd_body,
        cloth : spr_kd_cloth,
        head  : spr_kd_head,
        hair  : spr_kd_hair
    };
}

/// @function kd_parts_girl()
/// @desc Girl variant: long hair (front + back layer), baju kurung top, songket skirt.
///       Uses the same legs sprite as the boy, so the walk cycle is shared.
function kd_parts_girl()
{
    return {
        hair_back : spr_kd_girl_hair_back,
        legs  : spr_kd_legs,
        skirt : spr_kd_girl_skirt,
        body  : spr_kd_girl_body,
        cloth : spr_kd_girl_cloth,
        head  : spr_kd_girl_head,
        hair  : spr_kd_girl_hair
    };
}

/// @function kd_anim_length(_state)
/// @desc Number of frames in an animation state ("idle" = 4, "walk" = 6)
function kd_anim_length(_state)
{
    if (_state == "walk") return 6;
    return 4;
}

/// @function kd_anim_fps(_state)
function kd_anim_fps(_state)
{
    if (_state == "walk") return 10;
    return 4;
}

/// @function kd_draw(_x, _y, _xscale, _state, _frame, _look, _scale, _col, _alpha, [_shadow])
/// @param _x       feet x
/// @param _y       feet y
/// @param _xscale  1 = face right, -1 = face left
/// @param _state   "idle" or "walk"
/// @param _frame   current animation frame
/// @param _look    look struct (scr_kd_custom -> kd_look_make)
/// @param _scale   draw scale (1 = pixel size)
/// @param _col     blend colour (c_white = normal)
/// @param _alpha   alpha
/// @param _shadow  (optional) draw the soft shadow under the feet, default true
/// @param _arm     (optional) front arm swing in degrees; undefined = automatic swing from the animation,
///                 KD_ARM_NONE = don't draw the arms (obj_hand draws both arms for the player)
///                 The back arm always swings the opposite way.
/// Draw order: hair back -> BACK ARM -> legs -> skirt -> body -> top -> face -> hair -> FRONT ARM
#macro KD_ARM_NONE -999
function kd_draw(_x, _y, _xscale, _state, _frame, _look, _scale, _col, _alpha, _shadow, _arm)
{
    static idle_bob = [0, 0, 1, 1];
    static walk_bob = [0, 1, 0, 0, 1, 0];
    if (is_undefined(_shadow)) _shadow = true;
    var _d = kd_custom_data();

    var _len = kd_anim_length(_state);
    var _f   = ((_frame mod _len) + _len) mod _len;
    var _prev = (_f + _len - 1) mod _len;

    var _bob, _prev_bob, _leg_img;
    if (_state == "walk")
    {
        _bob      = walk_bob[_f];
        _prev_bob = walk_bob[_prev];
        _leg_img  = 1 + _f;            // leg frames 1..6 = walk cycle
    }
    else
    {
        _bob      = idle_bob[_f];
        _prev_bob = idle_bob[_prev];
        _leg_img  = 0;                 // leg frame 0 = standing
    }
    // long hair: only the tips trail 1px on the frame the body drops
    var _tips = 0;
    if (_bob > _prev_bob) _tips = 1;

    var _xs = _xscale * _scale;
    var _by = _y + _bob * _scale;

    if (_shadow)
    {
        draw_set_alpha(0.25 * _alpha);
        draw_set_colour(c_black);
        draw_ellipse(_x - 7 * _scale, _y - 2 * _scale, _x + 7 * _scale, _y + 1 * _scale, false);
        draw_set_alpha(1);
        draw_set_colour(c_white);
    }

    if (is_undefined(_arm)) _arm = kd_arm_swing(_state, _f, 0);

    // back arm (behind the body, darker, opposite swing)
    if (_arm != KD_ARM_NONE) kd_draw_arm(_x, _by, _xscale, -_arm * KD_BACK_SWING, _look, _scale, true);

    var _hb = _d.hair_back_spr[_look.hair];
    if (_hb != -1) draw_sprite_ext(_hb, _look.hair_col * 2 + _tips, _x, _by, _xs, _scale, 0, _col, _alpha);
    draw_sprite_ext(spr_cz_legs, _look.bottom_col * 7 + _leg_img, _x, _y, _xs, _scale, 0, _col, _alpha);
    var _sk = _d.skirt_spr[_look.bottom];
    if (_sk != -1) draw_sprite_ext(_sk, _look.bottom_col, _x, _by, _xs, _scale, 0, _col, _alpha);
    draw_sprite_ext(spr_cz_body, _look.skin, _x, _by, _xs, _scale, 0, _col, _alpha);
    draw_sprite_ext(_d.top_spr[_look.top], _look.top_col, _x, _by, _xs, _scale, 0, _col, _alpha);
    draw_sprite_ext(_d.face_spr[_look.face], _look.skin, _x, _by, _xs, _scale, 0, _col, _alpha);
    draw_sprite_ext(_d.hair_spr[_look.hair], _look.hair_col, _x, _by, _xs, _scale, 0, _col, _alpha);

    // front arm (same hand sprite as obj_hand), swinging from the shoulder
    if (_arm != KD_ARM_NONE) kd_draw_arm(_x, _by, _xscale, _arm, _look, _scale, false);
}

/// automatic arm swing for a frame: forward / back while walking, still when idle
function kd_arm_swing(_state, _frame, _sub)
{
    if (_state == "walk") return sin(((_frame + _sub) / 6) * 2 * pi) * 28;
    return 0;
}

/// shoulder pivot relative to the feet (x is mirrored by facing)
#macro KD_SHOULDER_X -4
#macro KD_SHOULDER_Y -14
#macro KD_ARM_LEN 6
#macro KD_BACK_SHOULDER_X 1        // back shoulder (behind the body)
#macro KD_BACK_SWING 1.4           // back arm swings a bit wider so it peeks out past the body
#macro KD_BACK_SHADE 0.78          // back hand is a bit darker
/// gun aim pivot (chest) - the gun rotates around this point
#macro KD_AIM_X 3
#macro KD_AIM_Y -11

/// draws an arm hanging from the shoulder, rotated by _swing degrees (0 = straight down, + = forward)
/// _back = true: the back arm (back shoulder, darker)
function kd_draw_arm(_x, _body_y, _facing, _swing, _look, _scale, _back)
{
    var _shx = KD_SHOULDER_X;
    var _shade = 1;
    if (!is_undefined(_back) && _back) { _shx = KD_BACK_SHOULDER_X; _shade = KD_BACK_SHADE; }
    var _sx = _x + _facing * _shx * _scale;
    var _sy = _body_y + KD_SHOULDER_Y * _scale;
    var _hx = _sx + lengthdir_x(KD_ARM_LEN * _scale, 270 + _swing * _facing);
    var _hy = _sy + lengthdir_y(KD_ARM_LEN * _scale, 270 + _swing * _facing);
    kd_draw_hand(_hx, _hy, _facing, 1, _swing * _facing, _look, _scale, _shade);
}

/// two-handed hold: where the back hand grabs the gun, and its angle (sleeve towards the back shoulder)
/// returns [x, y, angle]
function kd_support_hand(_gx, _gy, _aim, _ys, _wp, _owner_x, _body_y, _facing, _scale)
{
    var _hx = _gx + lengthdir_x(_wp.support_x * _scale, _aim) + lengthdir_x(_wp.support_y * _ys * _scale, _aim - 90);
    var _hy = _gy + lengthdir_y(_wp.support_x * _scale, _aim) + lengthdir_y(_wp.support_y * _ys * _scale, _aim - 90);
    var _bsx = _owner_x + _facing * KD_BACK_SHOULDER_X * _scale;
    var _bsy = _body_y + KD_SHOULDER_Y * _scale;
    var _ang = point_direction(_hx, _hy, _bsx, _bsy) - 90;
    return [_hx, _hy, _ang];
}

/// @function kd_anim_bob(_state, _frame)
/// @desc body bob (0 or 1 px) for a frame - lets hands / guns move with the body
function kd_anim_bob(_state, _frame)
{
    static idle_bob = [0, 0, 1, 1];
    static walk_bob = [0, 1, 0, 0, 1, 0];
    var _len = kd_anim_length(_state);
    var _f = ((_frame mod _len) + _len) mod _len;
    if (_state == "walk") return walk_bob[_f];
    return idle_bob[_f];
}
