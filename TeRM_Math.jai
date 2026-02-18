#module_parameters()(
    FLIP_2D_Y := false // origin at upper left? flip it
);

// move to a section by looking for ':' + section name. e.g. text search for ':Trig'

// -- sections --
// Constants
// Direction & Orientation
// Smoothing
// Clamp
// Lines
// Trigonometry and Trig Helpers
// Wrap
// Power of 2 Related
// Conversion, Rounding and Respace
// Limits
// Boxes
// Misc
// Vectors Extension
// Vector2 Extension
// Vector2i
// Vector3i
// Vector2d

// -----------------------------------------------------------------------------------
// ------------------------------------------------------------------------ :Constants

#if FLIP_2D_Y {
    VECTOR2_UP      :: Vector2.{ 0, -1};
    VECTOR2_DOWN    :: Vector2.{ 0,  1};
    Y_POSITIVE_DIRECTION_2D :: Direction_2D.DOWN;
    Y_NEGATIVE_DIRECTION_2D :: Direction_2D.UP;
} else {
    VECTOR2_UP      :: Vector2.{ 0,  1};
    VECTOR2_DOWN    :: Vector2.{ 0, -1};
    Y_POSITIVE_DIRECTION_2D :: Direction_2D.UP;
    Y_NEGATIVE_DIRECTION_2D :: Direction_2D.DOWN;
}
VECTOR2_RIGHT   :: Vector2.{ 1,  0};
VECTOR2_LEFT    :: Vector2.{-1,  0};
VECTOR3_FORE    :: Vector3.{ 0,  1,  0};
VECTOR3_BACK    :: Vector3.{ 0, -1,  0};
VECTOR3_RIGHT   :: Vector3.{ 1,  0,  0};
VECTOR3_LEFT    :: Vector3.{-1,  0,  0};
VECTOR3_UP      :: Vector3.{ 0,  0,  1};
VECTOR3_DOWN    :: Vector3.{ 0,  0, -1};

// some convenient values, 'small' relative to the precision of 1.0
SMALLISH_NUMBER     :: 0.003;
SMALL_NUMBER        :: 0.00001;
VERY_SMALL_NUMBER   :: 0.0000003;

INV_PI          :: 1.0 / PI;
INV_2_PI        :: 1.0 / (2.0 * PI);

COS_0            :: 1.0;
ALMOST_COS_0     :: COS_PI_OVER_2048;
COS_PI_OVER_2048 :: 0.9999988; // ~0.09 degrees
COS_PI_OVER_128  :: 0.9996988;
COS_PI_OVER_64   :: 0.9987955;
COS_PI_OVER_32   :: 0.9951847;
COS_PI_OVER_28   :: 0.9937122;
COS_PI_OVER_24   :: 0.9914449;
COS_PI_OVER_20   :: 0.9876883;
COS_PI_OVER_16   :: 0.9807853;
COS_PI_OVER_12   :: 0.9659258;
COS_PI_OVER_8    :: 0.9238795;
COS_PI_OVER_7    :: 0.9009689;
COS_PI_OVER_6    :: 0.8660254;
COS_PI_OVER_5    :: 0.8090170;
COS_PI_OVER_4    :: 0.7071067;
COS_PI_OVER_3    :: 0.5;
COS_PI_OVER_2    :: 0.0;

FloatTypes :: Type.[float32, float64];
VectorTypes :: Type.[Vector2, Vector3, Vector4, Vector2d, Quaternion];  // Used for type restriction in normalize().
Vector2Types :: Type.[Vector2, Vector2i, Vector2d];
Vector3Types :: Type.[Vector3, Vector3i];
VectorAndFloatTypes :: Type.[Vector2, Vector3, Vector4, Vector2d, Quaternion, float32, float64];  // Used for type restriction in normalize().

// -----------------------------------------------------------------------------------
// ---------------------------------------------------------- :Direction & Orientation

Direction_3D :: enum u8 {
    UP;
    DOWN;
    LEFT;
    RIGHT;
    FORE;
    BACK;
}

Direction_2D :: enum u8 {
    UP;
    RIGHT;
    DOWN;
    LEFT;
}

is_vertical :: (dir: Direction_2D) -> bool {
    return (dir & 0x1) == 0;
}

is_horizontal :: (dir: Direction_2D) -> bool {
    return (dir & 0x1) == 1;
}

rotate :: (dir: Direction_2D, clockwise := true) -> Direction_2D {
    if clockwise {
        return increment_wrap(dir, Direction_2D.UP, Direction_2D.LEFT);
    } else {
        return decrement_wrap(dir, Direction_2D.UP, Direction_2D.LEFT);
    }
}

to_direction2d :: (dir: Vector2) -> cardinal: Direction_2D {
    if abs(dir.y) >= SMALL_NUMBER {
        if dir.x == 0 {
            return ifx dir.y > 0 then Y_POSITIVE_DIRECTION_2D else Y_NEGATIVE_DIRECTION_2D;
        }
        abs_xy_ratio := abs(dir.x / dir.y);
        if abs_xy_ratio >= 0.5 {
            return ifx dir.x > 0 then .RIGHT else .LEFT;
        } else {
            return ifx dir.y > 0 then Y_POSITIVE_DIRECTION_2D else Y_NEGATIVE_DIRECTION_2D;
        }
    } else if abs(dir.x) >= SMALL_NUMBER {
        return ifx dir.x > 0 then .RIGHT else .LEFT;
    } else {
        return .UP;
    }
}

to_vector2 :: (cardinal: Direction_2D) -> Vector2 {
    if #complete dir == {
    case .UP;
        return VECTOR2_UP;
    case .RIGHT;
        return VECTOR2_RIGHT;
    case .DOWN;
        return VECTOR2_DOWN;
    case .LEFT;
        return VECTOR2_LEFT;
    }
}

to_vector3 :: (cardinal: Direction_3D) -> Vector3 {
    if #complete dir == {
    case .UP;
        return VECTOR3_UP;
    case .DOWN;
        return VECTOR3_DOWN;
    case .LEFT;
        return VECTOR3_LEFT;
    case .RIGHT;
        return VECTOR3_RIGHT;
    case .FORE;
        return VECTOR3_FORE;
    case .BACK;
        return VECTOR3_BACK;
    }
}

