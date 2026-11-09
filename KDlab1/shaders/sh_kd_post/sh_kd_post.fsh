// sh_kd_post - full-screen post-process for the KD Lab
// u_mode: 1 = Clean (soft bloom, colour grade, vignette)
//         2 = CRT   (scanlines, RGB split, vignette, slight flicker)
//         3 = Neon  (darker, cool tint, strong glow on bright pixels)
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform float u_time;
uniform vec2  u_texel;     // size of one surface pixel in UV
uniform vec2  u_uvmax;     // UV of the surface's bottom-right corner (for the vignette)
uniform float u_mode;
uniform float u_pix;       // screen pixels per game pixel (for scanlines)
uniform float u_flash;     // 0..1 white flash

vec3 bright(vec2 uv)
{
    vec3 c = texture2D(gm_BaseTexture, uv).rgb;
    return max(c - vec3(0.55), vec3(0.0));
}

void main()
{
    vec2 uv = v_vTexcoord;
    vec3 col;

    // RGB split for CRT
    if (u_mode > 1.5 && u_mode < 2.5)
    {
        float s = 1.2;
        col.r = texture2D(gm_BaseTexture, uv + vec2(u_texel.x * s, 0.0)).r;
        col.g = texture2D(gm_BaseTexture, uv).g;
        col.b = texture2D(gm_BaseTexture, uv - vec2(u_texel.x * s, 0.0)).b;
    }
    else
    {
        col = texture2D(gm_BaseTexture, uv).rgb;
    }

    // cheap bloom: bright pixels around this one
    vec2 o = u_texel * 3.0;
    vec3 b = bright(uv + vec2( o.x, 0.0)) + bright(uv + vec2(-o.x, 0.0))
           + bright(uv + vec2(0.0,  o.y)) + bright(uv + vec2(0.0, -o.y))
           + bright(uv + o) + bright(uv - o)
           + bright(uv + vec2(o.x, -o.y)) + bright(uv + vec2(-o.x, o.y));
    vec2 o2 = u_texel * 7.0;
    b += 0.6 * (bright(uv + vec2( o2.x, 0.0)) + bright(uv + vec2(-o2.x, 0.0))
              + bright(uv + vec2(0.0,  o2.y)) + bright(uv + vec2(0.0, -o2.y)));
    b /= 10.4;

    // vignette (0 at centre, 1 at corners)
    vec2 q = uv / u_uvmax - 0.5;
    float vig = dot(q, q) * 2.0;

    if (u_mode < 1.5)            // ---- Clean ----
    {
        col += b * 0.9;
        col = mix(vec3(dot(col, vec3(0.299, 0.587, 0.114))), col, 1.12);   // a little more saturation
        col = (col - 0.5) * 1.06 + 0.5;                                    // a little more contrast
        col *= 1.0 - vig * 0.35;
    }
    else if (u_mode < 2.5)       // ---- CRT ----
    {
        col += b * 0.6;
        float line = mod(gl_FragCoord.y, max(u_pix, 2.0));
        col *= (line < 1.0) ? 0.72 : 1.0;
        col *= 0.97 + 0.03 * sin(u_time * 60.0);                           // flicker
        col *= 1.0 - vig * 0.55;
    }
    else                         // ---- Neon ----
    {
        col = col * vec3(0.78, 0.86, 1.0) * 0.85;                          // cool + darker
        col += b * vec3(1.4, 1.7, 1.9);                                    // strong glow
        col *= 1.0 - vig * 0.6;
    }

    col = mix(col, vec3(1.0), clamp(u_flash, 0.0, 1.0));
    gl_FragColor = vec4(clamp(col, 0.0, 1.0), 1.0) * v_vColour;
}
