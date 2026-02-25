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

// todo: this image transitioning is a one-size-fits-all. look into how to do it otherwise.
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

roll_submit_info :: inline (cmd: *VkCommandBufferSubmitInfo, wait_semaphore_info: *VkSemaphoreSubmitInfo, signal_semaphore_info: *VkSemaphoreSubmitInfo,) -> VkSubmitInfo2 {
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

create_gpu_buffer_for_array :: (data: []$T, usage_flags: VkBufferUsageFlags, memory_flags: VkMemoryPropertyFlags) -> GPU_Buffer {
    return create_gpu_buffer(data.count * size_of(T), usage_flags, memory_flags);
}

copy_to_gpu_buffer :: (data: *void, buffer: *GPU_Buffer, offset : s32 = 0, size : s32 = 0) {
    using context.renderer;
    assert((buffer.memory_flags & .HOST_VISIBLE_BIT) != 0);
    use_size : s32 = ifx size == 0 then cast(s32) buffer.size else size;
    p: *void;
    vkMapMemory(logical.obj, buffer.memory, xx offset, xx use_size, 0, *p);
    memcpy(p, data, use_size);
    vkUnmapMemory(logical.obj, buffer.memory);
}

create_gpu_texture_for_sampling :: (path: string) -> Texture {
    using context.renderer;
    auto_release_temp();

    width, height, channels_in_file: s32;
    desired_channels : s32 = 4;
    image_data := stbi_load(temp_c_string(path), *width, *height, *channels_in_file, desired_channels); 
    defer stbi_image_free(image_data);

    assert(channels_in_file == 4 || channels_in_file == 3, "tried to load image with channel count %", channels_in_file);
    assert(width > 0 && height > 0);

    // create staging resources (cpu visible)
    image_size     := width * height * 4;
    staging_buffer := create_gpu_buffer(image_size, .TRANSFER_SRC_BIT, .HOST_VISIBLE_BIT | .HOST_COHERENT_BIT);
    copy_to_gpu_buffer(image_data, *staging_buffer);

    // create device-local image and view
    texture        := create_gpu_texture(width, height, .TRANSFER_DST_BIT | .SAMPLED_BIT, .DEVICE_LOCAL_BIT);

    // Record copy on transfer queue
    cmd := transfer_command_buffer;
    begin_command_buffer(cmd);

    transition_image(cmd, texture.obj, .UNDEFINED, .TRANSFER_DST_OPTIMAL);
    copy_buffer_to_texture(cmd, texture, staging_buffer);

    // Transition image layout for shader usage
    transition_image(cmd, texture.obj, .TRANSFER_DST_OPTIMAL, .SHADER_READ_ONLY_OPTIMAL);

    submit_commands(cmd, transfer_fence, transfer_queue);

    view_create_info := image_view_create_info(texture.format, texture.obj, .COLOR_BIT, texture.mip_count);
    validate(vkCreateImageView(logical.obj, *view_create_info, null, *texture.image_view), "failed to create an image view for a sampled texture");

    return texture;
}

copy_buffer_to_texture :: (cmd: VkCommandBuffer, dst: Texture, src: GPU_Buffer) {
    copy_region := VkBufferImageCopy.{
        imageSubresource = {
            aspectMask = .COLOR_BIT,
            layerCount = dst.layer_count,
        },
        imageExtent = dst.extent
    };
    vkCmdCopyBufferToImage(cmd, src.obj, dst.obj, .TRANSFER_DST_OPTIMAL, 1, *copy_region);
}

create_gpu_buffer :: (size: int, usage_flags: VkBufferUsageFlags, memory_flags: VkMemoryPropertyFlags) -> GPU_Buffer {
    using context.renderer;

    buffer := GPU_Buffer.{
        size = xx size,
        usage_flags = usage_flags,
        memory_flags = memory_flags
    };

    create_info := VkBufferCreateInfo.{
        size  = buffer.size,
        usage = usage_flags,
        sharingMode = .EXCLUSIVE
    };

    allocate_gpu_buffer(*buffer, create_info, memory_flags);

    return buffer;
}

create_gpu_texture :: (width: s32, height: s32, usage_flags: VkImageUsageFlags, memory_flags: VkMemoryPropertyFlags, format := VkFormat.R8G8B8A8_UNORM, mip_count: u32 = 1, layer_count: u32 = 1) -> Texture {
    using context.renderer;

    texture := Texture.{
        extent = {xx width, xx height, 1},
        format = format,
        usage = usage_flags,
        mip_count = mip_count,
        layer_count = layer_count 
    };

    create_info := VkImageCreateInfo.{
        imageType = ._2D,
        format = texture.format,
        extent = texture.extent,
        mipLevels = mip_count,
        // here, can stack images together, (like maybe albedo, metallic, roughness, etc.)
        // maybe it's not good for that example, though since I don't think we usually mip
        // pbr-type textures?
        arrayLayers = layer_count,
        samples = ._1_BIT, // MSAA
        tiling = .OPTIMAL,
        usage = usage_flags,
        sharingMode = .EXCLUSIVE
    };

    allocate_gpu_texture(*texture, create_info, memory_flags);

    return texture;
}

allocate_gpu_texture :: (texture: *Texture, create_info: VkImageCreateInfo, memory_flags: VkMemoryPropertyFlags) {
    using context.renderer;
    memory_requirements: VkMemoryRequirements;
    vkCreateImage(logical.obj, *create_info, null, *texture.obj);
    vkGetImageMemoryRequirements(logical.obj, texture.obj, *memory_requirements);
    allocate_gpu_memory(*texture.memory, memory_flags, memory_requirements);
    vkBindImageMemory(logical.obj, texture.obj, texture.memory, 0);   
}

allocate_gpu_buffer :: (buffer: *GPU_Buffer, create_info: VkBufferCreateInfo, memory_flags: VkMemoryPropertyFlags) {
    using context.renderer;
    memory_requirements: VkMemoryRequirements;
    vkCreateBuffer(logical.obj, *create_info, null, *buffer.obj);
    vkGetBufferMemoryRequirements(logical.obj, buffer.obj, *memory_requirements);
    allocate_gpu_memory(*buffer.memory, memory_flags, memory_requirements);
    vkBindBufferMemory(logical.obj, buffer.obj, buffer.memory, 0);   
}

allocate_gpu_memory :: (memory: *VkDeviceMemory, flags: VkMemoryPropertyFlags, requirements: VkMemoryRequirements) {
    using context.renderer;
    memory_properties: VkPhysicalDeviceMemoryProperties;
    vkGetPhysicalDeviceMemoryProperties(physical.obj, *memory_properties);
    memory_type_index := find_index_of_memory_type(requirements.memoryTypeBits, flags, *memory_properties);
    allocate_info := VkMemoryAllocateInfo.{
        allocationSize = requirements.size,
        memoryTypeIndex = memory_type_index
    };
    vkAllocateMemory(logical.obj, *allocate_info, null, memory);
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

submit_commands :: (cmd: VkCommandBuffer, fence: VkFence, queue: VkQueue, wait_semaphore: *VkSemaphoreSubmitInfo = null, signal_semaphore: *VkSemaphoreSubmitInfo = null) -> bool {
    using context.renderer;

    if !validate(vkEndCommandBuffer(cmd), "failed to end a command buffer") then return false;

    cmd_submit_info := command_buffer_submit_info(cmd);
    submit_info     := roll_submit_info(*cmd_submit_info, wait_semaphore, signal_semaphore); 

    if !validate(vkQueueSubmit2(queue, 1, *submit_info, fence), "failed to submit commands to a queue") then return false;

    if !validate(vkWaitForFences(logical.obj, 1, *fence, VK_TRUE, 9_999_999), "failed to wait for a fence") then return false;

    if !validate(vkResetFences(logical.obj, 1, *fence), "failed to reset a fence") then return false;

    return true;
}

create_descriptor_pool :: (pool: *VkDescriptorPool, max_sets: u32, ratios: []Descriptor_Pool_Ratio) -> bool {
    using context.renderer;
    auto_release_temp();

    sizes := make_dynamic_array(VkDescriptorPoolSize, ratios.count,,temp);    
    descriptor_set_count : u32 = 0; 

    // all ratios can come in at whatever sum. you might think they should sum to ~1, but
    // that creates unnecessary mental overhead on the input side. the important thing is that
    // the numbers make sense in proportion to each other.
    ratio_sum := 0.0;
    for ratios {
        ratio_sum += it.ratio;
    }
    inv_ratio_sum := 1.0 / ratio_sum;

    for ratios {
        count := round(it.ratio * inv_ratio_sum * max_sets, u32);
        count = min(max_sets - descriptor_set_count, count);
        if count > 0 {
            descriptor_set_count += count;
            array_add(*sizes, {type=it.type, descriptorCount=count});
        }
    }

    create_info := VkDescriptorPoolCreateInfo.{
        maxSets = descriptor_set_count,
        poolSizeCount = xx sizes.count,
        pPoolSizes = sizes.data
    };

    return validate(vkCreateDescriptorPool(logical.obj, *create_info, null, pool), "failed creating descriptor pool");
}

// this is inflexible and probably not great going forward due to forcing the stages to be uniform
build_descriptor_set_layout :: (layout_builder: []VkDescriptorSetLayoutBinding, shader_stages: VkShaderStageFlags, p_next: *void = null, flags: VkDescriptorSetLayoutCreateFlags = 0) -> VkDescriptorSetLayout {
    using context.renderer;

    for *layout_builder {
        it.stageFlags |= shader_stages;
    }

    create_info := VkDescriptorSetLayoutCreateInfo.{
        pBindings = layout_builder.data,
        bindingCount = xx layout_builder.count,
        flags = flags,
        pNext = p_next
    };

    set: VkDescriptorSetLayout;
    validate(vkCreateDescriptorSetLayout(logical.obj, *create_info, null, *set), "failed to create a descriptor set layout");

    return set;
}

allocate_descriptor_set :: (pool: VkDescriptorPool, layout: VkDescriptorSetLayout) -> VkDescriptorSet {
    alloc_info := VkDescriptorSetAllocateInfo.{
        descriptorPool = pool,
        descriptorSetCount = 1,
        pSetLayouts = *layout
    };
    descriptor_set: VkDescriptorSet;
    validate(vkAllocateDescriptorSets(context.renderer.logical.obj, *alloc_info, *descriptor_set), "failed to allocate a descriptor set");
    return descriptor_set;
}

#scope_file

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