to_vector3 :: (cardinal: Direction_3D, orientation: Quaternion) -> Vector3 {
    if #complete cardinal == {
    case .UP;
        return up_direction(*orientation);
    case .DOWN;
        return -up_direction(*orientation);
    case .LEFT;
        return -right_direction(*orientation);
    case .RIGHT;
        return right_direction(*orientation);
    case .FORE;
        return fore_direction(*orientation);
    case .BACK;
        return -fore_direction(*orientation);
    }
}

fore_direction :: inline (q: *Quaternion, $do_normalize := true) -> Vector3 {
    vec := rotate(VECTOR3_FORE, q);
    #if do_normalize {
        normalize(*vec);
    }
    return vec;
}

right_direction :: inline (q: *Quaternion, $do_normalize := true) -> Vector3 {
    vec := rotate(VECTOR3_RIGHT, q);
    #if do_normalize {
        normalize(*vec);
    }
    return vec;
}

up_direction :: inline (q: *Quaternion, $do_normalize := true) -> Vector3 {
    vec := rotate(VECTOR3_UP, q);
    #if do_normalize {
        normalize(*vec);
    }
    return vec;
}

fore_direction_xy :: inline (q: *Quaternion) -> Vector3 {
    fore_3d := fore_direction(q, false);
    fore_3d.z = 0;
    return normalize(fore_3d);
}

right_direction_xy :: inline (q: *Quaternion) -> Vector3 {
    right_3d := right_direction(q, false);
    right_3d.z = 0;
    return normalize(right_3d);
}

calculate_axes :: (orientation: Quaternion, fore: *Vector3, right: *Vector3, up: *Vector3) {
    fore.* = fore_direction(*orientation);
    up.* = up_direction(*orientation);
    right.* = normalize(cross(fore.*, up.*));
}

// e.g. local -> world
change_basis_forward :: inline (scalars: Vector3, fore: Vector3, right: Vector3, up: Vector3) -> Vector3 {
    return right * scalars.x + fore * scalars.y + up * scalars.z;
}

// e.g. world -> local
change_basis_backward :: inline (vector: Vector3, fore: Vector3, right: Vector3, up: Vector3) -> Vector3 {
    return {dot(right, vector), dot(fore, vector), dot(up, vector)};
}

distance_squared :: inline (q1: Quaternion, q2: Quaternion) -> float {
    diff := Vector4.{
        q1.x - q2.x,
        q1.y - q2.y,
        q1.z - q2.z,
        q1.w - q2.w,
    };
    return length_squared(diff);
}

distance :: inline (q1: Quaternion, q2: Quaternion) -> float {
    diff := Vector4.{
        q1.x - q2.x,
        q1.y - q2.y,
        q1.z - q2.z,
        q1.w - q2.w,
    };
    return length(diff);
}

make_quat :: (fore: Vector3, right: Vector3, up: Vector3) -> Quaternion {
    // assert(is_normalized(fore,      SMALL_NUMBER));
    // assert(is_normalized(right,     SMALL_NUMBER));
    // assert(is_normalized(up,        SMALL_NUMBER));
    rot_matrix := Matrix3.{
        right.x, fore.x, up.x,
        right.y, fore.y, up.y,
        right.z, fore.z, up.z,
    };
    return get_rotation(rot_matrix);
}

make_quat :: inline (fore: Vector3, up: Vector3) -> Quaternion {
    right := normalize(cross(fore, up));
    return make_quat(fore, right, up);
}

set_orientation :: (out_orientation: *Quaternion, forward: Vector3, up: Vector3) {
    out_orientation.* = make_quat(forward, up);
}

rotate :: (in_out_orientation: *Quaternion, axis: Vector3, angle: float32) {
    assert(is_normalized(axis));
    ht := angle * 0.5;
    sin_ht, cos_ht := sin_cos(ht);
    rot_quat := Quaternion.{xyz=axis*sin_ht, w=cos_ht};
    in_out_orientation.* = rot_quat * in_out_orientation.*;
    normalize_or_identity(in_out_orientation);
}

rotate :: inline (v: Vector3, axis: Vector3, angle: float32, $do_normalize := true) -> Vector3 {
    assert(is_normalized(axis));
    ht := angle * 0.5;
    sin_ht, cos_ht := sin_cos(ht);
    rot_quat := Quaternion.{xyz=axis*sin_ht, w=cos_ht};
    out_vec := rotate(v, rot_quat);
    if do_normalize {
        return normalize(out_vec);
    } else {
        return out_vec;
    }
}

interp_rotate_with_alpha :: (origin: Quaternion, target: Quaternion, alpha: float32) -> Quaternion {
    assert(alpha >= 0.0 && alpha <= 1.0);
    cos_theta := dot(origin, target);

    // put target in the same hemisphere as the origin, so that the interpolation takes the shortest path
    use_target := ifx cos_theta < 0 then -target else target;
    
    if cos_theta >= ALMOST_COS_0 {
        return use_target;
    } else if cos_theta >= COS_PI_OVER_12 {
        // small distances can be lerped without being able to tell the difference
        return nlerp(origin, use_target, alpha);
    } else {
        return slerp(origin, use_target, alpha);
    }
}

// slow because of acos at the top
// instead of calling this a bunch, for a fixed rotation, just use quat multiply
interp_rotate_with_time :: (origin: Quaternion, target: Quaternion, speed: float32, delta_time: float32) -> Quaternion {
    rot_dist := speed * delta_time;
    cos_ht := abs(dot(origin, target));
    t := 2.0 * acos_approx(cos_ht);
    if abs(rot_dist) >= t {
        return target;
    } else {
        return alpha_rotate(origin, target, rot_dist / t);
    }
}

quat_to_euler :: (q: Quaternion, degrees := true) -> Vector3 {
    yaw, roll, pitch: float = ---;
    // yaw (Z axis rotation)
    siny_cosp := 2.0 * (q.w * q.z + q.x * q.y);
    cosy_cosp := 1.0 - 2.0 * (q.y * q.y + q.z * q.z);
    yaw = atan2(siny_cosp, cosy_cosp);

    // roll (Y axis rotaton)
    sinr_cosp := 2.0 * (q.w * q.x + q.y * q.z);
    cosr_cosp := 1.0 - 2.0 * (q.x * q.x + q.y * q.y);
    roll = atan2(sinr_cosp, cosr_cosp);

    // pitch (X axis rotation)
    sinp := 2.0 * (q.w * q.y - q.z * q.x);
    if abs(sinp) >= 1 {
        pitch = PI / 2 * sign(sinp); // clamp
    } else {
        pitch = asin(sinp);
    }

    if degrees {
        return .{pitch, roll, yaw} * (180.0 / PI);
    } else {
        return .{pitch, roll, yaw};
    }
}

