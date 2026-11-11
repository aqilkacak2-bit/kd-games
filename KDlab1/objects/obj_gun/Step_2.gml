/// obj_gun - End Step  (runs after the player has moved, so the weapon never lags behind)
if (!equipped)
{
    // lying on a table / floor; disappears once the player owns this weapon
    if (kd_weapon_owned(weapon_key)) { instance_destroy(); exit; }
    bob += 3;
    image_angle = 0;
    image_yscale = 1;
    exit;
}

if (!instance_exists(owner)) { instance_destroy(); exit; }

visible = global.kd_weapon_out && owner.mode != "ladder" && owner.throw_t <= 0;   // put away while throwing a grenade
var _melee = (weapon.type == "melee");

// aim pivot at chest height (moves with the body bob)
var _sx = owner.x + owner.facing * KD_AIM_X;
var _sy = owner.y + KD_AIM_Y + owner.draw_bob - owner.recoil_lift;

// aim at the mouse (mouse_x / mouse_y are room coordinates)
aim_dir = point_direction(_sx, _sy, mouse_x, mouse_y);

// standing on the floor, guns can't point more than 40 degrees down:
// a long barrel aimed straight down went into the floor and made you look like you were floating on it
if (!_melee && owner.mode == "normal" && owner.on_ground && aim_dir > 220 && aim_dir < 320)
{
    if (aim_dir < 270) aim_dir = 220;
    else aim_dir = 320;
}

recoil   = max(0, recoil - 0.5);
cooldown = max(0, cooldown - 1);
if (flash > 0) flash -= 1;
if (burst_timer > 0) burst_timer -= 1;

// flip so the weapon is never upside-down when aiming left
if (aim_dir > 90 && aim_dir < 270) image_yscale = -1;
else image_yscale = 1;

var _dist = weapon.hold_dist - recoil;   // shoulder -> grip
if (_melee)
{
    // blade angle: raised over the shoulder at rest, sweeps through the arc while swinging
    var _off = 55;
    if (swing_t > 0)
    {
        swing_t -= 1;
        var _u = 1 - swing_t / weapon.swing_time;    // 0 -> 1 through the swing
        var _e = 1 - power(1 - _u, 3);                // fast start, soft finish
        _off = swing_dir * lerp(weapon.arc, -weapon.arc, _e);
        if (_u > 0.1 && _u < 0.9) kd_sword_hit();
    }
    image_angle = aim_dir + image_yscale * _off;
    // the hand follows half of the blade's turn so the arm moves with the slash
    var _ga = aim_dir + image_yscale * _off * 0.5;
    x = _sx + lengthdir_x(_dist, _ga);
    y = _sy + lengthdir_y(_dist, _ga);
}
else
{
    x = _sx + lengthdir_x(_dist, aim_dir);
    y = _sy + lengthdir_y(_dist, aim_dir);
    kick_ang = max(0, kick_ang - 1.5);
    image_angle = aim_dir + kick_ang * image_yscale;     // recoil: the muzzle flips up, then settles
}

depth = owner.depth - 1;

// ---------- attacking ----------
var _fire = false;
if (weapon.auto) _fire = mouse_check_button(mb_left);
else _fire = mouse_check_button_pressed(mb_left);
var _can = visible && !global.ui_block && !global.mouse_over_ui;

if (_can && _fire && cooldown == 0 && burst_left == 0)
{
    switch (weapon.type)
    {
        case "melee":
            cooldown   = round(weapon.fire_delay * kd_rate_mult());
            swing_dir  = -swing_dir;
            swing_t    = weapon.swing_time;
            swing_hit  = [];
            swing_from = aim_dir + image_yscale * swing_dir * weapon.arc;
            kd_sfx_p(snd_dash, weapon.pitch, 0.1, 0.55);
            break;
        case "beam":
            beam_on = 3;                         // stays on while the button is held
            break;
        case "lightning":
            cooldown = round(weapon.fire_delay * kd_rate_mult());
            kd_lightning_fire();
            break;
        default:
            cooldown    = round(weapon.fire_delay * kd_rate_mult());
            burst_left  = weapon.burst;
            burst_timer = 0;
    }
}

// laser: update the beam every step it is on
if (weapon.type == "beam" && beam_on > 0)
{
    kd_beam_update();
    beam_on -= 1;
}

// guns: shots come out here (one per trigger pull, or a burst spread over a few steps)
if (weapon.type == "gun" && burst_left > 0 && burst_timer == 0)
{
    if (visible) kd_gun_shoot();
    burst_left  -= 1;
    burst_timer  = weapon.burst_gap;
}
if (!visible) { burst_left = 0; swing_t = 0; beam_on = 0; }
