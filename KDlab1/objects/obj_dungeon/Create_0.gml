/// obj_dungeon - Create: builds the current arena of the Neon Dungeon run
depth = 200;                 // draws the background, behind everything
if (!kd_run_active()) kd_run_start();     // started the room straight from the editor
var _run = global.kd_run;
type      = _run.plan[_run.idx];
t         = 0;
cleared   = false;
queue     = [];              // enemies waiting to come out of their portals
solids    = [];              // [x, y, w, h] of every wall / platform (for drawing)
platforms = [];
banner    = "";
banner_t  = 0;
hue       = (_run.idx * 37) mod 256;

// shell: floor, walls, ceiling
kd_arena_solid(0, KD_FLOOR_Y, room_width, room_height - KD_FLOOR_Y);
kd_arena_solid(0, 0, 8, KD_FLOOR_Y);
kd_arena_solid(room_width - 8, 0, 8, KD_FLOOR_Y);
kd_arena_solid(0, 0, room_width, 8);

// platforms
var _L = kd_arena_layouts();
var _lay = _L[1 + irandom(array_length(_L) - 2)];
if (type == "boss") _lay = _L[0];
if (type == "treasure" || type == "shop") _lay = [];      // calm, empty rooms
for (var _i = 0; _i < array_length(_lay); _i++)
{
    var _p = _lay[_i];
    kd_arena_solid(_p[0], _p[1], _p[2], _p[3]);
    array_push(platforms, _p);
}

// player comes in on the left (health carries over between arenas)
with (obj_player)
{
    x = 32;
    y = KD_FLOOR_Y;
    xstart = x;
    ystart = y;
    if (_run.hp > 0) hp = min(hp_max, _run.hp);
}
kd_pets_sync();

switch (type)
{
    case "fight":
        kd_arena_wave(3 + _run.idx);
        banner = (_run.idx == 0) ? "NEON DUNGEON - clear every room" : "ARENA " + string(_run.idx + 1);
        break;
    case "treasure":
        cleared = true;
        kd_pedestal(240, kd_item_random(), 0);
        banner = "TREASURE - take it with E";
        break;
    case "shop":
        cleared = true;
        kd_pedestal(160, kd_item_random(), 8);
        kd_pedestal(240, kd_item_random(), 10);
        kd_pedestal(320, kd_item_random(), 12);
        banner = "SHOP - spend your coins";
        break;
    case "boss":
        array_push(queue, { kind : "boss", x : 240, y : KD_FLOOR_Y, t : 70 });
        banner = "BOSS: MERGE CONFLICT";
        break;
}
banner_t = 150;
