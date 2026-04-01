draw_particle :: inline (renderer: *Renderer, draw: Particle_Draw) {
    billboard_instance := array_add(*renderer.particle_draws);
    billboard_instance.position      = draw.position;
    billboard_instance.scale         = {draw.scale, draw.scale};
    billboard_instance.uv_offset     = {0,0};
    billboard_instance.uv_scale      = {1,1};
    billboard_instance.tint          = to_color4f(draw.color);
    billboard_instance.texture_index = xx draw.texture_index;
}

draw_static_mesh :: inline (renderer: *Renderer, draw: Mesh_Draw) {
    mesh := *renderer.meshes[draw.ref.index];
    assert(mesh.skeleton.joints.count == 0);
    array_add(*renderer.static_mesh_draws, draw);
}

draw_static_mesh :: inline (renderer: *Renderer, ref: Mesh_Ref, position: Vector3, scale := 1.0, orientation := Quaternion.{}) {
    mesh := *renderer.meshes[ref.index];
    assert(mesh.skeleton.joints.count == 0);
    array_add(*renderer.static_mesh_draws, {position, orientation, {scale,scale,scale}, ref});
}

draw_skinned_mesh :: inline (renderer: *Renderer, draw: Mesh_Draw) {
    mesh := *renderer.meshes[draw.ref.index];
    assert(mesh.skeleton.joints.count != 0);
    array_add(*renderer.skinned_mesh_draws, draw);
}

draw_skinned_mesh :: inline (renderer: *Renderer, ref: Mesh_Ref, position: Vector3, scale := 1.0, orientation := Quaternion.{}) {
    mesh := *renderer.meshes[ref.index];
    assert(mesh.skeleton.joints.count != 0);
    array_add(*renderer.skinned_mesh_draws, {position, orientation, {scale,scale,scale}, ref});
}
