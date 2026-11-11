/// KD game helpers: EXP + levels, toasts, chat, NPC replies, station info
/// Content based on krackeddevs.com (stats as of 31 Oct 2026).

// ---------------- EXP / LEVELS ----------------
// Level 2 = 100 EXP, Level 3 = 400, Level 4 = 900, Level 5 = 1600 ...  (same curve as KrackedDevs)
function kd_level_from_exp(_exp)
{
    return floor(sqrt(_exp / 100)) + 1;
}

function kd_exp_for_level(_lvl)
{
    return sqr(_lvl - 1) * 100;
}

function kd_add_exp(_amount, _reason)
{
    var _old = kd_level_from_exp(global.kd_exp);
    global.kd_exp += _amount;
    kd_toast("+" + string(_amount) + " EXP   " + _reason, make_colour_rgb(120, 235, 140));
    kd_sfx(snd_exp, 0.02, 0.8);
    var _new = kd_level_from_exp(global.kd_exp);
    if (_new > _old)
    {
        kd_toast("LEVEL UP!  You are now Level " + string(_new), make_colour_rgb(255, 214, 90));
        with (obj_player) kd_vfx_powerup(id);        // power-up.ts
        kd_chips_add(3 * (_new - _old));             // chips for the skill tree
        kd_sfx(snd_levelup, 0);
        global.kd_flash = 0.45;          // shader white flash
    }
}

// ---------------- TOASTS ----------------
function kd_toast(_text, _col)
{
    array_push(global.kd_toasts, { text : _text, col : _col, t : 200 });
}

// ---------------- CHAT ----------------
function kd_chat_add(_name, _text, _col)
{
    array_push(global.kd_chat_log, { name : _name, text : _text, col : _col });
    if (array_length(global.kd_chat_log) > 30) array_delete(global.kd_chat_log, 0, 1);
    global.kd_chat_log_timer = 60 * 10;
}

function kd_has(_text, _word)
{
    return string_pos(_word, _text) > 0;
}

/// NPC answers based on keywords in the player's message
function kd_npc_reply(_msg, _npc_name)
{
    var _m = " " + string_lower(_msg) + " ";

    if (kd_has(_m, "bount"))
        return "Check the Bounty Board in the basement! Builders get paid directly, KD takes 0%.";
    if (kd_has(_m, "guild"))
        return "There are 26 guilds now. Open the Guild Directory terminal in the office!";
    if (kd_has(_m, " xp") || kd_has(_m, "exp") || kd_has(_m, "level"))
        return "Ship stuff to earn EXP. Level 2 needs 100 EXP, Level 3 needs 400.";
    if (kd_has(_m, "school") || kd_has(_m, "class") || kd_has(_m, " ai "))
        return "AI Builder School has free classes every Monday. Jom join!";
    if (kd_has(_m, "lab"))
        return "KD Labs has 25 seats. You move up by shipping code, launches or sales.";
    if (kd_has(_m, "join") || kd_has(_m, "discord") || kd_has(_m, "free"))
        return "It's free to join, no experience gate. Join the Discord!";
    if (kd_has(_m, "event") || kd_has(_m, "hackathon"))
        return "29 events run so far. Hackathons are where the magic happens.";
    if (kd_has(_m, "how many") || kd_has(_m, "stat") || kd_has(_m, "builder"))
        return "3,775 builders and 594 projects shipped! See the big screen in the control room.";
    if (kd_has(_m, "name") || kd_has(_m, "who are"))
        return "I'm " + _npc_name + ". Just a builder trying to ship.";
    if (kd_has(_m, " hi ") || kd_has(_m, "hai") || kd_has(_m, "hello") || kd_has(_m, "salam") || kd_has(_m, " hey"))
        return "Hai! Welcome to KrackedDevs. Learn. Build. Ship.";
    if (kd_has(_m, "thank") || kd_has(_m, "terima kasih"))
        return "Sama-sama! Keep building.";

    var _r = [
        "Nice! What are you building?",
        "Jom ship something today!",
        "Have you checked the Guild Directory yet?",
        "Learn. Build. Ship. That's the way.",
        "Ask me about bounties, guilds, EXP or the AI school."
    ];
    return _r[irandom(array_length(_r) - 1)];
}

