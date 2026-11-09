/// KD CHARACTER CUSTOMISATION
/// A "look" is a struct of 8 numbers - one per slot - so it is tiny, easy to save and to copy:
///   hair, hair_col, face, skin, top, top_col, bottom, bottom_col
/// Every slot points at ONE sprite and the colour / skin is just the frame number (see scr_kd_character -> kd_draw).
/// ADD A NEW STYLE: draw it on the 32x32 template, import it as a sprite with one frame per colour
/// (same order as the colour list), then add its name + sprite to the lists below.

function kd_look_make(_hair, _hair_col, _face, _skin, _top, _top_col, _bottom, _bottom_col)
{
    return { hair : _hair, hair_col : _hair_col, face : _face, skin : _skin,
             top : _top, top_col : _top_col, bottom : _bottom, bottom_col : _bottom_col };
}

function kd_look_copy(_l)
{
    return kd_look_make(_l.hair, _l.hair_col, _l.face, _l.skin, _l.top, _l.top_col, _l.bottom, _l.bottom_col);
}

function kd_custom_data()
{
    static d = undefined;
    if (is_undefined(d))
    {
        d = {
        hair_names      : ["Messy", "Long + bunga raya", "Tudung", "Spiky + headphones", "Curly", "Bob cut"],
        hair_spr        : [spr_cz_hair_0, spr_cz_hair_1, spr_cz_hair_2, spr_cz_hair_3, spr_cz_hair_4, spr_cz_hair_5],
        hair_back_spr   : [-1, spr_cz_hairback_1, -1, -1, -1, -1],
        hair_col_names  : ["Navy", "Dark brown", "Teal", "Black", "Espresso", "Pink", "Blonde", "Auburn", "Silver", "Lilac"],
        hair_cols       : [make_colour_rgb(34, 32, 52), make_colour_rgb(64, 38, 42), make_colour_rgb(46, 134, 136), make_colour_rgb(42, 42, 56), make_colour_rgb(50, 34, 30), make_colour_rgb(212, 90, 158), make_colour_rgb(214, 170, 80), make_colour_rgb(160, 62, 40), make_colour_rgb(190, 192, 204), make_colour_rgb(150, 120, 200)],
        face_names      : ["Bold", "Soft", "Glasses", "Focused", "Bearded", "Edgy"],
        face_spr        : [spr_cz_face_0, spr_cz_face_1, spr_cz_face_2, spr_cz_face_3, spr_cz_face_4, spr_cz_face_5],
        skin_names      : ["Porcelain", "Light", "Warm", "Tan", "Brown", "Deep"],
        skin_cols       : [make_colour_rgb(252, 218, 184), make_colour_rgb(254, 199, 156), make_colour_rgb(238, 188, 148), make_colour_rgb(206, 148, 108), make_colour_rgb(156, 100, 70), make_colour_rgb(112, 70, 50)],
        top_names       : ["Open jacket", "Baju kurung", "Blouse", "Hoodie", "T-shirt", "Tech hoodie"],
        top_spr         : [spr_cz_top_0, spr_cz_top_1, spr_cz_top_2, spr_cz_top_3, spr_cz_top_4, spr_cz_top_5],
        top_short       : [false, false, false, false, true, false],
        top_col_names   : ["Forest", "Rose", "Cream", "White", "Mustard", "Black", "Teal", "Navy", "Red", "Purple"],
        top_cols        : [make_colour_rgb(75, 105, 47), make_colour_rgb(196, 82, 116), make_colour_rgb(236, 228, 210), make_colour_rgb(214, 218, 228), make_colour_rgb(212, 158, 44), make_colour_rgb(40, 38, 54), make_colour_rgb(46, 134, 136), make_colour_rgb(44, 52, 96), make_colour_rgb(180, 46, 56), make_colour_rgb(112, 62, 170)],
        bottom_names    : ["Trousers", "Songket skirt", "Long skirt"],
        skirt_spr       : [-1, spr_cz_skirt_1, spr_cz_skirt_2],
        bottom_col_names: ["Brown", "Black", "Denim", "Olive", "Charcoal", "Khaki", "Plum", "Navy"],
        bottom_cols     : [make_colour_rgb(126, 88, 95), make_colour_rgb(44, 42, 50), make_colour_rgb(52, 64, 104), make_colour_rgb(92, 100, 60), make_colour_rgb(70, 72, 82), make_colour_rgb(170, 150, 104), make_colour_rgb(98, 44, 90), make_colour_rgb(40, 44, 80)],
        presets         : [
            { name : "KD", role : "The Shipper", specialty : "Full-stack", look : kd_look_make(0, 0, 0, 1, 0, 0, 0, 0) },
            { name : "Mawar", role : "The Designer", specialty : "UI / UX", look : kd_look_make(1, 1, 1, 1, 1, 1, 1, 6) },
            { name : "Aina", role : "The AI Researcher", specialty : "Machine learning", look : kd_look_make(2, 2, 2, 2, 2, 2, 2, 7) },
            { name : "Wei Jie", role : "The Speedrunner", specialty : "Competitive coding", look : kd_look_make(3, 3, 3, 0, 3, 3, 0, 2) },
            { name : "Arjun", role : "The Maker", specialty : "Hardware + IoT", look : kd_look_make(4, 4, 4, 4, 4, 4, 0, 3) },
            { name : "Rina", role : "The Hacker", specialty : "Cybersecurity", look : kd_look_make(5, 5, 5, 0, 5, 5, 0, 4) }
        ]
        };
    }
    return d;
}

