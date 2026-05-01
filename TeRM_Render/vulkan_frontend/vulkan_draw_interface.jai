draw_particle :: inline (renderer: *Renderer, draw: Particle_Draw) {
    billboard_instance := array_add(*renderer.particle_draws);
    billboard_instance.position      = draw.position;
    billboard_instance.scale         = {draw.scale, draw.scale};
    billboard_instance.uv_offset     = {0,0};
    billboard_instance.uv_scale      = {1,1};
    billboard_instance.tint          = to_color4f(draw.color);
    billboard_instance.texture_index = xx draw.texture_index;
}

draw_static_mesh :: inline (renderer: *Renderer, draw: Static_Mesh_Draw) {
    mesh := *renderer.meshes[draw.ref.index];
    assert(mesh.skeleton.joints.count == 0);
    array_add(*renderer.static_mesh_draws, draw);
}

draw_static_mesh :: inline (renderer: *Renderer, ref: Mesh_Ref, position: Vector3, scale := 1.0, orientation := Quaternion.{}) {
    mesh := *renderer.meshes[ref.index];
    assert(mesh.skeleton.joints.count == 0);
    array_add(*renderer.static_mesh_draws, {position, orientation, {scale,scale,scale}, ref});
}

draw_static_mesh :: inline (renderer: *Renderer, ref: Mesh_Ref, position: Vector3, scale := Vector3.{1, 1, 1}, orientation := Quaternion.{}) {
    mesh := *renderer.meshes[ref.index];
    assert(mesh.skeleton.joints.count == 0);
    array_add(*renderer.static_mesh_draws, {position, orientation, scale, ref});
}

draw_skinned_mesh :: (renderer: *Renderer, draw: Skinned_Mesh_Draw) {
    mesh := *renderer.meshes[draw.ref.index];
    assert(mesh.skeleton.joints.count != 0);
    add_skinning_joints(renderer, *draw);
    array_add(*renderer.skinned_mesh_draws, draw);
}

draw_skinned_mesh :: (renderer: *Renderer, ref: Mesh_Ref, position: Vector3, pose: *Skeletal_Pose = null, scale := Vector3.{1,1,1}, orientation := Quaternion.{}) {
    mesh := *renderer.meshes[ref.index];

    assert(mesh.skeleton.joints.count != 0);

    new_draw := array_add(*renderer.skinned_mesh_draws);
    new_draw.* = {static_draw={position, orientation, scale, ref}, joint_data._interface.pose=pose};

    add_skinning_joints(renderer, new_draw);
}

draw_line :: inline (renderer: *Renderer, begin: Vector3, end: Vector3, color: Color4b, width := 1.0, draw_in_front := false) {
    if draw_in_front {
        array_add(*renderer.in_front_line_draws, {begin, end, color, width});
    } else {
        array_add(*renderer.line_draws, {begin, end, color, width});
    }
}

draw_circle :: (renderer: *Renderer, center: Vector3, radius: float32, up: Vector3, right: Vector3, color: Color4b, line_width := 1.0, segment_count := 16, draw_in_front := false) {
    assert(segment_count >= 3);

    inv_segment_count := 1.0 / cast(float) segment_count;
    radius_position := center + right * radius;
    next_radius_position: Vector3;

    for 1..segment_count {
        radians := (cast(float) it * inv_segment_count) * 2.0 * PI; 
        sin_x, cos_x := sin_cos(radians);
        next_radius_position := center + right * (radius * cos_x) + up * (radius * sin_x);

        draw_line(renderer, radius_position, next_radius_position, color, line_width, draw_in_front);
        draw_line(renderer, center, next_radius_position, color, line_width, draw_in_front);

        radius_position = next_radius_position;
    }
}

draw_circle :: inline (renderer: *Renderer, center: Vector3, radius: float32, orientation: Quaternion, color: Color4b, line_width := 1.0, segment_count := 16, draw_in_front := false) {
    up    := get_up_direction(*orientation);
    right := get_right_direction(*orientation);
    draw_circle(renderer, center, radius, up, right, color, line_width, segment_count, draw_in_front);
}

draw_cylinder :: (renderer: *Renderer, center: Vector3, radius: float32, height: float32, up: Vector3, right: Vector3, color: Color4b, line_width := 1.0, segment_count := 16, draw_in_front := false) {
    assert(segment_count >= 3);

    fore := cross(up, right);

    half_height := height * 0.5;
    inv_segment_count := 1.0 / cast(float) segment_count;
    radius_position := center + right * radius;
    next_radius_position: Vector3;

    up_center   := center + up * half_height;
    down_center := center - up * half_height;

    for 1..segment_count {
        radians := (cast(float) it * inv_segment_count) * 2.0 * PI; 
        sin_x, cos_x := sin_cos(radians);
        next_radius_position := center + right * (radius * cos_x) + fore * (radius * sin_x);

        up_offset := up * half_height;
        up_radius_position        := radius_position + up_offset;
        up_next_radius_position   := next_radius_position + up_offset;
        down_radius_position      := radius_position - up_offset;
        down_next_radius_position := next_radius_position - up_offset;

        // top circle
        draw_line(renderer, up_radius_position, up_next_radius_position, color, line_width, draw_in_front);
        draw_line(renderer, up_center, up_next_radius_position, color, line_width, draw_in_front);

        // bottom circle
        draw_line(renderer, down_radius_position, down_next_radius_position, color, line_width, draw_in_front);
        draw_line(renderer, down_center, down_next_radius_position, color, line_width, draw_in_front);

        // side
        draw_line(renderer, up_radius_position, down_radius_position, color, line_width, draw_in_front);

        radius_position = next_radius_position;
    }
}

draw_cylinder :: inline (renderer: *Renderer, center: Vector3, radius: float32, height: float32, orientation: Quaternion, color: Color4b, line_width := 1.0, segment_count := 16, draw_in_front := false) {
    up    := get_up_direction(*orientation);
    right := get_right_direction(*orientation);
    draw_cylinder(renderer, center, radius, height, up, right, color, line_width, segment_count, draw_in_front);
}

#scope_file

add_skinning_joints :: (renderer: *Renderer, draw: *Skinned_Mesh_Draw) {
    assert(draw.pose != null);
    joint_offset := renderer.skinning_joints.count;
    array_append(*renderer.skinning_joints, draw.pose.skinning_joints);
    draw.pose = null;
    draw.joint_offset = xx joint_offset;
}
