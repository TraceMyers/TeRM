COLOR4F_WHITE         :: Color4f.{1,1,1,1};
COLOR4F_RED           :: Color4f.{1,0,0,1};
COLOR4F_GREEN         :: Color4f.{0,1,0,1};
COLOR4F_BLUE          :: Color4f.{0,0,1,1};
COLOR4F_BLACK         :: Color4f.{0,0,0,1};
COLOR4F_MAGENTA       :: Color4f.{1,0,1,1};
COLOR4F_BRIGHT_PURPLE :: Color4f.{0.65, 0.1, 0.82, 1};

GREY_FACTORS :: Color3f.{0.2126, 0.7152, 0.0722};

HSY_Component :: enum {
    HUE; 
    SATURATION;
    LUMINANCE;
};

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

Color_HSY :: struct {
    hue: float32;
    saturation := 1.0;
    luminance := 0.5;
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

get_grey_value :: inline (color: Color3f) -> float32 {
    return GREY_FACTORS.r * color.r + GREY_FACTORS.g * color.g + GREY_FACTORS.b * color.b;
}

to_grey :: inline (color: Color3f) -> Color3f {
    grey := get_grey_value(color);
    return {grey, grey, grey};
}

lighten :: inline (color: Color3f, alpha: float32) -> Color3f {
    return lerp_to_grey(color, 1, alpha);
}

darken :: inline (color: Color3f, alpha: float32) -> Color3f {
    return lerp_to_grey(color, 0, alpha);
}

scale_saturation :: inline (color: Color3f, scale: float32, try_preserve_aspect := HSY_Component.HUE) -> Color3f {
    assert(scale >= 0);
    assert(try_preserve_accuracy_of != .SATURATION);

    min_saturation := to_min_saturation(color);

    if scale <= 1 {
        grey_value := min_saturation.r;
        return lerp_to_grey(color, grey_value, 1-scale);
    }

    max_saturation, max_saturation_scale := to_max_saturation(color, try_preserve_aspect);

    if scale >= max_saturation_scale {
        return max_saturation;
    } else {
        norm_saturation_alpha := (scale - 1) / (max_saturation_scale - 1);
        return {
            lerp(color.r, max_saturation.r, norm_saturation_alpha),
            lerp(color.g, max_saturation.g, norm_saturation_alpha),
            lerp(color.b, max_saturation.b, norm_saturation_alpha),
        };
    }
}

// the 'saturation_scale' out value would be 0, if it returned one, because saturation
// is being scaled to 0.
to_min_saturation :: to_grey;

// 'saturation_scale' is the distance from the current color to max saturation, relative
// to the distance from the min saturation to the color. e.g. if the color is equidistant
// between min and max saturation, saturation_scale would be 1.
to_max_saturation :: (color: Color3f, try_preserve_aspect := HSY_Component.HUE) -> max_saturation: Color3f, saturation_scale: float32 {
    assert(try_preserve_accuracy_of != .SATURATION);

    min_saturation := to_min_saturation(color);
    grey_value := min_saturation.r;

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

    max_channel.max_saturation.* -= min_channel.max_saturation.*;
    mid_channel.max_saturation.* -= min_channel.max_saturation.*;
    // in order for a color to hit max saturation, the lowest valued channel must be muted
    // to 0, because adding value in the third channel moves toward white, which moves
    // away from full saturation. 
    min_channel.max_saturation.* = 0;

    if max_channel.max_saturation.* <= 0 {
        return {}, 1;
    }

    if try_preserve_accuracy_of == .HUE {
        // there is always at least one channel with value 1. two channels have value 1 if the hue is
        // 50% the distance between two channels. here, we scale the max channel to 1 and mid channel to
        // a value in [0, 1]
        scale_factor := 1 / max_channel.max_saturation.*;
        mid_channel.max_saturation.* = clamp(mid_channel.max_saturation.* * scale_factor, 0, 1);
        max_channel.max_saturation.* = clamp(max_channel.max_saturation.* * scale_factor, 0, 1);
    } else { // .LUMINANCE
        // in attempting to preserve luminance, we are trying to keep the grey value the same.
        // doing so means maxing out the max channel and giving the remaining grey to the mid channel.
        // this only works if sufficient value exists in the channels. for dark colors, this
        // will just return only the channel with the strongest signal e.g. {r=0.2, g=0.1, b=0.05} -> {r=1}
        max_channel.max_saturation.* = 1;
        mid_channel.max_saturation.* = max((grey_value - max_channel.grey_factor) / mid_channel.grey_factor, 0);
    }

    // this procedure returns how much the channels can be scaled up until one of the 
    // channels hits its maximum, and a scale of 1 is represented by the current distance
    // from the grey value. so, 2x saturation scale would be 2x the current distance
    // from grey. 
    max_min_dist := max_channel.input - max_channel.min_saturation.*;
    mid_min_dist := mid_channel.input - mid_channel.min_saturation.*;

    max_max_dist := max_channel.max_saturation.* - max_channel.input;
    mid_max_dist := mid_channel.max_saturation.* - mid_channel.input;

    max_max_scale := abs(max_max_dist / max_min_dist);
    mid_max_scale := abs(mid_max_dist / mid_min_dist);

    max_saturation_scale := min(max_max_scale, mid_max_scale);

    return max_saturation, max_saturation_scale;
}

// sets default luminance to the mid grey for the hue
hue_to_hsy :: inline (hue: float32, saturation := 1.0) -> Color_HSY {
    hsy: Color_HSY = ---;
    hsy.hue = hue;
    hsy.saturation = saturation;
    hsy.luminance = get_grey_value(hue_to_rgb(hue));
    return hsy;
}

hue_to_rgb :: (hue: float32) -> Color3f {
    rgb: Color3f = ---;
    rgb.r = respace(abs(0.5 - hue),           {ONE_SIXTH, ONE_THIRD}, {0, 1});
    rgb.g = respace(abs(ONE_THIRD - hue),     {ONE_SIXTH, ONE_THIRD}, {1, 0});
    rgb.b = respace(abs(ONE_THIRD * 2 - hue), {ONE_SIXTH, ONE_THIRD}, {1, 0});
    return rgb;
}

hsy_to_rgb :: (hsy: Color_HSY) -> Color3f {
    rgb := hue_to_rgb(hsy.hue);

    max_saturated_luminance := get_grey_value(rgb);
    grey := Color3f.{max_saturated_luminance, max_saturated_luminance, max_saturated_luminance};
    
    luma_shifted_rgb: Color3f = ---;

    if max_saturated_luminance <= hsy.luminance {
        alpha := clamp(1 - max_saturated_luminance / hsy.luminance, 0, 1);
        luma_shifted_rgb.r = lerp(rgb.r, 1, alpha);
        luma_shifted_rgb.g = lerp(rgb.g, 1, alpha);
        luma_shifted_rgb.b = lerp(rgb.b, 1, alpha);
    } else {
        alpha := clamp((max_saturated_luminance - hsy.luminance) / (1 - hsy.luminance), 0, 1);
        luma_shifted_rgb.r = lerp(rgb.r, 0, alpha);
        luma_shifted_rgb.g = lerp(rgb.g, 0, alpha);
        luma_shifted_rgb.b = lerp(rgb.b, 0, alpha);
    }

    grey_alpha := clamp(1 - hsy.saturation, 0.0, 1.0);
    rgb.r = lerp(luma_shifted_rgb.r, grey.r, grey_alpha);
    rgb.g = lerp(luma_shifted_rgb.g, grey.g, grey_alpha);
    rgb.b = lerp(luma_shifted_rgb.b, grey.b, grey_alpha);

    return rgb;
}

rgb_to_hsy :: (rgb: Color3f) -> Color_HSY {
    hsy: Color_HSY = ---;
    
    // min_saturated := to_min_saturation(rgb);
    // // hsl = {hue=?, sat=1, light=0.5} is the reference value for a color
    // max_saturated := to_max_saturation(rgb);

    // color_grey_value     := get_grey_value(color);
    // // this represents 0.5 lightness, because the most saturated version of a color is halfway between
    // // black and white.
    // reference_grey_value := get_grey_value(max_saturated);

    // if color_grey_value > reference_grey_value {
    //     hsl.lightness = respace(color_grey_value, {reference_grey_value, 1}, {0.5, 1});
    // } else {
    //     hsl.lightness = respace(color_grey_value, {0, reference_grey_value}, {0, 0.5});
    // }

    // // use channel that the hue is closest to as the pivot and lerp along the edge of the circle toward the
    // // other nonzero channel.
    // if max_saturated.r == 1 {
    //     if max_saturated.g > 0 { // rg
    //         hsl.hue = 0 + max_saturated.g * ONE_SIXTH;
    //     } else { // rb
    //         hsl.hue = 1 - max_saturated.b * ONE_SIXTH;
    //     }
    //     // the two most active channels of the input color are in a lerp between their grey value 
    //     // and max saturated value. capture that lerp in the most active channel.
    //     hsl.saturation = respace(rgb.r, {min_saturated.r, max_saturated.r}, {0, 1});
    // } else if max_saturated.g == 1 {
    //     if max_saturated.r > 0 { // rg
    //         hsl.hue = ONE_THIRD - max_saturated.r * ONE_SIXTH;
    //     } else { // gb
    //         hsl.hue = ONE_THIRD + max_saturated.b * ONE_SIXTH;
    //     }
    // } else {
    //     assert(max_saturated.b == 1);
    //     if max_saturated.r > 0 { // rb
    //         hsl.hue = 2 * ONE_THIRD + max_saturated.r * ONE_SIXTH;
    //     } else { // bg
    //         hsl.hue = 2 * ONE_THIRD - max_saturated.g * ONE_SIXTH;
    //     }
    // }


    return hsy;
}

#scope_file

ONE_THIRD :: 1.0 / 3.0;
ONE_SIXTH :: 1.0 / 6.0;

#import "Basic";
#import "Random";
#import "Math";
#import "TeRM/TeRM_Math";

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
