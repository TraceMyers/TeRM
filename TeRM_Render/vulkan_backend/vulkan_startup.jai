
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
    
    // todo: this call takes a while... why?
    // if !validate(instance_extensions_are_supported(required_instance_extensions), "required instance extensions unsupported") then return false;

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
    properties.texel_buffer_alignment = temp_properties.minTexelBufferOffsetAlignment;
    properties.uniform_buffer_alignment = temp_properties.minUniformBufferOffsetAlignment;
    properties.storage_buffer_alignment = temp_properties.minStorageBufferOffsetAlignment;
    properties.image_alignment = temp_properties.bufferImageGranularity;
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
    || dummy_device.queue_family_indices.present_index  == -1 {
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

    descriptor_indexing_enable := VkPhysicalDeviceDescriptorIndexingFeatures.{
        descriptorBindingPartiallyBound = VK_TRUE,
        runtimeDescriptorArray = VK_TRUE,
        shaderSampledIMaeArrayNonUniformIndexing = VK_TRUE
    };

    // smooths over a bunch of unnecessary boilerplate in creating graphics pipeline-related stuff
    dynamic_rendering_enable := VkPhysicalDeviceDynamicRenderingFeatures.{
        dynamicRendering = VK_TRUE,
        pNext = *descriptor_indexing_enable
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
    using context.renderer;

    // making pipeline layouts
    create_default_pipeline_layouts();

    build_info: Graphics_Pipeline_Build_Info;
    build_info.pipeline_layout = billboard_pipeline_layout;
    make_default_vertex_fragment_pipeline_build_info(
        *build_info, "billboard", "billboard", Billboard_Vertex
    ); 
    billboard_pipeline = build_pipeline(*build_info);
    
    render_log("created default pipelines");
    return true;
}

create_default_pipeline_layouts :: () -> bool {
    using context.renderer;

    {
        descriptor_set_layouts := VkDescriptorSetLayout.[
            textures_descriptor_set_layout,
            per_frame_uniform_descriptor_set_layout,
            billboard_descriptor_set_layout
        ];
        create_pipeline_layout = VkPipelineLayoutCreateInfo.{
            setLayoutCount = 3,
            pSetLayouts = *layouts[0],
        };

        if !validate(vkCreatePipelineLayout(logical.obj, *create_pipeline_layout, null, *billboard_pipeline_layout), "failed to create device space mesh pipeline layout") {
            return false;
        }
    }
}

// -----------------------------------------------------------------------------------
// ---------------------------------------------------------------------- :descriptors

create_descriptors :: () -> bool {
    using context.renderer;

    ratios := Descriptor_Pool_Ratio.[
        {.STORAGE_IMAGE, 0.25}, 
        {.COMBINED_IMAGE_SAMPLER, 0.25}, 
        {.UNIFORM_BUFFER, 0.25},
        {.STORAGE_BUFFER, 0.25}
    ];
    create_descriptor_pool(*descriptor_pool, 100, ratios);

    // todo: use bindings for frames in flight

    // Set 0 — per-frame data (camera, time, lights) — shared across all pipelines
    // Set 1 — per-pass data (shadow map, render targets)
    // Set 2 — per-material data (textures, material params)
    // Set 3 — per-object data (model matrix, object ID)

    // Sets = granularity of when things change
    // Bindings = individual resources within that granularity

    {
        // descriptor set of all images
        textures_binding := VkDescriptorSetLayoutBinding.[{
            binding         = 0, 
            descriptorCount = max_texture_count, 
            descriptorType  = .COMBINED_IMAGE_SAMPLER, 
            stageFlags      = .VERTEX_BIT | .VRAGMENT_BIT
        }];

        // Mark it as partially bound and variable count
        binding_flags := VkDescriptorBindingFlags.{ PARTIALLY_BOUND_BIT | VARIABLE_DESCRIPTOR_COUNT_BIT };
        flags_info := VkDescriptorSetLayoutBindingFlagsCreateInfo.{
            bindingCount  = 1,
            pBindingFlags = *binding_flags
        };

        textures_descriptor_set_layout = build_descriptor_set_layout(textures_binding, p_next = *flags_info);

        variable_count_info := VkDescriptorSetVariableDescriptorCountAllocateInfo.{
            descriptorSetCount = 1,
            pDescriptorCounts  = *max_textures_count
        };

        textures_descriptor_set = allocate_descriptor_set(descriptor_pool, textures_descriptor_set_layout, *variable_count_info);

        add_gpu_image_for_sampling(corrugated_cardboard_path, image_sampler_nearest);  // 0
    }
    {
        // descriptor set for the per-frame uniform buffer
        per_frame_uniform_binding := VkDescriptorSetLayoutBinding.[
            {binding=0, descriptorCount=1, descriptorType=.UNIFORM_BUFFER, stageFlags=.ALL}
        ];
        per_frame_uniform_descriptor_set_layout = build_descriptor_set_layout(per_frame_uniform_binding);
        per_frame_uniform_descriptor_set = allocate_descriptor_set(descriptor_pool, per_frame_uniform_descriptor_set_layout);
    }
    {
        // any ssbo can use this layout
        storage_buffer_binding := VkDescriptorSetLayoutBinding.[
            {binding=0, descriptorcount=1, descriptorType=.STORAGE_BUFFER, stageFlags=.VERTEX_BIT | .FRAGMENT_BIT}
        ];
        storage_buffer_descriptor_set_layout = build_descriptor_set_layout(storage_buffer_binding);
    }
    {
        billboard_instance_buffer_descriptor_set = allocate_descriptor_set(descriptor_pool, storage_buffer_descriptor_set_layout);
    }

// ***

// struct BillboardInstance {
//     vec3 position;
//     vec2 size;
//     uint texture_index;    // indexes into set 0
//     vec4 color;
//     // whatever else
// };

// layout(set = 2, binding = 0) buffer BillboardInstances {
//     BillboardInstance instances[];
// };

// void main() {
//     BillboardInstance inst = instances[gl_InstanceIndex];
//     vec4 tex = texture(textures[nonuniformEXT(inst.texture_index)], uv);
//     // ...
// }

    return true;
}

// -----------------------------------------------------------------------------------
// ----------------------------------------------------------------------- :allocators

initialize_allocators :: () -> bool {
    using context.renderer;

    // Create throwaway resources to probe compatibility

    dummy_buffer_create_info := VkBufferCreateInfo.{
        size = 4096,
        usage = .VERTEX_BUFFER_BIT
              | .INDEX_BUFFER_BIT
              | .UNIFORM_BUFFER_BIT
              | .STORAGE_BUFFER_BIT
              | .TRANSFER_SRC_BIT
              | .TRANSFER_DST_BIT,
        sharingMode = .EXCLUSIVE
    };
    dummy_buffer: VkBuffer;

    dummy_image_create_info := VkImageCreateInfo.{
        imageType = ._2D,
        format = .R8G8B8A8_UNORM,
        extent = {1024, 1024, 1},
        mipLevels = 1,
        arrayLayers = 1,
        samples = ._1_BIT, // MSAA
        tiling = .OPTIMAL,
        usage =  .TRANSFER_DST_BIT | .SAMPLED_BIT,
        sharingMode = .EXCLUSIVE
    };
    dummy_image: VkImage;

    dummy_buffer_requirements: VkMemoryRequirements;
    dummy_image_requirements: VkMemoryRequirements;

    vkCreateBuffer(logical.obj, *dummy_buffer_create_info, null, *dummy_buffer);
    vkGetBufferMemoryRequirements(dummy_buffer, *dummy_buffer_requirements);
    vkDestroyBuffer(logical.obj, dummy_buffer, null);

    vkCreateImage(dummy_image_create_info, *dummy_image);   // OPTIMAL tiling, typical format
    vkGetImageMemoryRequirements(dummy_image, *dummy_image_requirements);
    vkDestroyImage(logical.obj, dummy_image, null);

    memory_properties: VkPhysicalDeviceMemoryProperties;
    vkGetPhysicalDeviceMemoryProperties(physical.obj, *memory_properties);

    device_local_buffer_index := find_index_of_memory_type(dummy_buffer_requirements.memoryTypeBits, .DEVICE_LOCAL_BIT, *memory_properties);
    host_coherent_buffer_index := find_index_of_memory_type(dummy_buffer_requirements.memoryTypeBits, .HOST_VISIBLE_BIT | .HOST_COHERENT_BIT, *memory_properties);
    device_local_image_index := find_index_of_memory_type(dummy_image_requirements.memoryTypeBits, .DEVICE_LOCAL_BIT, *memory_properties);
    host_coherent_image_index := find_index_of_memory_type(dummy_image_requirements.memoryTypeBits, .HOST_VISIBLE_BIT | .HOST_COHERENT_BIT, *memory_properties);

    // todo: allocate memory in each category for allocators.
}

// -----------------------------------------------------------------------------------
// -------------------------------------------------------------------------- :scratch

create_scratch_data :: () -> bool {
    using context.renderer;

    simple_vertex_buffer = create_gpu_buffer_for_array(
        scratch_vertices, .VERTEX_BUFFER_BIT, .HOST_VISIBLE_BIT | .HOST_COHERENT_BIT
    );
    copy_to_gpu_buffer(scratch_vertices.data, *simple_vertex_buffer);

    billboard_vertex_buffer = create_gpu_buffer_for_array(
        billboard_vertices, .VERTEX_BUFFER_BIT, .HOST_VISIBLE_BIT | .HOST_COHERENT_BIT
    );
    copy_to_gpu_buffer(billboard_vertices.data, *billboard_vertex_buffer);

    per_frame_uniform_buffer = create_gpu_buffer(size_of(Per_Frame_Uniform_Buffer), .UNIFORM_BUFFER_BIT, .HOST_VISIBLE_BIT | .HOST_COHERENT_BIT);

    {
        create_info := VkSamplerCreateInfo.{
            minFilter = .NEAREST,
            magFilter = .NEAREST,
            mipmapMode = .NEAREST,
            addressModeU = .REPEAT,
            addressModeV = .REPEAT,
            addressModeW = .REPEAT,
        };
        validate(vkCreateSampler(logical.obj, *create_info, null, *image_sampler_nearest), "failed to create the all nearest sampler");

        create_info = VkSamplerCreateInfo.{
            minFilter = .LINEAR,
            magFilter = .LINEAR,
            mipmapMode = .NEAREST,
            addressModeU = .REPEAT,
            addressModeV = .REPEAT,
            addressModeW = .REPEAT,
        };
        validate(vkCreateSampler(logical.obj, *create_info, null, *image_sampler_bilinear), "failed to create the all nearest sampler");

        create_info = VkSamplerCreateInfo.{
            minFilter = .LINEAR,
            magFilter = .LINEAR,
            mipmapMode = .LINEAR,
            addressModeU = .REPEAT,
            addressModeV = .REPEAT,
            addressModeW = .REPEAT,
        };
        validate(vkCreateSampler(logical.obj, *create_info, null, *image_sampler_trilinear), "failed to create the all nearest sampler");
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
