COLOR4F_WHITE       :: Color4f.{1,1,1,1};
COLOR4F_RED         :: Color4f.{1,0,0,1};
COLOR4F_GREEN       :: Color4f.{0,1,0,1};
COLOR4F_BLUE        :: Color4f.{0,0,1,1};
COLOR4F_BLACK       :: Color4f.{0,0,0,1};
COLOR4F_MAGENTA     :: Color4f.{1,0,1,1};

COLOR4F_BRIGHT_PURPLE      :: Color4f.{0.65, 0.1, 0.82, 1};

Color2f :: struct {
    r: float32;
    g: float32;

#overlay(r) vec2: Vector2 = ---;
#overlay(r) component: [2]float = ---;
#overlay(r) array: [2]float32 = ---;
}

Color3f :: struct {
    r: float32;
    g: float32;
    b: float32;

#overlay(r) rg: Color2f = ---;
#overlay(g) gb: Color2f = ---;
#overlay(r) using #as vec3: Vector3 = ---;
#overlay(r) array: [3]float32 = ---;
}

Color_HSL :: struct {
    hue: float32;
    saturation := 1.0;
    lightness := 0.5;
}

Color4f :: struct {
    r: float32;
    g: float32;
    b: float32;
    a: float32 = 1.0;

#overlay(r) rgb: Color3f = ---;
#overlay(r) rg: Color2f = ---;
#overlay(g) gb: Color2f = ---;
#overlay(b) ba: Color2f = ---;
#overlay(r) using #as vec4: Vector4 = ---;
#overlay(r) array: [4]float32 = ---;
}

Color4b :: struct {
    r: u8 #align 4; // should align to 4 bytes so this struct can be read as a u32;
    g: u8;
    b: u8;
    a: u8 = 255;

#overlay(r) bytes: [4]u8 = ---;
#overlay(r) _u32: u32 = ---;
}

operator * :: inline (color: Color4f, scalar: float) -> Color4f #symmetric {
    c := Color4f.{color.r * scalar, color.g * scalar, color.b * scalar, color.a};
    c.r = clamp(c.r, 0, 1);
    c.g = clamp(c.g, 0, 1);
    c.b = clamp(c.b, 0, 1);
    return c;
}

to_color4f :: inline (color3f: Color3f, alpha := 1.0) -> Color4f {
    float_color: Color4f = ---;
    float_color.r = color3f.r;
    float_color.g = color3f.g;
    float_color.b = color3f.b;
    float_color.a = alpha;
    return float_color;
}

to_color4f :: inline (color3f: Color3f, alpha : u8 = 255) -> Color4f {
    float_color: Color4f = ---;
    float_color.r = color3f.r;
    float_color.g = color3f.g;
    float_color.b = color3f.b;
    float_color.a = alter_cast(alpha, float, true);
    return float_color;
}

to_color4b :: inline (color4f: Color4f) -> Color4b {
    byte_color: Color4b = ---;
    byte_color.r = alter_cast(color4f.r, u8, true);
    byte_color.b = alter_cast(color4f.b, u8, true);
    byte_color.g = alter_cast(color4f.g, u8, true);
    byte_color.a = alter_cast(color4f.a, u8, true);
    return byte_color;
}

to_color4f :: inline (color4b: Color4b) -> Color4f {
    float_color: Color4f = ---;
    float_color.r = alter_cast(color4b.r, float, true);
    float_color.g = alter_cast(color4b.g, float, true);
    float_color.b = alter_cast(color4b.b, float, true);
    float_color.a = alter_cast(color4b.a, float, true);
    return float_color;
}

to_color4b :: inline (hex_color_code: u32) -> Color4b {
    byte_color: Color4b = ---;
    byte_color.r = ((hex_color_code & 0xff0000) >> 16).(u8);
    byte_color.g = ((hex_color_code & 0x00ff00) >>  8).(u8);
    byte_color.b = ((hex_color_code & 0x0000ff) >>  0).(u8);
    byte_color.a = 255;
    return byte_color;
}

to_color4f :: inline (hex_color_code: u32) -> Color4f {
    color_4b := to_color4b(hex_color_code);
    return to_color4f(color_4b);
}

lerp :: inline (begin: Color4f, end: Color4f, t: float) -> Color4f {
    return {
        r = begin.r + (end.r - begin.r) * t,
        g = begin.g + (end.g - begin.g) * t,
        b = begin.b + (end.b - begin.b) * t,
        a = begin.a + (end.a - begin.a) * t,
    };
}