// ---------------- BUBBLES (drawn in Draw GUI) ----------------
/// draws a speech bubble above a world position, converted to GUI space
function kd_draw_bubble(_wx, _wy, _text, _alpha)
{
    var _cam = view_camera[0];
    var _s   = display_get_gui_width() / camera_get_view_width(_cam);
    var _gx  = (_wx - camera_get_view_x(_cam)) * _s;
    var _gy  = (_wy - camera_get_view_y(_cam)) * _s;

    var _maxw = 280;
    var _tw = min(string_width(_text), _maxw);
    var _th = string_height_ext(_text, -1, _maxw);
    var _pad = 8;
    var _x1 = _gx - _tw / 2 - _pad;
    var _x2 = _gx + _tw / 2 + _pad;
    var _y2 = _gy - 12;
    var _y1 = _y2 - _th - _pad * 2;

    draw_set_alpha(_alpha);
    draw_set_colour(c_white);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 12, 12, false);
    draw_triangle(_gx - 7, _y2 - 1, _gx + 7, _y2 - 1, _gx, _y2 + 9, false);
    draw_set_colour(make_colour_rgb(30, 30, 40));
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 12, 12, true);
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_text_ext(_gx, _y1 + _pad, _text, -1, _maxw);
    draw_set_halign(fa_left);
    draw_set_alpha(1);
}

// ---------------- STATIONS ----------------
/// returns the info panel content for a station id
function kd_station_info(_id)
{
    var _i = {
        title  : "",
        sub    : "",
        tiles  : [],
        lines  : [],
        cols   : [],
        xp     : 20,
        reason : "",
        feed   : false,
        discord: false
    };

    switch (_id)
    {
        case "about":
            _i.title  = "<KD/>  KrackedDevs";
            _i.sub    = "Malaysia's builder ecosystem   |   Learn. Build. Ship.";
            _i.lines  = [
                "A community, a school and a product lab, run by builders.",
                "Free for builders to join. No experience gate.",
                "",
                "## What we run",
                "- Community: guilds, weekly classes, hackathons, bounties and KD Square.",
                "  Members earn EXP for shipping.",
                "- AI Builder School: free Monday classes and a Builders Sandbox.",
                "- KD Labs: a 25-seat builder programme. You move up by shipping.",
                "",
                "## Products",
                "Jalan Malaysia, Kuntum & Embun, JomQR, MyPeta, KD Wiki, Fluid",
                "",
                "krackeddevs.com"
            ];
            _i.reason = "Discovered KrackedDevs";
            break;

        case "guilds":
            _i.title  = "Guild Directory";
            _i.sub    = "26 guilds - find your people, or create your own.";
            _i.cols   = [
                "XMUM SDC Hackathon", "MSU.zip", "MATA", "D'Blox Studio", "KrackedDev HerOps",
                "Hang TuAI", "KrackedDev HerStacks", "KrackedPUO", "HACKDEV MY", "UTM KRACKS",
                "Rekt", "K.D BORNEO", "PeakyBuildr!",
                "VibeKualaLumpur", "rea-pers", "KrackedDevs X Sabah", "SIDEQUEST",
                "Sunway Kracked Devs Club", "HomeLAB.my", "Sunway DealFlow Club", "KAGE ALLIENCES",
                "Malaysia Asset Digital Community", "Vibekoder", "BELANTIK", "VibeKedah", "K.D Official Guild"
            ];
            _i.reason = "Browsed the Guild Directory";
            break;

        case "stats":
            _i.title  = "Community Stats";
            _i.sub    = "Live numbers from krackeddevs.com (31 Oct 2026)";
            _i.tiles  = [ ["3,775", "Builders"], ["594", "Projects shipped"], ["26", "Guilds"], ["29", "Events run"] ];
            _i.lines  = [
                "## Builders by state",
                "Selangor 352   |   Kuala Lumpur 201   |   Johor 62",
                "",
                "## Bounties",
                "RM3,550 paid across 13 completed bounties.",
                "",
                "## Partners",
                "MyDIGITAL, UiTM, UTM, APU, Sunway University, Hostinger, IBM, Xsolla Curine Academy"
            ];
            _i.reason = "Checked the community stats";
            break;

        case "bounty":
            _i.title  = "Bounty Board";
            _i.sub    = "Real tasks from real companies. Get paid to build.";
            _i.lines  = [
                "- Companies post a bounty with a MYR budget.",
                "- Builders are paid directly. KD takes 0%.",
                "- RM3,550 paid across 13 completed bounties so far.",
                "",
                "## Bounty EXP",
                "Submission ............ +20 EXP",
                "Honorable mention ..... +50 EXP",
                "Win ................... 100 + (reward / 10) EXP",
                "",
                "Find open bounties on the Bounty Board at krackeddevs.com"
            ];
            _i.reason = "Bounty submission";
            break;

        case "discord":
            _i.title   = "KD Discord";
            _i.sub     = "Talk to real builders - the KrackedDevs community lives on Discord.";
            _i.discord = true;
            var _bridge = "OFF - set KD_DISCORD_WEBHOOK in scr_kd_discord to post in-game chat to the channel.";
            if (kd_discord_bridge_on()) _bridge = "ON - your in-game chat is also posted to the channel.";
            _i.lines   = [
                "Press ENTER (or click) to open the KD channel in Discord.",
                "",
                "## In the game",
                "- The Discord button (top right) opens the same channel any time.",
                "- Chat bridge: " + _bridge,
                "",
                "Free to join, no experience gate. Learn. Build. Ship."
            ];
            _i.reason  = "Found the KD Discord";
            break;

        case "feed":
            _i.title  = "KD Feed";
            _i.sub    = "@krackeddev - events";
            _i.feed   = true;
            _i.reason = "Checked the KD feed";
            break;

        case "exp":
            _i.title  = "How to earn EXP";
            _i.sub    = "Ship, help others and show up - level up your builder profile.";
            _i.lines  = [
                "## Community & knowledge",
                "Daily login +10   |   Answer accepted +100   |   Upvote received +5   |   Poll vote +10",
                "## Development & open source",
                "GitHub contribution +5/day   |   Bounty submission +20   |   Bounty win 100 + reward/10",
                "## Bonuses",
                "Profile completion +30   |   Login streak: 7 days +50, 30 days +200, 90 days +500",
                "",
                "## Levels",
                "Level 2 = 100 EXP   |   Level 3 = 400   |   Level 4 = 900   |   Level 5 = 1,600",
                "Higher levels unlock badges, early access and more visibility to employers."
            ];
            _i.xp     = 30;
            _i.reason = "Profile completion";
            break;
    }
    return _i;
}

