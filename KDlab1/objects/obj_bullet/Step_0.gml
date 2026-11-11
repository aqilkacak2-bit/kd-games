/// obj_bullet - Step  (built-in speed / direction move it)
life -= 1;
var _hit  = false;
var _wall = false;

// ---------- motion per kind ----------
switch (kind)
{
    case "rocket":
        speed = min(speed + 0.3, 9);           // starts slow, speeds up
        image_angle = direction;
        if (life mod 2 == 0)
        {
            var _s = instance_create_depth(x - lengthdir_x(5, direction), y - lengthdir_y(5, direction), depth + 1, obj_kd_fx);
            _s.kind = "smoke";
            _s.life = 26;
            _s.r    = 2.5;
        }
        break;
    case "grenade":
        vspeed += grav;
        image_angle += 14 * sign(hspeed);
        break;
    case "flame":
        speed  *= 0.95;                        // flames slow down and drift up
        vspeed -= 0.035;
        break;
}

// ---------- walls ----------
if (kind == "grenade")
{
    // grenades bounce and roll, losing energy each time
    var _b = false;
    if (place_meeting(x + hspeed, y, obj_solid)) { hspeed = -hspeed * 0.6; _b = true; }
    if (place_meeting(x, y + vspeed, obj_solid))
    {
        if (thrown && !landed && vspeed > 0) { landed = true; life = min(life, 45); }   // landed: explodes in 0.75 s
        vspeed = -vspeed * 0.5;
        hspeed *= 0.8;
        if (abs(vspeed) < 0.6) vspeed = 0;
        _b = true;
    }
    if (_b && speed > 1) kd_sfx_p(snd_step, 1.3, 0.1, 0.5);
}
else if (bounces > 0)
{
    // Recursion Blaster: look one step ahead and mirror off whatever wall is there
    var _bounced = false;
    var _in_dir = direction;
    var _nrm = 90;
    if (place_meeting(x + hspeed, y, obj_solid)) { hspeed = -hspeed; _bounced = true; _nrm = (hspeed > 0) ? 0 : 180; }
    if (place_meeting(x, y + vspeed, obj_solid)) { vspeed = -vspeed; _bounced = true; _nrm = (vspeed < 0) ? 90 : 270; }
    if (_bounced)
    {
        bounces -= 1;
        image_angle = direction;
        // impact.ts "ricochet": glancing streak + chips off the wall
        kd_vfx_impact(x, y, _in_dir, true, kd_pal().wall, _nrm, (_nrm == 90) ? y + 1 : 100000, 0.6);
        kd_sfx(snd_ricochet, 0.15, 0.35);
    }
}
else if (place_meeting(x, y, obj_solid))
{
    if (kind == "flame") { speed = 0; life = min(life, 6); }   // flames splash on walls
    else _wall = true;
}

// ---------- item boxes take damage from bullets ----------
if (_wall && kind != "flame")
{
    var _box = instance_place(x, y, obj_item_box);
    if (_box != noone) kd_box_damage(_box, max(damage, 5));
}

// ---------- people ----------
var _npc = instance_place(x, y, obj_kd_npc);
if (_npc != noone)
{
    var _seen = false;
    for (var _i = 0; _i < array_length(hit_list); _i++) if (hit_list[_i] == _npc) _seen = true;
    if (!_seen)
    {
        array_push(hit_list, _npc);
        if (ignite > 0 && _npc.freeze <= 0 && irandom(99) < 15 * ignite) _npc.burn = max(_npc.burn, 120);
        if (chill > 0 && irandom(99) < 12 * chill) { _npc.freeze = max(_npc.freeze, 90); _npc.burn = 0; }
        switch (kind)
        {
            case "rocket":
            case "grenade":
                _hit = true;                    // explodes below
                break;
            case "flame":
                if (_npc.freeze <= 0)
                {
                    if (_npc.burn <= 0) kd_npc_hit(_npc, direction, 0, "", damage);
                    _npc.burn = max(_npc.burn, burn);
                }
                break;
            case "ice":
                if (_npc.ko > 0) break;
                kd_npc_damage(_npc, damage);
                _npc.freeze = max(_npc.freeze, freeze);
                _npc.burn   = 0;
                _npc.hit_flash = 4;
                if (_npc.bubble_timer <= 0)
                {
                    _npc.bubble_text  = choose("So... cold...", "Frozen like a stuck build!", "Can't... move...");
                    _npc.bubble_timer = 90;
                }
                kd_sfx_p(snd_hit, 1.6, 0.1, 0.5);
                _hit = true;
                break;
            default:
                kd_npc_hit(_npc, direction, knock, choose("Ouch!", "Hey! Watch it!", "Not cool!", "I'm on your team!"), damage);
                if (pierce > 0)
                {
                    pierce -= 1;                // Deploy Rifle: keep flying through
                    kd_vfx_impact(x, y, direction, false, -1, 0, _npc.y, 0.9);
                }
                else _hit = true;
        }
    }
}

// ---------- end of life ----------
var _out = (x < -16 || y < -16 || x > room_width + 16 || y > room_height + 16);
if (_hit || _wall || life <= 0 || _out)
{
    if (blast > 0 && !_out)
    {
        kd_explode(x, y, blast, blast_knock, blast_damage);   // rockets + grenades
    }
    else if (_hit || _wall)
    {
        // impact.ts: on a person, or on the wall (which way the wall faces = where the chips fly)
        var _isz = clamp(0.35 + damage / 40, 0.35, 1.3);
        if (_wall)
        {
            var _nrm2 = (hspeed > 0) ? 180 : 0;
            if (place_meeting(xprevious, y, obj_solid)) _nrm2 = (vspeed > 0) ? 90 : 270;
            kd_vfx_impact(xprevious, yprevious, direction, false, kd_pal().wall, _nrm2, (_nrm2 == 90) ? y : 100000, _isz);
            if (kind != "ice") kd_sfx(snd_ricochet, 0.15, 0.5);
        }
        else
        {
            var _gy = 100000;
            if (_npc != noone) _gy = _npc.y;
            kd_vfx_impact(x, y, direction, false, -1, 0, _gy, _isz);
        }
    }
    instance_destroy();
}
// normal bullets fade out over their last few steps (shotgun pellets have a short range)
if (kind == "bullet") image_alpha = min(1, life / 8);
