// basis is y forward, x right, z up

Camera_Projection :: enum {
    PERSPECTIVE;
    ORTHOGRAPHIC;
}

Camera_Info :: struct {
    projection := Camera_Projection.PERSPECTIVE;
    orthographic_scale := 1.0;
    perspective_vertical_fov := 100.0; // degrees
    aspect_ratio := 0.0; // 0 for default
    near_plane := 0.1;
    far_plane := 100_000.0;
}

get_camera_aspect_ratio :: (using camera: Camera_Info, viewport: Vector2, which := enum { X_OVER_Y; Y_OVER_X; }.X_OVER_Y) -> float {
    if which == .X_OVER_Y {
        return ifx aspect_ratio == 0.0 then viewport.x / viewport.y else aspect_ratio;
    } else {
        return ifx aspect_ratio == 0.0 then viewport.y / viewport.x else 1.0 / aspect_ratio;
    }
}

make_camera_view_matrix :: (camera_center: Vector3, camera_orientation: Quaternion) -> Matrix4 {
    // vpos = R * (p - C); (or, rotate the point's position relative to the camera)
    // rotated = R * p
    q := normalize(camera_orientation);
    inverse_orientation :=  Quaternion.{xyz=-q.xyz, w=q.w};
    view := rotation_matrix(Matrix4, inverse_orientation);
    // vpos = R * p - R * C (to translate, the -C has to be rotated as well)
    translate(*view, -camera_center);
    // swap y and z, because y is forward and row 3 (index 2) is the depth channel
    view.v[1], view.v[2] = view.v[2], view.v[1];
    return view;
}

make_camera_projection_matrix :: (using camera: Camera_Info, viewport: Vector2) -> Matrix4 {
    aspect := get_camera_aspect_ratio(camera, viewport);
    inv_plane_to_plane := 1 / (far_plane - near_plane);

    if camera.projection == .PERSPECTIVE {
        half_vertical_angle_radians := PI / 180 * perspective_vertical_fov * 0.5;
        inv_far_plane_half_height := 1 / tan(half_vertical_angle_radians);
        inv_far_plane_half_width := inv_far_plane_half_height / aspect;

        perspective := Matrix4.{
            _11 = inv_far_plane_half_width,
            _22 = inv_far_plane_half_height,
            // normalized depth = fore dist * (-1/(near far dist)) ...
            _33 = -inv_plane_to_plane,
            // ... + (1 + near dist / (near far dist))
            _34 = far_plane * inv_plane_to_plane,
            // w = z, for ndc normalization using the depth coord I think
            _43 = 1,
            _44 = 0
        };

        return perspective;
    } else { // ORTHOGRAPHIC
        half_width := orthographic_scale * aspect;
        half_height := orthographic_scale;

        orthographic := Matrix4.{
            // scale
            _11 = 1 / half_width,
            _22 = 1 / half_height,
            _33 = -inv_plane_to_plane,
            _34 = far_plane * inv_plane_to_plane, 
            _44 = 1
        };

        return orthographic;
    }
}

// breaking projection into steps and putting it on cpu for debug
transform_to_clip_coordinates :: (using camera: Camera_Info, camera_center: Vector3, camera_orientation: Quaternion, viewport: Vector2, point: Vector3) -> Vector4 {
    view_mat := make_camera_view_matrix(camera_center, camera_orientation);
    projection_mat := make_camera_projection_matrix(camera, viewport);
    view_coords := view_mat * Vector4.{xyz=point,w=1};
    clip_coords := projection_mat * view_coords;
    return clip_coords;
}

// returns the ray passing through the camera's near plane at the location of the 
// mouse cursor. origin is camera center if projection is perspective. if orthographic, the origin
// is the point on the camera plane at the mouse cursor location.
get_camera_ray_passing_through_mouse_pointer_position :: (using camera: Camera_Info, camera_center: Vector3, camera_orientation: Quaternion, viewport: Vector2, window: Window_Type) -> origin: Vector3, direction: Vector3, success: bool {
    cursor_pos_x, cursor_pos_y, success := get_mouse_pointer_position(window, false);
    if success {
        origin, direction := get_camera_ray_passing_through_window_position(camera, camera_center, camera_orientation, viewport, {xx cursor_pos_x, xx cursor_pos_y}, window);
        return origin, direction, true;
    } else {
        return {}, {}, false;
    }
}

// returns the ray passing through the camera's near plane at the given window position.
// origin is camera center if projection is perspective. if orthographic, the origin
// is the point on the camera plane at the given window position.
get_camera_ray_passing_through_window_position :: (using camera: Camera_Info, camera_center: Vector3, camera_orientation: Quaternion, viewport: Vector2, window_pos: Vector2, window: Window_Type) -> origin: Vector3, direction: Vector3 {
    norm_position := window_pos / viewport;
    norm_clip_rect_center := Vector2.{0.5,0.5};
    norm_center_diff := norm_position - norm_clip_rect_center;

    WORLD_AXIS_FORE  :: Vector3.{0, 1, 0};
    WORLD_AXIS_RIGHT :: Vector3.{1, 0, 0};
    camera_axis_fore := rotate(WORLD_AXIS_FORE, camera_orientation);
    camera_axis_right := rotate(WORLD_AXIS_RIGHT, camera_orientation);
    camera_axis_up := normalize(cross(camera_axis_right, camera_axis_fore));

    if camera.projection == .PERSPECTIVE {
        theta := (perspective_vertical_fov * 0.5) * (PI / 180.0);
        half_y_dist := near_plane * tan(theta); // tan(theta) = opp / adj
        clip_rect_height := half_y_dist * 2.0;
        clip_rect_width := get_camera_aspect_ratio(camera, viewport) * clip_rect_height;

        world_clip_rect_diff := norm_center_diff * Vector2.{clip_rect_width, clip_rect_height};

        world_clip_rect_center := camera_center + camera_axis_fore * near_plane;
        world_clip_rect_cursor_pos := world_clip_rect_center + world_clip_rect_diff.x * camera_axis_right + world_clip_rect_diff.y * camera_axis_up;
        ray_direction := normalize(world_clip_rect_cursor_pos - camera_center);

        return camera_center, ray_direction;
    } else {
        aspect := get_camera_aspect_ratio(camera, viewport);
        half_width := orthographic_scale * aspect;
        half_height := orthographic_scale;

        world_clip_rect_diff := norm_center_diff * Vector2.{2*half_width, 2*half_height};   

        origin := camera_center + world_clip_rect_diff.x * camera_axis_right + world_clip_rect_diff.y * camera_axis_up;
        return origin, camera_axis_fore;
    }
}

#scope_file

#import "Math";
#import "Window_Creation";
#import "Basic";
