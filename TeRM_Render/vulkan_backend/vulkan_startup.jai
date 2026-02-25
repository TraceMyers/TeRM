
// --- sections ---
// vk instance
// surface
// physical device
// logical device
// frame data
// descriptors
// scratch

// -----------------------------------------------------------------------------------
// ---------------------------------------------------------------------- :vk instance

create_vk_instance :: () -> bool {
    using context.renderer;
    auto_release_temp();

    if !validate(instance_extensions_are_supported(required_instance_extensions), "required instance extensions unsupported") then return false;
    
    if !validate(instance_layers_are_supported(required_layers), "required instance layers unsupported") then return false;

    app_info := VkApplicationInfo .{
        pApplicationName    = temp_c_string(application_name),
        applicationVersion  = application_version,
        pEngineName         = temp_c_string(engine_name),
        engineVersion       = engine_version,
        apiVersion          = API_VERSION
    };
    create_info := VkInstanceCreateInfo.{
        pApplicationInfo = *app_info,
        enabledLayerCount = xx required_layers.count,
        ppEnabledLayerNames = required_layers.data,
        enabledExtensionCount = xx required_instance_extensions.count,
        ppEnabledExtensionNames = required_instance_extensions.data
    };

    if !validate(vkCreateInstance(*create_info, null, *vk_instance), "failed to create vulkan instance") then return false;

    render_log("created vk instance");
    return true;
}

instance_extensions_are_supported :: (extensions: []*u8) -> bool {
    auto_release_temp();

    available_extensions, result := vkEnumerateInstanceExtensionProperties(null,,temp);
    if !validate(result, "failed to enumerate instance extension properties") then return false;

    for need_ext : extensions {
        ext_found: bool;
        for have_ext : available_extensions {
            max_read_ct := have_ext.extensionName.count;
            if c_strings_equal(need_ext, have_ext.extensionName.data, max_read_ct) {
                ext_found = true;
                break;
            }
        }
        if !ext_found {
            return false;
        }
    }

    return true;
}

instance_layers_are_supported :: (layers: []*u8) -> bool {
    auto_release_temp();
    
    available_layers, result := vkEnumerateInstanceLayerProperties(,,temp);
    if !validate(result, "failed to enumerate instance instance layer properties") then return false;

    for need_layer : layers {
        layer_found: bool;
        for have_layer : available_layers {
            max_read_ct := have_layer.layerName.count;
            if c_strings_equal(need_layer, have_layer.layerName.data, max_read_ct) {
                layer_found = true;
                break;
            }
        }
        if !layer_found {
            render_log("unable to find layer % in available layers", to_string(need_layer));
            return false;
        }
    }

    return true;
}

// -----------------------------------------------------------------------------------
// -------------------------------------------------------------------------- :surface

create_surface :: () -> bool {
    using context.renderer;

    #if OS == .WINDOWS {
        create_info := VkWin32SurfaceCreateInfoKHR.{
            hwnd = window,
            hinstance = Win32.GetModuleHandleW(null)
        };
        if !validate(vkCreateWin32SurfaceKHR(vk_instance, *create_info, null, *surface), "failed to create surface") then return false;
    } else {
        return false;
    }

    render_log("created surface from window");
    return true;
}

// -----------------------------------------------------------------------------------
// ------------------------------------------------------------------ :physical device

select_physical_device :: () -> bool {
    using context.renderer;
    auto_release_temp();

    devices, result := vkEnumeratePhysicalDevices(vk_instance,,temp);
    if !validate(result, "failed to enumerate physical devices") then return false;
    if !validate(devices.count > 0, "no physical devices found on the system") then return false;

    best_score: s32;
    best_scored_device: VkPhysicalDevice;

    for devices {
        device_score := score_physical_device(it);
        if device_score > best_score {
            best_score = device_score;
            best_scored_device = it;
        }
    }

    if !validate(best_scored_device != null, "unable to find a suitable physical device") then return false;

    context.renderer.physical.obj = best_scored_device;
    if !validate(determine_physical_device_queue_family_capabilities(*context.renderer.physical), "unable to set selected physical device queue family properties") then return false;

    set_physical_device_properties(*physical);
    {
        using physical.properties;
        render_log(
#string HERE
found suitable physical device...

    api version     %
    driver version  %
    vendor          %
    device id       0x%
    device type     %
    device name     %
HERE,
            make_string(get_graphics_api_version(context.renderer),,temp),
            make_string(get_physical_device_driver_version(context.renderer),,temp),
            get_physical_device_vendor(context.renderer),
            FormatInt.{value=device_id, base=16, minimum_digits=4},
            device_type,
            device_name
        );
    }

    return true;
}