/// display name for the interaction prompt
function kd_station_name(_id)
{
    if (room == rm_lobby && _id == "door_lab")   return "Character Lab";
    if (_id == "door_lobby") return "KD Lobby";
    if (room == rm_select && _id == "door_lab")  return "Showcase Hall";
    if (room == rm_showcase && _id == "door_select") return "Character Lab";
    if (room == rm_showcase && _id == "door_lab")    return "Out to Kuala Lumpur";
    if (room == rm_main && _id == "door_select") return "Out to the street (KL)";
    if (room == rm_kl && _id == "door_select")   return "Showcase Hall";
    if (_id == "door_dungeon") return "Enter the Neon Dungeon";
    if (_id == "pets") return "Robot Pet Bay";
    if (_id == "shop") return "KD Item Shop";
    switch (_id)
    {
        case "about":  return "KrackedDevs";
        case "guilds": return "Guild Directory";
        case "stats":  return "Community Stats";
        case "bounty": return "Bounty Board";
        case "exp":    return "EXP Guide";
        case "feed":   return "Computer - KD Feed";
        case "discord": return "KD Discord terminal";
        case "select": return "Character Select";
        case "door_lab":    return "Enter the KD Lab";
        case "door_select": return "Back to the Character Lab";
        case "door_range":  return "Training Range";
        case "door_roof":   return "Rooftop";
        case "door_back":   return "Back to the KD Lab";
    }
    return "Look";
}

// ---------------- DATE ----------------
/// today as a number yyyymmdd (e.g. 20261031) - easy to compare
function kd_today_key()
{
    return current_year * 10000 + current_month * 100 + current_day;
}

/// "Saturday, 31 October 2026"
function kd_date_text()
{
    var _days   = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
    var _months = ["January", "February", "March", "April", "May", "June", "July",
                   "August", "September", "October", "November", "December"];
    return _days[current_weekday] + ", " + string(current_day) + " " + _months[current_month - 1] + " " + string(current_year);
}

