/// obj_game - Room Start
// obj_game is persistent: forget things that belonged to the previous room
near_station = noone;
near_gun     = noone;
panel_open   = false;
select_open  = false;
pending      = [];
kd_ambience_update();

// arriving through a door: stand at the matching door in this room
// the Neon Dungeon portal stands at the end of the Training Range
if (room == rm_range && !instance_exists(obj_station_door_dungeon)) instance_create_depth(456, 150, 50, obj_station_door_dungeon);
// Robot Pet Bay (Character Lab) and KD Item Shop (Training Range)
if (room == rm_lobby && !instance_exists(obj_station_pets)) instance_create_depth(KD_LOBBY_PETS_X, 308, 50, obj_station_pets);
if (room == rm_select && !instance_exists(obj_station_pets)) instance_create_depth(120, 150, 50, obj_station_pets);
if (room == rm_range && !instance_exists(obj_station_shop)) instance_create_depth(128, 150, 50, obj_station_shop);
kd_place_player_at_door();

// ambient effects for this room (fog banks)
kd_room_fx_setup();

// item boxes
kd_spawn_boxes();

// your companion pet (Robot Pet Bay) follows you into every room
kd_pets_sync();
