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

draw_skinned_mesh :: (renderer: *Renderer, ref: Mesh_Ref, position: Vector3, pose: *Skeletal_Pose = null, scale := 1.0, orientation := Quaternion.{}) {
    mesh := *renderer.meshes[ref.index];

    assert(mesh.skeleton.joints.count != 0);

    new_draw := array_add(*renderer.skinned_mesh_draws);
    new_draw.* = {static_draw={position, orientation, {scale,scale,scale}, ref}, joint_data._interface.pose=pose};

    add_skinning_joints(renderer, new_draw);
}

draw_line :: inline (renderer: *Renderer, begin: Vector3, end: Vector3, color: Color4b, width := 1.0) {
    array_add(*renderer.line_draws, {begin, end, color, width});
}

#scope_file

add_skinning_joints :: (renderer: *Renderer, draw: *Skinned_Mesh_Draw) {
    assert(draw.pose != null);
    joint_offset := renderer.skinning_joints.count;
    array_append(*renderer.skinning_joints, draw.pose.skinning_joints);
    draw.pose = null;
    draw.joint_offset = xx joint_offset;
}
