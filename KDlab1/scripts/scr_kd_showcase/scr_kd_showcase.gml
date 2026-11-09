/// KDlab1 Showcase Hall: statues / logos that open the game's website.
/// Edit the cards here (title, description, maker, socials, link, glow colour).

function kd_showcase_info(_obj)
{
    var _green = make_colour_rgb(64, 226, 110);
    switch (_obj)
    {
        case obj_show_kracked:
            return {
                title:  "Kracked Studio",
                tag:    "Indie game studio. Makers of MyFootball Manager 27.",
                by:     "",
                social: [],
                url:    "https://kracked.studio",
                col:    make_colour_rgb(255, 120, 110)
            };
        case obj_show_myfm:
            return {
                title:  "MyFootball Manager 27",
                tag:    "Free browser football manager. Take a village club from the A3 Community League all the way to the Malaysia Super League.",
                by:     "Kracked Studio",
                social: [],
                url:    "https://myfm27.app",
                col:    make_colour_rgb(120, 200, 255)
            };
        case obj_show_wardrun:
            return {
                title:  "WardRun",
                tag:    "Cel-shaded 3D hospital game for web and mobile. Survive a junior doctor's shift: thirty beds and a phone that never stops ringing.",
                by:     "",
                social: [],
                url:    "https://wardrun.app",
                col:    make_colour_rgb(110, 230, 220)
            };
        case obj_show_lembah:
            return {
                title:  "Lembah Bintang",
                tag:    "Pixel-art farming and survival in a Malaysian village. Harvest, grow crops, build, and survive the nights as your plot grows into a town.",
                by:     "",
                social: [],
                url:    "https://lembahbintang.app",
                col:    make_colour_rgb(150, 230, 110)
            };
        case obj_show_pendekar:
            return {
                title:  "Pendekar",
                tag:    "Free old-school browser MMORPG set in Malaysia. Play on desktop or mobile, no download.",
                by:     "Danial Alias",
                social: ["Threads / Instagram:  @_d.hadii", "X:  @masterofnone"],
                url:    "https://pendekar.io",
                col:    make_colour_rgb(255, 204, 64)
            };
    }
    return { title: "Exhibit", tag: "", by: "", social: [], url: "", col: _green };
}

/// the exhibit under the mouse (or noone)
function kd_showcase_hovered()
{
    if (!instance_exists(obj_showcase)) return noone;
    if (variable_global_exists("ui_block") && global.ui_block) return noone;
    var _hit = noone;
    with (obj_showcase)
    {
        if (point_in_rectangle(mouse_x, mouse_y, bbox_left - 2, bbox_top - 2, bbox_right + 2, bbox_bottom + 2)) _hit = id;
    }
    return _hit;
}

/// the exhibit the player is standing at (or noone)
function kd_showcase_nearest(_p)
{
    var _best = noone;
    var _bd = 1000000;
    with (obj_showcase)
    {
        var _cx = (bbox_left + bbox_right) / 2;
        var _dx = abs(_p.x - _cx);
        if (_dx < max(22, (bbox_right - bbox_left) / 2 + 6) && _dx < _bd) { _bd = _dx; _best = id; }
    }
    return _best;
}

function kd_showcase_open(_inst)
{
    with (_inst)
    {
        if (info.url == "") return;
        kd_sfx(snd_ui_click);
        kd_toast("Opening " + info.url, info.col);
        url_open_ext(info.url, "_blank");
        opened = 20;
    }
}