euler_to_quat :: (euler_angles: Vector3, degrees := true) -> Quaternion {
    use_angles := euler_angles;
    if degrees {
        use_angles *= (PI / 180.0);
    }
    sy, cy := sin_cos(use_angles.z * 0.5);
    sp, cp := sin_cos(use_angles.x * 0.5);
    sr, cr := sin_cos(use_angles.y * 0.5);

    q: Quaternion;
    q.w = cr * cp * cy + sr * sp * sy;
    q.x = sr * cp * cy - cr * sp * sy;
    q.y = cr * sp * cy + sr * cp * sy;
    q.z = cr * cp * sy - sr * sp * cy;
    return normalize(q);
}

// -----------------------------------------------------------------------------------
// ------------------------------------------------------------------------ :Smoothing

decay_exponentially_with_time :: inline (a: $T/VectorAndFloatTypes, b: T, speed: float32, delta_time: float32) -> T {
    move_factor := min(speed * delta_time, 1.0);
    return a + (b - a) * move_factor;
}

sigmoid :: inline (x: float32) -> float32 {
    return 1.0 / (1.0 + exp(-x));
}

// alpha: 0 to 1 linear value to be transformed into an S-curve value
// extent: how much of the curve to include. smaller number will clip values close to the edges and as such will also begin and end at a faster speed (steeper gradient on curve)
// midpoint: 0 to 1 linear value, toward 0 = more time spent smoothing out, toward 1 = more time spent smoothing in
interp_sigmoid_with_alpha :: (alpha: float32, extent := 10.0, midpoint := 0.5) -> float32 {
    sigmoid_input: float32 = ---;
    if midpoint != 0.5 {
        if alpha < midpoint {
            sigmoid_input = respace(respaced_alpha, {0, midpoint}, {0, 0.5});
        } else {
            sigmoid_input = respace(respaced_alpha, {midpoint, 1}, {0.5, 1});
        }
    } else {
        sigmoid_input = alpha;
    }
    neg_one_to_one := (sigmoid_input - 0.5) * 2.0;
    return sigmoid(clamp(neg_one_to_one * extent, -extent, extent));
}

// -----------------------------------------------------------------------------------
// ---------------------------------------------------------------------------- :Clamp

clamp :: inline (v: $T/Vector2Types, min: T, max: T) -> T {
    return .{
        clamp(v.x, min.x, max.x),
        clamp(v.y, min.y, max.y),
    };
}

clamp :: inline (v: $T/Vector3Types, min: T, max: T) -> T {
    return .{
        clamp(v.x, min.x, max.x),
        clamp(v.y, min.y, max.y),
        clamp(v.z, min.z, max.z),
    };
}

informed_clamp :: inline (x: float, min: float, max: float) -> float, s32 {
    if x < min {
        return min, -1;
    } else if x > max {
        return max, 1;
    } else {
        return x, 0;
    }
}

// -----------------------------------------------------------------------------------
// ---------------------------------------------------------------------------- :Lines

closest_point_on_each_line_segment :: (a1: Vector3, a2: Vector3, b1: Vector3, b2: Vector3, closest_pt_a: *Vector3, closest_pt_b: *Vector3) -> s: float, t: float {
    // from Real Time Collision Detection, by Christer Ericson
    a_diff          := a2 - a1;
    b_diff          := b2 - b1;
    b_to_a_diff     := a1 - b1;
    a_len_sq        := length_squared(a_diff);
    b_len_sq        := length_squared(b_diff);
    cos_t           := dot(b_diff, b_to_a_diff);

    // normalized distance along each segement where the respective closest points lie
    s, t: float = ---;

    MAX_ERROR :: SMALL_NUMBER;
    if a_len_sq <= MAX_ERROR {
        if b_len_sq <= MAX_ERROR {
            s, t = 0;
            closest_pt_a.* = a1;
            closest_pt_b.* = b1;
            return s, t;
        } else {
            s = 0;
            t = clamp(cos_t / b_len_sq, 0, 1);
        }
    } else {
        cos_p := dot(a_diff, b_to_a_diff);
        if b_len_sq <= MAX_ERROR {
            t = 0;
            s = clamp(-cos_p / a_len_sq, 0, 1);
        } else {
            // |a| |b| cos(q)
            scaled_cos_diffs := dot(a_diff, b_diff);
            // |a|^2 |b|^2 - (|a| |b| cos(q))^2 = (1 - cos(q)^2) |a|^2 |b|^2)
            denom := a_len_sq * b_len_sq - scaled_cos_diffs * scaled_cos_diffs; // book says always nonnegative

            if denom > MAX_ERROR {
                s = clamp((scaled_cos_diffs * cos_t - cos_p * b_len_sq) / denom, 0, 1);
            } else {
                // segments parallel
                // not from book; actually, everybody seems to get this wrong. both the book and some guy on stack overflow seem to think that picking an arbitrary value for s (like 0) here is fine, but this doesn't give a valuable answer in cases where the segments are non-overlapping along their parallel axis.
                // example: a1-------a2        b1--------b2
                // these two are parallel, but s should be 1 because a2 is closer to both b1 and b2
                // it's not pointless to make this distinction. i have found cases where it is important.
                b_to_a_dist_sq_1 := length_squared(a1 - b1);
                b_to_a_dist_sq_2 := length_squared(a2 - b2);    
                b_to_a_dist_sq_3 := length_squared(a1 - b2);    
                b_to_a_dist_sq_4 := length_squared(a2 - b1);
                min_dist_sq: float = ---;
                if b_to_a_dist_sq_1 < b_to_a_dist_sq_2 {
                    min_dist_sq = b_to_a_dist_sq_1;
                    s = 0;
                } else {
                    min_dist_sq = b_to_a_dist_sq_2;
                    s = 1;
                }
                if b_to_a_dist_sq_3 < min_dist_sq {
                    min_dist_sq = b_to_a_dist_sq_3;
                    s = 0;
                }
                if b_to_a_dist_sq_4 < min_dist_sq {
                    s = 1;
                }
            }

            t = (scaled_cos_diffs * s + cos_t) / b_len_sq;

            if t < 0 {
                t = 0;
                s = clamp(-cos_p / a_len_sq, 0, 1);
            } else if t > 1 {
                t = 1;
                s = clamp((scaled_cos_diffs - cos_p) / a_len_sq, 0, 1);
            }
        }
    }

    closest_pt_a.* = a1 + a_diff * s;
    closest_pt_b.* = b1 + b_diff * t;
    return s, t;
}

