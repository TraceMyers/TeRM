Raycast_Result_Simple :: struct {
    hit_location: Vector3;
    hit_distance: float;
    is_hit: bool;
    hit_back_face: bool;
}

raycast_plane_simple :: (result: *Raycast_Result_Simple, ray_origin: Vector3, ray_direction: Vector3, point_on_plane: Vector3, plane_normal: Vector3) -> bool {
    diff_to_plane := point_on_plane - ray_origin;
    signed_distance_to_plane := dot(diff_to_plane, plane_normal);
    pointing_cos_t := dot(plane_normal, ray_direction);

    result.hit_distance = signed_distance_to_plane / pointing_cos_t;
    result.is_hit = result.hit_distance >= 0;

    if !result.is_hit {
        result.* = {};
        return false;
    } else {
        result.hit_back_face = signed_distance_to_plane > 0;
        result.hit_location = ray_origin + ray_direction * result.hit_distance;
        return true;
    }
}

raycast_circle_simple :: inline (result: *Raycast_Result_Simple, ray_origin: Vector3, ray_direction: Vector3, center: Vector3, radius: float, plane_normal: Vector3) -> bool {
    if raycast_plane_simple(result, ray_origin, ray_direction, center, plane_normal) {
        if distance_squared(center, result.hit_location) > square(radius) {
            result.* = {};
            return false;
        } 
        return true;
    }
    return false;
}

raycast_rectangle_simple :: inline (result: *Raycast_Result_Simple, ray_origin: Vector3, ray_direction: Vector3, center: Vector3, half_width: float, half_length: float, width_direction: Vector3, length_direction: Vector3, plane_normal: Vector3) -> bool {
    if raycast_plane_simple(result, ray_origin, ray_direction, center, plane_normal) {
        toward_hit_diff := result.hit_location - center;
        width_dist := dot(width_direction, toward_hit_diff);
        if width_dist > half_width {
            result.* = {};
            return false;
        }
        length_dist := dot(length_direction, toward_hit_diff);
        if length_dist > half_length {
            result.* = {};
            return false;
        }
        return true;
    } 
    return false;
}
