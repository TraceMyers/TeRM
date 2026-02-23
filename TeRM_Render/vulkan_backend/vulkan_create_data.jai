// todo: rename this file

image_create_info :: inline (format: VkFormat, usage_flags: VkImageUsageFlags, extent: VkExtent3D, mip_levels : u32 = 1, msaa_samples: VkSampleCountFlags = ._1_BIT /*1 = no msaa*/, tiling_format := VkImageTiling.OPTIMAL) -> VkImageCreateInfo {
    return VkImageCreateInfo.{
        imageType = ._2D,
        format = format,
        extent = extent,
        mipLevels = mip_levels,
        arrayLayers = 1,
        samples = msaa_samples,
        tiling = tiling_format,
        usage = usage_flags
    };
}

image_view_create_info :: inline (format: VkFormat, image: VkImage, aspect_flags: VkImageAspectFlags, mip_levels: u32 = 1) -> VkImageViewCreateInfo {
    return VkImageViewCreateInfo.{
        viewType = ._2D,
        image = image,
        format = format,
        subresourceRange = .{
            levelCount = mip_levels,
            layerCount = 1,
            aspectMask = aspect_flags
        }
    };
}

begin_command_buffer :: (frame: *Graphics_Frame) -> VkCommandBuffer, bool {
    cmd := frame.command_buffer;
    success := begin_command_buffer(cmd);
    return cmd, success;
}

begin_command_buffer :: (cmd: VkCommandBuffer) -> bool {
    if !validate(vkResetCommandBuffer(cmd, 0), "failed to reset a command buffer") then return false;
    command_buffer_begin := VkCommandBufferBeginInfo.{flags = .ONE_TIME_SUBMIT_BIT};
    if !validate(vkBeginCommandBuffer(cmd, *command_buffer_begin), "failed to begin a command buffer") then return false;
    return true;
}

acquire_next_swapchain_image :: (current_frame: *Graphics_Frame) -> u32, bool {
    using context.renderer;
    image_index: u32;
    if !validate(vkAcquireNextImageKHR(logical.obj, swapchain.obj, NANOSECONDS_PER_SECOND, current_frame.image_available_semaphore, null, *image_index), "failed to wait to get an image from the swapchain") then return 0xffff_ffff, false;
    return image_index, true;
}

transition_image :: (cmd: VkCommandBuffer, image: VkImage, old_layout: VkImageLayout, new_layout: VkImageLayout, force_aspect_mask: VkImageAspectFlags = 0) {
    image_barrier := VkImageMemoryBarrier2.{
        srcStageMask = VK_PIPELINE_STAGE_2_ALL_COMMANDS_BIT,
        srcAccessMask = VK_ACCESS_2_MEMORY_WRITE_BIT,
        dstStageMask = VK_PIPELINE_STAGE_2_ALL_COMMANDS_BIT,
        dstAccessMask = VK_ACCESS_2_MEMORY_WRITE_BIT | VK_ACCESS_2_MEMORY_READ_BIT,
        oldLayout = old_layout,
        newLayout = new_layout,
        subresourceRange = .{
            aspectMask = ifx new_layout == .DEPTH_ATTACHMENT_OPTIMAL then .DEPTH_BIT else .COLOR_BIT, 
            baseMipLevel = 0,
            levelCount = VK_REMAINING_MIP_LEVELS,
            baseArrayLayer = 0,
            layerCount = VK_REMAINING_ARRAY_LAYERS
        },
        image = image
    };

    if force_aspect_mask != 0 then {
        image_barrier.subresourceRange.aspectMask = force_aspect_mask;
    }

    dependency_info := VkDependencyInfo.{
        imageMemoryBarrierCount = 1,
        pImageMemoryBarriers = *image_barrier
    };

    vkCmdPipelineBarrier2(cmd, *dependency_info);
}

begin_rendering :: (cmd: VkCommandBuffer, render_target_view: VkImageView) {
    using context.renderer;
// random_color4f :: inline (r_bounds := Vector2.{0.2, 0.8}, g_bounds := Vector2.{0.2, 0.8}, b_bounds := Vector2.{0.2, 0.8}, a := 1.0, random_state : *Random_State = null) -> Color4f {
    color_attachment := VkRenderingAttachmentInfo.{
        // sType:              VkStructureType = .RENDERING_ATTACHMENT_INFO;
        // pNext:              *void;
        imageView = render_target_view,
        imageLayout = .COLOR_ATTACHMENT_OPTIMAL,
        // resolveMode:        VkResolveModeFlagBits;
        // resolveImageView:   VkImageView;
        // resolveImageLayout: VkImageLayout;
        loadOp = .CLEAR,
        storeOp = .STORE,
        clearValue = {color={_float32=COLOR4F_BRIGHT_PURPLE.array}}
    };

    depth_attachment := VkRenderingAttachmentInfo.{
        imageView = depth_buffer.image_view,
        imageLayout = .DEPTH_ATTACHMENT_OPTIMAL,
        loadOp = .CLEAR,
        storeOp = .STORE,
        clearValue.depthStencil = .{0, 0}
    };

    rendering_info := VkRenderingInfo.{
        // pNext:                *void;
        // flags:                VkRenderingFlags;
        renderArea = .{
            {0,0},
            {render_target_width, render_target_height},
        },
        layerCount = 1,
        // viewMask:             u32;
        colorAttachmentCount = 1,
        pColorAttachments = *color_attachment,
        pDepthAttachment = *depth_attachment,
        // pStencilAttachment:   *VkRenderingAttachmentInfo;
    };

    viewport := VkViewport.{
        x = 0,
        y = 0,
        width = xx render_target_width,
        height = xx render_target_height,
        minDepth = MIN_DEPTH,
        maxDepth = MAX_DEPTH 
    };

    scissor := VkRect2D.{
        {0,0},
        {render_target_width, render_target_height}
    };

    vkCmdSetViewport(cmd, 0, 1, *viewport);
    vkCmdSetScissor(cmd, 0, 1, *scissor);
    vkCmdBeginRendering(cmd, *rendering_info);
}

