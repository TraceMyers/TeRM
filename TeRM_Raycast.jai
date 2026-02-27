// a module for casting rays and hitting volumes in 3D + getting some extra data back.
// this is only meant to handle the question 'does this ray hit this volume and how?'
// it doesn't handle culling, channels, looping over entities/volumes, and it isn't opinionated
// about how your physics data should be stored, which makes it flexible for a wider 
// range of projects.

#module_parameters()(
    // 0, 1, 2 (0=none, 1=validate+log, 2=validate+assert). validation requires TeRM_Log module.
    // term logs can be customized program-wide to go to stdout, stdout + callback, or just callback.
    VALIDATION_LEVEL := 0, 
    // how close is considered basically touching?
    VERY_CLOSE_DISTANCE := 0.0000005,
    // how close is pretty close?
    CLOSE_DISTANCE := 0.00001
);

Raycast_Request :: struct {
    ray_src: Vector3;
    ray_dst: Vector3;
    origin_inside_collider_rules: struct {
        // where should the hit be if the origin is inside the collider?
        hit_where: enum u8 {
            // doesn't count as a hit
            NO_HIT;
            // origin location is the hit location (can be projected to surface if that option is true)
            RAY_ORIGIN;
            // override can_hit_back_face as true in the case where the origin is inside the volume
            BACK_FACE;
        } = .NO_HIT;
        // only matters if hit_where is .RAY_ORIGIN. if false, origin is the hit location. if true, get the closest location on the surface.
        project_ray_origin_to_surface: bool;
    };
    // can hit back face regardless of whether started inside or not. useful for rectangles (or volumes with holes?)
    can_hit_back_face: bool;
    // if false, use the outward-facing normal of the hit. if true, treat the inner intersection as the true hit, so the normal is the inner normal.
    flip_back_face_hit_normal: bool;
    // these are for repeat usage, so the direction + len is only calculated once
    ray_direction: Vector3;
    ray_length: float;
    ray_direction_and_length_calculated: bool;
}

Raycast_Result :: struct {
    hit_index: s32;
    hit_distance := FLOAT32_MAX;
    hit_location: Vector3;
    hit_normal: Vector3;
    is_hit: bool;
    hit_back_face: bool;
    origin_inside_collider: bool;
    projected_origin_to_surface: bool;
    normal_is_degenerate: bool;
    normal_is_back_face: bool;
}

raycast_rectangle :: (request: Raycast_Request, result: *Raycast_Result, rect_half_width: float, rect_half_height: float, rect_center: Vector3, rect_axis_up: Vector3, rect_axis_right: Vector3, rect_axis_fore: Vector3, caller_loc := #caller_location) -> bool {
    validate_axes(rect_axis_up, rect_axis_right, rect_axis_fore, .RECTANGLE, caller_loc);

    calculate_ray_direction_and_length(request); 
    result.* = .{};

    ray_direction_cos_t := dot(rect_axis_fore, request.ray_direction);
    aiming_for_backside := ray_direction_cos_t >= 0;

    if !aiming_for_backside || request.can_hit_back_face {
        origin_projection, projection_t := project_point_onto_plane(request.ray_src, rect_center, rect_axis_fore);
        // the two given dot products should have a product with a negative sign if a hit is possible. to see this, build out a table of the four possible combinations of [sign of dp of normals] and [sign of projection norm dist along plane normal]
        t_mix_test := ray_direction_cos_t * projection_t;
        if t_mix_test < 0 {
            // heading is valid
            origin_projection_diff := origin_projection - request.ray_src;
            toward_projection_scaled_cos_t := dot(origin_projection_diff, request.ray_direction);
            assert(toward_projection_scaled_cos_t > 0);

            origin_projection_dist := abs(dot(origin_projection_diff, rect_axis_fore));
            inv_cos_t := origin_projection_dist / toward_projection_scaled_cos_t;
            distance_to_intersection := origin_projection_dist * inv_cos_t; 
            if distance_to_intersection <= request.ray_length {
                // ray intersects the infinite plane
                hit_location := request.ray_src + request.ray_direction * distance_to_intersection;
                plane_center_to_hit_diff := hit_location - rect_center;
                hit_distance_along_height_axis := abs(dot(plane_center_to_hit_diff, rect_axis_up));
                hit_distance_along_width_axis := abs(dot(plane_center_to_hit_diff, rect_axis_right));
                if hit_distance_along_height_axis <= rect_half_height && hit_distance_along_width_axis <= rect_half_width {
                    // infinite plane intersection is within the bounds of the finite plane
                    result.hit_location = hit_location;
                    result.hit_normal = rect_axis_fore;
                    result.hit_distance = distance_to_intersection;
                    result.is_hit = true;
                    result.hit_back_face = aiming_for_backside;
                    if result.hit_back_face && !request.flip_back_face_hit_normal {
                        result.hit_normal *= -1.0;
                        result.normal_is_back_face = true;
                    }
                }
            }
        }
    }

    result.normal_is_degenerate |= !is_normalized(result.hit_normal, SMALL_NUMBER);
    return result.is_hit;
}

