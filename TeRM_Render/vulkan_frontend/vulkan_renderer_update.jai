
update_render_dimensions :: (width: u32, height: u32) {
    if render_target_width != width || render_target_height != height {
        render_target_width = width;
        render_target_height = height;
        should_recreate_swapchain = true;
    }
}

update_renderer :: (thread_local_renderer: *Renderer) -> bool {
    scope_set_renderer(thread_local_renderer);
    using context.renderer;
    auto_release_temp();

    if !is_window_open(window) || is_window_minimized(window) then return false;

    current_frame := *frames[rendered_frame_count % frames.count];

    if !validate(vkWaitForFences(logical.obj, 1, *current_frame.fence, VK_TRUE, NANOSECONDS_PER_SECOND), "timed out waiting for the render fence") then return false;

    if !validate(vkResetFences(logical.obj, 1, *current_frame.fence), "failed to reset the render fence") then return false;

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

        copy_to_gpu_buffer(*per_frame_uniform_buffer, *per_frame_uniform);
    }

    instances := make_static_array(Billboard_Instance, particle_positions.count,, temp);

    quick_sort(particle_positions, pos => -distance(pos, context.renderer.camera_position));

    for *billboard_instance : instances {
        billboard_instance.position      = particle_positions[it_index];
        billboard_instance.scale         = {20.0, 20.0};
        billboard_instance.uv_offset     = {0,0};
        billboard_instance.uv_scale      = {1,1};
        billboard_instance.tint          = COLOR4F_WHITE.rgb;
        billboard_instance.texture_index = xx light_glow_image.pool_index;
    }

    copy_to_gpu_buffer(*billboard_instance_buffer, instances);

    vkCmdBindDescriptorSets(
        cmd, .GRAPHICS, billboard_pipeline_layout, 0, 1, *textures_descriptor_set, 0, null
    );

    vkCmdBindDescriptorSets(
        cmd, .GRAPHICS, billboard_pipeline_layout, 1, 1, *per_frame_uniform_descriptor_set, 0, null
    );

    vkCmdBindDescriptorSets(
        cmd, .GRAPHICS, billboard_pipeline_layout, 2, 1, *billboard_instance_buffer_descriptor_set, 0, null
    );

    {
        vkCmdBindPipeline(cmd, .GRAPHICS, billboard_pipeline);
        heap   := *gpu_heap_pool[billboard_vertex_buffer.source_heap];
        buffer := heap.buffer;
        offset := billboard_vertex_buffer.source_heap_offset;
        offset_u64 : u64 = xx billboard_vertex_buffer.source_heap_offset;
        vkCmdBindVertexBuffers(cmd, 0, 1, *buffer, *offset_u64);
        vkCmdDraw(cmd, xx billboard_vertices.count, xx instances.count, 0, 0); 
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

    if !validate(vkQueueSubmit2(graphics_queue, 1, *submit_info, null), "failed to submit draw commands to the graphics queue") then return false;

    present_fence_info := VkSwapchainPresentFenceInfoEXT.{
        swapchainCount = 1,
        pFences=*current_frame.fence,
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