semaphore_submit_info :: inline (stage_mask: VkPipelineStageFlags2, semaphore: VkSemaphore) -> VkSemaphoreSubmitInfo {
    return .{
        semaphore = semaphore,
        stageMask = stage_mask,
        // deviceIndex = 0,
        value = 1
    };
}

command_buffer_submit_info :: inline (cmd: VkCommandBuffer) -> VkCommandBufferSubmitInfo {
    return .{
        commandBuffer = cmd,
        // deviceMask = 0
    };
}

roll_submit_info :: inline (cmd: *VkCommandBufferSubmitInfo, signal_semaphore_info: *VkSemaphoreSubmitInfo, wait_semaphore_info: *VkSemaphoreSubmitInfo) -> VkSubmitInfo2 {
    return .{
        waitSemaphoreInfoCount = ifx wait_semaphore_info == null then (0).(u32) else (1).(u32),
        pWaitSemaphoreInfos = wait_semaphore_info,
        signalSemaphoreInfoCount = ifx signal_semaphore_info == null then (0).(u32) else (1).(u32),
        pSignalSemaphoreInfos = signal_semaphore_info,
        commandBufferInfoCount = 1,
        pCommandBufferInfos = cmd
    };
}

make_vertex_descriptors :: ($T: Type, binding_index: u32 = 0) -> VkVertexInputBindingDescription, []VkVertexInputAttributeDescription {
    binding := VkVertexInputBindingDescription.{
        stride = size_of(T),
        inputRate = .VERTEX
    };

    struct_info := cast(*Type_Info_Struct)T;
    assert(struct_info.members.count > 0);

    attributes: [..]VkVertexInputAttributeDescription;
    array_reserve(*attributes, struct_info.members.count);

    for *struct_info.members {
        format := struct_member_vertex_input_binding_format(it);
        assert(format != .UNDEFINED);
        array_add(*attributes, .{
            location = xx it_index,
            binding = binding_index,
            format = format,
            offset = xx it.offset_in_bytes
        });
    }

    return binding, attributes;
}

struct_member_vertex_input_binding_format :: (info: *Type_Info_Struct_Member, depth := 0) -> VkFormat {
    assert(depth <= 1);
    format: VkFormat;
    if info.type.type == .FLOAT {
        format = ifx info.type.runtime_size == 4 then .R32_SFLOAT else .R64_SFLOAT;
    } else if info.type.type == .INTEGER {
        member_int_info := cast(*Type_Info_Integer)info.type;
        is_signed := member_int_info.signed;

        if info.type.runtime_size == {
        case 1;
            format = ifx is_signed then .R8_SINT else .R8_UINT;
        case 2;
            format = ifx is_signed then .R16_SINT else .R16_UINT;
        case 4;
            format = ifx is_signed then .R32_SINT else .R32_UINT;
        case 8;
            format = ifx is_signed then .R64_SINT else .R64_UINT;
        }
    } else if info.type.type == .STRUCT {
        assert(depth == 0);
        member_struct_info := cast(*Type_Info_Struct)info.type;
        assert(member_struct_info.members.count > 0);

        only_one_field_type := true;
        repeating_field_format: VkFormat;

        // look for placements
        unique_offsets: [..]s64;
        unique_offsets.allocator = temp;

        for *member_struct_info.members {
            find_success, _ := array_find(unique_offsets, it.offset_in_bytes);

            if find_success {
                continue;
            }

            if it.flags & .CONSTANT {
                continue;
            }

            field_format := struct_member_vertex_input_binding_format(it, depth + 1);

            // only structs with repeating fields of same type are allowed
            if repeating_field_format == .UNDEFINED {
                repeating_field_format = field_format;
            } else if repeating_field_format != field_format {
                only_one_field_type = false;
                break;
            }

            array_add(*unique_offsets, it.offset_in_bytes);
        }
        if only_one_field_type && repeating_field_format == .R32_SFLOAT {
            if unique_offsets.count == {
            case 2;
                format = .R32G32_SFLOAT;
            case 3;
                format = .R32G32B32_SFLOAT;
            case 4;
                format = .R32G32B32A32_SFLOAT;
            }
        }
    } else if info.type.type == .ARRAY {
        array_type_info := info.type.(*Type_Info_Array);
        assert(array_type_info.array_count > 0 && array_type_info.array_type == .FIXED);
        if array_type_info.element_type.type == {
        case .INTEGER;
            // $todo: rest of this
            int_element_type := array_type_info.element_type.(*Type_Info_Integer);
            assert(int_element_type.runtime_size == 2 && int_element_type.signed);
            if array_type_info.array_count == {
            case 2;
                return .R16G16_SINT;
            case 3;
                return .R16G16B16_SINT;
            case 4;
                return .R16G16B16A16_SINT;
            }
        case .FLOAT;
        }
    }
    return format;
}

