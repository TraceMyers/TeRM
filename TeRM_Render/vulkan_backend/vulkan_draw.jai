
draw_billboard_particles :: (cmd: VkCommandBuffer, current_frame: *Graphics_Frame) {
    using context.renderer;

    if particle_draws.count > 0 {
        quick_sort(particle_draws, draw => -distance_squared(draw.position, context.renderer.camera_position));

        copy_to_gpu_buffer(*current_frame.billboard_instance_buffer, particle_draws);
        vkCmdBindDescriptorSets(cmd, .GRAPHICS, billboard_pipeline_layout, 3, 1, *current_frame.billboard_instance_buffer_descriptor_set, 0, null);

        vkCmdBindPipeline(cmd, .GRAPHICS, billboard_pipeline);
        heap   := *gpu_heap_pool[billboard_vertex_buffer.source_heap];
        buffer := heap.buffer;
        offset := billboard_vertex_buffer.source_heap_offset;
        offset_u64 : u64 = xx billboard_vertex_buffer.source_heap_offset;
        vkCmdBindVertexBuffers(cmd, 0, 1, *buffer, *offset_u64);
        vkCmdDraw(cmd, xx billboard_vertices.count, xx particle_draws.count, 0, 0); 
    }
}

draw_meshes :: (cmd: VkCommandBuffer, current_frame: *Graphics_Frame, draws: []Mesh_Draw, $skinned_meshes := false) {
    using context.renderer;

    #if skinned_meshes {
        gpu_instances_descriptor_set := *current_frame.skinned_mesh_instances_shader_data_descriptor_set;
        gpu_sections_descriptor_set := *current_frame.skinned_mesh_sections_shader_data_descriptor_set;
        gpu_instances_shader_data := *current_frame.skinned_mesh_instances_shader_data;
        gpu_sections_shader_data := *current_frame.skinned_mesh_sections_shader_data;
        gpu_skinning_joints := *current_frame.skinning_joints_buffer;
        gpu_skinning_joints_descriptor_set := *current_frame.skinning_joints_buffer_descriptor_set;
        gpu_draw_commands := *current_frame.opaque_skinned_mesh_draw_commands;
        pipeline := opaque_skinned_mesh_pipeline;
        vbo := get_skinned_vbo();
        instance_type :: Skinned_Mesh_Instance_Shader_Data;
        vertex_type :: Skinned_Mesh_Vertex;
    } else {
        gpu_instances_descriptor_set := *current_frame.mesh_instances_shader_data_descriptor_set;
        gpu_sections_descriptor_set := *current_frame.mesh_sections_shader_data_descriptor_set;
        gpu_instances_shader_data := *current_frame.mesh_instances_shader_data;
        gpu_sections_shader_data := *current_frame.mesh_sections_shader_data;
        gpu_draw_commands := *current_frame.opaque_mesh_draw_commands;
        pipeline := opaque_mesh_pipeline;
        vbo := get_vbo();
        instance_type :: Mesh_Instance_Shader_Data;
        vertex_type :: Static_Mesh_Vertex;
    }

    if draws.count > 0 {
        mesh_draw_commands := make_dynamic_array(VkDrawIndexedIndirectCommand, draws.count*8,, temp);

        quick_sort(draws, draw => draw.ref.index);

        vkCmdBindDescriptorSets(
            cmd, .GRAPHICS, opaque_mesh_pipeline_layout, 3, 1, gpu_instances_descriptor_set, 0, null
        );
        vkCmdBindDescriptorSets(
            cmd, .GRAPHICS, opaque_mesh_pipeline_layout, 4, 1, gpu_sections_descriptor_set, 0, null
        );

        #if skinned_meshes {
            vkCmdBindDescriptorSets(cmd, .GRAPHICS, opaque_skinned_mesh_pipeline_layout, 5, 1, gpu_skinning_joints_descriptor_set, 0, null);
        }

        vkCmdBindIndexBuffer(cmd, get_ibo(), 0, .UINT32);
        vbo_offset: u64;
        vkCmdBindVertexBuffers(cmd, 0, 1, *vbo, *vbo_offset);
        vkCmdBindPipeline(cmd, .GRAPHICS, pipeline);

        mesh_instances := make_static_array(instance_type, draws.count,, temp);
        mesh_sections  := make_dynamic_array(Mesh_Section_Shader_Data, draws.count*8,, temp);
        #if skinned_meshes {
            skinning_joints := make_dynamic_array(Matrix4, draws.count*96,, temp);
        }

        instances_begin_index: int = 0;
        instances_count:       int = 1;
        instances_ref_index:   int = draws[0].ref.index;
        next_ref_index:        int = -1;

        instance_count_total:  s32;

        flush_draws: bool;

        for 1..draws.count {
            prev_draw  := *draws[it-1];

            prev_transform   := *mesh_instances[it-1].transform;
            prev_transform.*  = make_translation_matrix4(prev_draw.position);
            prev_transform.*  = rotate(prev_transform.*, prev_draw.orientation);
            scale := make_scale_matrix4(prev_draw.scale);
            prev_transform.* *= scale;

            #if skinned_meshes {
                mesh_instances[it-1].joint_offset = xx skinning_joints.count;

                mesh      := *meshes[prev_draw.ref.index];
                skeleton  := *mesh.skeleton;
                assert(skeleton.joints.count > 0);

                // todo: only calculate pose when it wants to update.
                // for that, need an animation instance type.
                pose: Skeletal_Pose;
                make_pose(*pose, skeleton, get_animation_blends(prev_draw),, temp);

                array_append(*skinning_joints, pose.skinning_joints);
            }

            if it == draws.count {
                flush_draws = true;
            } else {
                cur_draw := *draws[it];
                if instances_ref_index != cur_draw.ref.index {
                    flush_draws = true;
                    next_ref_index = cur_draw.ref.index;
                }
            }

            if flush_draws {
                assert(instances_count > 0);

                draws_of_one_mesh: []Mesh_Draw;
                draws_of_one_mesh.data  = draws.data + instances_begin_index;
                draws_of_one_mesh.count = instances_count;

                if draws_of_one_mesh.count > 1 {
                    // sort opaque instances in front-to-back order to take advantage of the depth buffer
                    quick_sort(draws_of_one_mesh, draw => distance_squared(draw.position, context.renderer.camera_position));
                }
                
                mesh := *meshes[instances_ref_index];

                for section : mesh.sections {
                    array_add(*mesh_sections, Mesh_Section_Shader_Data.{
                        cast(s32) instance_count_total, 
                        cast(s32) instances_count, 
                        cast(s32) section.material.user_data
                    });
                    array_add(*mesh_draw_commands, {
                        indexCount    = xx section.indices.count,
                        instanceCount = xx instances_count,
                        firstIndex    = xx (section.indices.gpu_allocation.source_heap_offset / size_of(u32)),
                        vertexOffset  = xx (section.vertices.gpu_allocation.source_heap_offset / size_of(vertex_type)),
                        firstInstance = 0
                    });
                }

                instance_count_total += cast(s32) instances_count;

                instances_ref_index = next_ref_index;
                instances_begin_index = it;
                instances_count = 0;
                flush_draws = false;
            }

            instances_count += 1;
        }

        copy_to_gpu_buffer(gpu_instances_shader_data, mesh_instances);
        copy_to_gpu_buffer(gpu_sections_shader_data,  mesh_sections);
        copy_to_gpu_buffer(gpu_draw_commands, mesh_draw_commands);

        #if skinned_meshes {
            copy_to_gpu_buffer(gpu_skinning_joints, skinning_joints);
        }

        draw_command_buffer := gpu_heap_pool[gpu_draw_commands.source_heap].buffer;

        vkCmdDrawIndexedIndirect(
            cmd,
            draw_command_buffer,
            xx gpu_draw_commands.source_heap_offset,
            cast(u32) mesh_draw_commands.count,
            size_of(VkDrawIndexedIndirectCommand)
        );
    }
}
