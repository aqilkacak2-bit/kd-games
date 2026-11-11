/// obj_bullet - Create
// Every projectile: bullets, flames, ice, rockets, grenades. kd_gun_shoot() sets these from the weapon.
kind        = "bullet";
life        = 90;
life_max    = 90;
pierce      = 0;     // NPCs this bullet can still pass through
bounces     = 0;     // wall bounces left
knock       = 1;     // knockback in pixels
damage      = 6;     // health taken from the person it hits
blast_damage = 0;    // explosion damage (rockets / grenades)
burn        = 0;     // flame: how long the person burns
freeze      = 0;     // ice: how long the person stays frozen
blast       = 0;     // rocket / grenade explosion radius
blast_knock = 0;
grav        = 0;     // grenade gravity
thrown      = false; // hand grenade (G): the fuse starts when it lands
landed      = false;
hit_list    = [];    // NPCs already hit (so a piercing bullet hits each person once)
image_speed = 0;
ignite      = 0;     // item Hot Fix: chance to set enemies on fire
chill       = 0;     // item Cold Cache: chance to freeze
