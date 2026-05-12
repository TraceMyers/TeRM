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

Raycast_Request :: struct {
    ray_origin: Vector3;
    ray_destination: Vector3;
    // can hit back face regardless of whether started inside or not. useful for rectangles (or volumes with holes?)
    can_hit_back_face: bool;
    // if the ray hits a back face and this is true, returns the negated/inside normal.
    return_back_face_normal: bool;
    // these are for repeat usage, so the direction + len is only calculated once
    ray_direction: Vector3;
    ray_length: float;
    ray_direction_and_length_calculated: bool;
}

Raycast_Result :: struct {
    hit_index: s32;
    ray_origin: Vector3;
    ray_destination: Vector3;
    hit_distance := FLOAT32_MAX;
    hit_location: Vector3;
    hit_normal: Vector3;
    is_hit: bool;
    hit_back_face: bool;
    origin_inside_collider: bool;
    normal_is_degenerate: bool;
    normal_is_inside: bool;
}

make_raycast_request :: inline (ray_begin: Vector3, ray_end: Vector3) -> Raycast_Request {
    return Raycast_Request.{ray_origin=ray_begin, ray_destination=ray_end};
}

// if you already have origin & direction, saves a little calculation time.
make_raycast_request :: inline (ray_origin: Vector3, ray_direction: Vector3, ray_length: float) -> Raycast_Request {
    return Raycast_Request.{
        ray_origin = ray_origin, 
        ray_destination = ray_origin + ray_direction * ray_length, 
        ray_direction = ray_direction,
        ray_length = ray_length,
        ray_direction_and_length_calculated = true
    };
}

