
update_render_dimensions :: (width: u32, height: u32) {
    if render_target_width != width || render_target_height != height {
        render_target_width = width;
        render_target_height = height;
        should_recreate_swapchain = true;
    }
}

add_particle_draw :: inline (renderer: *Renderer, draw: Particle_Draw) {
    billboard_instance := array_add(*renderer.particle_draws);
    billboard_instance.position      = draw.position;
    billboard_instance.scale         = {draw.scale, draw.scale};
    billboard_instance.uv_offset     = {0,0};
    billboard_instance.uv_scale      = {1,1};
    billboard_instance.tint          = to_color4f(draw.color);
    billboard_instance.texture_index = xx draw.texture_index;
}

add_static_mesh_draw :: inline (renderer: *Renderer, draw: Static_Mesh_Draw) {
    array_add(*renderer.static_mesh_draws, draw);
}

add_static_mesh_draw :: inline (renderer: *Renderer, ref: Mesh_Ref, position: Vector3, scale := 1.0, orientation := Quaternion.{}) {
    array_add(*renderer.static_mesh_draws, {position, orientation, {scale,scale,scale}, ref});
}

update_renderer :: (thread_local_renderer: *Renderer) -> bool {
    scope_set_renderer(thread_local_renderer);
    using context.renderer;
    auto_release_temp();

    current_frame := get_current_frame();

    defer array_reset_keeping_memory(*particle_draws);
    defer array_reset_keeping_memory(*static_mesh_draws);
    defer for 0..GPU_HEAP_TYPE_COUNT-1 {
        gpu_linear_allocator_reset(*current_frame.temp_allocators[it], true);
    }

    if !is_window_open(window) || is_window_minimized(window) then return false;

    frame_fences := VkFence.[current_frame.render_fence, current_frame.present_fence];
    if !validate(vkWaitForFences(logical.obj, frame_fences.count, frame_fences.data, VK_TRUE, NANOSECONDS_PER_SECOND), "timed out waiting for frame fences") then return false;

    if !validate(vkResetFences(logical.obj, frame_fences.count, frame_fences.data), "failed to reset frame fences") then return false;

    if should_recreate_swapchain && !validate(create_swapchain_and_attachments(), "failed to recreate the swapchain when it was expected") then return false;

    swapchain_image_index, acquire_success := acquire_next_swapchain_image(current_frame);
    render_target := swapchain.images[swapchain_image_index];
    render_target_view := swapchain.image_views[swapchain_image_index];

    if render_target_width == 0 || render_target_height == 0 then return false;

    viewport := Vector2.{xx render_target_width, xx render_target_height};

    cmd := begin_command_buffer(current_frame);

    // note: UNDEFINED treats the previous data in the image as garbage, which doesn't allow
    // reading from it at this stage. probably want to change this in the future.
    transition_image(cmd, render_target, .UNDEFINED, .COLOR_ATTACHMENT_OPTIMAL);
    transition_image(cmd, depth_buffer.obj, .UNDEFINED, .DEPTH_STENCIL_ATTACHMENT_OPTIMAL);

    // clear render target, among other things
    begin_rendering(cmd, render_target_view);

    // note : frames in flight blech. will get memory tearing without buffer copies.

    per_frame_uniform: Per_Frame_Uniform_Buffer;
    {
        projection_matrix := make_camera_projection_matrix(camera_info, viewport);
        per_frame_uniform.view            = make_camera_view_matrix(camera_position, camera_orientation);
        per_frame_uniform.view_projection = projection_matrix * per_frame_uniform.view;
        per_frame_uniform.camera_position = camera_position;
        per_frame_uniform.camera_forward  = get_fore_direction(*camera_orientation);
        per_frame_uniform.camera_up       = get_up_direction(*camera_orientation);
        per_frame_uniform.camera_right    = get_right_direction(*camera_orientation);
        per_frame_uniform.time            = 0;
        per_frame_uniform.delta_time      = 1.0 / 120.0;

        copy_to_gpu_buffer(*current_frame.per_frame_uniform_buffer, *per_frame_uniform);
    }

    vkCmdBindDescriptorSets(
        cmd, .GRAPHICS, billboard_pipeline_layout, 0, 1, *textures_descriptor_set, 0, null
    );

    vkCmdBindDescriptorSets(
        cmd, .GRAPHICS, billboard_pipeline_layout, 1, 1, *materials_storage_buffer_descriptor_set, 0, null
    );

    vkCmdBindDescriptorSets(
        cmd, .GRAPHICS, billboard_pipeline_layout, 2, 1, *current_frame.per_frame_uniform_descriptor_set, 0, null
    );

    if static_mesh_draws.count > 0 {
        mesh_draw_commands := make_dynamic_array(VkDrawIndexedIndirectCommand, static_mesh_draws.count*4,, temp);

        quick_sort(static_mesh_draws, draw => draw.ref.index);

        vkCmdBindDescriptorSets(
            cmd, .GRAPHICS, opaque_mesh_pipeline_layout, 3, 1, *current_frame.mesh_instances_shader_data_descriptor_set, 0, null
        );
        vkCmdBindDescriptorSets(
            cmd, .GRAPHICS, opaque_mesh_pipeline_layout, 4, 1, *current_frame.mesh_sections_shader_data_descriptor_set, 0, null
        );

        vkCmdBindIndexBuffer(cmd, get_ibo(), 0, .UINT32);
        vbo_offset: u64;
        vbo := get_vbo();
        vkCmdBindVertexBuffers(cmd, 0, 1, *vbo, *vbo_offset);
        vkCmdBindPipeline(cmd, .GRAPHICS, opaque_mesh_pipeline);

        mesh_instances := make_static_array(Mesh_Instance_Shader_Data, static_mesh_draws.count,, temp);
        mesh_sections  := make_dynamic_array(Mesh_Section_Shader_Data, static_mesh_draws.count*4,, temp);

        instances_begin_index: int = 0;
        instances_count:       int = 1;
        instances_ref_index:   int = static_mesh_draws[0].ref.index;
        next_ref_index:        int = -1;

        instance_count_total:  s32;

        flush_draws: bool;

        for 1..static_mesh_draws.count {
            prev_draw  := *static_mesh_draws[it-1];
            prev_transform   := *mesh_instances[it-1].transform;
            prev_transform.*  = make_translation_matrix4(prev_draw.position);
            prev_transform.*  = rotate(prev_transform.*, prev_draw.orientation);
            scale := make_scale_matrix4(prev_draw.scale);
            prev_transform.* *= scale;

            if it == static_mesh_draws.count {
                flush_draws = true;
            } else {
                cur_draw := *static_mesh_draws[it];
                if instances_ref_index != cur_draw.ref.index {
                    flush_draws = true;
                    next_ref_index = cur_draw.ref.index;
                }
            }

            if flush_draws {
                assert(instances_count > 0);

                draws_of_one_mesh: []Static_Mesh_Draw;
                draws_of_one_mesh.data  = static_mesh_draws.data + instances_begin_index;
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
                        vertexOffset  = xx (section.vertices.gpu_allocation.source_heap_offset / size_of(Static_Mesh_Vertex)),
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

        copy_to_gpu_buffer(*current_frame.mesh_instances_shader_data, mesh_instances);
        copy_to_gpu_buffer(*current_frame.mesh_sections_shader_data,  mesh_sections);
        copy_to_gpu_buffer(*current_frame.opaque_mesh_draw_commands, mesh_draw_commands);

        dcbuf := *current_frame.opaque_mesh_draw_commands;
        draw_command_buffer := gpu_heap_pool[dcbuf.source_heap].buffer;

        vkCmdDrawIndexedIndirect(
            cmd,
            draw_command_buffer,
            xx dcbuf.source_heap_offset,
            cast(u32) mesh_draw_commands.count,
            size_of(VkDrawIndexedIndirectCommand)
        );
    }


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

    vkCmdEndRendering(cmd);

    // vkCmdDescriptorSets is for some reason designed s.t. you give it a pipeline layout it
    // must be compatible with.
    transition_image(cmd, render_target, .COLOR_ATTACHMENT_OPTIMAL, .PRESENT_SRC_KHR);

    if !validate(vkEndCommandBuffer(cmd), "failed to end the main command buffer") then return false;

    submit_command_info := command_buffer_submit_info(cmd);
    wait_info := semaphore_submit_info(
        VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT, 
        current_frame.image_available_semaphore
    );
    signal_info := semaphore_submit_info(
        VK_PIPELINE_STAGE_2_ALL_GRAPHICS_BIT, 
        current_frame.image_rendered_semaphore
    );
    submit_info := roll_submit_info(*submit_command_info, *wait_info, *signal_info, );

    if !validate(vkQueueSubmit2(graphics_queue, 1, *submit_info, current_frame.render_fence), "failed to submit draw commands to the graphics queue") then return false;

    present_fence_info := VkSwapchainPresentFenceInfoEXT.{
        swapchainCount = 1,
        pFences=*current_frame.present_fence,
    };

    present_info := VkPresentInfoKHR.{
        pSwapchains = *swapchain.obj,
        swapchainCount = 1,
        pWaitSemaphores = *current_frame.image_rendered_semaphore,
        waitSemaphoreCount = 1,
        pImageIndices = *swapchain_image_index,
        pNext = *present_fence_info
    };

    if !validate(vkQueuePresentKHR(graphics_queue, *present_info), "failed to present the render target") then return false;

    rendered_frame_count += 1;
    return true;
}

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