random_color4f :: inline (r_bounds := Vector2.{0.3, 0.95}, g_bounds := Vector2.{0.3, 0.95}, b_bounds := Vector2.{0.3, 0.95}, a := 1.0, random_state : *Random_State = null) -> Color4f {
    if random_state == null {
        random_state = *context.random_state;
    }
    float_color: Color4f = ---;
    float_color.r = r_bounds.x + random_get_zero_to_one(random_state) * (r_bounds.y - r_bounds.x);
    float_color.g = g_bounds.x + random_get_zero_to_one(random_state) * (g_bounds.y - g_bounds.x);
    float_color.b = b_bounds.x + random_get_zero_to_one(random_state) * (b_bounds.y - b_bounds.x);
    float_color.a = a;
    return float_color;
}

lerp_to_grey :: inline (color: Color3f, grey_value: float, alpha: float) -> Color3f {
    out_color: Color3f = ---;
    out_color.r = lerp(color.r, grey_value, alpha);
    out_color.g = lerp(color.g, grey_value, alpha);
    out_color.b = lerp(color.b, grey_value, alpha);
    return out_color;
}

lighten :: inline (color: Color3f, alpha: float32) -> Color3f {
    return lerp_to_grey(color, 1, alpha);
}

darken :: inline (color: Color3f, alpha: float32) -> Color3f {
    return lerp_to_grey(color, 0, alpha);
}

scale_lightness :: (color: Color3f, alpha: float32) -> Color3f {
    grey_value := color_to_grey(color); 
    grey_value *= alpha;
    // color := grey_to_color(grey_value);
    color.r = clamp(color.r, 0, 1);
    color.g = clamp(color.g, 0, 1);
    color.b = clamp(color.b, 0, 1);
    return color;
}

// 1. finding max headroom with a division is silly
// 2. this definitely increases brightness
// 3. increasing saturation is a matter of moving values away from grey, but some things must increase and some must decrease to keep the same grey.
scale_saturation :: inline (color: Color3f, scale: float32) -> Color3f {
    assert(scale >= 0);

    min_saturation := color_to_grey(color);
    grey_value := min_saturation.r;

    if scale <= 1 {
        return lerp_to_grey(color, grey_value, 1-scale);
    }

    max_saturation := color;

    Color_Channel :: struct {
        input: float;
        max_saturation: *float;
        min_saturation: *float;
        grey_factor: float;
    }

    min_channel: Color_Channel;
    mid_channel: Color_Channel;
    max_channel: Color_Channel;

    r_channel := Color_Channel.{color.r, *max_saturation.r, *min_saturation.r, GREY_FACTORS.r};
    g_channel := Color_Channel.{color.g, *max_saturation.g, *min_saturation.g, GREY_FACTORS.g};
    b_channel := Color_Channel.{color.b, *max_saturation.b, *min_saturation.b, GREY_FACTORS.b};

    if color.r < color.g {
        if color.r < color.b {
            max_channel = g_channel;
            mid_channel = b_channel;
            min_channel = r_channel;
        } else {
            max_channel = g_channel;
            mid_channel = r_channel;
            min_channel = b_channel;
        }
    } else if color.g < color.b {
        if color.r > color.b {
            max_channel = r_channel;
            mid_channel = b_channel;
        } else {
            max_channel = b_channel;
            mid_channel = r_channel;
        }
        min_channel = g_channel;
    } else {
        max_channel = r_channel;
        mid_channel = g_channel;
        min_channel = b_channel;
    }

    min_channel.max_saturation.* = 0;
    max_channel.max_saturation.* = 1;
    grey_remainder := grey_value - max_channel.grey_factor;
    mid_channel.max_saturation.* = grey_remainder / mid_channel.grey_factor;

    // this distance represents a scale of 1
    max_min_dist := max_channel.input - max_channel.min_saturation.*;
    mid_min_dist := mid_channel.input - mid_channel.min_saturation.*;

    max_max_dist := max_channel.max_saturation.* - max_channel.input;
    mid_max_dist := mid_channel.max_saturation.* - mid_channel.input;

    max_max_scale := abs(max_max_dist / max_min_dist);
    mid_max_scale := abs(mid_max_dist / mid_min_dist);

    max_scale := min(max_max_scale, mid_max_scale);

    if scale >= max_scale {
        return max_saturation;
    } else {
        norm_saturation_alpha := (scale - 1) / (max_scale - 1);
        return {
            lerp(color.r, max_saturation.r, norm_saturation_alpha),
            lerp(color.g, max_saturation.g, norm_saturation_alpha),
            lerp(color.b, max_saturation.b, norm_saturation_alpha),
        };
    }
}
// scale_saturation :: inline (color: Color3f, alpha: float32) -> Color3f {
//     grey_value := color_to_grey(color);
//     if alpha > 1 {
//         max_headroom: float32; // i love to see style.
//         grey_relative_scalars := Color3f.{1,1,1};
//         if color.r != 0 {
//             max_headroom = (1 - color.r) / color.r;
//             grey_relative_scalars = {1, GREY_FACTORS.g / GREY_FACTORS.r, GREY_FACTORS.b / GREY_FACTORS.r};
//         }
//         if color.g != 0 {
//             headroom_g := (1 - color.g) / color.g;
//             if headroom_g > max_headroom {
//                 max_headroom = headroom_g;
//                 grey_relative_scalars = {GREY_FACTORS.r / GREY_FACTORS.g, 1, GREY_FACTORS.b / GREY_FACTORS.g};
//             }
//         }
//         if color.b != 0 {
//             headroom_b := (1 - color.b) / color.b;
//             if headroom_b > max_headroom {
//                 max_headroom = headroom_b;
//                 grey_relative_scalars = {GREY_FACTORS.r / GREY_FACTORS.b, GREY_FACTORS.g / GREY_FACTORS.b, 1};
//             }
//         }
//         out_color := color;
//         if max_headroom > 0 {
//             use_alpha := min(alpha - 1, max_headroom);
//             out_color.r = clamp(color.r + color.r * use_alpha * grey_relative_scalars.r, 0, 1);
//             out_color.g = clamp(color.g + color.g * use_alpha * grey_relative_scalars.g, 0, 1);
//             out_color.b = clamp(color.b + color.b * use_alpha * grey_relative_scalars.b, 0, 1);
//         }
//         return out_color;
//     }
//     return color;
// }