raycast_plane :: (request: *Raycast_Request, result: *Raycast_Result, point_on_plane: Vector3, plane_normal: Vector3, caller_loc := #caller_location) -> bool {
    validate_axes(plane_normal, {}, {}, .PLANE, caller_loc);
    calculate_ray_direction_and_length(request);
    result.* = {ray_origin=request.ray_origin, ray_destination=request.ray_destination};

    diff_to_plane := point_on_plane - request.ray_origin ;
    dist_sq_to_plane := length_squared(diff_to_plane);
    signed_distance_to_plane := dot(diff_to_plane, plane_normal);

    if dist_sq_to_plane < VERY_SMALL_NUMBER {
        result.origin_inside_collider = true;
        if request.origin_inside_collider_rules.hit_where != .NO_HIT {
            result.hit_distance = 0;
            result.hit_location = request.ray_origin;
            result.hit_normal = plane_normal;
            result.is_hit = true;
            if request.origin_inside_collider_rules.hit_where == .BACK_FACE {
                result.hit_back_face = true;
                result.hit_normal = -result.hit_normal;
            }
        }
    } else  {
        pointing_cos_t := dot(-plane_normal, request.ray_direction);
        impact_dist := -signed_distance_to_plane / pointing_cos_t;

        // pointing wrong direction or too far?
        if impact_dist >= 0 && impact_dist <= request.ray_length {
            on_front_side := signed_distance_to_plane <= 0;
            on_back_side_and_can_hit_back_face := signed_distance_to_plane > 0 && request.can_hit_back_face;

            set_hit :: () #expand {
                `result.is_hit = true;
                `result.hit_distance = `impact_dist;
                `result.hit_location = `request.ray_origin + `request.ray_direction * `impact_dist;
            }

            if on_front_side {
                set_hit();
                result.hit_normal = plane_normal;
                result.hit_back_face = false;
            } else if on_back_side_and_can_hit_back_face {
                set_hit();
                if request.return_back_face_normal {
                    result.hit_normal = -plane_normal;
                    result.normal_is_inside = true;
                } else {
                    result.hit_normal = plane_normal;
                }
                result.hit_back_face = true;
            }
        }
    }

    result.normal_is_degenerate |= !is_normalized(result.hit_normal, SMALL_NUMBER);
    return result.is_hit;
}

raycast_circle :: (request: *Raycast_Request, result: *Raycast_Result, center: Vector3, radius: float, plane_normal: Vector3, caller_loc := #caller_location) -> bool {
    // initialization stuff is done in this proc call
    raycast_plane(request, result, center, plane_normal, caller_loc);
    if result.is_hit {
        center_dist_sq := distance_squared(center, result.hit_location);
        radius_sq := square(radius);
        if center_dist_sq > radius_sq {
            result.* = {};
        }
    }

    return result.is_hit;
}

raycast_cylinder :: (request: *Raycast_Request, result: *Raycast_Result, center: Vector3, radius: float, half_height: float, height_direction: Vector3, caller_loc := #caller_location) -> bool {
    validate_axes(height_direction, {}, {}, .CYLINDER, caller_loc);
    calculate_ray_direction_and_length(request);
    result.* = {ray_origin=request.ray_origin, ray_destination=request.ray_destination};

    result.origin_inside_collider = is_point_inside_cylinder(request.ray_origin, center, radius, half_height, height_direction);
    can_hit_back_face := request.can_hit_back_face & result.origin_inside_collider;

    if !result.origin_inside_collider || can_hit_back_face {
        top_center := center + half_height * height_direction;
        bot_center := center - half_height * height_direction;

        top_plane_intersection, distance_to_top_plane, hit_top_plane, hit_top_plane_back_face := get_ray_intersection_with_plane(request.ray_origin, request.ray_direction, top_center, height_direction, true);
        bot_plane_intersection, distance_to_bot_plane, hit_bot_plane, hit_bot_plane_back_face := get_ray_intersection_with_plane(request.ray_origin, request.ray_direction, bot_center, -height_direction, true);

        hit_top_plane &= distance_to_top_plane <= request.ray_length;
        hit_bot_plane &= distance_to_bot_plane <= request.ray_length;

        try_hit_circle :: inline (result: *Raycast_Result, plane_intersection: Vector3, circle_center: Vector3, radius: float, distance: float, normal: Vector3) -> bool {
            dist_sq_to_intersection := distance_squared(plane_intersection, circle_center);
            if dist_sq_to_intersection <= radius * radius {
                result.is_hit = true;
                result.hit_distance = distance;
                result.hit_location = plane_intersection;
                result.hit_normal = normal;
                return true;
            } else return false;
        }

        try_hit_back_of_circle :: inline (result: *Raycast_Result, plane_intersection: Vector3, circle_center: Vector3, radius: float, distance: float, normal: Vector3, can_hit_back_face: bool, return_back_face_normal: bool) {
            if can_hit_back_face && try_hit_circle(result, plane_intersection, circle_center, radius, distance, normal) {
                result.origin_inside_collider = true;
                result.hit_back_face = true;
                if return_back_face_normal {
                    result.hit_normal *= -1;
                    result.normal_is_inside = true;
                }
            }
        }

        if hit_top_plane && hit_bot_plane {
            if distance_to_top_plane < distance_to_bot_plane {
                try_hit_circle(result, top_plane_intersection, top_center, radius, distance_to_top_plane, height_direction);
            } else {
                try_hit_circle(result, bot_plane_intersection, bot_center, radius, distance_to_bot_plane, -height_direction);
            }
        } else if hit_top_plane {
            if hit_top_plane_back_face {
                try_hit_back_of_circle(result, top_plane_intersection, top_center, radius, distance_to_top_plane, height_direction, can_hit_back_face, request.return_back_face_normal);
            } else {
                try_hit_circle(result, top_plane_intersection, top_center, radius, distance_to_top_plane, height_direction);
            }
        } else if hit_bot_plane {
            if hit_bot_plane_back_face {
                try_hit_back_of_circle(result, bot_plane_intersection, bot_center, radius, distance_to_bot_plane, -height_direction, can_hit_back_face, request.return_back_face_normal);
            } else {
                try_hit_circle(result, bot_plane_intersection, bot_center, radius, distance_to_bot_plane, -height_direction);
            }
        }

        // if already hit, then it hit the top or bottom
        if !result.is_hit {
            // analytic ray-cylinder side intersection: project the ray and origin offset onto the
            // plane perpendicular to the axis, then solve |X_perp + t*D_perp|^2 = r^2 for t.
            X_perp := (request.ray_origin - center) - dot(request.ray_origin - center, height_direction) * height_direction;
            D_perp := request.ray_direction - dot(request.ray_direction, height_direction) * height_direction;

            a := dot(D_perp, D_perp);
            b := 2.0 * dot(X_perp, D_perp);
            c := dot(X_perp, X_perp) - radius * radius;

            // a is sin^2(angle between ray and axis); near zero means ray is parallel to the axis,
            // in which case the side cannot be entered (caps are handled above).
            if a > VERY_SMALL_NUMBER {
                discriminant := b * b - 4.0 * a * c;
                if discriminant >= 0 {
                    sqrt_disc := sqrt(discriminant);

                    // citardauq form: pick the addition that doesn't cancel, derive the other root via Vieta's.
                    q      := -0.5 * (b + (ifx b >= 0 then sqrt_disc else -sqrt_disc));
                    t1     := q / a;
                    t2     := ifx q != 0 then c / q else t1;
                    t_near := min(t1, t2);
                    t_far  := max(t1, t2);

                    try_register_side_hit :: (result: *Raycast_Result, request: *Raycast_Request, t: float, center: Vector3, axis: Vector3, half_height: float, radius: float, is_back_face: bool) -> bool {
                        if t < 0 || t > request.ray_length return false;
                        hit_location := request.ray_origin + request.ray_direction * t;
                        height_offset := dot(hit_location - center, axis);
                        if abs(height_offset) > half_height return false;

                        axis_point := center + height_offset * axis;
                        normal := (hit_location - axis_point) / radius;

                        result.is_hit = true;
                        result.hit_distance = t;
                        result.hit_location = hit_location;
                        if is_back_face {
                            result.hit_back_face = true;
                            if request.return_back_face_normal {
                                result.hit_normal = -normal;
                                result.normal_is_inside = true;
                            } else {
                                result.hit_normal = normal;
                            }
                        } else {
                            result.hit_normal = normal;
                        }
                        return true;
                    }

                    if !try_register_side_hit(result, request, t_near, center, height_direction, half_height, radius, false) {
                        if can_hit_back_face {
                            try_register_side_hit(result, request, t_far, center, height_direction, half_height, radius, true);
                        }
                    }
                }
            }
        }
    }

    result.normal_is_degenerate |= !is_normalized(result.hit_normal);
    return result.is_hit;
}

raycast_box :: (request: *Raycast_Request, result: *Raycast_Result, center: Vector3, half_width: float, half_length: float, half_height: float, width_direction: Vector3, length_direction: Vector3, height_direction: Vector3, caller_loc := #caller_location) -> bool {
    // ------

    Dist_And_Norm :: struct {
        dist: float;
        normal: Vector3;
    }

    first_dist_is_lesser :: (a: Dist_And_Norm, b: Dist_And_Norm) -> bool {
        return a.dist < b.dist;
    }

    get_slab_intersection_distances :: (face_center: Vector3, face_normal: Vector3, extent: float, inv_cos_t: float) -> Dist_And_Norm, Dist_And_Norm #expand {
        diff_to_plane := face_center - `request.ray_origin;
        signed_distance_to_plane := dot(diff_to_plane, face_normal);

        intersection_a_dist := signed_distance_to_plane * inv_cos_t;
        _isnan, _isinf := is_nan_is_inf(intersection_a_dist);
        if _isinf {
            return {-1, face_normal}, {request.ray_length+1, -face_normal};
        }
        // scaling 2 * extent by cos(t) gives distance along the ray across
        // the solid, since the two faces share the same normal.
        intersection_b_dist := intersection_a_dist + (2 * extent) * -inv_cos_t;

        return {intersection_a_dist, face_normal}, {intersection_b_dist, -face_normal};
    }

    // ------

    validate_axes(height_direction, width_direction, length_direction, .BOX, caller_loc);
    calculate_ray_direction_and_length(request);
    result.* = {ray_origin=request.ray_origin, ray_destination=request.ray_destination};

    result.origin_inside_collider = is_point_inside_box(request.ray_origin, center, {half_width, half_length, half_height}, width_direction, length_direction, height_direction);

    box_right_center := center + (half_width  * width_direction);
    box_left_center  := center - (half_width  * width_direction);
    box_front_center := center + (half_length * length_direction);
    box_rear_center  := center - (half_length * length_direction);
    box_top_center   := center + (half_height * height_direction);
    box_bot_center   := center - (half_height * height_direction);

    inv_width_cos_t  := 1.0 / dot(width_direction,  request.ray_direction);
    inv_length_cos_t := 1.0 / dot(length_direction, request.ray_direction);
    inv_height_cos_t := 1.0 / dot(height_direction, request.ray_direction);

    can_hit_back_face := request.can_hit_back_face & result.origin_inside_collider;

    if !result.origin_inside_collider || can_hit_back_face {
        right_intersection_dist, left_intersection_dist := get_slab_intersection_distances(box_right_center, width_direction, half_width, inv_width_cos_t);
        front_intersection_dist, rear_intersection_dist := get_slab_intersection_distances(box_front_center, length_direction, half_length, inv_length_cos_t);
        top_intersection_dist, bot_intersection_dist := get_slab_intersection_distances(box_top_center, height_direction, half_height, inv_height_cos_t);

        width_min_idist, width_max_idist   := min_and_max(right_intersection_dist, left_intersection_dist, first_dist_is_lesser);
        length_min_idist, length_max_idist := min_and_max(front_intersection_dist, rear_intersection_dist, first_dist_is_lesser);
        height_min_idist, height_max_idist := min_and_max(top_intersection_dist, bot_intersection_dist, first_dist_is_lesser);

        min_idist := max(width_min_idist, max(length_min_idist, height_min_idist, first_dist_is_lesser), first_dist_is_lesser);
        // may end up with inf here, which is fine, since all real values
        // give x < inf -> true.
        max_idist := min(width_max_idist, min(length_max_idist, height_max_idist, first_dist_is_lesser), first_dist_is_lesser);

        if !result.origin_inside_collider {
            if min_idist.dist <= request.ray_length && min_idist.dist < max_idist.dist && max_idist.dist > 0 {
                result.is_hit = true;
                result.hit_location = request.ray_origin + min_idist.dist * request.ray_direction;
                result.hit_distance = min_idist.dist;
                result.hit_normal = min_idist.normal;
            }
        } else {
            if max_idist.dist <= request.ray_length && max_idist.dist > min_idist.dist && min_idist.dist < 0 {
                result.is_hit = true;
                result.hit_back_face = true;
                result.hit_location = request.ray_origin + max_idist.dist * request.ray_direction;
                result.hit_distance = max_idist.dist;
                if request.return_back_face_normal {
                    result.hit_normal = -max_idist.normal;
                    result.normal_is_inside = true;
                } else {
                    result.hit_normal = max_idist.normal;
                }
            }
        }
    }

    result.normal_is_degenerate |= !is_normalized(result.hit_normal);
    return result.is_hit;
}

// a pillbox is: start with an upright capsule and take a cross section of it, such that 
// it's a standing, thin sheet of paper with a sillhouette like a nascar race track
// with a half-circle at the top and bottom. lie the sheet flat on the ground and 
// extrude it vertically, giving the sheet depth, which becomes the height of the volume.
//
// from above:              from side:
//
//    |  length |                  |  length  | <-- half_box_length excudes radius
//    ___________                 ______________
//   /           \               | `          ` | | height
//  |          ,--| radius       | `          ` | |
//   \_________|_/               |_`__________`_| |
//            radius
//
// half_box_length is not half the length of the pillbox, but rather the length
// of the inner box. this is because if it did include the radius of the two end circles,
// you would have to obey the rule length >= radius, compared to the much simpler
// length >= 0 (and half_box_length >= 0). note also that half_width = radius.
raycast_pillbox :: (request: *Raycast_Request, result: *Raycast_Result, center: Vector3, radius: float, half_box_length: float, half_height: float, width_direction: Vector3, length_direction: Vector3, height_direction: Vector3, caller_loc := #caller_location) -> bool {
    starting_inside_box := is_point_inside_box(request.ray_origin, center, {radius, half_box_length, half_height}, width_direction, length_direction, height_direction);
    starting_inside_front_cylinder := is_point_inside_cylinder(request.ray_origin, center + length_direction * half_box_length, radius, half_height, height_direction);
    starting_inside_rear_cylinder := is_point_inside_cylinder(request.ray_origin, center - length_direction * half_box_length, radius, half_height, height_direction);

    result.origin_inside_collider = starting_inside_box || starting_inside_front_cylinder || starting_inside_rear_cylinder;

    result.* = {ray_origin=request.ray_origin, ray_destination=request.ray_destination};

    box_result: Raycast_Result;
    // raycast to the oriented box that contains the pillbox. if it hits the 
    // box-part of the pillbox, just return. if it hits an endcap occupied by
    // a half-cylinder, try raycasting to that cylinder.
    if raycast_box(request, *box_result, center, radius, half_box_length + radius, half_height, width_direction, length_direction, height_direction, caller_loc) {
        center_diff := box_result.hit_location - center;
        length_distance := dot(center_diff, length_direction);

        if abs(length_distance) > half_box_length {
            cylinder_center: Vector3 = ---;
            if length_distance > 0 {
                cylinder_center = center + length_direction * half_box_length;
            } else {
                cylinder_center = center - length_direction * half_box_length;
            }

            NUDGE_DISTANCE :: 0.0001;
            dummy_request := request.*;

            // wherever on the containing box the ray hit, we want to 
            // create a new ray starting just outside the containing box,
            // moving along the ray's line, toward the volume. only attempting
            // to contact the outsides of the cylinder sidesteps the complex
            // situation where you're trying to raycast to the inner surface of a thing
            // which has multiple implicit cylinder surfaces *inside* it. basically,
            // if you try to raycast from inside, there is a 50% chance you will
            // hit an implied inner surface... which is bad.
            if box_result.origin_inside_collider {
                dummy_request.ray_origin = box_result.hit_location + request.ray_direction * NUDGE_DISTANCE;
                dummy_request.ray_direction = -request.ray_direction;
            } else {
                dummy_request.ray_origin = box_result.hit_location - request.ray_direction * NUDGE_DISTANCE;
                dummy_request.ray_direction = request.ray_direction;
            }

            cylinder_result: Raycast_Result;
            if raycast_cylinder(*dummy_request, *cylinder_result, cylinder_center, radius, half_height, height_direction, caller_loc) {
                diff_to_hit := cylinder_result.hit_location - request.ray_origin;
                distance_along_ray := dot(diff_to_hit, request.ray_direction);

                hit_within_range := distance_along_ray >= 0 && distance_along_ray <= request.ray_length;
                allowed_to_hit := !result.origin_inside_collider || request.can_hit_back_face;

                if hit_within_range && allowed_to_hit {
                    result.is_hit = true;
                    result.hit_location = cylinder_result.hit_location;
                    result.hit_distance = distance_along_ray;
                    result.hit_normal   = cylinder_result.hit_normal;
                    if result.origin_inside_collider {
                        result.hit_back_face = true;
                        if request.return_back_face_normal {
                            result.hit_normal *= -1;
                            result.normal_is_inside = true;
                        }
                    }
                }
            }
        } else {
            result.* = box_result;
        }
    }

    result.normal_is_degenerate |= !is_normalized(result.hit_normal);
    return result.is_hit;
}

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

raycast_sphere :: (request: *Raycast_Request, result: *Raycast_Result, sphere_radius: float, sphere_center: Vector3) -> bool {
    calculate_ray_direction_and_length(request); 
    result.* = .{};

    sphere_radius_sq := square(sphere_radius);

    toward_ray_origin_diff := request.ray_origin - sphere_center;
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
                result.hit_location = request.ray_origin;
            } else {
                result.projected_origin_to_surface = true;
                if result.normal_is_degenerate {
                    // send back the normal used for projection, even though the true normal is degenerate
                    result.hit_normal = .{0,0,1};
                }
                result.hit_location = sphere_center + result.hit_normal * sphere_radius;
                result.hit_distance = distance(request.ray_origin, result.hit_location);
            }
        } else if can_hit_back_face {
            // hit is true only if ray intersects an inside face of the volume
            ray_end_diff := request.ray_destination - sphere_center;
            ray_end_dist_sq := length_squared(ray_end_diff);
            if ray_end_dist_sq >= sphere_radius_sq {
                result.is_hit = true;
                result.hit_back_face = true;

                line_pt := closest_point_on_line(sphere_center, request.ray_origin, request.ray_destination);
                line_pt_dist_sq := distance_squared(line_pt, sphere_center);

                raycast_sphere_hit_calculation(sphere_center, sphere_radius, request.ray_origin, -request.ray_direction, line_pt, line_pt_dist_sq, result);

                if request.flip_back_face_hit_normal {
                    result.hit_normal *= -1;
                } else {
                    result.normal_is_inside = true;
                }
            }
        } else { // NO_HIT
            // hit is never true when origin is inside the volume
        }
    } else {
        // if we can get the t of the projection, we can know if it's normal-forward or normal-backward
        line_pt, segment_pt: Vector3;
        closest_point_on_line_and_segment(sphere_center, request.ray_origin, request.ray_destination, *line_pt, *segment_pt);
        segment_pt_dist_sq := distance_squared(segment_pt, sphere_center);
        if segment_pt_dist_sq < sphere_radius_sq {
            result.is_hit = true;
            line_pt_dist_sq := distance_squared(line_pt, sphere_center);
            raycast_sphere_hit_calculation(sphere_center, sphere_radius, request.ray_origin, request.ray_direction, line_pt, line_pt_dist_sq, result);
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

#scope_file

calculate_ray_direction_and_length :: inline (request: *Raycast_Request) {
    if !request.ray_direction_and_length_calculated {
        ray_diff := request.ray_destination - request.ray_origin;
        ray_length_sq := length_squared(ray_diff);
        if ray_length_sq <= VERY_SMALL_NUMBER {
            request.ray_length = 0;
            request.ray_direction = {};
        } else {
            request.ray_length = sqrt(ray_length_sq);
            request.ray_direction = ray_diff / request.ray_length;
        }
        request.ray_direction_and_length_calculated = true;
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
