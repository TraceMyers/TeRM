// basis is y forward, x right, z up
// this file is still only halfway converted from being a part of a video game into being a module, so
// it's not ready for use yet

Camera_Projection :: enum {
    PERSPECTIVE;
    ORTHOGRAPHIC;
}

Camera_Info :: struct {
    projection := Camera_Projection.PERSPECTIVE;
    orthographic_scale := 1.0;
    perspective_vertical_fov := 100.0; // degrees
    aspect_ratio := 0.0; // 0 for default
    near_plane := 1.0;
    far_plane := 10_000.0;
}

make_camera_view_matrix :: (camera_center: Vector3, camera_orientation: Quaternion) -> Matrix4 {
    UP    :: Vector3.{0,0,1};
    RIGHT :: Vector3.{1,0,0};
    FORE  :: Vector3.{0,1,0};
    return make_camera_view_matrix(
        camera_center,
        rotate(UP,    camera_orientation),
        rotate(RIGHT, camera_orientation),
        rotate(FORE,  camera_orientation)
    );
}

make_camera_view_matrix :: (camera_center: Vector3, camera_up: Vector3, camera_right: Vector3, camera_fore: Vector3) -> Matrix4 {
    // making inverse of transform that tr
    // we can get this effect by just passing the relative normalized axes of the camera
    // world (x right, y forward, z up) -> camera (x right, y forward, z up)
    rotation := make_matrix_from_rows(camera_right, camera_fore, camera_up);
    // 'moving the world' into place by removing the camera's position
    return translate(rotation, -camera_center);
}

get_camera_aspect_ratio :: (using camera: Camera_Info, viewport: Vector2, which := enum { X_OVER_Y; Y_OVER_X; }.X_OVER_Y) -> float {
    if which == .X_OVER_Y {
        return ifx aspect_ratio == 0.0 then viewport.x / viewport.y else aspect_ratio;
    } else {
        return ifx aspect_ratio == 0.0 then viewport.y / viewport.x else 1.0 / aspect_ratio;
    }
}

// for learning. just doing things in the most intuitive way for me, then moving into using matrices
transform_point_with_camera :: (using camera: Camera_Info, camera_center: Vector3, camera_orientation: Quaternion, point: Vector3) -> Vector3 {
    relative_position := point - camera_center;

    camera_view_matrix := make_camera_view_matrix(camera_center, camera_orientation);
    camera_forward     := Vector3.{camera_view_matrix._21, camera_view_matrix._22, camera_view_matrix._23};
    camera_right       := Vector3.{camera_view_matrix._11, camera_view_matrix._12, camera_view_matrix._13};
    camera_up          := Vector3.{camera_view_matrix._31, camera_view_matrix._32, camera_view_matrix._33};

    relative_distance := length(relative_position);
    relative_direction := relative_position / relative_distance;

    cos_theta_xy := dot(relative_direction.xy, camera_forward.xy);
    cos_zeta_xy  := dot(relative_direction.xy, camera_right.xy);
    cos_theta_yz := dot(relative_direction.yz, camera_forward.yz);
    cos_zeta_yz  := dot(relative_direction.yz, camera_up.yz);
    
    theta_xy := acos(cos_theta_xy);
    point_is_to_right := cos_zeta_xy > 0;
    if !point_is_to_right then theta_xy *= -1;

    theta_yz := acos(cos_theta_yz);
    point_is_above := cos_zeta_yz > 0;
    if !point_is_above then theta_yz *= -1;

    phi_yz := PI / 180 * perspective_vertical_fov * 0.5;
    phi_xy := phi_yz * aspect_ratio;

    norm_signed_distance_xy := theta_xy / phi_xy;
    norm_signed_distance_yz := theta_yz / phi_yz;

    distance_to_centerline_projection := abs(norm_signed_distance_xy) / tan(theta_xy);

    near_to_far_difference := far_plane - near_plane;
    near_to_projection_difference := distance_to_centerline_projection - near_plane;
    // using reverse depth to put more precision in the distance, near 0
    // subtraction before division to preserve precision before compressing into [0,1]
    reverse_depth := (near_to_far_projection_distance - near_to_projection_difference) / near_to_far_difference;

    return Vector3.{norm_signed_distance_xy, norm_signed_distance_yz, depth};
}

