// todo: when more APIs are added, can figure out the generic versions rather than the 
// vk versions of these things. some of that is already started (e.g. Physical_Device_Properties);

MIN_DEPTH :: 0.0;
MAX_DEPTH :: 1.0;
VK_API_VERSION_1_3 :: #run VK_MAKE_VERSION(1, 3, 0);
TERM_RENDERER_VERSION :: #run VK_MAKE_VERSION(
    TERM_RENDER_VERSION_MAJOR, TERM_RENDER_VERSION_MINOR, 0
);
DEPTH_FORMAT :: VkFormat.D24_UNORM_S8_UINT;
INVALID_MEMORY_TYPE_INDEX : u32 : 0xffff_ffff;

Renderer :: struct {
    API :: "vulkan";
    API_VERSION :: VK_API_VERSION_1_3;

    // when multithreading with multiple renderers, this data should be copied.
    using shared_data: struct {
        application_name := "your graphics application";
        application_version := #run VK_MAKE_VERSION(0, 1, 0);
        // please feel free to change this when you instantiate your renderer
        engine_name := "TeRM/Render";
        engine_version := TERM_RENDERER_VERSION;

        window: Window_Type;

        vk_instance: VkInstance;
        surface: VkSurfaceKHR;
        physical: Physical_Device;
        logical: Logical_Device;
        swapchain: Swapchain;
        frames: []Graphics_Frame;

        transfer_command_pool: VkCommandPool;
        transfer_command_buffer: VkCommandBuffer;
        transfer_fence: VkFence;

        device_space_mesh_pipeline: VkPipeline;
        device_space_mesh_pipeline_layout: VkPipelineLayout;

        graphics_queue: VkQueue; // per thread?
        transfer_queue: VkQueue; // per thread?

        rendered_frame_count: s32;

        depth_buffer: Texture;

        init_success: bool;
        
        // scratch space (or more scratchy than the rest)
        scratch_time: float;
        simple_vertex_buffer: GPU_Buffer;
        scratch_vertices := Simple_Vertex.[
            // front face
            {{-0.5, -0.5,  0.5}, {1, 0, 0}},
            {{ 0.5, -0.5,  0.5}, {1, 0, 0}},
            {{ 0.5,  0.5,  0.5}, {1, 0, 0}},
            {{-0.5, -0.5,  0.5}, {1, 0, 0}},
            {{ 0.5,  0.5,  0.5}, {1, 0, 0}},
            {{-0.5,  0.5,  0.5}, {1, 0, 0}},
            // back face
            {{-0.5, -0.5, -0.5}, {0, 1, 0}},
            {{ 0.5, -0.5, -0.5}, {0, 1, 0}},
            {{ 0.5,  0.5, -0.5}, {0, 1, 0}},
            {{-0.5, -0.5, -0.5}, {0, 1, 0}},
            {{ 0.5,  0.5, -0.5}, {0, 1, 0}},
            {{-0.5,  0.5, -0.5}, {0, 1, 0}},
            // left face
            {{-0.5, -0.5,  0.5}, {0, 0, 1}},
            {{-0.5,  0.5,  0.5}, {0, 0, 1}},
            {{-0.5,  0.5, -0.5}, {0, 0, 1}},
            {{-0.5, -0.5,  0.5}, {0, 0, 1}},
            {{-0.5,  0.5, -0.5}, {0, 0, 1}},
            {{-0.5, -0.5, -0.5}, {0, 0, 1}},
            // right face
            {{ 0.5, -0.5,  0.5}, {0, 0, 1}},
            {{ 0.5,  0.5,  0.5}, {0, 0, 1}},
            {{ 0.5,  0.5, -0.5}, {0, 0, 1}},
            {{ 0.5, -0.5,  0.5}, {0, 0, 1}},
            {{ 0.5,  0.5, -0.5}, {0, 0, 1}},
            {{ 0.5, -0.5, -0.5}, {0, 0, 1}},
        ];
    };

    shader_table: Linear_Table(string, VkShaderModule);
}

Render_Init_Options :: struct {
    populate_shader_data_in_working_directory := true;
}

Queue_Family_Capability_Flags :: enum_flags {
    PRESENT;
    GRAPHICS;
    COMPUTE;
    TRANSFER;
}

Queue_Family_Indices :: struct {
    present_index:  u32 = U32_MAX;
    graphics_index: u32 = U32_MAX;
    compute_index:  u32 = U32_MAX;
    transfer_index: u32 = U32_MAX;
    #overlay(present_index) array: [4]u32;
}

