/// obj_pet - Create  (pets from run items; kd_pets_sync sets kind + idx)
//   "pet"        Bug Pet: shoots small bullets
//   "laserbot"   zaps the nearest enemy with a laser beam
//   "shieldbot"  circles you and eats enemy bullets
//   "rocketbot"  fires homing mini rockets
//   "coinbot"    flies off to grab coins and brings them to you
kind     = "pet";
idx      = 0;
t        = irandom(100);
cd       = 40;
face     = 1;
orbit    = 0;          // shieldbot angle
beam_t   = 0;          // laserbot: beam visible for a few steps
beam_x   = 0;
beam_y   = 0;
rockets  = [];         // rocketbot: { x, y, dir, life }
carry    = noone;      // coinbot: the coin it is bringing back