// make_camera_projection_matrix :: (using camera: Camera_Info, viewport: Vector2) -> Matrix4 {
//     aspect := get_camera_aspect_ratio(camera, viewport);
//     if camera.projection == .ORTHOGRAPHIC {
//         width := orthographic_scale * aspect;
//         height := orthographic_scale;
//         return orthographic_projection_matrix(
//             -width, width, -height, height, near_plane, far_plane, true
//         );
//     } else { // PERSPECTIVE
//         fov_radians := perspective_vertical_fov * (PI / 180.0);
//         #if PROJECTION_REVERSE_Z {
//             return make_reverse_z_projection_matrix(fov_radians, aspect, NEAR_PLANE, FAR_PLANE);
//         } else {
//             return make_projection_matrix(fov_radians, aspect, NEAR_PLANE, FAR_PLANE, 0, 0, true);
//         }
//     }
// }

// view_projection_matrix :: (camera: *Entity, viewport: Vector2) -> Matrix4 {
//     assert(is_set(*camera.flags, .USES_CAMERA));
//     view := view_matrix(camera);
//     proj := projection_matrix(camera, viewport);
//     return proj * view;
// }

// get_mouse_cursor_ray :: (camera: *Entity, viewport: Vector2) -> Ray3, success: bool {
//     assert(is_set(*camera.flags, .USES_CAMERA));
//     theta := (camera.perspective.vertical_fov * 0.5) * (PI / 180.0);
//     half_y_dist := NEAR_PLANE * tan(theta); // tan(theta) = opp / adj
//     clip_rect_height := half_y_dist * 2.0;
//     clip_rect_width := get_aspect_ratio(camera, viewport) * clip_rect_height;

//     p: Win32.POINT;
//     Win32.GetCursorPos(*p);
//     success := Win32.ScreenToClient(window, *p) != 0;
//     cursor_position: Vector2i;
//     cursor_norm_position: Vector2;
//     if success {
//         cursor_position.x = p.x;
//         cursor_position.y = p.y;
//         cursor_norm_position.x = p.x.(float) / viewport.x.(float);
//         cursor_norm_position.y = p.y.(float) / viewport.y.(float);
//     } else {
//         return .{}, false;
//     }

//     norm_clip_rect_center := Vector2.{0.5,0.5};
//     norm_center_diff := cursor_norm_position - norm_clip_rect_center;
//     world_clip_rect_diff := norm_center_diff * Vector2.{clip_rect_width, -clip_rect_height};

//     world_clip_rect_center := camera.center + camera.axes.fore * NEAR_PLANE;
//     world_clip_rect_cursor_pos := world_clip_rect_center + world_clip_rect_diff.x * camera.axes.right + world_clip_rect_diff.y * camera.axes.up;
//     cursor_raycast_dir := normalize(world_clip_rect_cursor_pos - camera.center);

//     return .{look_origin(camera), cursor_raycast_dir}, true;
// }

// copied from make_projection_matrix()
// $todo: actually probably don't need this...? I think all it actually does is assume 0-to-1 and flip z_near and z_far.
// make_reverse_z_projection_matrix :: (fov_vertical: float, aspect_ratio_horizontal_over_vertical: float, z_near: float, z_far: float, x_offset:=0.0, y_offset:=0.0) -> Matrix4 {
//     result := Matrix4_Identity;

//     tan_theta := tan(fov_vertical * 0.5);
//     cot_theta := 1 / tan_theta;

//     f := z_far;
//     n := z_near;
//     denom := 1 / (n - f);

//     result._11 = cot_theta / aspect_ratio_horizontal_over_vertical;
//     result._22 = cot_theta;
//     result._33 = n * denom;
//     result._43 = 1;
//     result._34 = (f * n) * denom;
//     result._44 = 0;

//     result._13 = x_offset; // w;
//     result._23 = y_offset; // h;

//     return result;
// }

#scope_file

#import "Math";