color_to_grey :: inline (color: Color3f) -> Color3f {
    grey := get_grey_value(color);
    return {grey, grey, grey};
}

get_grey_value :: inline (color: Color3f) -> float32 {
    return GREY_FACTORS.r * color.r + GREY_FACTORS.g * color.g + GREY_FACTORS.b * color.b;
}

GREY_FACTORS :: Color3f.{0.2126, 0.7152, 0.0722};


hsl_to_rgb :: (hsl: Color_HSL) -> Color3f {
    rgb: Color3f = ---;
    ONE_THIRD :: 1.0 / 3.0;
    ONE_SIXTH :: 1.0 / 6.0;

    rgb.r = respace(abs(0.5 - hsl.hue),           {ONE_SIXTH, ONE_THIRD}, {0, 1});
    rgb.g = respace(abs(ONE_THIRD - hsl.hue),     {ONE_SIXTH, ONE_THIRD}, {1, 0});
    rgb.b = respace(abs(ONE_THIRD * 2 - hsl.hue), {ONE_SIXTH, ONE_THIRD}, {1, 0});

    grey_value := get_grey_value(rgb);
    grey_alpha := clamp(1 - hsl.saturation, 0.0, 1.0);
    rgb.r = lerp(rgb.r, grey_value, grey_alpha);
    rgb.g = lerp(rgb.g, grey_value, grey_alpha);
    rgb.b = lerp(rgb.b, grey_value, grey_alpha);

    if hsl.lightness > 0.5 {
        white_alpha := clamp((hsl.lightness - 0.5) * 2, 0.0, 1.0); 
        rgb = lighten(rgb, white_alpha);
    } else if hsl.lightness < 0.5 {
        black_alpha := clamp((0.5 - hsl.lightness) * 2, 0.0, 1.0); 
        rgb = darken(rgb, black_alpha);
    }

    return rgb;
}

rgb_to_hsl :: (rgb: Color3f) -> Color_HSL {
    hsl: Color_HSL = ---;


    return hsl;
}

#scope_file

#import "Basic";
#import "Random";
#import "Math";
#import "TeRM/TeRM_Math";

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
