/// obj_game - Async HTTP   (result of a Discord webhook post)
if (async_load[? "id"] != discord_req) exit;
if (async_load[? "status"] < 0) exit;                       // still sending
var _code = async_load[? "http_status"];
if (_code >= 300 || _code < 200)
{
    kd_toast("Discord: message not sent (HTTP " + string(_code) + ") - check KD_DISCORD_WEBHOOK", make_colour_rgb(255, 120, 120));
}
