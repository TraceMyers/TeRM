// a module for casting rays and hitting volumes in 3D + getting some extra data back.
// this is only meant to handle the question 'does this ray hit this volume and how?'
// it doesn't handle culling, channels, looping over entities/volumes, and it isn't opinionated
// about how your physics data should be stored, which makes it flexible for a wider 
// range of projects.

#module_parameters()(
    // 0, 1, 2 (0=none, 1=validate+log, 2=validate+assert). validation requires TeRM_Log module.
    // term logs can be customized program-wide to go to stdout, stdout + callback, or just callback.
    VALIDATION_LEVEL := 0
);


/*
raycast_rectangle :: (request: Raycast_Request, result: *Raycast_Result, rect_half_width: float, rect_half_height: float, rect_center: Vector3, rect_axis_up: Vector3, rect_axis_right: Vector3, rect_axis_fore: Vector3, caller_loc := #caller_location) -> bool {
    validate_axes(rect_axis_up, rect_axis_right, rect_axis_fore, .RECTANGLE, caller_loc);

    calculate_ray_direction_and_length(request); 
    result.* = .{};

    ray_direction_cos_t := dot(rect_axis_fore, request.ray_direction);
    aiming_for_backside := ray_direction_cos_t >= 0;

    if !aiming_for_backside || request.can_hit_back_face {
        origin_projection, projection_t := project_point_onto_plane(request.ray_origin, rect_center, rect_axis_fore);
        // the two given dot products should have a product with a negative sign if a hit is possible. to see this, build out a table of the four possible combinations of [sign of dp of normals] and [sign of projection norm dist along plane normal]
        t_mix_test := ray_direction_cos_t * projection_t;
        if t_mix_test < 0 {
            // heading is valid
            origin_projection_diff := origin_projection - request.ray_origin;
            toward_projection_scaled_cos_t := dot(origin_projection_diff, request.ray_direction);
            assert(toward_projection_scaled_cos_t > 0);

            origin_projection_dist := abs(dot(origin_projection_diff, rect_axis_fore));
            inv_cos_t := origin_projection_dist / toward_projection_scaled_cos_t;
            distance_to_intersection := origin_projection_dist * inv_cos_t; 
            if distance_to_intersection <= request.ray_length {
                // ray intersects the infinite plane
                hit_location := request.ray_origin + request.ray_direction * distance_to_intersection;
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
                        result.normal_is_inside = true;
                    }
                }
            }
        }
    }

    result.normal_is_degenerate |= !is_normalized(result.hit_normal, SMALL_NUMBER);
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

    closest_pt_from_ray_origin,_ := closest_point_on_line(request.ray_origin, line_segment_bottom, line_segment_top);
    toward_origin_diff := request.ray_origin - closest_pt_from_ray_origin;
    origin_dist_sq := length_squared(toward_origin_diff);

    // todo: make it so capsule raycasts correctly return the hit location, normal, etc..
    // todo: could still be originating inside the capsule even if not inside the radius
    if origin_dist_sq <= square(capsule_radius) {
        result.origin_inside_collider = true;
        if can_hit_back_face {
            if origin_inside_collider_rules.hit_where == .RAY_ORIGIN {
                result.is_hit = true;
                result.hit_location = request.ray_origin;
                if origin_dist_sq >= VERY_CLOSE_DISTANCE  {
                    result.hit_distance = sqrt(origin_dist_sq);
                    result.hit_normal = toward_origin_diff / result.hit_distance;
                }
            } else if can_hit_back_face {
                closest_pt_from_ray_end,_ := closest_point_on_line(request.ray_destination, line_segment_bottom, line_segment_top);
                toward_ray_end_diff := request.ray_destination - closest_pt_from_ray_end;
                ray_end_dist_sq := length_squared(toward_ray_end_diff);

                if ray_end_dist_sq >= square(capsule_radius) {
                    result.is_hit = true;
                    
                }
            }
        }
    } else {
        closest_pt_on_ray, closest_pt_on_line_segment: Vector3 = ---;
        closest_point_on_each_line_segment(request.ray_origin, request.ray_destination, line_segment_bottom, line_segment_top, *closest_pt_on_ray, *closest_pt_on_line_segment);
        distance_sq := distance_squared(closest_pt_on_ray, closest_pt_on_line_segment);
        if distance_sq <= square(body.shape.capsule.radius) {
            result.is_hit = true;
        }
    }

    result.normal_is_degenerate |= !is_normalized(result.hit_normal, SMALL_NUMBER);
    return result.is_hit;
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
*/
Internal_Volume_Type :: enum {
    PLANE;
    CIRCLE;
    CYLINDER;
    RECTANGLE;
    SPHERE;
    CAPSULE;
    BOX;
    PILLBOX;
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

validate_axes :: (axis_up: Vector3, axis_right: Vector3, axis_fore: Vector3, volume_type: Internal_Volume_Type, caller_loc: Source_Code_Location) {
    /*
    #if VALIDATION_LEVEL >= VALIDATION_LEVEL_MEDIUM {
        up_normalized, right_normalized, fore_normalized, up_and_right_orthogonal, up_and_fore_orthogonal, right_and_fore_orthogonal := true, true, true, true, true, true;

        up_fore_dot, right_fore_dot, up_right_dot: float;

        if #complete volume_type == {
        case .PLANE;
            up_normalized = is_normalized(axis_up);
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
    */
}

VALIDATION_LEVEL_NONE   :: 0;
VALIDATION_LEVEL_MEDIUM :: 1;
VALIDATION_LEVEL_HIGH   :: 2;

report_module_error :: (fmt: string, args: ..Any) #expand {
    #if VALIDATION_LEVEL >= VALIDATION_LEVEL_MEDIUM {
        if term_encode_text_allow_log() {
            trm_log(fmt=fmt, args=..args, header="TeRM/Raycast");
        }
    } else #if VALIDATION_LEVEL == VALIDATION_LEVEL_HIGH {
        if term_encode_text_allow_assert() {
            assert(false, fmt, ..args);
        }
    }
}

#import "Basic";
#import "Math";

#import "TeRM/TeRM_Log";
#import "TeRM/TeRM_Math";

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
