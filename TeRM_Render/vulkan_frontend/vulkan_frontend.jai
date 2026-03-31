// todo: when more APIs are added, can figure out the generic versions rather than the 
// vk versions of these things. some of that is already started (e.g. Physical_Device_Properties);

// probably should be using arena buffers a lot. dramatically simplifies allocation for per-frame 
// and especially variably sized stuff.

MIN_DEPTH :: 0.0;
MAX_DEPTH :: 1.0;
VK_API_VERSION_1_3 :: #run VK_MAKE_VERSION(1, 3, 0);
TERM_RENDERER_VERSION :: #run VK_MAKE_VERSION(
    TERM_RENDER_VERSION_MAJOR, TERM_RENDER_VERSION_MINOR, 0
);
DEPTH_FORMAT :: VkFormat.D24_UNORM_S8_UINT;
INVALID_MEMORY_TYPE_INDEX : u32 : 0xffff_ffff;
// Query these at startup from VkPhysicalDeviceLimits
// limits.minUniformBufferOffsetAlignment   // often 64 or 256
// limits.minStorageBufferOffsetAlignment   // often 16-64
// limits.minTexelBufferOffsetAlignment     // often 16
// limits.bufferImageGranularity            // often 1024-65536
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

        descriptor_pool: VkDescriptorPool;

        rendered_frame_count: s32;

        depth_buffer: *GPU_Image;

        init_success: bool;

        camera_info: Camera_Info;
        camera_position: Vector3;
        camera_orientation: Quaternion;
        
        // scratch space (or more scratchy than the rest)
        corrugated_cardboard_path: string;
        corrugated_cardboard_image: *GPU_Image;

        light_glow_image_path: string;
        light_glow_image: *GPU_Image;

        per_frame_uniform_buffer: GPU_Buffer;
        per_frame_uniform_descriptor_set_layout: VkDescriptorSetLayout;
        per_frame_uniform_descriptor_set: VkDescriptorSet;

        // allocator stuff

        max_texture_count: int;

        gpu_heap_pool: Pool(GPU_Heap);
        image_pool: Pool(GPU_Image);

        linear_allocators: [GPU_HEAP_TYPE_COUNT]GPU_Linear_Allocator;

        textures_descriptor_set_layout: VkDescriptorSetLayout;
        textures_descriptor_set: VkDescriptorSet;

        materials_storage_buffer_descriptor_set: VkDescriptorSet;
        materials_storage_buffer: GPU_Buffer;

        mesh_transforms_descriptor_set: VkDescriptorSet;
        mesh_transforms_buffer: GPU_Buffer;

        storage_buffer_descriptor_set_layout: VkDescriptorSetLayout;

        billboard_vertex_buffer: GPU_Buffer;
        billboard_instance_buffer: GPU_Buffer;
        billboard_instance_buffer_descriptor_set: VkDescriptorSet;
        billboard_pipeline_layout: VkPipelineLayout;
        billboard_pipeline: VkPipeline;

        opaque_mesh_pipeline_layout: VkPipelineLayout;
        opaque_mesh_pipeline: VkPipeline;

        mesh_instance_buffer: GPU_Buffer;
        mesh_instance_buffer_descriptor_set: VkDescriptorSet;

        texture_references: []Texture_Ref;
        mesh_references: []Mesh_Ref;

        meshes: [..]Mesh;
        materials: Pool(Material);

        particle_draws: [..]Billboard_Instance;
        // todo: could probably do this the same way as Billboard_Instance and it'd be simpler.
        // but I'd have to move transform into the mesh draw instance
        static_mesh_draws: [..]Static_Mesh_Draw;

        debug_switch: bool;

        billboard_vertices := Billboard_Vertex.[
            {position={-0.5, -0.5}, uv={0, 0}},
            {position={ 0.5, -0.5}, uv={1, 0}},
            {position={ 0.5,  0.5}, uv={1, 1}},
            {position={-0.5, -0.5}, uv={0, 0}},
            {position={ 0.5,  0.5}, uv={1, 1}},
            {position={-0.5,  0.5}, uv={0, 1}},
        ];

        point_light_position: Vector3;

        sampler_table: Linear_Table(u32, VkSampler);

        scratch_position: Vector3;
        scratch_update_position: bool;
        scratch_time: float;
        simple_vertex_buffer: GPU_Buffer;
        scratch_vertices := Simple_Vertex.[
            // front face
            {{-0.5, -0.5,  0.5, 1}, {1, 1, 1}, {0, 0}},
            {{ 0.5, -0.5,  0.5, 1}, {1, 1, 1}, {1, 0}},
            {{ 0.5,  0.5,  0.5, 1}, {1, 1, 1}, {1, 1}},
            {{-0.5, -0.5,  0.5, 1}, {1, 1, 1}, {0, 0}},
            {{ 0.5,  0.5,  0.5, 1}, {1, 1, 1}, {1, 1}},
            {{-0.5,  0.5,  0.5, 1}, {1, 1, 1}, {0, 1}},
            // back face
            {{-0.5, -0.5, -0.5, 1}, {1, 1, 1}, {0, 0}},
            {{ 0.5, -0.5, -0.5, 1}, {1, 1, 1}, {1, 0}},
            {{ 0.5,  0.5, -0.5, 1}, {1, 1, 1}, {1, 1}},
            {{-0.5, -0.5, -0.5, 1}, {1, 1, 1}, {0, 0}},
            {{ 0.5,  0.5, -0.5, 1}, {1, 1, 1}, {1, 1}},
            {{-0.5,  0.5, -0.5, 1}, {1, 1, 1}, {0, 1}},
            // // left face
            {{-0.5, -0.5,  0.5, 1}, {1, 1, 1}, {0, 1}},
            {{-0.5,  0.5,  0.5, 1}, {1, 1, 1}, {1, 1}},
            {{-0.5,  0.5, -0.5, 1}, {1, 1, 1}, {1, 0}},
            {{-0.5, -0.5,  0.5, 1}, {1, 1, 1}, {0, 1}},
            {{-0.5,  0.5, -0.5, 1}, {1, 1, 1}, {1, 0}},
            {{-0.5, -0.5, -0.5, 1}, {1, 1, 1}, {0, 0}},
            // // right face
            {{ 0.5, -0.5,  0.5, 1}, {1, 1, 1}, {0, 1}},
            {{ 0.5,  0.5,  0.5, 1}, {1, 1, 1}, {1, 1}},
            {{ 0.5,  0.5, -0.5, 1}, {1, 1, 1}, {1, 0}},
            {{ 0.5, -0.5,  0.5, 1}, {1, 1, 1}, {0, 1}},
            {{ 0.5,  0.5, -0.5, 1}, {1, 1, 1}, {1, 0}},
            {{ 0.5, -0.5, -0.5, 1}, {1, 1, 1}, {0, 0}},
        ];
    };

    shader_table: Linear_Table(string, VkShaderModule);
}

