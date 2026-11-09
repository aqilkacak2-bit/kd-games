/// obj_kd_fx - Create
// Short-lived weapon effects. Whoever creates it sets "kind":
//   "boom"  explosion flash + shockwave ring   (r = radius)
//   "smoke" grey puff that drifts up            (r = size)
//   "ember" tiny spark rising off a burning person
//   "bolt"  lightning through the points in pts = [x1, y1, x2, y2, ...]
kind = "boom";
t    = 0;
life = 20;
r    = 30;
pts  = [];
col  = c_white;
vx   = random_range(-0.3, 0.3);
vy   = -random_range(0.2, 0.6);
seed = irandom(100000);   // keeps a bolt's shape steady between its glow and core