raycast_sphere :: (request: *Raycast_Request, result: *Raycast_Result, sphere_radius: float, sphere_center: Vector3) -> bool {
    calculate_ray_direction_and_length(request); 
    result.* = .{};

    sphere_radius_sq := square(sphere_radius);

    toward_ray_origin_diff := request.ray_src - sphere_center;
    toward_ray_origin_dist_sq := length_squared(toward_ray_origin_diff);

    can_hit_back_face := raycast_can_hit_back_face(request, true);

    if toward_ray_origin_dist_sq < sphere_radius_sq {
        // origin inside volume
        result.origin_inside_collider = true;

        if request.origin_inside_collider_rules.hit_where == .RAY_ORIGIN {
            // hit is true if ray origin is inside volume (and it is)
            result.is_hit = true;

            if toward_ray_origin_dist_sq < VERY_CLOSE_DISTANCE {
                result.normal_is_degenerate = true;
            } else {
                toward_ray_origin_dist := sqrt(toward_ray_origin_dist_sq);
                result.hit_normal = toward_ray_origin_diff / toward_ray_origin_dist;
            }

            if !request.origin_inside_collider_rules.project_ray_origin_to_surface {
                result.hit_location = request.ray_src;
            } else {
                result.projected_origin_to_surface = true;
                if result.normal_is_degenerate {
                    // send back the normal used for projection, even though the true normal is degenerate
                    result.hit_normal = .{0,0,1};
                }
                result.hit_location = sphere_center + result.hit_normal * sphere_radius;
                result.hit_distance = distance(request.ray_src, result.hit_location);
            }
        } else if can_hit_back_face {
            // hit is true only if ray intersects an inside face of the volume
            ray_end_diff := request.ray_dst - sphere_center;
            ray_end_dist_sq := length_squared(ray_end_diff);
            if ray_end_dist_sq >= sphere_radius_sq {
                result.is_hit = true;
                result.hit_back_face = true;

                line_pt := closest_point_on_line(sphere_center, request.ray_src, request.ray_dst);
                line_pt_dist_sq := distance_squared(line_pt, sphere_center);

                raycast_sphere_hit_calculation(sphere_center, sphere_radius, request.ray_src, -request.ray_direction, line_pt, line_pt_dist_sq, result);

                if request.flip_back_face_hit_normal {
                    result.hit_normal *= -1;
                } else {
                    result.normal_is_back_face = true;
                }
            }
        } else { // NO_HIT
            // hit is never true when origin is inside the volume
        }
    } else {
        // if we can get the t of the projection, we can know if it's normal-forward or normal-backward
        line_pt, segment_pt: Vector3;
        closest_point_on_line_and_segment(sphere_center, request.ray_src, request.ray_dst, *line_pt, *segment_pt);
        segment_pt_dist_sq := distance_squared(segment_pt, sphere_center);
        if segment_pt_dist_sq < sphere_radius_sq {
            result.is_hit = true;
            line_pt_dist_sq := distance_squared(line_pt, sphere_center);
            raycast_sphere_hit_calculation(sphere_center, sphere_radius, request.ray_src, request.ray_direction, line_pt, line_pt_dist_sq, result);
        }
    }

    result.normal_is_degenerate |= !is_normalized(result.hit_normal);
    return result.is_hit;
}