MAX_MATERIALS :: 1024;
MAX_MESHES   :: 128_000;

GPU_Material :: struct {
    albedo_factor: Vector4;
    emissive_factor: Vector4;
    metallic_factor: float;
    roughness_factor: float;

    alpha_cutoff: float;

    albedo_uv: s32;
    metallic_uv: s32;
    roughness_uv: s32;
    normal_uv: s32;
    occlusion_uv: s32;
    emissive_uv: s32;

    albedo_tex: s32;
    normal_tex: s32;
    emissive_tex: s32;
    orm_tex: s32;
};

Static_Mesh_Draw :: struct {
    position: Vector3;
    orientation: Quaternion;
    scale: Vector3;
    ref: Mesh_Ref;
}

Particle_Draw :: struct {
    position: Vector3;
    color: Color4b = #run to_color4b(COLOR4F_WHITE);
    scale: float = 1.0;
    texture_index: s16 = -1;
}

Texture_Ref :: struct {
    path: string;
    using texture: Texture;
}

Mesh_Ref :: struct {
    path: string;
    index: int;
}

Mesh_Instance :: struct {
    transform_id: s32;
    material_id: s32;
}

Render_Init_Options :: struct {
    populate_shader_data_in_working_directory := true;
    max_texture_count := 4096;
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
    #overlay(present_index) array: [4]u32 = ---;
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

DEFAULT_BUFFER_HEAP_SIZE : int : 32  * 1024 * 1024;
DEFAULT_IMAGE_HEAP_SIZE  : int : 128 * 1024 * 1024;
VERTEX_BUFFER_SIZE : int : 96 * 1024 * 1024;
INDEX_BUFFER_SIZE  : int : 32 * 1024 * 1024;

GPU_Heap_Type :: enum u8 {
    PERMANENT_DEVICE_LOCAL_BUFFER;
    PERMANENT_HOST_VISIBLE_BUFFER;
    TEMP_DEVICE_LOCAL_BUFFER;
    TEMP_HOST_VISIBLE_BUFFER;
    VERTEX_BUFFER;
    INDEX_BUFFER; // if this isn't the last buffer type, update is_buffer_type

    DEVICE_LOCAL_IMAGE; // if this isn't the first image type, update is_image_type
    HOST_VISIBLE_IMAGE;
}

GPU_HEAP_TYPE_COUNT :: #run enum_highest_value(GPU_Heap_Type) + 1;

is_buffer_type :: (heap_type: GPU_Heap_Type) -> bool {
    return heap_type <= .INDEX_BUFFER;
}

is_image_type :: (heap_type: GPU_Heap_Type) -> bool {
    return !is_buffer_type(heap_type);
}

is_host_visible_type :: (heap_type: GPU_Heap_Type) -> bool {
    if heap_type == {
    case .PERMANENT_HOST_VISIBLE_BUFFER;
        return true;
    case .TEMP_HOST_VISIBLE_BUFFER;
        return true;
    case .HOST_VISIBLE_IMAGE;
        return true;
    }
    return false;
}

is_device_local_type :: (heap_type: GPU_Heap_Type) -> bool {
    return !is_host_visible_type(heap_type);
}

GPU_Heap :: struct {
    memory: VkDeviceMemory;
    size: int;

    type: GPU_Heap_Type;
    allocator: GPU_Allocator;

    // these fields are only valid if this is a heap for allocating buffers
    buffer: VkBuffer; 
    buffer_usage: VkBufferUsageFlags;
    buffer_min_alignment: u32;

    is_valid: bool;
}

GPU_Allocator :: enum u8 {
    LINEAR_ALLOCATOR;
}

GPU_Allocation :: struct {
    source_heap: s16 = -1;
    allocator_heap_index: s16;
    source_heap_offset: s32;
    size: u32;
}

GPU_Image :: struct {
    using #as allocation: GPU_Allocation;
    obj:                  VkImage;   
    view:                 VkImageView;
    extent:               VkExtent3D;
    format:               VkFormat;
    usage:                VkImageUsageFlags;
    mip_count:            u8;
    layer_count:          u8;
    pool_index:           s16;
}

GPU_Buffer :: struct {
    using #as allocation: GPU_Allocation;
    usage_flags: VkBufferUsageFlags;
}

Physical_Device_Properties :: struct {
    api_version: u32;
    driver_version: u32;
    vendor_id: u32;
    device_id: u32;
    device_type: VkPhysicalDeviceType;
    device_name: string;
    device_name_buffer: [256]u8;
    texel_buffer_alignment: VkDeviceSize;
    uniform_buffer_alignment: VkDeviceSize;
    storage_buffer_alignment: VkDeviceSize;
    device_local_buffer_memory_index: u32;
    host_visible_buffer_memory_index: u32;
    device_local_image_memory_index: u32;
    host_visible_image_memory_index: u32;
    image_alignment: VkDeviceSize;
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


Graphics_Frame :: struct {
    command_pool: VkCommandPool;
    command_buffer: VkCommandBuffer;
    image_available_semaphore: VkSemaphore;
    image_rendered_semaphore: VkSemaphore;
    fence: VkFence;
}

Descriptor_Pool_Ratio :: struct {
    type: VkDescriptorType;
    ratio: float32;
}

Billboard_Vertex :: struct {
    position: Vector2;
    uv: Vector2;
}

Billboard_Instance :: struct {
    position:      Vector3; _pad0: float32;
    tint:          Color4f;
    scale:         Vector2; 
    uv_offset:     Vector2;
    uv_scale:      Vector2; 
    texture_index: u32;     _pad1: float32;
}

Per_Frame_Uniform_Buffer :: struct {
    view:            Matrix4;
    view_projection: Matrix4;
    camera_position: Vector3; _pad0: float32;
    camera_forward:  Vector3; _pad1: float32;
    camera_up:       Vector3; _pad2: float32;
    camera_right:    Vector3; _pad3: float32;
    time:            float32;
    delta_time:      float32;
}

Sprite_Rect :: struct {
    offset: Vector2;
    scale: Vector2;
}

Simple_Vertex :: struct {
    position: Vector4;
    color: Color3f;
    uv: Vector2;
}

Mesh_Import_Types :: struct {
    vertex_buffer_type :: GPU_Buffer;
    index_buffer_type  :: GPU_Buffer;
    texture_type       :: s16;
    material_type      :: s16;
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
#load "../vulkan_backend/vulkan_linear_allocator.jai";

#import "Window_Creation";
#import "Basic";
#import "Math";
#import "File";
#import "File_Utilities";
#import "Process";
#import "Sort";
#import "stb_image";

#import "TeRM/TeRM_Log";
#import "TeRM/TeRM_Array";
#import "TeRM/TeRM_String";
#import "TeRM/TeRM_Storage";
#import "TeRM/TeRM_Color";
#import "TeRM/TeRM_File";
#import "TeRM/TeRM_System";
#import "TeRM/TeRM_Math";
#import "TeRM/TeRM_Render/vulkan-jai";
#import "TeRM/TeRM_Camera";
#import "TeRM/TeRM_Metaprogram";
#import "TeRM/TeRM_Mesh"(user_types = Mesh_Import_Types);

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