distance_between_line_segments :: (a1: Vector3, a2: Vector3, b1: Vector3, b2: Vector3, closest_point_a: *Vector3, closest_point_b: *Vector3) -> float {
    closest_point_on_each_line_segment(a1, a2, b1, b2, closest_point_a, closest_point_b);
	return distance(closest_point_a.*, closest_point_b.*);
}

distance_squared_between_line_segments :: (a1: Vector3, a2: Vector3, b1: Vector3, b2: Vector3, closest_point_a: *Vector3, closest_point_b: *Vector3) -> float {
    closest_point_on_each_line_segment(a1, a2, b1, b2, closest_point_a, closest_point_b);
	return distance_squared(closest_point_a.*, closest_point_b.*);
}

line_projection_norm_dist :: inline (point: *Vector3, seg_beg: *Vector3, seg_end: *Vector3, out_toward_end: *Vector3) -> t: float {
    out_toward_end.* = seg_end.* - seg_beg.*;
    toward_pt  := point.* - seg_beg.*;
    scaled_cos_t := dot(out_toward_end.*, toward_pt);
    segment_dist_sq := dot(out_toward_end.*, out_toward_end.*);
    return scaled_cos_t / segment_dist_sq;
}

closest_point_on_line_and_segment :: (point: Vector3, seg_beg: Vector3, seg_end: Vector3, out_point_on_line: *Vector3, out_point_on_segment: *Vector3) -> norm_dist: float {
    toward_end: Vector3 = ---;
    norm_dist := line_projection_norm_dist(*point, *seg_beg, *seg_end, *toward_end);
    out_point_on_line.* = seg_beg + toward_end * norm_dist;
    clamped_norm_dist := clamp(norm_dist, 0, 1);
    out_point_on_segment.* = seg_beg + toward_end * clamped_norm_dist;
    return norm_dist;
}

closest_point_on_line_segment :: (point: Vector3, seg_beg: Vector3, seg_end: Vector3) -> Vector3, float {
    toward_end: Vector3 = ---;
    norm_dist := line_projection_norm_dist(*point, *seg_beg, *seg_end, *toward_end);
    clamped_norm_dist := clamp(norm_dist, 0, 1);
    return seg_beg + toward_end * clamped_norm_dist, clamped_norm_dist;
}

closest_point_on_line :: (point: Vector3, seg_beg: Vector3, seg_end: Vector3) -> Vector3, float {
    toward_end: Vector3 = ---;
    norm_dist := line_projection_norm_dist(*point, *seg_beg, *seg_end, *toward_end);
    return seg_beg + toward_end * norm_dist, norm_dist;
}

distance_from_line_segment :: inline (point: Vector3, seg_beg: Vector3, seg_end: Vector3) -> float {
    closest_point := closest_point_on_line_segment(point, seg_beg, seg_end);
    return distance(closest_point, point);
}

distance_squared_from_line_segment :: inline (point: Vector3, seg_beg: Vector3, seg_end: Vector3) -> float {
    closest_point := closest_point_on_line_segment(point, seg_beg, seg_end);
    return distance_squared(closest_point, point);
}

distance_from_line :: inline (point: Vector3, seg_beg: Vector3, seg_end: Vector3) -> float {
    closest_point := closest_point_on_line(point, seg_beg, seg_end);
    return distance(closest_point, point);
}

distance_squared_from_line :: inline (point: Vector3, seg_beg: Vector3, seg_end: Vector3) -> float {
    closest_point := closest_point_on_line(point, seg_beg, seg_end);
    return distance_squared(closest_point, point);
}

// -----------------------------------------------------------------------------------
// ---------------------------------------------------- :Trigonometry and Trig Helpers

// small abs max error (~0.0008) and ~15% faster when using cephes.jai acos() as the reference. thanks to Vasili at https://math.stackexchange.com/questions/4983100/finding-arcsin-or-arccos-from-other-mathmatical-functions
acos_approx :: inline (x: float) -> float {
    if x < 0 {
        x = max(-x, -1);
        return PI - sqrt(1-x) * (1.5707963267948966 - 0.20347053865798365 * x + 0.046887774236182234 * x * x).(float32);
    } else {
        x = min(x, 1);
        return sqrt(1-x) * (1.5707963267948966 - 0.20347053865798365 * x + 0.046887774236182234 * x * x).(float32);
    }
}

// don't use this procedure if the input value is too large! makes large error.
// recommended max ~4000
mod_two_pi :: inline (x: float) -> float {
    assert(x >= 0);

    // fixed point division, from before cpus could divide. conveniently gives the remainder as a byproduct.

    x_fixed := (x * FIXED_ONE).(u64);
    prod := x_fixed * RECIP_TWO_PI_FIXED_32;
    quotient := prod >> 32;

    remainder_fixed := x_fixed - (quotient * TWO_PI_FIXED);
    if remainder_fixed < 0 {
        remainder_fixed += TWO_PI_FIXED;
    } else if remainder_fixed >= TWO_PI_FIXED {
        remainder_fixed -= TWO_PI_FIXED;
    }

    out_val := remainder_fixed.(float) * INV_FIXED_ONE;
    return out_val;
}

// gives value and sign in [-pi/2, pi/2] for sin_cos
convert_to_fast_trig_range :: inline (x: float32) -> x1: float32, sin_sign: float32, cos_sign: float32 {
    pos_x, sin_sign, cos_sign : float32 = ---;
    if sign(x) == 1.0 {
        pos_x = x;
        sin_sign = 1.0;
        cos_sign = 1.0;
    } else {
        pos_x = x * -1.0;
        sin_sign = sign(x);
        cos_sign = -sin_sign;
    }

    // get value in [0, 2pi)
    x1 := mod_two_pi(pos_x);
    // map to [-pi/2, pi/2)
    if x1 > (3 * PI * 0.5) {
        x1 -= 2.0 * PI;
    } else if x1 > PI {
        x1 = (PI * 0.5 - (x1 - (3.0 * PI * 0.5)));
        sin_sign *= -1.0;
    } else if x1 > PI * 0.5 {
        x1 = PI - x1;    
        cos_sign *= -1.0;
    }

    return x1, sin_sign, cos_sign;
}