/// the 8 customisation rows used by the Character Customiser
function kd_custom_slots()
{
    static s = undefined;
    if (is_undefined(s))
    {
        var _d = kd_custom_data();
        s = [
            { label : "Hair style",    key : "hair",       names : _d.hair_names,       cols : -1 },
            { label : "Hair colour",   key : "hair_col",   names : _d.hair_col_names,   cols : _d.hair_cols },
            { label : "Face",          key : "face",       names : _d.face_names,       cols : -1 },
            { label : "Skin tone",     key : "skin",       names : _d.skin_names,       cols : _d.skin_cols },
            { label : "Top",           key : "top",        names : _d.top_names,        cols : -1 },
            { label : "Top colour",    key : "top_col",    names : _d.top_col_names,    cols : _d.top_cols },
            { label : "Bottom",        key : "bottom",     names : _d.bottom_names,     cols : -1 },
            { label : "Bottom colour", key : "bottom_col", names : _d.bottom_col_names, cols : _d.bottom_cols }
        ];
    }
    return s;
}

function kd_look_get(_look, _key)          { return variable_struct_get(_look, _key); }
function kd_look_set(_look, _key, _value)  { variable_struct_set(_look, _key, _value); }

/// step one slot forwards / backwards (wraps around)
function kd_look_step(_look, _slot, _dir)
{
    var _n = array_length(_slot.names);
    var _v = (kd_look_get(_look, _slot.key) + _dir + _n) mod _n;
    kd_look_set(_look, _slot.key, _v);
}

function kd_look_random()
{
    var _d = kd_custom_data();
    return kd_look_make(irandom(array_length(_d.hair_names) - 1), irandom(array_length(_d.hair_cols) - 1),
                        irandom(array_length(_d.face_names) - 1), irandom(array_length(_d.skin_cols) - 1),
                        irandom(array_length(_d.top_names) - 1),  irandom(array_length(_d.top_cols) - 1),
                        irandom(array_length(_d.bottom_names) - 1), irandom(array_length(_d.bottom_cols) - 1));
}

/// a hand: outline + sleeve (tinted with the top colour, or skin for short sleeves) + skin
/// _shade (optional, default 1): < 1 darkens it (used for the back hand so it reads as further away)
function kd_draw_hand(_x, _y, _xs, _ys, _angle, _look, _scale, _shade)
{
    if (is_undefined(_shade)) _shade = 1;
    var _d = kd_custom_data();
    var _skin = _d.skin_cols[_look.skin];
    var _sleeve = _d.top_cols[_look.top_col];
    if (_d.top_short[_look.top]) _sleeve = _skin;
    if (_shade < 1)
    {
        _skin   = merge_colour(_skin, c_black, 1 - _shade);
        _sleeve = merge_colour(_sleeve, c_black, 1 - _shade);
    }
    draw_sprite_ext(spr_cz_hand_sleeve, 0, _x, _y, _xs * _scale, _ys * _scale, _angle, _sleeve, 1);
    draw_sprite_ext(spr_cz_hand_skin,   0, _x, _y, _xs * _scale, _ys * _scale, _angle, _skin, 1);
    draw_sprite_ext(spr_cz_hand_line,   0, _x, _y, _xs * _scale, _ys * _scale, _angle, c_white, 1);
}
