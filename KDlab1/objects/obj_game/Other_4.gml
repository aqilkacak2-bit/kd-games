/// obj_game - Room Start
// obj_game is persistent: forget things that belonged to the previous room
near_station = noone;
near_gun     = noone;
panel_open   = false;
select_open  = false;
pending      = [];
kd_ambience_update();

// arriving through a door: stand at the matching door in this room
kd_place_player_at_door();

// ambient effects for this room (fog banks)
kd_room_fx_setup();

// item boxes
kd_spawn_boxes();
