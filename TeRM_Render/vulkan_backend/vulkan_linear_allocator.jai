
GPU_Linear_Allocator :: struct {
    heaps: [..]u16;
    heap_index: int;
    position_in_heap: int;
}

gpu_linear_allocate :: (allocation: *GPU_Allocation, size: int, heap_type: GPU_Heap_Type, usage_flags: VkBufferUsageFlags) {
    using context.renderer;

    if heaps.count == 0 {
        
    }
}

// Query these at startup from VkPhysicalDeviceLimits
// limits.minUniformBufferOffsetAlignment   // often 64 or 256
// limits.minStorageBufferOffsetAlignment   // often 16-64
// limits.minTexelBufferOffsetAlignment     // often 16
// limits.bufferImageGranularity            // often 1024-65536

// GPU_Heap :: struct {
//     memory: VkDeviceMemory;
//     size: VkDeviceSize;
//     flags: VkMemoryPropertyFlags;
//     valid: bool;
// }

// GPU_Allocation_Type :: enum u8 {
//     BUFFER;
//     IMAGE;
// }

// GPU_Allocator :: enum u8 {
//     LINEAR_ALLOCATOR;
// }

// GPU_Allocation :: struct {
//     type: GPU_Allocation_Type;
//     allocator: GPU_Allocator;
//     source_heap: u16;
//     source_heap_offset: s32;
//     size: VkDeviceSize;
//     using type_info: union {
//         buffer: GPU_Buffer;
//         texture: GPU_Texture;
//     }
// }

// GPU_Texture :: struct {
//     obj: VkImage;   
//     image_view: VkImageView;
//     extent: VkExtent3D;
//     format: VkFormat;
//     usage: VkImageUsageFlags;
//     mip_count: u32;
//     layer_count: u32;
// }

// GPU_Buffer :: struct {
//     obj: VkBuffer;
//     usage_flags: VkBufferUsageFlags;
// }