// test shows ~25-50% reduction in time (maybe depending on branch misses) from using sin and cos separately. inputs are recommended to stay within domain (-5000,5000) to keep max error below 0.035 and median error ~0.0001, due to limitations with mod_two_pi()
// todo: bring the error down
sin_cos :: inline (x: float32) -> sin_x: float32, cos_x: float32 {
    x1, sin_sign, cos_sign := convert_to_fast_trig_range(x); 
    x2 := x1 * x1;
	pos_val_sin := (((((-0.000000023889859 * x2 + 0.0000027525562) * x2 - 0.00019840874) * x2 + 0.0083333310) * x2 - 0.16666667) * x2 + 1.0) * x1;
	pos_val_cos := ((((-0.00000026051615 * x2 + 0.000024760495) * x2 - 0.0013888378) * x2 + 0.041666638) * x2 - 0.5) * x2 + 1.0;
    return pos_val_sin * sin_sign, pos_val_cos * cos_sign;
}

// -----------------------------------------------------------------------------------
// ----------------------------------------------------------------------------- :Wrap

increment_wrap :: inline (val: $T, min: T, max: T) -> T {
    if val >= max {
        val = min;
    } else val += 1;
    return val;
}

decrement_wrap :: inline (val: $T, min: T, max: T) -> T {
    if val <= min {
        val = max;
    } else val -= 1;
    return val;
}

add_wrap :: (val: $T, add_amt: T, min: T, max: T) -> T {
    assert(val >= min && val <= max && max >= min);
    sum := val + add_amt;
    min_max_diff := (max - min) + 1;
    if sum > max {
        sum_max_diff := sum - (max + 1); // adding one makes the rest simpler
        remainder := sum_max_diff % min_max_diff;
        return min + remainder;
    } else if sum < min {
        min_sum_diff := (min - 1) - sum;
        remainder := min_sum_diff % min_max_diff;
        return max - remainder;
    } else {
        return sum;
    }
}

// -----------------------------------------------------------------------------------
// --------------------------------------------------------------- :Power of 2 Related

is_power_of_two :: inline (val: $T) -> bool {
    return val > 0 && (val & (val - 1)) == 0;
}

ceil_to_power_of_two_multiple :: inline (n: $T, power_of_two_size: T) -> T {
    assert(is_power_of_two(power_of_two_size));
    return (n + power_of_two_size-1) & ~(power_of_two_size-1);
}

// floor to a multiple of a power of 2
floor_to_power_of_two_multiple :: inline (n: $T, power_of_two_size: T) -> T {
    assert(is_power_of_two(power_of_two_size));
    return n & ~(power_of_two_size-1);
}

ceil_to_power_of_two :: inline (n: $T) -> T {
    if n == 0 {
        return 0;
    } else if !is_power_of_two(n) {
        return xx ((1).(u64) << (bit_scan_reverse(n)).(u64));
    } else return n;
}

shift_for_power_of_two_mul_or_div :: inline (divide_by: int) -> u8 {
    assert(is_power_of_two(divide_by));
    return bit_scan_forward(divide_by) - 1;
}

// -----------------------------------------------------------------------------------
// ------------------------------------------------- :Conversion, Rounding and Respace

div_ceil :: inline (a: $Int_Type, b: Int_Type) -> Int_Type 
#modify {
    return Int_Type.(*Type_Info).type == .INTEGER;
} {
    assert(a >= 0 && b > 0);
    return ((a - 1) / b) + 1;
}

ceil_to_multiple :: inline (a: $Int_Type, b: Int_Type) -> Int_Type
#modify {
    return Int_Type.(*Type_Info).type == .INTEGER;
} {
    assert(a >= 0 && b > 0);
    return div_ceil(a, b) * b;
}

floor_to_multiple :: inline (a: $Int_Type, b: Int_Type) -> Int_Type
#modify {
    return Int_Type.(*Type_Info).type == .INTEGER;
} {
    assert(a >= 0 && b > 0);
    return (a / b) * b;
}

round :: (a: float64, $Int_Type := s32) -> Int_Type 
#modify {
    return Int_Type.(*Type_Info).type == .INTEGER;
} {
    if a < get_min_value(Int_Type).(float64) {
        return get_min_value(Int_Type);
    }
    rounded_toward_zero := a.(Int_Type);
    if a > 0 && rounded_toward_zero < 0 { // overflow on cast
        return get_max_value(Int_Type);
    }
    diff := a - cast(float64)rounded_toward_zero;
    if diff > 0.5 {
        return rounded_toward_zero + 1;
    } else if diff < -0.5 {
        return rounded_toward_zero - 1;
    } else {
        return rounded_toward_zero;
    }
}

// cast between int and normalized or non-normalized floats with optional rounding on float->int
alter_cast :: inline (number: $In_Type, $Out_Type: Type, $NORMALIZED_FLOAT := false, $ROUND_TO_INT := true) -> Out_Type
#modify {
    float_to_int := In_Type.(*Type_Info).type == .FLOAT && Out_Type.(*Type_Info).type == .INTEGER;
    int_to_float := In_Type.(*Type_Info).type == .INTEGER && Out_Type.(*Type_Info).type == .FLOAT;
    return float_to_int || int_to_float;
} {
    MIN_IN :: #run get_min_value(In_Type);
    MAX_IN :: #run get_max_value(In_Type);
    IN_DIFF :: MAX_IN - MIN_IN;
    MIN_OUT :: #run get_min_value(Out_Type);
    MAX_OUT :: #run get_max_value(Out_Type);
    OUT_DIFF :: MAX_OUT - MIN_OUT;
    IN_IS_FLOAT :: #run type_info(In_Type).type == .FLOAT;
    OUT_IS_FLOAT :: #run type_info(Out_Type).type == .FLOAT;
    FLOAT_TO_INT :: IN_IS_FLOAT && !OUT_IS_FLOAT;
    INT_TO_FLOAT :: !IN_IS_FLOAT && OUT_IS_FLOAT;

    #if NORMALIZED_FLOAT {
        #if FLOAT_TO_INT {
            #if ROUND_TO_INT {
                return round(MIN_OUT.(float64) + (MAX_OUT.(float64) - MIN_OUT.(float64)) * xx number, Out_Type);
            } else {
                return xx (MIN_OUT.(float64) + (MAX_OUT.(float64) - MIN_OUT.(float64)) * xx number);
            }
        } else #if INT_TO_FLOAT {
            return xx clamp((number.(float64) - MIN_IN.(float64)) / IN_DIFF.(float64), 0.0, 1.0);
        }
    } else {
        if number < MIN_OUT {
            return MIN_OUT;
        } else if number > MAX_OUT {
            return MAX_OUT;
        } else {
            #if FLOAT_TO_INT && ROUND_TO_INT {
                return round(number, Out_Type);
            } 
            return xx number;
        }
    }
    return xx 0;
}