/// "7:08 PM"
function kd_time_text()
{
    var _h = current_hour mod 12;
    if (_h == 0) _h = 12;
    var _m = string(current_minute);
    if (current_minute < 10) _m = "0" + _m;
    var _ampm = "AM";
    if (current_hour >= 12) _ampm = "PM";
    return string(_h) + ":" + _m + " " + _ampm;
}

// ---------------- EVENTS (KD Feed on the computer) ----------------
/// Events from krackeddevs.com/events (October 2026).
/// img = the poster sprite. To use a real Instagram post: open the sprite in GameMaker,
/// Import your image (any size - it is scaled to fit). Add new events by copying a line.
/// start / finish = yyyymmdd numbers, used for LIVE / UPCOMING / ENDED.
function kd_events()
{
    return [
        { title : "Hacktoberfest Hack Day KL 2026", tag : "AI Hack Sprint", date : "30 - 31 October 2026", time : "",
          place : "Kuala Lumpur", host : "KrackedDevs", start : 20261030, finish : 20261031, img : spr_kd_event_hacktoberfest,
          desc : "A free, in-person AI hack sprint focused on open-source and open-weight AI - held in Malaysia for the first time." },

        { title : "KD Girlies - Zero to Website Building Session", tag : "KD HerStacks", date : "Friday, 30 October 2026", time : "9:30 PM (MYT)",
          place : "Discord server: GirlyOnly", host : "KD HerStacks // KrackedDevs", start : 20261030, finish : 20261030, img : spr_kd_event_girlies_web,
          desc : "Girls-only, hands-on session led by Tyra: build a website with AI and customise your portfolio. No coding experience needed." },

        { title : "XMUM SDC Hackathon", tag : "Hackathon", date : "28 - 29 October 2026", time : "",
          place : "XMUM", host : "XMUM SDC Hackathon guild", start : 20261028, finish : 20261029, img : spr_kd_event_xmum,
          desc : "Official SDC Hackathon at XMUM - finalist teams build their projects with KrackedDev credits." },

        { title : "AI Builder Foundation - How to Start Your First Project", tag : "AI Builder Foundation", date : "26 October 2026", time : "Evening, about 2.5 hours",
          place : "In person", host : "KrackedDevs", start : 20261026, finish : 20261026, img : spr_kd_event_first_project,
          desc : "Workshop: take your first project from idea to a working start, building step by step with AI." },

        { title : "AI Builder Foundation: Introduction to Vibe Coding", tag : "AI Builder Foundation", date : "19 October 2026", time : "",
          place : "Weekly workshop", host : "KrackedDevs", start : 20261019, finish : 20261019, img : spr_kd_event_vibe_intro,
          desc : "Build a working app for one real problem using AI, one step at a time." },

        { title : "KD Girlies - Build Fast, Think Secure", tag : "KD HerStacks", date : "Saturday, 17 October 2026", time : "9:30 PM (MYT)",
          place : "Online", host : "KD HerStacks // KrackedDevs, with Mia", start : 20261017, finish : 20261017, img : spr_kd_event_girlies_secure,
          desc : "Vibe coding session: build your portfolio website step by step - plus a surprise extra segment." },

        { title : "Builder Sandbox", tag : "Co-work + Jam", date : "14 October 2026", time : "",
          place : "Kracked Labs", host : "Kracked Labs", start : 20261014, finish : 20261014, img : spr_kd_event_sandbox,
          desc : "Open co-working and jam space for founders, developers and creators to work on side projects or new ideas." },

        { title : "Vibe Coding 101: Build Real Apps Without Writing Code", tag : "KrackedDevs", date : "5 October 2026", time : "",
          place : "", host : "KrackedDevs", start : 20261005, finish : 20261005, img : spr_kd_event_vibe101,
          desc : "Learn to build real apps with AI tools - no code needed." }
    ];
}

/// "LIVE TODAY", "UPCOMING" or "ENDED" compared with the real date on your computer
function kd_event_status(_ev)
{
    var _today = kd_today_key();
    if (_today < _ev.start) return "UPCOMING";
    if (_today > _ev.finish) return "ENDED";
    return "LIVE TODAY";
}