set_physical_device_properties :: (physical: *Physical_Device) {
    using physical;
    temp_properties: VkPhysicalDeviceProperties;
    vkGetPhysicalDeviceProperties(obj, *temp_properties);
    properties.api_version = temp_properties.apiVersion;
    properties.driver_version = temp_properties.driverVersion;
    properties.vendor_id = temp_properties.vendorID;
    properties.device_id = temp_properties.deviceID;
    properties.device_type = temp_properties.deviceType;
    memcpy(properties.device_name_buffer.data, temp_properties.deviceName.data, min(properties.device_name_buffer.count, temp_properties.deviceName.count));
    properties.device_name = to_string_safe(properties.device_name_buffer.data, properties.device_name_buffer.count);
}

score_physical_device :: (device: VkPhysicalDevice) -> score: s32 {
    properties: VkPhysicalDeviceProperties;
    features: VkPhysicalDeviceFeatures;
    vkGetPhysicalDeviceProperties(device, *properties);
    vkGetPhysicalDeviceFeatures(device, *features);

    dummy_device := Physical_Device.{obj=device};
    if !determine_physical_device_queue_family_capabilities(*dummy_device) {
        return 0;
    }
    if depth_buffer_format(device) == .UNDEFINED {
        return 0;
    }
    if dummy_device.queue_family_indices.graphics_index == -1 
    || dummy_device.queue_family_indices.present_index == -1 {
        return 0;
    }
    if !device_extensions_are_supported(device, required_device_extensions) {
        return 0;
    }
    info: Swapchain_Support_Info;
    if !get_swapchain_support_info(device, *info,, temp) {
        return 0;
    }
    if info.present_modes.count == 0 || info.formats.count == 0 {
        return 0;
    }

    score : s32 = ifx properties.deviceType == .DISCRETE_GPU then (100).(s32) else (1).(s32);
    score += cast(s32) properties.limits.maxImageDimension2D;
    render_log("max image dimension: %", properties.limits.maxImageDimension2D);
    if dummy_device.queue_family_indices.graphics_index == dummy_device.queue_family_indices.present_index 
        then score += 50;
    return score;
}

determine_physical_device_queue_family_capabilities :: (physical: *Physical_Device) -> bool {
    physical.queue_family_indices = .{};

    queue_family_properties := vkGetPhysicalDeviceQueueFamilyProperties(physical.obj,,temp);
    if !validate(queue_family_properties.count > 0, "physical device queue family properties count is 0") then return false;

    GRAPHICS_AND_COMPUTE : VkQueueFlagBits : (.GRAPHICS_BIT | .COMPUTE_BIT);

    for family : queue_family_properties {
        using physical.queue_family_indices;

        present_support: VkBool32;
        vkGetPhysicalDeviceSurfaceSupportKHR(physical.obj, xx it_index, context.renderer.surface, *present_support);

        // just try to get them all on the same queue for now. maybe forever?
        if present_support {
            if (family.queueFlags & GRAPHICS_AND_COMPUTE) == GRAPHICS_AND_COMPUTE {
                present_index  = xx it_index;
                graphics_index = xx it_index;
                compute_index  = xx it_index;
            } else if present_index == -1 {
                present_index = xx it_index;
            } 
        }
        if family.queueFlags & .GRAPHICS_BIT && graphics_index == -1 {
            graphics_index = xx it_index;
        }
        if family.queueFlags & .COMPUTE_BIT && compute_index == -1 {
            compute_index = xx it_index;
        }
        if family.queueFlags & .TRANSFER_BIT {
            if transfer_index == -1 || family.queueFlags & (.GRAPHICS_BIT | .COMPUTE_BIT) == 0 {
                transfer_index = xx it_index;
            }
        }
    }
    return true;
}

device_extensions_are_supported :: (phys: VkPhysicalDevice, extensions: []*u8) -> bool {
    auto_release_temp();

    available_extensions, result := vkEnumerateDeviceExtensionProperties(phys, null,,temp);
    if !validate(result, "unable to enumerate physical device extension properties") then return false;

    for need_ext : extensions {
        ext_found: bool;
        for have_ext : available_extensions {
            max_read_ct := have_ext.extensionName.count;
            if c_strings_equal(need_ext, have_ext.extensionName.data, max_read_ct) {
                ext_found = true;
                break;
            }
        }
        if !ext_found {
            return false;
        }
    }
    return true;
}

// -----------------------------------------------------------------------------------
// ------------------------------------------------------------------- :logical device

