/// obj_dash_fx - Create
// GML port of the "dash" effect from movement.ts (Sprite Fusion, MIT License, (c) 2026 Hugo Duprez).
// One instance per dash. obj_player moves itself; this object only draws the VFX:
// windup flash, dust + smoke kick, speed lines, afterimage ghosts, glow, skid sparks, skid marks, screen shake.
owner    = noone;
dir      = 1;          // dash direction
x0       = x;          // start x
g        = y;          // ground y (feet) at the start
grounded = true;       // only leave dust / skid marks when the dash started on the ground
dist     = 64;
d0       = 0.06;       // windup (seconds)
d1       = 0.26;       // dash end
t        = 0;
started  = false;
stopped  = false;
stop_x   = x;
end_x    = x;
last_ghost_x = undefined;
shake    = 0;

ghosts = [];           // { x, y, f, frame, t }
lines  = [];           // { x, y, l, t }
parts  = [];           // particles { k, x, y, vx, vy, life, max, col, size, seed }

// colours from movement.ts
C = [ make_colour_rgb(255, 255, 255), make_colour_rgb(204, 246, 255), make_colour_rgb(163, 220, 255),
      make_colour_rgb(94, 176, 255),  make_colour_rgb(91, 108, 255),  make_colour_rgb(119, 58, 228),
      make_colour_rgb(76, 37, 171) ];
COL_DUST  = make_colour_rgb(97, 87, 115);
COL_SMOKE = make_colour_rgb(96, 84, 112);
COL_SKID  = make_colour_rgb(34, 26, 51);
SMOKE_RAMP = [ make_colour_rgb(123, 111, 114), make_colour_rgb(93, 86, 96), make_colour_rgb(67, 61, 72),
               make_colour_rgb(43, 38, 48), make_colour_rgb(26, 23, 30) ];
SPARK_HOT = make_colour_rgb(255, 243, 166); SPARK_YEL = make_colour_rgb(255, 226, 107);
SPARK_ORA = make_colour_rgb(255, 138, 42);  SPARK_TAIL = make_colour_rgb(242, 86, 29);

// particle kinds
PK_SPARK = 0; PK_SMOKE = 3; PK_DUST = 4;
