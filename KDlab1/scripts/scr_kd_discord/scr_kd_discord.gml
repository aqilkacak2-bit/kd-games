/// KD Discord link.
/// KD_DISCORD_URL     : the channel the game opens (Discord button top-right, or the Discord terminal in the lab)
/// KD_DISCORD_WEBHOOK : OPTIONAL. Paste a webhook URL to send in-game chat messages to the channel:
///                      Discord -> channel settings (gear) -> Integrations -> Webhooks -> New Webhook -> Copy Webhook URL
///                      Leave it "" to keep chat inside the game.
///                      NOTE: anyone who has the game files can read this URL and post with it - only use it for
///                      private builds / testing, or put a small server in between for a public release.
#macro KD_DISCORD_URL     "https://discord.com/channels/1445246968367677573/1556568809802834010"
#macro KD_DISCORD_WEBHOOK ""

function kd_discord_open()
{
    url_open(KD_DISCORD_URL);
}

function kd_discord_bridge_on()
{
    return KD_DISCORD_WEBHOOK != "";
}

/// send one chat line to the Discord channel (only when a webhook is set). Returns the request id or -1.
function kd_discord_post(_name, _text)
{
    if (!kd_discord_bridge_on()) return -1;
    var _headers = ds_map_create();
    ds_map_add(_headers, "Content-Type", "application/json");
    var _body = json_stringify({ username : "KD Lab | " + _name, content : _text });
    var _id = http_request(KD_DISCORD_WEBHOOK, "POST", _headers, _body);
    ds_map_destroy(_headers);
    return _id;
}