Physical_Device :: struct {
    obj: VkPhysicalDevice;
    type: VkPhysicalDeviceType;
    size: VkDeviceSize;
    queue_family_indices: Queue_Family_Indices;
    properties: Physical_Device_Properties;
}

Logical_Device :: struct {
    obj: VkDevice;
}

Physical_Device_Vendor :: enum u32 {
    UNKNOWN;
    NVIDIA;
    AMD;
    INTEL;
    ARM;
    QUALCOMM;
    IMGTEC;
}

Physical_Device_Driver_Version :: struct {
    major: s32      = -1;
    minor: s32      = -1;
    secondary: s32  = -1;
    tertiary: s32   = -1;
    #overlay(secondary) patch: s32 = ---;
    #overlay(major) array: [4]s32;
}

Graphics_API_Version :: struct {
    major: u32;
    minor: u32;
    patch: u32;
}

GPU_Buffer :: struct {
    obj: VkBuffer;
    memory: VkDeviceMemory;
    size: VkDeviceSize;
}

Physical_Device_Properties :: struct {
    api_version: u32;
    driver_version: u32;
    vendor_id: u32;
    device_id: u32;
    device_type: VkPhysicalDeviceType;
    device_name: string;
    device_name_buffer: [256]u8;
}

Swapchain_Support_Info :: struct {
    capabilities: VkSurfaceCapabilitiesKHR;
    formats: []VkSurfaceFormatKHR;
    present_modes: []VkPresentModeKHR;
}

Swapchain :: struct {
    obj: VkSwapchainKHR;
    extent: VkExtent2D;
    format: VkSurfaceFormatKHR;
    present_mode: VkPresentModeKHR;
    // the underlying image datas. not explicitly created by the vulkan api user, so not destroyed by vulkan api user.
    images: []VkImage;
    // the interface for an image. how to access it. texture and possibly a render target. in this case, definitely a render target.
    image_views: []VkImageView;
}

Texture :: struct {
    obj: VkImage;   
    memory: VkDeviceMemory;
    image_view: VkImageView;
    extent: VkExtent3D;
    format: VkFormat;
    // cpu_memory: []u8;
}

Graphics_Frame :: struct {
    command_pool: VkCommandPool;
    command_buffer: VkCommandBuffer;
    image_available_semaphore: VkSemaphore;
    image_rendered_semaphore: VkSemaphore;
    fence: VkFence;
}

Descriptor_Pool_Size_Ratio :: struct {
    type: VkDescriptorType;
    ratio: float32;
}

Graphics_Pipeline_Build_Info :: struct {
    shader_stages:              []VkPipelineShaderStageCreateInfo;
    input_assembly:             VkPipelineInputAssemblyStateCreateInfo;
    rasterization:              VkPipelineRasterizationStateCreateInfo;
    color_blend_attachment:     VkPipelineColorBlendAttachmentState;
    multisampling:              VkPipelineMultisampleStateCreateInfo;
    pipeline_layout:            VkPipelineLayout;
    depth_stencil:              VkPipelineDepthStencilStateCreateInfo;
    render_info:                VkPipelineRenderingCreateInfo;
    color_attachment_format:    VkFormat;
}

Simple_Vertex :: struct {
    position: Vector3;
    color: Color3f;
}


#load "vulkan_renderer_initialization.jai";
#load "vulkan_system_information.jai";
#load "vulkan_renderer_update.jai";

#scope_module

#load "../vulkan_backend/vulkan_getters.jai";
#load "../vulkan_backend/vulkan_startup.jai";
#load "../vulkan_backend/vulkan_validation.jai";
#load "../vulkan_backend/vulkan_swapchain_and_attachments.jai";
#load "../vulkan_backend/vulkan_create_data.jai";
#load "../vulkan_backend/vulkan_pipelines.jai";
#load "../vulkan_backend/vulkan_shaders.jai";

#import "Window_Creation";
#import "Basic";
#import "Math";
#import "File";
#import "File_Utilities";
#import "Process";
#import "Sort";

#import "TeRM/TeRM_Log";
#import "TeRM/TeRM_Array";
#import "TeRM/TeRM_String";
#import "TeRM/TeRM_Storage";
#import "TeRM/TeRM_Color";
#import "TeRM/TeRM_File";
#import "TeRM/TeRM_Window";
#import "TeRM/TeRM_Math";
#import "TeRM/TeRM_Render/vulkan-jai";
#import "TeRM/TeRM_Camera";

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