raycast_capsule :: (request: Raycast_Request, result: *Raycast_Result, capsule_radius: float, capsule_half_height: float, capsule_center: Vector3, capsule_axis_up: Vector3, caller_loc := #caller_location) -> bool {
    validate_axes(capsule_axis_up, {}, {}, .CAPSULE, caller_loc);
    validate_capsule(capsule_radius, capsule_half_height, caller_loc);

    calculate_ray_direction_and_length(request); 
    result.* = .{};

    // a cylinder is just a line segment with a radius
    line_segment_offset := max(capsule_axis_up * (capsule_half_height - capsule_radius), 0.0);
    line_segment_bottom := capsule_center + line_segment_offset;
    line_segment_top    := capsule_center - line_segment_offset;

    can_hit_back_face := raycast_can_hit_back_face(request, true);

    closest_pt_from_ray_origin,_ := closest_point_on_line(request.ray_src, line_segment_bottom, line_segment_top);
    toward_origin_diff := request.ray_src - closest_pt_from_ray_origin;
    origin_dist_sq := length_squared(toward_origin_diff);

    // todo: make it so capsule raycasts correctly return the hit location, normal, etc..
    // todo: could still be originating inside the capsule even if not inside the radius
    if origin_dist_sq <= square(capsule_radius) {
        result.origin_inside_collider = true;
        if can_hit_back_face {
            if origin_inside_collider_rules.hit_where == .RAY_ORIGIN {
                result.is_hit = true;
                result.hit_location = request.ray_src;
                if origin_dist_sq >= VERY_CLOSE_DISTANCE  {
                    result.hit_distance = sqrt(origin_dist_sq);
                    result.hit_normal = toward_origin_diff / result.hit_distance;
                }
            } else if can_hit_back_face {
                closest_pt_from_ray_end,_ := closest_point_on_line(request.ray_dst, line_segment_bottom, line_segment_top);
                toward_ray_end_diff := request.ray_dst - closest_pt_from_ray_end;
                ray_end_dist_sq := length_squared(toward_ray_end_diff);

                if ray_end_dist_sq >= square(capsule_radius) {
                    result.is_hit = true;
                    
                }
            }
        }
    } else {
        closest_pt_on_ray, closest_pt_on_line_segment: Vector3 = ---;
        closest_point_on_each_line_segment(request.ray_src, request.ray_dst, line_segment_bottom, line_segment_top, *closest_pt_on_ray, *closest_pt_on_line_segment);
        distance_sq := distance_squared(closest_pt_on_ray, closest_pt_on_line_segment);
        if distance_sq <= square(body.shape.capsule.radius) {
            result.is_hit = true;
        }
    }

    result.normal_is_degenerate |= !is_normalized(result.hit_normal, SMALL_NUMBER);
    return result.is_hit;
}

raycast_box :: (request: Raycast_Request, result: *Raycast_Result, box_half_width: float, box_half_height: float, box_half_length: float, box_center: Vector3, box_axis_up: Vector3, box_axis_right: Vector3, box_axis_fore: Vector3, caller_loc := #caller_location) -> bool {
    validate_axes(box_axis_up, box_axis_right, box_axis_fore, .BOX, caller_loc);
    calculate_ray_direction_and_length(request); 
    result.* = .{};
    return false;
}

raycast_convex :: (request: Raycast_Request, result: *Raycast_Result) -> bool {
    calculate_ray_direction_and_length(request); 
    result.* = .{};
    return false;
}

raycast_non_convex :: (request: Raycast_Request, result: *Raycast_Result) -> bool {
    calculate_ray_direction_and_length(request); 
    result.* = .{};
    return false;
}

#scope_file

calculate_ray_direction_and_length :: inline (request: *Raycast_Result) {
    if !request.ray_direction_and_length_calculated {
        ray_diff := request.ray_dst - request.ray_src;
        ray_length_sq := length_squared(ray_diff);
        if ray_length_sq <= VERY_CLOSE_DISTANCE {
            request.ray_length = 0;
            request.ray_direction = {};
        } else {
            request.ray_length = sqrt(ray_length_sq);
            request.ray_direction = ray_diff / ray_length;
        }
        request.ray_direction_and_length_calculated = true;
    }
}

is_normalized :: (v: $Vec_Type, tolerance := CLOSE_DISTANCE) -> bool {
    return abs(length_squared(v) - 1.0) < tolerance;
}

closest_point_on_line_and_segment :: (point: Vector3, seg_beg: Vector3, seg_end: Vector3, out_point_on_line: *Vector3, out_point_on_segment: *Vector3) -> norm_dist: float {
    toward_end: Vector3 = ---;
    norm_dist := line_projection_norm_dist(*point, *seg_beg, *seg_end, *toward_end);
    out_point_on_line.* = seg_beg + toward_end * norm_dist;
    clamped_norm_dist := clamp(norm_dist, 0, 1);
    out_point_on_segment.* = seg_beg + toward_end * clamped_norm_dist;
    return norm_dist;
}

closest_point_on_line :: (point: Vector3, seg_beg: Vector3, seg_end: Vector3) -> Vector3, float {
    toward_end: Vector3 = ---;
    norm_dist := line_projection_norm_dist(*point, *seg_beg, *seg_end, *toward_end);
    return seg_beg + toward_end * norm_dist, norm_dist;
}

