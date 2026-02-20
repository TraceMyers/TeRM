// todo: when more APIs are added, can figure out the generic versions rather than the 
// vk versions of these things. some of that is already started (e.g. Physical_Device_Properties);

VK_API_VERSION_1_3 :: #run VK_MAKE_VERSION(1, 3, 0);
TERM_RENDERER_VERSION :: #run VK_MAKE_VERSION(
    TERM_RENDER_VERSION_MAJOR, TERM_RENDER_VERSION_MINOR, 0
);
DEPTH_FORMAT :: VkFormat.D24_UNORM_S8_UINT;

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

        graphics_queue: VkQueue; // per thread?
        transfer_queue: VkQueue; // per thread?

        swapchain_image_index: s32;
        frame_index: s32;

        depth_buffer: Texture;

        init_success: bool;
    };

    shader_table: Linear_Table(string, VkShaderModule);
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

renderer_version_string :: (version: u32) -> string {
    major := VK_API_VERSION_MAJOR(version);
    minor := VK_API_VERSION_MINOR(version);
    patch := VK_API_VERSION_PATCH(version);
    return tprint("%.%.%", major, minor, patch);
}

#load "vulkan_renderer_initialization.jai";
#load "vulkan_system_information.jai";
#load "vulkan_renderer_update.jai";

#scope_module

U32_MAX :: 0xffff_ffff;

#load "../vulkan_backend/vulkan_getters.jai";
#load "../vulkan_backend/vulkan_startup.jai";
#load "../vulkan_backend/vulkan_validation.jai";
#load "../vulkan_backend/vulkan_swapchain_and_attachments.jai";
#load "../vulkan_backend/vulkan_create_data.jai";
#load "../vulkan_backend/vulkan_pipelines.jai";

#import "Window_Creation";
#import "Basic";
#import "Math";

#import "TeRM/TeRM_Log";
#import "TeRM/TeRM_Array";
#import "TeRM/TeRM_String";
#import "TeRM/TeRM_Storage";
#import "TeRM/TeRM_Render/vulkan-jai";
