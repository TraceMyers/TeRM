
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

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
