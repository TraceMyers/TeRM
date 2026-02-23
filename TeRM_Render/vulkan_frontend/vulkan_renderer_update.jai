
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

    // clear render target, among other things
    begin_rendering(cmd, render_target_view);

    // model - local transformations 
    // view - adding camera position/rotation/scale transformations
    // projection - closer things are larger, or in other words, all points are scaled toward
    // the camera center line, I think in a log_2 relationship with distance, or in a linear
    // relationship with the square distance

    camera: Camera_Info;

    scratch_vertices_copy := array_copy(scratch_vertices,,temp);

    camera_position := Vector3.{cos(scratch_time), sin(scratch_time), 0} * 3;
    camera_fore := normalize(-camera_position);
    camera_up := Vector3.{0,0,1};
    camera_orientation := make_quat(camera_fore, camera_up);

    // render_log("camera pos: %", camera_position);

    // todo before moving on: solve the mystery of the depth sorting issue

    for *scratch_vertices_copy {
        it.position = transform_point_with_camera(camera, camera_position, camera_orientation, {xx render_target_width, xx render_target_height}, it.position);
    }

    triangle_view: [][3]Simple_Vertex;
    triangle_view.data = xx scratch_vertices_copy.data;
    triangle_view.count = scratch_vertices_copy.count / 3;

    quick_sort(triangle_view, (a: [3]Simple_Vertex) -> float { 
        return (a[0].position.z + a[1].position.z + a[2].position.z) / 3; 
    });
    copy_into_simple_vertex_buffer(scratch_vertices_copy, *simple_vertex_buffer);

    vkCmdBindPipeline(cmd, .GRAPHICS, device_space_mesh_pipeline);
    offset: u64;
    vkCmdBindVertexBuffers(cmd, 0, 1, *simple_vertex_buffer.obj, *offset);
    vkCmdDraw(cmd, xx (simple_vertex_buffer.size / size_of(Simple_Vertex)), 1, 0, 0);

    vkCmdEndRendering(cmd);

    transition_image(cmd, render_target, .COLOR_ATTACHMENT_OPTIMAL, .PRESENT_SRC_KHR);

    if !validate(vkEndCommandBuffer(cmd), "failed to end the main command buffer") then return false;

    submit_command_info := command_buffer_submit_info(cmd);
    wait_info := semaphore_submit_info(
        VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT_KHR, 
        current_frame.image_available_semaphore
    );
    signal_info := semaphore_submit_info(
        VK_PIPELINE_STAGE_2_ALL_GRAPHICS_BIT, 
        current_frame.image_rendered_semaphore
    );
    submit_info := roll_submit_info(*submit_command_info, *signal_info, *wait_info);

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
