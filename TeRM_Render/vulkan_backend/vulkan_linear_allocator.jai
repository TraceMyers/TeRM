// procedures in this file will no doubt need to be split up so the code can be shared among
// allocators, but I only plan on having two of them. also, a lot of parameterization that will
// eventually be needed is hidden right now for convenience.

GPU_Linear_Allocator :: struct {
    heaps: [..]s16;
    heap_type: GPU_Heap_Type;
    frontier: int;
    frontier_offset: int;
}

gpu_linear_allocate :: inline (heap_type: GPU_Heap_Type, size: int, usage_flags: VkBufferUsageFlags) -> GPU_Buffer {
    using context.renderer;

    assert(heap_type == .DEVICE_LOCAL_BUFFER || heap_type == .HOST_VISIBLE_BUFFER);

    align := usage_alignment(usage_flags);
    buffer := GPU_Buffer.{
        allocation = gpu_linear_allocate_aligned(size, align, heap_type),
        usage_flags = usage_flags
    };

    return buffer;
}

gpu_linear_allocate :: inline (heap_type: GPU_Heap_Type, width: s32, height: s32, usage_flags: VkImageUsageFlags, format := VkFormat.R8G8B8A8_UNORM, mip_count: u32 = 1, layer_count: u32 = 1, create_color_view := true) -> *GPU_Image {
    using context.renderer;

    assert(heap_type == .DEVICE_LOCAL_IMAGE || heap_type == .HOST_VISIBLE_IMAGE);

    image_index := pool_acquire(*image_pool);
    assert(image_index < max_texture_count);
    image := *image_pool[image_index];
    image.pool_index = xx image_index;

    image.extent      = {xx width, xx height, 1};
    image.format      = format;
    image.usage       = usage_flags;
    image.mip_count   = xx mip_count;
    image.layer_count = xx layer_count;

    create_info := VkImageCreateInfo.{
        imageType = ._2D,
        format = image.format,
        extent = image.extent,
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

    memory_requirements: VkMemoryRequirements;
    vkCreateImage(logical.obj, *create_info, null, *image.obj);
    vkGetImageMemoryRequirements(logical.obj, image.obj, *memory_requirements);

    align : int = xx memory_requirements.alignment;
    size  : int = xx memory_requirements.size;

    image.allocation = gpu_linear_allocate_aligned(size, align, heap_type);

    heap := *gpu_heap_pool[image.allocation.source_heap];
    vkBindImageMemory(logical.obj, image.obj, heap.memory, xx image.allocation.source_heap_offset);

    if create_color_view {
        view_create_info := image_view_create_info(image.format, image.obj, .COLOR_BIT, image.mip_count);
        validate(vkCreateImageView(logical.obj, *view_create_info, null, *image.view), "failed to create an image view for a sampled texture");
    }

    return image;
}

gpu_linear_allocate_aligned :: (size: int, align: int, heap_type: GPU_Heap_Type) -> GPU_Allocation {
    using context.renderer;

    if size == 0 then return {};

    allocator := get_gpu_linear_allocator(heap_type);

    heap: *GPU_Heap; 
    available_size: int;

    aligned_size := size;
    aligned_frontier_offset: int;

    while allocator.frontier < allocator.heaps.count {
        frontier_heap_index := allocator.heaps[allocator.frontier];
        heap = *gpu_heap_pool[frontier_heap_index];
        assert(heap.is_valid);

        use_align := max(heap.buffer_min_alignment, cast(u32) align);
        aligned_frontier_offset = align_up(allocator.frontier_offset, use_align);
        available_size = heap.size - aligned_frontier_offset;

        if available_size >= size {
            break;
        }

        allocator.frontier += 1;
    }

    allocation_offset := aligned_frontier_offset;

    if available_size < aligned_size {
        buffer_usage : VkBufferUsageFlags = 
              .TRANSFER_SRC_BIT
            | .TRANSFER_DST_BIT
            | .UNIFORM_TEXEL_BUFFER_BIT
            | .STORAGE_TEXEL_BUFFER_BIT
            | .UNIFORM_BUFFER_BIT
            | .STORAGE_BUFFER_BIT
            | .INDEX_BUFFER_BIT
            | .VERTEX_BUFFER_BIT;

        heap_size := max(size, DEFAULT_ALLOCATOR_HEAP_SIZE);
        heap_index := allocate_gpu_heap(heap_size, heap_type, .LINEAR_ALLOCATOR, buffer_usage);
        assert(heap_index != 0xffff);
        array_add(*allocator.heaps, heap_index);
        heap = *gpu_heap_pool[heap_index];

        allocation_offset = 0;
        allocator.frontier = xx allocator.heaps.count - 1;
        allocator.frontier_offset = size;
    } else {
        allocator.frontier_offset = allocation_offset + size;
    }

    allocation := GPU_Allocation.{
        source_heap           = allocator.heaps[allocator.frontier],
        allocator_heap_index  = xx allocator.frontier,
        source_heap_offset    = xx allocation_offset,
        size                  = xx size
    };

    return allocation;
}

// assumes keeping memory. will add a parameter for not if needed
gpu_linear_allocator_reset :: (heap_type: GPU_Heap_Type) {
    allocator := get_gpu_linear_allocator(heap_type);
    allocator.frontier = 0;
    allocator.frontier_offset = 0;
}

get_gpu_linear_allocator :: inline (heap_type: GPU_Heap_Type) -> *GPU_Linear_Allocator {
    using context.renderer;
    if heap_type == {
    case .DEVICE_LOCAL_BUFFER;
        return *device_local_buffer_linear_allocator;
    case .DEVICE_LOCAL_IMAGE;
        return *device_local_image_linear_allocator;
    case .HOST_VISIBLE_BUFFER;
        return *host_visible_buffer_linear_allocator;
    case .HOST_VISIBLE_IMAGE;
        return *host_visible_image_linear_allocator;
    case;
        assert(false, "invalid heap type");
    }
    return null;
}