create_simple_vertex_buffer :: (vertices: []Simple_Vertex) -> GPU_Buffer {
    using context.renderer;

    buffer: GPU_Buffer;
    buffer.size = xx (size_of(Simple_Vertex) * vertices.count);

    // 1) Create buffer
    buffer_create_info := VkBufferCreateInfo.{
        size  = buffer.size,
        usage = .VERTEX_BUFFER_BIT,
        sharingMode = .EXCLUSIVE
    };

    vkCreateBuffer(logical.obj, *buffer_create_info, null, *buffer.obj);

    // 2) Allocate memory (HOST_VISIBLE so we can memcpy into it)
    memory_requirements: VkMemoryRequirements;
    vkGetBufferMemoryRequirements(logical.obj, buffer.obj, *memory_requirements);

    memory_properties: VkPhysicalDeviceMemoryProperties;
    vkGetPhysicalDeviceMemoryProperties(physical.obj, *memory_properties);

    flags : VkMemoryPropertyFlags = .HOST_VISIBLE_BIT | .HOST_COHERENT_BIT;

    memory_type_index := find_index_of_memory_type(memory_requirements.memoryTypeBits, flags, *memory_properties);

    allocate_info := VkMemoryAllocateInfo.{
        allocationSize = memory_requirements.size,
        memoryTypeIndex = memory_type_index
    };

    vkAllocateMemory(logical.obj, *allocate_info, null, *buffer.memory);
    vkBindBufferMemory(logical.obj, buffer.obj, buffer.memory, 0);

    // 3) Upload data
    copy_into_simple_vertex_buffer(vertices, *buffer);

    return buffer;
}

copy_into_simple_vertex_buffer :: (vertices: []Simple_Vertex, buffer: *GPU_Buffer) {
    using context.renderer;
    p: *void;
    vkMapMemory(logical.obj, buffer.memory, 0, buffer.size, 0, *p);
    memcpy(p, vertices.data, xx buffer.size);
    vkUnmapMemory(logical.obj, buffer.memory);
}

// upload_vertices_to_host_visible_buffer :: (vertices: []Simple_Vertex, buffer: GPU_Buffer, is_host_coherent: bool) {
//     dest: *void;
//     vkMapMemory(device, mem, offsetBytes, sizeBytes, 0, &dst);
//     memcpy(dst, src, (size_t)sizeBytes);

//     if (!isHostCoherent) {
//         VkMappedMemoryRange range = {
//             .sType  = VK_STRUCTURE_TYPE_MAPPED_MEMORY_RANGE,
//             .memory = mem,
//             .offset = offsetBytes,
//             .size   = sizeBytes,
//         };
//         vkFlushMappedMemoryRanges(device, 1, &range);
//     }

//     vkUnmapMemory(device, mem);
// }

find_index_of_memory_type :: (can_use_type_bits: u32, must_have_props: VkMemoryPropertyFlags, memory_properties: *VkPhysicalDeviceMemoryProperties) -> u32 {
    for 0..memory_properties.memoryTypeCount-1 {
        type_props := memory_properties.memoryTypes[it].propertyFlags;
        type_has_props := (type_props & must_have_props) == must_have_props;
        type_can_be_used := (cast(u32) (1 << it) & can_use_type_bits) != 0;
        if type_has_props && type_can_be_used {
            return cast(u32) it;
        }
    }
    return INVALID_MEMORY_TYPE_INDEX;
}

immediate_submit_transfer_queue :: () -> bool {
    using context.renderer;
    cmd := transfer_command_buffer;

    if !validate(vkEndCommandBuffer(cmd), "failed to end the main command buffer") then return false;

    cmd_submit_info := command_buffer_submit_info(cmd);
    submit_info := roll_submit_info(*cmd_submit_info, null, null); 

    if !validate(vkQueueSubmit2(transfer_queue, 1, *submit_info, transfer_fence), "failed to submit transfer commands to the graphics queue") then return false;

    if !validate(vkWaitForFences(logical_device, 1, *transfer_fence, VK_TRUE, 99_999_999_999), "failed to wait for the transfer fence") then return false;

    if !validate(vkResetFences(logical_device, 1, *transfer_fence), "failed to reset the transfer fence") then return false;

    return true;
}

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