// transform x from space in_range to space out_range
// e.g. respace(time, {min_time, max_time}, {0, 1}); outputs normalized time
respace :: (x: float32, in_range: Vector2, out_range: Vector2, $do_clamp := true) -> float32 {
    norm_val: float32 = ---;
    if in_range.y > in_range.x {
        in_range_width := in_range.y - in_range.x;
        #if do_clamp {
            norm_val = (clamp(x, in_range.x, in_range.y) - in_range.x) / in_range_width;
        } else {
            norm_val = (x - in_range.x) / in_range_width;
        }
    } else {
        in_range_width := in_range.x - in_range.y;
        #if do_clamp {
            norm_val = 1.0 - (clamp(x, in_range.y, in_range.x) - in_range.y) / in_range_width;
        } else {
            norm_val = 1.0 - (x - in_range.y) / in_range_width;
        }
    }
    out_range_width := out_range.y - out_range.x;
    return out_range.x + out_range_width * norm_val;
}

// -----------------------------------------------------------------------------------
// --------------------------------------------------------------------------- :Limits

get_min_value :: ($Number_Type: Type) -> Number_Type
#modify {
    tinfo := Number_Type.(*Type_Info);
    return tinfo.type == .INTEGER || tinfo.type == .FLOAT;
} {
    #if Number_Type == {
    case u8;
        return 0;
    case u16; 
        return 0;
    case u32; 
        return 0;
    case u64;
        return 0;
    case s8;
        return S8_MIN;
    case s16;
        return S16_MIN;
    case s32;
        return S32_MIN;
    case s64;
        return S64_MIN;
    case float32;
        return FLOAT32_MIN;
    case float64;
        return FLOAT64_MIN;
    case;
        return 0;
    }
}

get_max_value :: ($Number_Type: Type) -> Number_Type
#modify {
    tinfo := Number_Type.(*Type_Info);
    return tinfo.type == .INTEGER || tinfo.type == .FLOAT;
} {
    #if Number_Type == {
    case u8;
        return U8_MAX;
    case u16;
        return U16_MAX;
    case u32;
        return U32_MAX;
    case u64;
        return U64_MAX;
    case s8;
        return S8_MAX;
    case s16;
        return S16_MAX;
    case s32;
        return S32_MAX;
    case s64;
        return S64_MAX;
    case float32;
        return FLOAT32_MAX;
    case float64;
        return FLOAT64_MAX;
    case;
        return 0;
    }
}

// -----------------------------------------------------------------------------------
// ---------------------------------------------------------------------------- :Boxes

AABB :: struct {
    center: Vector3;
    extent: Vector3;
}

Box :: struct {
    center: Vector3;
    extent: Vector3;
    fore: Vector3;
    up: Vector3;
    right: Vector3;
#overlay(fore) axes: [3]Vector3 = ---;
}

Box_Point :: enum u8 {
    BOT_LOWER_LEFT;
    BOT_LOWER_RIGHT;
    BOT_UPPER_LEFT;
    BOT_UPPER_RIGHT;
    TOP_LOWER_LEFT;
    TOP_LOWER_RIGHT;
    TOP_UPPER_LEFT;
    TOP_UPPER_RIGHT;
}

Box_Edge :: struct {
    a: Box_Point;
    b: Box_Point;
}

Box_Edges :: Box_Edge.[
    .{.BOT_LOWER_LEFT,  .BOT_LOWER_RIGHT},
    .{.BOT_LOWER_LEFT,  .BOT_UPPER_LEFT},
    .{.BOT_UPPER_RIGHT, .BOT_LOWER_RIGHT},
    .{.BOT_UPPER_RIGHT, .BOT_UPPER_LEFT},
    .{.BOT_LOWER_LEFT,  .TOP_LOWER_LEFT},
    .{.BOT_LOWER_RIGHT, .TOP_LOWER_RIGHT},
    .{.BOT_UPPER_LEFT,  .TOP_UPPER_LEFT},
    .{.BOT_UPPER_RIGHT, .TOP_UPPER_RIGHT},
    .{.TOP_LOWER_LEFT,  .TOP_LOWER_RIGHT},
    .{.TOP_LOWER_LEFT,  .TOP_UPPER_LEFT},
    .{.TOP_UPPER_RIGHT, .TOP_LOWER_RIGHT},
    .{.TOP_UPPER_RIGHT, .TOP_UPPER_LEFT}
];

is_overlap_aabb_aabb :: inline (aabb_a: AABB, aabb_b: AABB) -> bool {
    abs_pos_diff := abs(aabb_a.center - aabb_b.center);
    return abs_pos_diff.x < aabb_a.extent.x + aabb_b.extent.x
        && abs_pos_diff.y < aabb_a.extent.y + aabb_b.extent.y
        && abs_pos_diff.z < aabb_a.extent.z + aabb_b.extent.z;
}

get_aabb_points :: (aabb: AABB, out_points: *[8]Vector3) {
    out_points.*[Box_Point.BOT_LOWER_LEFT]    = aabb.center - aabb.extent;
    out_points.*[Box_Point.BOT_LOWER_RIGHT]   = aabb.center + Vector3.{ aabb.extent.x, -aabb.extent.y, -aabb.extent.z}; 
    out_points.*[Box_Point.BOT_UPPER_LEFT]    = aabb.center + Vector3.{-aabb.extent.x,  aabb.extent.y, -aabb.extent.z}; 
    out_points.*[Box_Point.BOT_UPPER_RIGHT]   = aabb.center + Vector3.{ aabb.extent.x,  aabb.extent.y, -aabb.extent.z}; 
    out_points.*[Box_Point.TOP_LOWER_LEFT]    = aabb.center + Vector3.{-aabb.extent.x, -aabb.extent.y,  aabb.extent.z};
    out_points.*[Box_Point.TOP_LOWER_RIGHT]   = aabb.center + Vector3.{ aabb.extent.x, -aabb.extent.y,  aabb.extent.z}; 
    out_points.*[Box_Point.TOP_UPPER_LEFT]    = aabb.center + Vector3.{-aabb.extent.x,  aabb.extent.y,  aabb.extent.z};
    out_points.*[Box_Point.TOP_UPPER_RIGHT]   = aabb.center + aabb.extent;
} 