raycast_can_hit_back_face :: inline (using request: Raycast_Request, origin_inside_collider: bool) -> bool {
    if origin_inside_collider {
        return can_hit_back_face || origin_inside_collider_rules.hit_where == .BACK_FACE;
    } else {
        return can_hit_back_face;
    }
} 

raycast_sphere_hit_calculation :: inline (sphere_center: Vector3, sphere_radius: float, ray_origin: Vector3, ray_direction: Vector3, line_pt: Vector3, line_pt_dist_sq: float, result: *Raycast_Result) {
    projection_tri_edge_dist_sq := square(sphere_radius) - line_pt_dist_sq;
    if projection_tri_edge_dist_sq < VERY_SMALL_NUMBER {
        result.hit_location = sphere_center - ray_direction * sphere_radius;
        result.hit_normal = -ray_direction;
    } else {
        projection_tri_edge_dist := sqrt(projection_tri_edge_dist_sq);
        result.hit_location = line_pt - ray_direction * projection_tri_edge_dist;
        result.hit_normal = normalize(result.hit_location - sphere_center);
    }
    result.hit_distance = distance(ray_origin, result.hit_location);
}

Internal_Volume_Type :: enum {
    RECTANGLE;
    SPHERE;
    CAPSULE;
    BOX;
    CONVEX;
    NON_CONVEX;
}

validate_capsule :: (radius: float, half_height: float, caller_loc: string) {
    #if VALIDATION_LEVEL >= VALIDATION_LEVEL_MEDIUM {
        if radius > half_height {
            report_module_error("when doing a % raycast, a radius (%) larger than the half height (%) was observed. radius must be <= half height.", Internal_Volume_Type.CAPSULE, radius, half_height);
        }
    }
}

validate_axes :: (axis_up: Vector3, axis_right: Vector3, axis_fore: Vector3, volume_type: Internal_Volume_Type, caller_loc: string) {
    #if VALIDATION_LEVEL >= VALIDATION_LEVEL_MEDIUM {
        up_normalized, right_normalized, fore_normalized, up_and_right_orthogonal, up_and_fore_orthogonal, right_and_fore_orthogonal := true, true, true, true, true, true;

        if volume_type == {
        case .RECTANGLE; 
            #through; 
        case .BOX; 
            #through;
        case .CONVEX; 
            #through;
        case .NON_CONVEX;
            right_normalized = is_normalized(axis_right);
            fore_normalized = is_normalized(axis_fore);
            up_fore_dot = dot(axis_up, axis_fore);
            up_and_fore_orthogonal = abs(1 - up_fore_dot) < CLOSE_DISTANCE;
            right_fore_dot = dot(axis_right, axis_fore);
            right_and_fore_orthogonal = abs(1 - right_fore_dot) < CLOSE_DISTANCE;
            #through; 
        case .CAPSULE;
            up_normalized = is_normalized(axis_up);
            up_right_dot = dot(axis_up, axis_right);
            up_and_right_orthogonal = abs(1 - up_right_dot) < CLOSE_DISTANCE;
            #through;
        case .SPHERE;
        }

        any_invalid_input := !up_normalized | !right_normalized | !fore_normalized | !up_and_right_orthogonal | !up_and_fore_orthogonal | !right_and_fore_orthogonal;

        if any_invalid_input {
            report_module_error(
#string HERE
    when doing a % raycast, one of these facets of the input axes was invalid:
    up    axis normalized: %
    right axis normalized: %
    fore  axis normalized: %
    up    and right axes orthogonal: %
    up    and fore  axes orthogonal: %
    right and fore  axes orthogonal: %
    ***
    axis up    : %
    axis right : %
    axis fore  : %
    ***
    callsite: %
HERE,
                volume_type, up_normalized, right_normalized, fore_normalized, up_and_right_orthogonal, up_and_fore_orthogonal, right_and_fore_orthogonal, axis_up, axis_right, axis_fore, caller_loc
            );
        }
    }
}

#import "Math";

VALIDATION_LEVEL_NONE   :: 0;
VALIDATION_LEVEL_MEDIUM :: 1;
VALIDATION_LEVEL_HIGH   :: 2;

report_module_error :: (fmt: string, args: ..Any) #expand {
    #if VALIDATION_LEVEL >= VALIDATION_LEVEL_MEDIUM {
        #import "TeRM/Log";
        if term_encode_text_allow_log() {
            trm_log(fmt=fmt, args=..args, header="TeRM/Raycast");
        }
    } else #if VALIDATION_LEVEL == VALIDATION_LEVEL_HIGH {
        if term_encode_text_allow_assert() {
            assert(false, fmt, ..args);
        }
    }
}

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