create_logical_device :: () -> bool {
    using context.renderer;
    auto_release_temp();

    queue_priority : float32 = 1.0;
    unique_queue_family_indices := get_unique_queue_family_indices(*physical);
    queue_create_infos := make_dynamic_array(VkDeviceQueueCreateInfo, 4,, temp);

    for unique_queue_family_indices {
        array_add(*queue_create_infos, {
            queueFamilyIndex = it,
            queueCount = 1,
            pQueuePriorities = *queue_priority,
        });
    }

    enable_device_features := VkPhysicalDeviceFeatures.{
        fillModeNonSolid = VK_TRUE,
        wideLines = VK_TRUE,
    };

    // smooths over a bunch of unnecessary boilerplate in creating graphics pipeline-related stuff
    dynamic_rendering_enable := VkPhysicalDeviceDynamicRenderingFeatures.{
        dynamicRendering = VK_TRUE,
    };

    // enables syncing a fence on present
    maintenance1_enable := VkPhysicalDeviceSwapchainMaintenance1FeaturesEXT.{
        swapchainMaintenance1 = VK_TRUE,
        pNext = *dynamic_rendering_enable,
    };

    sync_feature_enable := VkPhysicalDeviceSynchronization2Features.{
        synchronization2 = VK_TRUE,
        pNext = *maintenance1_enable
    };

    device_create_info := VkDeviceCreateInfo.{
        pQueueCreateInfos = queue_create_infos.data,
        queueCreateInfoCount = xx queue_create_infos.count,
        pEnabledFeatures = *enable_device_features,
        enabledLayerCount = xx required_layers.count,
        ppEnabledLayerNames = xx required_layers.data,
        enabledExtensionCount = xx required_device_extensions.count,
        ppEnabledExtensionNames = required_device_extensions.data,
        pNext = *sync_feature_enable
    };

    result := vkCreateDevice(physical.obj, *device_create_info, null, *logical.obj);
    if !validate(result, "failed to create the logical device") return false;

    vkGetDeviceQueue(logical.obj, xx physical.queue_family_indices.graphics_index, 0, *graphics_queue);
    vkGetDeviceQueue(logical.obj, xx physical.queue_family_indices.transfer_index, 0, *transfer_queue);

    render_log("created logical device");
    return true;
}

get_unique_queue_family_indices :: (physical: *Physical_Device) -> []u32 {
    already_made_queue: Queue_Family_Capability_Flags;
    unique_indices := make_dynamic_array(u32, 4,, temp);
    for 0..physical.queue_family_indices.array.count-1 {
        flag := (1 << physical.queue_family_indices.array[it]).(Queue_Family_Capability_Flags);
        if (already_made_queue & flag) != 0 {
            continue;
        }
        array_add(*unique_indices, xx physical.queue_family_indices.array[it]);
        already_made_queue |= flag;
    }
    return unique_indices;
}

// -----------------------------------------------------------------------------------
// ----------------------------------------------------------------------- :frame data

create_frame_datas :: () -> bool {
    using context.renderer;
    auto_release_temp();

    assert(frames.data == null);
    frames = make_static_array(Graphics_Frame, min(swapchain.images.count, 2));

    command_pool_info := VkCommandPoolCreateInfo.{
        flags = .RESET_COMMAND_BUFFER_BIT,
        queueFamilyIndex = xx physical.queue_family_indices.graphics_index
    };

    fence_info := VkFenceCreateInfo.{
        flags = .SIGNALED_BIT
    };
    
    semaphore_info := VkSemaphoreCreateInfo.{};

    for 0..frames.count-1 {
        if !validate(vkCreateCommandPool(logical.obj, *command_pool_info, null, *frames[it].command_pool), "failed to create a command pool") then return false;

        command_alloc_info := VkCommandBufferAllocateInfo.{
            commandPool = frames[it].command_pool,
            commandBufferCount = 1,
            level = .PRIMARY
        };

        if !validate(vkAllocateCommandBuffers(logical.obj, *command_alloc_info, *frames[it].command_buffer), "failed to create a command buffer") then return false;

        if !validate(vkCreateFence(logical.obj, *fence_info, null, *frames[it].fence), "failed to create a render fence") then return false;

        if !validate(vkCreateSemaphore(logical.obj, *semaphore_info, null, *frames[it].image_available_semaphore), "failed to create a semaphore") then return false;

        if !validate(vkCreateSemaphore(logical.obj, *semaphore_info, null, *frames[it].image_rendered_semaphore), "failed to create a semaphore") then return false;
    }

    fence_info.flags = 0;

    {
        pool_info := VkCommandPoolCreateInfo.{
            flags = .RESET_COMMAND_BUFFER_BIT,
            queueFamilyIndex = xx physical.queue_family_indices.transfer_index
        };

        if !validate(vkCreateCommandPool(logical.obj, *pool_info, null, *transfer_command_pool), "failed to create the transfer command pool") then return false;

        buffer_alloc_info := VkCommandBufferAllocateInfo.{
            commandPool = transfer_command_pool,
            commandBufferCount = 1,
            level = .PRIMARY
        };

        if !validate(vkAllocateCommandBuffers(logical.obj, *buffer_alloc_info, *transfer_command_buffer), "failed to create the transfer command pool") then return false;

        if !validate(vkCreateFence(logical.obj, *fence_info, null, *transfer_fence), "failed to create the transfer fence") then return false;
    }

    render_log("created frame datas. max frames in flight %", frames.count);
    return true;
}