get_box_points :: inline (position: Vector3, length_vec: Vector3, height_vec: Vector3, width_vec: Vector3, out_points: *[8]Vector3) {
    out_points.*[Box_Point.BOT_LOWER_LEFT]     = position - length_vec - height_vec - width_vec;
    out_points.*[Box_Point.BOT_LOWER_RIGHT]    = position - length_vec - height_vec + width_vec;
    out_points.*[Box_Point.BOT_UPPER_LEFT]     = position + length_vec - height_vec - width_vec;
    out_points.*[Box_Point.BOT_UPPER_RIGHT]    = position + length_vec - height_vec + width_vec;
    out_points.*[Box_Point.TOP_LOWER_LEFT]     = position - length_vec + height_vec - width_vec;
    out_points.*[Box_Point.TOP_LOWER_RIGHT]    = position - length_vec + height_vec + width_vec;
    out_points.*[Box_Point.TOP_UPPER_LEFT]     = position + length_vec + height_vec - width_vec;
    out_points.*[Box_Point.TOP_UPPER_RIGHT]    = position + length_vec + height_vec + width_vec;
}

is_closest_point_in_aabb :: inline (position: Vector3, aabb: AABB) -> Vector3 {
    diff := position - aabb.center;
    return aabb.center + clamp(diff, aabb.extent);
}

is_closest_point_in_box :: inline (position: Vector3, box: Box) -> Vector3 {
    diff := position - box.center;
    dist_along_axes := Vector3.{dot(diff, box.right), dot(diff, box.fore), dot(diff, box.up)};
    return box.center + clamp(dist_along_axes, box.extent);
}

is_point_inside_box :: (point: Vector2, upper_left: Vector2, lower_right: Vector2) -> bool {
    return point.x >= upper_left.x && point.x <= lower_right.x
        && point.y >= upper_left.y && point.y <= lower_right.y;
}

is_point_inside_box :: (point: Vector2i, upper_left: Vector2i, lower_right: Vector2i) -> bool {
    return point.x >= upper_left.x && point.x <= lower_right.x
        && point.y >= upper_left.y && point.y <= lower_right.y;
}

// if an AABB were to move, what would the bounding box containing the previous and new AABB be?
sweep_aabb :: inline  (aabb: AABB, displacement: Vector3) -> AABB {
    min := aabb.center - aabb.extent;
    max := aabb.center + aabb.extent;
    if displacement.x < 0 then min.x += displacement.x; else max.x += displacement.x;
    if displacement.y < 0 then min.y += displacement.y; else max.y += displacement.y;
    if displacement.z < 0 then min.z += displacement.z; else max.z += displacement.z;
    extent := (max - min) * 0.5;
    return .{min + extent, extent};
}

// -----------------------------------------------------------------------------------
// ----------------------------------------------------------------------------- :Misc

sign :: inline (x: $T, $can_return_zero := true) -> T {
    #if can_return_zero {
        if x == 0 return xx 0;
    }
    return ifx x < 0 then (-1).(T) else (1).(T);
}

deg2rad :: inline (deg: float) -> rad: float {
    return deg * (PI / 180.0);
}

rad2deg :: inline (rad: float) -> deg: float {
    return rad * (180.0 / PI);
}

// note that because this is done step-wise, it degrades the amount at each step, not the initial value. meaning, it doesn't actually lose 'proportion_lost_per_second' per second. that name only makes sense if you consider what is happening in the moment of application.
degrade_over_time :: (x: *$T/VectorAndFloatTypes, proportion_lost_per_second: float, time_step: float) -> bool {
    IS_VECTOR_TYPE :: #run array_find(VectorTypes, T);
    keep_proportion_per_second := 1 - proportion_lost_per_second;
    delta := x.* * (keep_proportion_per_second * time_step);
    #if IS_VECTOR_TYPE {
        if length_squared(delta) > length_squared(x) {
            x.* = .{};
            return true;
        } else {
            x.* -= delta;
            return false;
        }
    } else {
        if delta > x {
            x.* = 0;
            return true;
        } else {
            x.* -= delta;
            return false;
        }
    }
}

// -----------------------------------------------------------------------------------
// -------------------------------------------------------------------------- :Vectors

is_normalized :: (v: $Vec_Type, tolerance := 0.0001) -> bool {
    return abs(length_squared(v) - 1.0) < tolerance;
}

project_point_onto_plane :: inline (point: Vector3, point_on_plane: Vector3, plane_normal: Vector3) -> pos: Vector3, signed_dist: float {
    assert(is_normalized(plane_normal, SMALL_NUMBER));
    diff := point - point_on_plane;
    // distance along the plane normal
    signed_dist_along_normal := dot_product(plane_normal, diff);
    return point - plane_normal * signed_dist_along_normal, signed_dist_along_normal;
}

reflection_component :: inline (vector: Vector3, normal: Vector3) -> float {
    return 2.0 * dot(vector, -normal);
}

reflect :: inline (vector: Vector3, normal: Vector3) -> Vector3 {
    return vector + reflection_component(vector, normal) * normal; 
}

// -----------------------------------------------------------------------------------
// ---------------------------------------------------------------- :Vector2 Extension

operator - :: (a: Vector2, scalar: float32) -> Vector2 {
    return .{a.x - scalar, a.y - scalar};
}

operator + :: (a: Vector2, scalar: float32) -> Vector2 {
    return .{a.x + scalar, a.y + scalar};
}

operator - :: (a: Vector3, scalar: float32) -> Vector3 {
    return .{a.x - scalar, a.y - scalar, a.z - scalar};
}

operator + :: (a: Vector3, scalar: float32) -> Vector3 {
    return .{a.x + scalar, a.y + scalar, a.z + scalar};
}

// -----------------------------------------------------------------------------------
// ------------------------------------------------------------------------- :Vector2i

Vector2i :: struct {
    x: s32;
    y: s32;
}

operator + :: inline (a: Vector2i, b: Vector2i) -> Vector2i {
    return .{a.x + b.x, a.y + b.y};
}

operator - :: inline (a: Vector2i, b: Vector2i) -> Vector2i {
    return .{a.x - b.x, a.y - b.y};
}

operator * :: inline (a: Vector2i, b: Vector2i) -> Vector2i {
    return .{a.x * b.x, a.y * b.y};
}

operator / :: inline (a: Vector2i, b: Vector2i) -> Vector2i {
    return .{a.x / b.x, a.y / b.y};
}

