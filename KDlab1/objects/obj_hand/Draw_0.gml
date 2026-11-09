/// obj_hand - Draw
if (!instance_exists(owner)) { instance_destroy(); exit; }
var _back = (side == "back");
var _by = round(owner.y) + owner.draw_bob - owner.recoil_lift;

// throwing a grenade: the front arm winds up and throws (the gun is put away for a moment)
if (!_back && owner.throw_t > 0)
{
    depth = owner.depth - 1;
    if (!owner.thrown)
    {
        var _h = kd_throw_hand(owner);
        draw_sprite_ext(spr_item, 1, _h[0], _h[1] + 4, 0.6, 0.6, 0, c_white, 1);   // grenade in hand
    }
    kd_draw_arm(round(owner.x), _by, owner.facing, owner.throw_ang, owner.look, 1, false);
    exit;
}

if (instance_exists(gun) && gun.visible)
{
    var _melee = (gun.weapon.type == "melee");
    if (!_back)
    {
        // trigger / sword hand on the grip, sleeve pointing back to the shoulder
        depth = gun.depth - 2;
        kd_draw_hand(round(gun.x), round(gun.y), gun.image_yscale, 1, gun.image_angle + 90, owner.look, 1);
        exit;
    }
    if (!_melee)
    {
        // support hand on the front of the gun (drawn over the gun, under the front hand)
        depth = gun.depth - 1;
        var _s = kd_support_hand(gun.x, gun.y, gun.image_angle, gun.image_yscale, gun.weapon, round(owner.x), _by, owner.facing, 1);
        kd_draw_hand(round(_s[0]), round(_s[1]), gun.image_yscale, 1, _s[2], owner.look, 1, KD_BACK_SHADE);
        exit;
    }
    // the keris is one-handed: the back arm keeps swinging normally (below)
}

// no weapon: swing from the shoulder pivot
if (_back)
{
    depth = owner.depth + 1;                       // behind the body
    kd_draw_arm(round(owner.x), _by, owner.facing, owner.arm_swing_back, owner.look, 1, true);
}
else
{
    depth = owner.depth - 1;
    kd_draw_arm(round(owner.x), _by, owner.facing, owner.arm_swing, owner.look, 1, false);
}