create_default_descriptors :: () -> bool {
    using context.renderer;
    auto_release_temp();
    return true;
}

create_default_pipelines :: () -> bool {
    if !create_device_space_mesh_pipeline() then return false;
    if !create_device_space_mesh_textured_pipeline() then return false;
    render_log("created default pipelines");
    return true;
}

// -----------------------------------------------------------------------------------
// ---------------------------------------------------------------------- :descriptors

create_descriptors :: () -> bool {
    using context.renderer;

    ratios := Descriptor_Pool_Ratio.[
        {.STORAGE_IMAGE, 0.2}, 
        {.COMBINED_IMAGE_SAMPLER, 0.5}, 
        {.UNIFORM_BUFFER, 0.3}
    ];
    create_descriptor_pool(*descriptor_pool, 100, ratios);

    {
        bindings := VkDescriptorSetLayoutBinding.[
            {binding=0, descriptorCount=1, descriptorType=.COMBINED_IMAGE_SAMPLER}
        ];

        // i'm guessing this could be more generally usable than for one texture...
        scratch_texture_sampler_descriptor_set_layout = build_descriptor_set_layout(bindings, .FRAGMENT_BIT);
        scratch_texture_sampler_descriptor_set = allocate_descriptor_set(descriptor_pool, scratch_texture_sampler_descriptor_set_layout);

        image_info := VkDescriptorImageInfo.{
            sampler = scratch_sampler,
            imageLayout = .SHADER_READ_ONLY_OPTIMAL,
            imageView = scratch_texture.image_view
        };

        update := VkWriteDescriptorSet.{
            dstSet = scratch_texture_sampler_descriptor_set,
            descriptorCount = 1,
            descriptorType = .COMBINED_IMAGE_SAMPLER,
            pImageInfo = *image_info
        };

        vkUpdateDescriptorSets(logical.obj, 1, *update, 0, null);
    }

    return true;
}

// -----------------------------------------------------------------------------------
// -------------------------------------------------------------------------- :scratch

create_scratch_data :: () -> bool {
    using context.renderer;

    simple_vertex_buffer = create_gpu_buffer_for_array(
        scratch_vertices, .VERTEX_BUFFER_BIT, .HOST_VISIBLE_BIT | .HOST_COHERENT_BIT
    );
    copy_to_gpu_buffer(scratch_vertices.data, *simple_vertex_buffer);

    if scratch_texture_path != "" {
        scratch_texture = create_gpu_texture_for_sampling(scratch_texture_path);
    }

    {
        // create_info := VkSamplerCreateInfo.{
        //     minFilter = .LINEAR,
        //     magFilter = .LINEAR,
        //     mipmapMode = .NEAREST,
        //     addressModeU = .REPEAT,
        //     addressModeV = .REPEAT,
        //     addressModeW = .REPEAT,
        // };
        create_info := VkSamplerCreateInfo.{
            minFilter = .NEAREST,
            magFilter = .NEAREST,
            mipmapMode = .NEAREST,
            addressModeU = .REPEAT,
            addressModeV = .REPEAT,
            addressModeW = .REPEAT,
        };
        validate(vkCreateSampler(logical.obj, *create_info, null, *scratch_sampler), "failed to create the scratch sampler");
    }

    return true;
}

// -----------------------------------------------------------------------------------

#scope_file

#if VALIDATION_ON {
    required_layers := (*u8).[
        "VK_LAYER_KHRONOS_validation",
    ];
} else {
    required_layers := (*u8).[];
}

#if OS == .WINDOWS {
    required_instance_extensions := (*u8).[
        "VK_KHR_surface",
        "VK_KHR_win32_surface",
        "VK_KHR_get_surface_capabilities2",
        "VK_EXT_surface_maintenance1",
    ];
} else {
    required_instance_extensions := (*u8).[
        "VK_KHR_surface",
        "VK_KHR_get_surface_capabilities2",
        "VK_EXT_surface_maintenance1",
    ];
}

required_device_extensions := (*u8).[
    "VK_KHR_swapchain",
    "VK_EXT_swapchain_maintenance1",
    "VK_KHR_buffer_device_address",
    "VK_KHR_dynamic_rendering",
];

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