operator + :: inline (a: Vector2i, scalar: s32) -> Vector2i #symmetric {
    return .{a.x + scalar, a.y + scalar};
}

operator - :: inline (a: Vector2i, scalar: s32) -> Vector2i {
    return .{a.x - scalar, a.y - scalar};
}

operator - :: inline (scalar: s32, a: Vector2i) -> Vector2i {
    return .{scalar - a.x, scalar - a.y};
}

operator * :: inline (a: Vector2i, scalar: s32) -> Vector2i #symmetric {
    return .{a.x * scalar, a.y * scalar};
}

operator / :: inline (a: Vector2i, scalar: s32) -> Vector2i {
    return .{a.x / scalar, a.y / scalar};
}

operator / :: inline (scalar: s32, a: Vector2i) -> Vector2i {
    return .{scalar / a.x, scalar / a.y};
}

operator == :: inline (a: Vector2i, b: Vector2i) -> bool {
    return (a.x == b.x) && (a.y == b.y);
}

to_vector2 :: inline (v: Vector2i) -> Vector2 {
    return .{xx v.x, xx v.y};
}

to_vector2i :: inline (v: Vector2) -> Vector2i {
    return .{xx v.x, xx v.y};
}

// -----------------------------------------------------------------------------------
// ------------------------------------------------------------------------- :Vector3i

Vector3i :: struct {
    x: s32;
    y: s32;
    z: s32;

#overlay(x) xy: Vector2i = ---;
#overlay(y) yz: Vector2i = ---;
}

operator + :: inline (a: Vector3i, b: Vector3i) -> Vector3i {
    return .{a.x + b.x, a.y + b.y, a.z + b.z};
}

operator - :: inline (a: Vector3i, b: Vector3i) -> Vector3i {
    return .{a.x - b.x, a.y - b.y, a.z - b.z};
}

operator * :: inline (a: Vector3i, b: Vector3i) -> Vector3i {
    return .{a.x * b.x, a.y * b.y, a.z * b.z};
}

operator / :: inline (a: Vector3i, b: Vector3i) -> Vector3i {
    return .{a.x / b.x, a.y / b.y, a.z / b.z};
}

operator + :: inline (a: Vector3i, scalar: s32) -> Vector3i #symmetric {
    return .{a.x + scalar, a.y + scalar, a.z + scalar};
}

operator - :: inline (a: Vector3i, scalar: s32) -> Vector3i {
    return .{a.x - scalar, a.y - scalar, a.z - scalar};
}

operator - :: inline (scalar: s32, a: Vector3i) -> Vector3i {
    return .{scalar - a.x, scalar - a.y, scalar - a.z};
}

operator * :: inline (a: Vector3i, scalar: s32) -> Vector3i #symmetric {
    return .{a.x * scalar, a.y * scalar, a.z * scalar};
}

operator / :: inline (a: Vector3i, scalar: s32) -> Vector3i {
    return .{a.x / scalar, a.y / scalar, a.z / scalar};
}

operator / :: inline (scalar: s32, a: Vector3i) -> Vector3i {
    return .{scalar / a.x, scalar / a.y, scalar / a.z};
}

operator == :: inline (a: Vector3i, b: Vector3i) -> bool {
    return (a.x == b.x) && (a.y == b.y) && (a.z == b.z);
}

to_vector3 :: inline (v: Vector3i) -> Vector3 {
    return .{xx v.x, xx v.y, xx v.z};
}

to_vector3i :: inline (v: Vector3) -> Vector3i {
    return .{xx v.x, xx v.y, xx v.z};
}

abs :: inline (a: Vector3i) -> Vector3i {
    return .{abs(a.x), abs(a.y), abs(a.z)};
}

sum :: inline (a: Vector3i) -> s32 {
    return a.x + a.y + a.z;
}

vector :: inline (scalar: float) -> Vector3 {
    return Vector3.{scalar, scalar, scalar};
}

max :: (a: Vector3) -> float {
    return max(a.x, max(a.y, a.z));
}

// -----------------------------------------------------------------------------------
// ------------------------------------------------------------------------- :Vector2d

Vector2d :: struct {
    x: float64;
    y: float64;
}

operator + :: inline (a: Vector2d, b: Vector2d) -> Vector2d {
    return .{a.x + b.x, a.y + b.y};
}

operator - :: inline (a: Vector2d, b: Vector2d) -> Vector2d {
    return .{a.x - b.x, a.y - b.y};
}

operator * :: inline (a: Vector2d, b: Vector2d) -> Vector2d {
    return .{a.x * b.x, a.y * b.y};
}

operator / :: inline (a: Vector2d, b: Vector2d) -> Vector2d {
    return .{a.x / b.x, a.y / b.y};
}

operator + :: inline (a: Vector2d, scalar: float64) -> Vector2d #symmetric {
    return .{a.x + scalar, a.y + scalar};
}

operator - :: inline (a: Vector2d, scalar: float64) -> Vector2d {
    return .{a.x - scalar, a.y - scalar};
}

operator - :: inline (scalar: float64, a: Vector2d) -> Vector2d {
    return .{scalar - a.x, scalar - a.y};
}

operator * :: inline (a: Vector2d, scalar: float64) -> Vector2d #symmetric {
    return .{a.x * scalar, a.y * scalar};
}

operator / :: inline (a: Vector2d, scalar: float64) -> Vector2d {
    return .{a.x / scalar, a.y / scalar};
}

operator / :: inline (scalar: float64, a: Vector2d) -> Vector2d {
    return .{scalar / a.x, scalar / a.y};
}

operator == :: inline (a: Vector2d, b: Vector2d) -> bool {
    return (a.x == b.x) && (a.y == b.y);
}

to_vector2 :: inline (v: Vector2d) -> Vector2 {
    return .{xx v.x, xx v.y};
}

to_vector2d :: inline (v: Vector2) -> Vector2d {
    return .{xx v.x, xx v.y};
}

#scope_file

// precalculated fixed point math values for sin_cos
FIXED_SHIFT : u64 : 14; // seems to maximize precision over the whole sin_cos process
FIXED_ONE : u64 : 1 << FIXED_SHIFT;
INV_FIXED_ONE :: 1.0 / FIXED_ONE.(float);
TWO_PI_FIXED : u64 : xx (PI * 2.0 * FIXED_ONE.(float));
RECIP_TWO_PI_FIXED_32 :: (1 << 32) / TWO_PI_FIXED;

#import "Math";
#import "Basic";

// MIT License
// Copyright (c) 2026 Trace Myers
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
