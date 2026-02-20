// an extension of allocators what ship with the compiler. it's a well-rounded collection 
// on its own, but I wouldn't be leaving Flat_Pool out of my programs.

// --- sections ---
// Bump_Allocator
// Super_Allocotor
// GP_Allocator
// No_Allocator

// -----------------------------------------------------------------------------------
// ------------------------------------------------------------------- :Bump_Allocator
// bump/arena with no resize. because sometimes less features is a feature

BUMP_ALLOCATOR_DEFAULT_HEAP_SIZE : s32 : 16 * 1024 * 1024; // 16MB

Bump_Allocator :: struct {
    using #as base: Allocator;
    parent_allocator: Allocator;
    heap: Bump_Allocator_Heap;
}

Bump_Allocator_Heap :: struct {
    bytes: []u8;
    end: s32;
}

bump_allocator_initialize :: (using bump: *Bump_Allocator, in_heap_size := BUMP_ALLOCATOR_DEFAULT_HEAP_SIZE) {
    parent_allocator = context.allocator;
    assert(in_heap_size > 0);
    in_heap_size = ceil_to_power_of_two_multiple(in_heap_size, 8);
    proc = bump_allocator_proc;
    data = bump;
    heap = .{};
    heap.bytes = make_static_array(u8, in_heap_size);
}

bump_allocator_proc :: (mode: Allocator_Mode, size: s64, old_size: s64, old_memory: *void, allocator_data: *void) -> *void {
    if mode == {
    case .ALLOCATE;
        return bump_allocator_allocate(xx allocator_data, size);
    case .RESIZE;
        return bump_allocator_resize(xx allocator_data, size, old_size, old_memory);
    case .FREE;
        // could be useful for debug
    case .CREATE_HEAP;
        // bump_allocator_initialize(xx allocator_data);
    case .DESTROY_HEAP;
        bump_allocator_reset(xx allocator_data, false);
    }
    return null;
}

bump_allocator_allocate :: (using bump: *Bump_Allocator, size: s64) -> *void {
    new_size := heap.end + size;
    assert(new_size <= heap.bytes.count);
    data_out := *heap.bytes[heap.end];
    memset(data_out, 0, size);
    // align everything to 8 because it's easy and works fine I think
    heap.end += xx size;
    heap.end = ceil_to_power_of_two_multiple(heap.end, 8);

    return data_out;
}

bump_allocator_resize :: (using bump: *Bump_Allocator, size: s64, old_size: s64, old_memory: *void) -> *void {
    if size <= old_size {
        return old_memory;
    }
    new_memory := bump_allocator_allocate(bump, size);
    memcpy(new_memory, old_memory, old_size);
    return new_memory;
}

bump_allocator_reset :: (using bump: *Bump_Allocator, keep_memory := true) {
    if keep_memory {
        heap.end = 0;
    } else {
        if heap.bytes.count > 0 {
            free(heap.bytes.data,,parent_allocator);
        }
        bump.* = .{};
    }
}

auto_reset_to_high_water_mark :: (using bump: *Bump_Allocator) #expand {
    _mark := heap.end;
    `defer reset_to_high_water_mark(bump, _mark);
}

get_high_water_mark :: (using bump: *Bump_Allocator) -> s32 {
    return heap.end;
}

reset_to_high_water_mark :: (using bump: *Bump_Allocator, mark: s32) {
    assert(heap.bytes.count >= mark);
    heap.end = mark;
}

scope_mark_and_recede_allocations :: (using bump: *Bump_Allocator) #expand {
    mark := get_high_water_mark(bump);
    `defer reset_to_high_water_mark(bump, mark);
}

// -----------------------------------------------------------------------------------
// ------------------------------------------------------------------ :Super_Allocator
// it's super.
// very good on its own in a user-defined range of allocation sizes, [n, 64*n], 
// n = min allocation size. can be used for larger ones, but just not as good. 
// i have used this for strings in a text editor, was great.
// more generally, works well as a building block allocator, as in GP_Allocator.

SUPER_ALLOCATOR_MIN_ALLOCATION_SIZE :: 16;

Allocation_Header :: struct {
    id: Allocator_Identifier;
    // when an allocation is valid, the upper 4 bits are stamped with a specific bit pattern.
    // this is intentionally placed at byte 0 of the struct because the lowest byte of data is the one most likely to change, and so (naively speaking) most likely to change when trashed.
    using specific: union {
        super: struct {
            inner_chunk: u8;
            inner_chunk_count: u16;
            outer_chunk: u16;
            list: s16;
        };
        gp: struct {
            list: s32 = ---;
        };
    };
    #overlay(id) bit_pattern: u8 = ---;
}

Super_Allocator :: struct ($MIN_ALLOCATION_SIZE := SUPER_ALLOCATOR_MIN_ALLOCATION_SIZE) {
    using #as super_base: Allocator;
    min_alloc_size := xx MIN_ALLOCATION_SIZE;
    parent_allocator: Allocator;
    chunk_lists: [..][]Super_Allocator_Outer_Chunk(MIN_ALLOCATION_SIZE);
    books: Super_Allocator_Books;
    books_allocated_size: s64;
    default_outer_chunk_count_per_list: s32 = 32;
    shrink_to_min_lists: s32 = 1;
    default_reserve_size: s32;
    old_list_count: s32;

    CHUNKS_PER_HEAP :: 64;
    CHUNK_SIZE :: size_of(Super_Allocator_Outer_Chunk(MIN_ALLOCATION_SIZE));
    #run assert(is_power_of_two(MIN_ALLOCATION_SIZE));
    #run assert(MIN_ALLOCATION_SIZE >= size_of(Allocation_Header), "min allocation size: %, allocation header size: %", MIN_ALLOCATION_SIZE, size_of(Allocation_Header));
}

Super_Allocator_Outer_Chunk :: struct ($MIN_ALLOCATION_SIZE: s64) {
    inner_chunks: [64][MIN_ALLOCATION_SIZE]u8;
}

Super_Allocator_Books :: struct {
    largest_gap_per_list: *u8;
    gap_list_of_lists: []*u8;
    flag_list_of_lists: []*u64;
}

super_allocator_proc ::(mode: Allocator_Mode, size: s64, old_size: s64, old_memory: *void, allocator_data: *void) -> *void {
    MIN_SIZE :: 16;
    MAX_SIZE :: 131072;

    dummy_super_allocator := allocator_data.(*Super_Allocator);

    #insert -> string {
        builder: String_Builder;

        print(*builder, 
#string HERE
        if dummy_super_allocator.min_alloc_size == {
HERE
        );

        size := MIN_SIZE;
        while size <= MAX_SIZE {
            print(*builder,
#string HERE
        case %;   
            super_allocator := allocator_data.(*Super_Allocator(%));
            return super_allocator_proc_impl(mode, size, old_size, old_memory, super_allocator);
HERE,
                size, size
            );
            size <<= 1;
        }

        print(*builder,
#string HERE
        case;
            assert(false, "invalid super allocator min alloc size: % (must be >= % and <= %)", dummy_super_allocator.min_alloc_size, MIN_SIZE, MAX_SIZE);
        }
HERE,
            size, MIN_SIZE, MAX_SIZE
        );
        return builder_to_string(*builder);
    };
    return null;
}

super_allocator_proc_impl :: inline (mode: Allocator_Mode, size: s64, old_size: s64, old_memory: *void, super_allocator: *Super_Allocator) -> *void {
    if mode == {
    case .ALLOCATE;
        return super_alloc(super_allocator, size);
    case .RESIZE;
        if old_memory != null {
            super_free(super_allocator, old_memory);
        }
        return super_alloc(super_allocator, size);
    case .FREE;
        if old_memory != null {
            super_free(super_allocator, old_memory);
        }
    case .STARTUP;
    case .SHUTDOWN;
    case .THREAD_START;
    case .THREAD_STOP;
    case .CREATE_HEAP;
    case .DESTROY_HEAP;
    case .IS_THIS_YOURS;
    case .CAPS;
    }
    return null;
}

initialize_super_allocator :: (using allocator: *Super_Allocator, in_default_chunk_list_size := 0, add_chunk_lists := 1) {
    in_parent_allocator := context.allocator;
    assert(chunk_lists.count == 0 && chunk_lists.data == null);

    allocator.* = .{};
    allocator.super_base.data = allocator;
    allocator.super_base.proc = super_allocator_proc;
    parent_allocator = in_parent_allocator;

    if in_default_chunk_list_size > 0 {
        default_reserve_size = xx in_default_chunk_list_size;
    } else {
        default_reserve_size = xx (CHUNK_SIZE * 8);
    }

    if add_chunk_lists > 0 {
        for 0..add_chunk_lists - 1 {
            add_chunk_list(allocator, default_reserve_size, true,,parent_allocator);
        }
    }
}

shutdown_super_allocator :: (using allocator: *Super_Allocator) {
    for list : *chunk_lists {
        array_reset(list);
    }
    array_reset(*chunk_lists);
    free(books.largest_gap_per_list);
    allocator.* = .{};
}

add_chunk_list :: (using allocator: *Super_Allocator, min_bytes: s64, remake_books := true) {
    chunk_list := array_add(*chunk_lists);
    alloc_chunk_count := max(div_ceil(min_bytes, CHUNK_SIZE), 2);

    // Super_Allocation_Header requirements
    assert(chunk_lists.count <= S16_MAX);
    assert(alloc_chunk_count <= U16_MAX);

    if alloc_chunk_count < 8 && !did_small_chunk_count_warning {
        log("[Super_Allocator::add_chunk_list()] min bytes % leads to only % chunks being allocated per super allocator heap. the number of chunks per heap should probably be somewhere between 8 and 128", min_bytes, alloc_chunk_count);
        did_small_chunk_count_warning = true;
    }

    chunk_list.* = make_static_array(Super_Allocator_Outer_Chunk(allocator.MIN_ALLOCATION_SIZE), alloc_chunk_count);

    // removing this option because currently grow_allocator_books assumes only one list is
    // added at a time. so, if you don't grow the books after this list was added, 
    // it will cause problems.
    // if remake_books {
        grow_super_allocator_books(allocator,,parent_allocator);
    // }
}

basic_validity_check :: inline (using header: Allocation_Header) -> bool {
    return super.list >= 0 && (bit_pattern & 0xf0) == ALLOCATOR_VALIDATION_PATTERN;
}

super_alloc :: (using allocator: *Super_Allocator, size: s64) -> *void {
    allocation_size_with_header := size + ALLOCATION_HEADER_SPACE;
    ptr := try_super_alloc(allocator, allocation_size_with_header);
    // didn't find existing space, need to grow
    if ptr == null {
        add_chunk_list(allocator, max(allocation_size_with_header, default_reserve_size),, parent_allocator);
        ptr = try_super_alloc(allocator, allocation_size_with_header);
        assert(ptr != null);
    }
    return ptr.(*u8) + ALLOCATION_HEADER_SPACE;
}

super_free :: (using allocator: *Super_Allocator, ptr: *void) {
    byte_ptr := ptr.(*u8);
    header := (byte_ptr - ALLOCATION_HEADER_SPACE).(*Allocation_Header);
    assert(basic_validity_check(header.*));

    list := header.super.list;
    outer_chunk := header.super.outer_chunk;
    inner_chunk := header.super.inner_chunk;
    inner_chunk_count := header.super.inner_chunk_count;

    if inner_chunk_count > 64 {
        outer_chunk_count := div_ceil(inner_chunk_count, 64);
        assert(outer_chunk_count <= U16_MAX);
        li := *chunk_lists[list];
        start_index := outer_chunk;
        end_index := start_index + outer_chunk_count - 1;
        assert(end_index < li.count);
        for i : start_index..end_index-1 {
            flag_set := *books.flag_list_of_lists[list][i];
            assert((flag_set.* & U64_MAX) == U64_MAX);
            flag_set.* = 0;
            gap := *books.gap_list_of_lists[list][i];
            gap.* = 64;
            inner_chunk_count -= 64;
        }
        outer_chunk = end_index;
        inner_chunk = 0;
    }

    mask: u64 = ---;
    if inner_chunk_count == 64 {
        mask = U64_MAX;
    } else {
        mask = (((1).(u64) << (inner_chunk_count)) - 1) << (inner_chunk);
    }

    flag_set := *books.flag_list_of_lists[list][outer_chunk];
    assert(flag_set.* & mask == mask, "\nflag set: \n%, \nmask: \n%", FormatInt.{value=flag_set.*, base=2, minimum_digits=64}, FormatInt.{value=mask, base=2, minimum_digits=64});
    flag_set.* &= ~mask;

    gap := *books.gap_list_of_lists[list][outer_chunk];
    gap.* = xx largest_gap_in_bit_sequence_lsb(flag_set.*);

    largest_gap := *books.largest_gap_per_list[list];
    if inner_chunk_count > 64 {
        largest_gap.* = 64;
    } else if gap.* > largest_gap.* {
        max_gap: u8;
        for chunk : 0..chunk_lists[list].count-1 {
            gap = *books.gap_list_of_lists[list][outer_chunk];
            max_gap = max(max_gap, gap.*);
            if max_gap == CHUNKS_PER_HEAP then break;
        }
        largest_gap.* = max_gap;
    }

    header.* = .{};
}

try_super_alloc :: (using allocator: *Super_Allocator, size: s64) -> *void {
    header: *Allocation_Header;
    alloc_inner_chunk_count := div_ceil(size, allocator.MIN_ALLOCATION_SIZE);
    if alloc_inner_chunk_count > 64 {
        header = try_super_alloc_large(allocator, alloc_inner_chunk_count);
    } else {
        header = try_super_alloc_small(allocator, alloc_inner_chunk_count);
    }
    if header != null {
        // (these two fields are unioned)
        header.id = .SUPER_ALLOCATOR;
        header.bit_pattern |= ALLOCATOR_VALIDATION_PATTERN;
    }
    return header;
}

try_super_alloc_small :: (using allocator: *Super_Allocator, alloc_inner_chunk_count: s64) -> *Allocation_Header {
    alloc_mask: u64 = ---;
    if alloc_inner_chunk_count == 64 {
        alloc_mask = U64_MAX;
    } else {
        alloc_mask = ((1).(u64) << alloc_inner_chunk_count) - (1).(u64);
    }

    out_header: *Allocation_Header;
    allocated_gap_is_max := false;

    if chunk_lists.count > 0 then for list : 0..chunk_lists.count-1 {
        largest_gap := *books.largest_gap_per_list[list];
        if largest_gap.* >= alloc_inner_chunk_count {
            max_gap: u8;
            for chunk : 0..chunk_lists[list].count-1 {
                gap := *books.gap_list_of_lists[list][chunk];
                // only need to go in here if we haven't found the allocation that must be in this list yet...
                if out_header == null && gap.* >= alloc_inner_chunk_count {
                    allocated_gap_is_max = gap.* == largest_gap.*;
                    flag_set := *books.flag_list_of_lists[list][chunk];
                    alloc_index := find_index_of_missing_bit_sequence_lsb(flag_set.*, alloc_mask, alloc_inner_chunk_count);
                    flag_set.* |= alloc_mask << alloc_index;
                    gap.* = xx largest_gap_in_bit_sequence_lsb(flag_set.*);
                    out_header = (*chunk_lists[list][chunk].inner_chunks[alloc_index]).(*Allocation_Header);
                    out_header.super.list = xx list;
                    out_header.super.outer_chunk = xx chunk;
                    out_header.super.inner_chunk = xx alloc_index;
                    out_header.super.inner_chunk_count = xx alloc_inner_chunk_count;
                    if !allocated_gap_is_max {
                        max_gap = largest_gap.*;
                        break;
                    }
                }
                // ...otherwise, if we have found it, we're just doing bookkeeping
                max_gap = max(max_gap, gap.*);
                if max_gap == CHUNKS_PER_HEAP {
                    break;
                }
            }
            assert(out_header != null);
            largest_gap.* = max_gap;
            break;
        }
    }

    return out_header;
}

try_super_alloc_large :: (using allocator: *Super_Allocator, alloc_inner_chunk_count: s64) -> *Allocation_Header {
    assert(alloc_inner_chunk_count > 64);
    alloc_outer_chunk_count := div_ceil(alloc_inner_chunk_count, 64);
    assert(alloc_outer_chunk_count <= U16_MAX);

    out_header: *Allocation_Header;

    if chunk_lists.count > 0 then for list_index : 0..chunk_lists.count-1 {
        largest_gap := books.largest_gap_per_list[list_index];
        if largest_gap < 64 {
            continue;
        }
        chunk_index := 0;
        consecutive_free_outer_chunk_ct := 0;
        list := *chunk_lists[list_index];
        while chunk_index + alloc_outer_chunk_count <= list.count {
            gap := books.gap_list_of_lists[list_index][chunk_index];
            if gap == 64 {
                consecutive_free_outer_chunk_ct += 1;
                if consecutive_free_outer_chunk_ct == alloc_outer_chunk_count {
                    first_chunk_index := chunk_index - (alloc_outer_chunk_count-1);
                    last_chunk_index := first_chunk_index + (alloc_outer_chunk_count-1);
                    remain_inner_chunks := alloc_inner_chunk_count;
                    for c : first_chunk_index..last_chunk_index {
                        if remain_inner_chunks >= 64 {
                            books.gap_list_of_lists[list_index][c] = 0;
                            books.flag_list_of_lists[list_index][c] = U64_MAX;
                        } else {
                            books.gap_list_of_lists[list_index][c] = xx (64 - remain_inner_chunks);
                            books.flag_list_of_lists[list_index][c] = ((1).(u64) << remain_inner_chunks) - 1;
                        }
                        remain_inner_chunks -= 64;
                    }
                    out_header = (*list.*[first_chunk_index].inner_chunks[0]).(*Allocation_Header);
                    out_header.super.list = xx list_index;
                    out_header.super.outer_chunk = xx first_chunk_index;
                    out_header.super.inner_chunk = 0;
                    out_header.super.inner_chunk_count = xx alloc_inner_chunk_count;
                    break;
                }
            } else {
                consecutive_free_outer_chunk_ct = 0;
            }
            chunk_index += 1;
        }
        if out_header != null then break;
    }

    return out_header;
}

// todo: this function assumes ONE new list is being appended to the allocator data
// if I want this to be able to grow once after multiple lists are added (which would be 
// preferable for init), then this needs to be edited / rewritten.
grow_super_allocator_books :: (using allocator: *Super_Allocator) {
    // ---

    // for debuggging with memory view, set bytes to something nonzero and repeating
    write_debug_bytes_for_memory_view :: (bytes: *u8, byte_count: s64) {
        memset(bytes, 0xaf, byte_count);
    }

    // ---

    auto_release_temp();
    assert(chunk_lists.count > 0);

    reader: []u8;
    reader.data = books.largest_gap_per_list;
    reader.count = books_allocated_size;
    reader_head: s64 = 0;

    writer := make_dynamic_array(u8, max(reader.count * 2, 2048),,temp);
    writer_head: s64 = 0;

    // write_debug_bytes_for_memory_view(writer.data, writer.allocated);

    do_copy := old_list_count > 0;
    if do_copy {
        assert(books.largest_gap_per_list != null);
    }

    // ----- gap super list -----

    if do_copy {
        // copy the old super list
        write_and_read_bytes(*writer, reader, *writer_head, *reader_head, old_list_count);
    }

    // add a new final entry indicating 64 inner chunks is the largest available allocation in the new list
    free_count : u8 = 64;
    write_bytes(*writer, *writer_head, *free_count, 1);

    // ----- gap array datas -----

    gap_array_datas_offset := writer_head;
    if do_copy {
        // copy over each array of gaps
        for 0..chunk_lists.count-2 {
            write_and_read_bytes(*writer, reader, *writer_head, *reader_head, chunk_lists[it].count);
        }
    }
    // create new array of gaps
    final_list := *chunk_lists[chunk_lists.count-1];
    for 0..final_list.count-1 {
        write_bytes(*writer, *writer_head, *free_count, 1);
    }
    
    // all reads and writes going forward are 8-byte aligned, this only needs to be done once.
    serial_align_head_up(*reader_head, 8, reader.count);
    serial_writer_resize_if_needed(*writer, writer_head+8);
    serial_align_head_up(*writer_head, 8, writer.count);

    // ----- flag array datas -----

    flag_array_datas_offset := writer_head;
    if do_copy {
        // copy over each array of flags
        for 0..chunk_lists.count-2 {
            write_and_read_bytes(*writer, reader, *writer_head, *reader_head, xx (chunk_lists[it].count * 8), 8);
        }
    }
    // create new array of flags
    zero_u64 : u64 = 0;
    for 0..final_list.count-1 {
        write_bytes(*writer, *writer_head, xx *zero_u64, 8, 8);
    }

    // ----- gap array pointers -----

    pointers_to_gap_arrays_offset := writer_head;
    running_gap_array_offset : u64 = xx gap_array_datas_offset;
    if do_copy {
        // write offsets to gap array datas. will add base address later
        for 0..chunk_lists.count-2 {
            write_bytes(*writer, *writer_head, xx *running_gap_array_offset, 8, 8);
            running_gap_array_offset += xx chunk_lists[it].count;
        }
    }
    // create new offset/pointer to gap array datas
    write_bytes(*writer, *writer_head, xx *running_gap_array_offset, 8, 8);

    // ----- flag array pointers -----

    pointers_to_flag_arrays_offset := writer_head;
    running_flag_array_offset : u64 = xx flag_array_datas_offset;
    if do_copy {
        // write offsets to flag array datas. will add base address later
        for 0..chunk_lists.count-2 {
            write_bytes(*writer, *writer_head, xx *running_flag_array_offset, 8, 8);
            running_flag_array_offset += xx (chunk_lists[it].count * 8);
        }
    }
    // create new offset/pointer to flag array datas
    write_bytes(*writer, *writer_head, xx *running_flag_array_offset, 8, 8);

    old_allocation: *u8 = books.largest_gap_per_list;
    new_books_data_allocation: *u8;
    new_books_data_size: s64;

    if writer_head > books_allocated_size {
        new_books_data_size = ceil_to_power_of_two_multiple(max(writer_head, 1024), 2);
        new_books_data_allocation = make_static_array(u8, new_books_data_size,, parent_allocator).data;
        if old_allocation != null {
            free(old_allocation,,parent_allocator);
        }
    } else {
        new_books_data_size = books_allocated_size;
        new_books_data_allocation = old_allocation;
    }

    memset(new_books_data_allocation, 0, new_books_data_size);
    memcpy(new_books_data_allocation, writer.data, writer_head);

    // tell the books struct where its data is
    books.largest_gap_per_list = new_books_data_allocation;
    books.gap_list_of_lists.data = xx (new_books_data_allocation + pointers_to_gap_arrays_offset);
    books.gap_list_of_lists.count = chunk_lists.count;
    books.flag_list_of_lists.data = xx (new_books_data_allocation + pointers_to_flag_arrays_offset);
    books.flag_list_of_lists.count = chunk_lists.count;

    // previously, because we didn't know what the address of the allocation would be, when we created arrays of pointers,
    // we had to store offsets rather than actual addresses. now that we know the allocation address, we can add that
    // so the pointer points to the right place.
    for 0..chunk_lists.count-1 {
        gap_array_offset_from_allocation_head := books.gap_list_of_lists[it].(u64);
        books.gap_list_of_lists[it] = (new_books_data_allocation + gap_array_offset_from_allocation_head).(*u8);
        flag_array_offset_from_allocation_head := books.flag_list_of_lists[it].(u64);
        books.flag_list_of_lists[it] = (new_books_data_allocation.(u64) + flag_array_offset_from_allocation_head).(*u64);
    }

    books_allocated_size = new_books_data_size;
    old_list_count = xx chunk_lists.count;
}

repr :: (using allocator: *Super_Allocator) -> string {
    builder: String_Builder;
    builder.allocator = temp;
    for list : 0..chunk_lists.count-1 {
        print_to_builder(*builder, "list %:\n", FormatInt.{value=list, minimum_digits=2});
        for chunk : 0..chunk_lists[list].count-1 {
            print_to_builder(*builder, "\tchunk %: [%|%]\n", 
                FormatInt.{value=chunk, minimum_digits=3}, 
                FormatInt.{value=books.gap_list_of_lists[list][chunk], minimum_digits=2},
                FormatInt.{value=books.flag_list_of_lists[list][chunk], base=2, minimum_digits=64},
            );
        }
    }
    return builder_to_string(*builder);
}

// 0: one byte gap per chunk list
// 1: array of gap bytes per chunk list, laid out one after another
// 2: align to 8 bytes
// 3: array of flag u64s per chunk list, laid out one after another
// 4. one slice per chunk list, each pointing into [1]
// 5. one slice per chunk list, each pointing into [3]

// books "array data offset" offsets to [4]

/*
Super_Allocator {
    books pointers:

    ----------- largest_gap_array_ptr    
    |     ----- lists_of_gaps_array_ptr 
    |     |     flag_set_array_ptr ---------------------------------------
    |     |                                                               |
    |     ------------------------------------------                      |
    v                                              V                      v
    [gaps data | lists_of_gaps data | flags data | [lists_of_gaps_ptrs] | [flags_ptrs]
                  ^    ^   ^   ^                    |  |   |   |           |   |  |  |
                  |    |   |   |--------------------   |   |   |           (point into the flags data. omitted arrows because diagram would get confusing)
                  |    |   |---------------------------|   |   |
                  |    |------------------------------------   |
                  |--------------------------------------------|

*/

// -----------------------------------------------------------------------------------
// --------------------------------------------------------------------- :GP_Allocator
// general purpose allocator
// release build, tight loops, tested ~50ns for small allocations and ~500ns for medium to large. 
// still probably needs work and likely has bugs. probably needs explicit debug support...

GP_Allocator :: struct {
    MIN_BIN_ITEM_SIZE :: 16;
    ITEMS_PER_LIST :: 128;
    INITIAL_LIST_COUNT_PER_BIN :: 50;
    using #as base: Allocator;
    bins: [8]GP_Bin;
    med_allocator: Super_Allocator(4096);
    lrg_allocator: Super_Allocator(131072);
    parent_allocator: Allocator;
}

GP_Bin :: struct {
    first_available : s32 = -1;
    lists: [..][]u8;
}

gp_allocator_proc :: (mode: Allocator_Mode, size: s64, old_size: s64, old_memory: *void, allocator: *void) -> *void {
    gp_allocator := allocator.(*GP_Allocator);
    if mode == {
    case .ALLOCATE;
        return gp_alloc(gp_allocator, size);
    case .RESIZE;
        new_allocation := gp_alloc(gp_allocator, size);
        if old_memory != null {
            memcpy(new_allocation, old_memory, min(size, old_size));
            gp_free(gp_allocator, xx old_memory);
        }
        return new_allocation;
    case .FREE;
        if old_memory != null {
            gp_free(gp_allocator, old_memory);
        }
    case .STARTUP;
    case .SHUTDOWN;
    case .THREAD_START;
    case .THREAD_STOP;
    case .CREATE_HEAP;
    case .DESTROY_HEAP;
    case .IS_THIS_YOURS;
    case .CAPS;
    }
    return null;
}

// last checked, defaults give ~70MB
initialize_gp_allocator :: (using allocator: *GP_Allocator, add_medium_chunk_lists := 4, add_large_chunk_lists := 1) {
    in_parent_allocator := context.allocator;
    allocator.* = .{parent_allocator=in_parent_allocator};
    base.data = allocator;
    base.proc = gp_allocator_proc;
    for *bin : bins {
        bin_index := it_index;
        for 1..INITIAL_LIST_COUNT_PER_BIN {
            gp_allocator_add_list(allocator, bin_index);
        }
    }
    initialize_super_allocator(allocator=*med_allocator, add_chunk_lists=add_medium_chunk_lists,, parent_allocator);
    initialize_super_allocator(allocator=*lrg_allocator, add_chunk_lists=add_large_chunk_lists,, parent_allocator);
}

gp_allocator_add_list :: (using allocator: *GP_Allocator, bin_index: s64) {
    assert(bin_index >= 0 && bin_index < bins.count);
    item_size := MIN_BIN_ITEM_SIZE << bin_index;
    list_size := item_size * ITEMS_PER_LIST;
    bin := *bins[bin_index];
    list := array_add(*bin.lists);
    list.data = alloc(item_size * ITEMS_PER_LIST,,parent_allocator);
    list.count = ITEMS_PER_LIST;

    item_index_begin : s32 = xx ((bin.lists.count - 1) * ITEMS_PER_LIST);
    for < 0..ITEMS_PER_LIST-2 {
        item_slot : *s32 = xx (list.data + item_size * it);
        item_slot.* = item_index_begin + (it.(s32) + 1);
    }

    final_slot : *s32 = xx (list.data + item_size * (ITEMS_PER_LIST - 1));
    if bin.first_available == -1 {
        final_slot.* = -1;
    } else {
        final_slot.* = bin.first_available;        
    }
    bin.first_available = item_index_begin;
}

gp_alloc :: (using allocator: *GP_Allocator, alloc_size: s64) -> *void {
    if alloc_size <= 0 {
        return null;
    } else if alloc_size <= (2048 - size_of(Allocation_Header)) {
        // small allocations, fast track
        alloc_size += size_of(Allocation_Header);
        bin_index := max(bit_scan_reverse((alloc_size-1) >> 3) - 1, 0);
        bin := *bins[bin_index];
        if bin.first_available == -1 {
            gp_allocator_add_list(allocator, bin_index);
        }
        assert(bin.first_available != -1);
        item_size := MIN_BIN_ITEM_SIZE << bin_index;
        list_index := bin.first_available / ITEMS_PER_LIST;
        item_index := bin.first_available - list_index * ITEMS_PER_LIST;
        allocation := bin.lists[list_index].data + item_index * item_size;

        bin.first_available = allocation.(*s32).*;

        allocation.(*Allocation_Header).id = xx ((Allocator_Identifier.GP_ALLOCATOR_16.(s32) + bin_index) | ALLOCATOR_VALIDATION_PATTERN);
        allocation.(*Allocation_Header).gp.list = xx list_index;

        return allocation + size_of(Allocation_Header);
    } else if alloc_size < (131072 - size_of(Allocation_Header)) {
        // medium allocations ~(2-130KB)
        allocation := super_alloc(*med_allocator, alloc_size);
        header := (allocation.(*u8) - size_of(Allocation_Header)).(*Allocation_Header);
        // overwrite the id so the allocator can be identified on free
        header.id = xx (Allocator_Identifier.GP_ALLOCATOR_SUPER_MED.(s32) | ALLOCATOR_VALIDATION_PATTERN);
        return allocation;
    } else {
        // large allocations (130KB+)
        allocation := super_alloc(*lrg_allocator, alloc_size);
        header := (allocation.(*u8) - size_of(Allocation_Header)).(*Allocation_Header);
        // overwrite the id so the allocator can be identified on free
        header.id = xx (Allocator_Identifier.GP_ALLOCATOR_SUPER_LRG.(s32) | ALLOCATOR_VALIDATION_PATTERN);
        return allocation;
    }
}

gp_free :: (using allocator: *GP_Allocator, addr: *u8) {
    header := (addr - size_of(Allocation_Header)).(*Allocation_Header);
    // log("free header address: %", header.(u64));
    identifier := (header.bit_pattern & 0x0f).(Allocator_Identifier);
    if identifier >= .GP_ALLOCATOR_16 && identifier <= .GP_ALLOCATOR_2048 {
        assert((header.bit_pattern & 0xf0) == ALLOCATOR_VALIDATION_PATTERN, "bad validation bits %", (header.bit_pattern & 0xf0));
        bin_index := (identifier - .GP_ALLOCATOR_16).(s64);
        item_size := MIN_BIN_ITEM_SIZE << bin_index;
        bin := *bins[bin_index];
        list_index := header.gp.list;
        list_data_begin := bin.lists[list_index].data;
        list_data_end   := list_data_begin + item_size * ITEMS_PER_LIST;
        assert(header.(*u8) >= list_data_begin && header.(*u8) < list_data_end);
        header.(*s32).* = bin.first_available;
        item_index := (header.(*u8) - list_data_begin) / item_size;
        bin.first_available = xx (list_index * ITEMS_PER_LIST + item_index);
    } else if identifier == {
    case .GP_ALLOCATOR_SUPER_MED;
        // this id was overwritten so it could be directed to the medium allocator. need to fix it so the super allocator can validate
        header.id = xx (Allocator_Identifier.SUPER_ALLOCATOR.(s32) | ALLOCATOR_VALIDATION_PATTERN);
        super_free(*med_allocator, addr);
    case .GP_ALLOCATOR_SUPER_LRG;
        // this id was overwritten so it could be directed to the large allocator. need to fix it so the super allocator can validate
        header.id = xx (Allocator_Identifier.SUPER_ALLOCATOR.(s32) | ALLOCATOR_VALIDATION_PATTERN);
        super_free(*lrg_allocator, addr);
    case;
        assert(false, "invalid id for allocation %", identifier);
    }
}

// -----------------------------------------------------------------------------------
// --------------------------------------------------------------------- :No_Allocator

no_allocator_proc :: (mode: Allocator_Mode, size: s64, old_size: s64, old_memory: *void, allocator_data: *void) -> *void {
    if mode == {
    case .CREATE_HEAP; #through;
    case .ALLOCATE;
        assert(false, "no_allocator is not supposed to allocate");
    case .RESIZE;
        if size <= old_size {
            return old_memory;
        }
        assert(false, "no_allocator is not supposed to allocate");
    case .IS_THIS_YOURS;
        assert(false, "no_allocator is not able to answer if an allocation belongs to it");
    case .FREE;
    case .DESTROY_HEAP;
    case .STARTUP;
    case .SHUTDOWN;
    case .THREAD_START;
    case .THREAD_STOP;
    };
    return null;
}

no_allocator := Allocator.{proc=no_allocator_proc};

// -----------------------------------------------------------------------------------

#scope_file

ALLOCATOR_VALIDATION_PATTERN : u8 : 0x70;
ALLOCATION_HEADER_SPACE :: #run ceil_to_power_of_two_multiple(size_of(Allocation_Header), 8);

Allocator_Identifier :: enum u8 {
    SUPER_ALLOCATOR :: 1;
    GP_ALLOCATOR_16;
    GP_ALLOCATOR_32;
    GP_ALLOCATOR_64;
    GP_ALLOCATOR_128;
    GP_ALLOCATOR_256;
    GP_ALLOCATOR_512;
    GP_ALLOCATOR_1024;
    GP_ALLOCATOR_2048;
    GP_ALLOCATOR_SUPER_MED;   
    GP_ALLOCATOR_SUPER_LRG;
}

largest_gap_in_bit_sequence_lsb :: inline (bits: $T) -> size: s8 {
    TYPE_BIT_COUNT :: (size_of(T) * 8);
    gap_size: s8;
    largest_gap_size: s8;
    for 0..TYPE_BIT_COUNT-1 {
        if (bits & xx ((1).(u64) << it)) == 0 {
            gap_size += 1;
            largest_gap_size = max(gap_size, largest_gap_size);
        } else {
            gap_size = 0;
        }
    }
    return largest_gap_size;
}

find_index_of_missing_bit_sequence_lsb :: inline (bits: $T, sequence: u64, sequence_bit_count: s64) -> s8 {
    TYPE_BIT_COUNT :: (size_of(T) * 8);
    assert(sequence_bit_count > 0 && sequence_bit_count <= TYPE_BIT_COUNT);
    shift_range := TYPE_BIT_COUNT - sequence_bit_count;
    for 0..shift_range {
        mask := sequence << it;
        if (bits & mask) == 0 {
            return xx it;
        }
    }
    return -1;
}

is_power_of_two :: inline (val: $T) -> bool {
    return val > 0 && (val & (val - 1)) == 0;
}

ceil_to_power_of_two_multiple :: inline (n: $T, power_of_two_size: T) -> T {
    assert(is_power_of_two(power_of_two_size));
    return (n + power_of_two_size-1) & ~(power_of_two_size-1);
}

div_ceil :: inline (a: $Int_Type, b: Int_Type) -> Int_Type 
#modify {
    return Int_Type.(*Type_Info).type == .INTEGER;
} {
    assert(a >= 0 && b > 0);
    return ((a - 1) / b) + 1;
}

make_static_array :: inline ($T: Type, count := 0) -> []T {
    array: []T;
    array_resize(*array, count);
    return array;
}

make_dynamic_array :: inline ($T: Type, reserve_count := 0) -> [..]T {
    array: [..]T;
    array.allocator = context.allocator;
    array_reserve(*array, reserve_count);
    return array;
}

// tiny serializer implementation for Super_Allocator stuff
// -----------------------------------------------------------------------------------

write_bytes :: (record: *[..]u8, record_head: *s64, bytes: *u8, byte_count: s64, align : s8 = 1) {
    if byte_count == 0 {
        return;
    }

    serial_align_head_up(record_head, align, record.count);
    new_head := record_head.* + byte_count;

    serial_writer_resize_if_needed(record, new_head);
    memcpy(record.data + record_head.*, bytes, byte_count);   

    record_head.* = new_head;
}

write_and_read_bytes :: (writer: *[..]u8, reader: []u8, writer_head: *s64, reader_head: *s64, byte_count: s64, align : s8 = 1) {
    if byte_count == 0 {
        return;
    }

    serial_align_head_up(reader_head, align, writer.count);
    serial_align_head_up(writer_head, align, reader.count);
    new_reader_head := reader_head.* + byte_count;
    new_writer_head := writer_head.* + byte_count;

    serial_writer_resize_if_needed(writer, new_writer_head);
    assert(reader_head.* <= reader.count);
    memcpy(writer.data + writer_head.*, reader.data + reader_head.*, byte_count);

    reader_head.* = new_reader_head;
    writer_head.* = new_writer_head;
}

serial_writer_resize_if_needed :: (record: *[..]u8, new_head: s64) {
    if new_head >= record.count {
        array_resize(record, new_head, false);
    }
}

serial_advance_head :: inline (record_head: *s64, by_count: s64, memory_size: s64) {
    new_head := record_head.* + by_count;
    assert(by_count > 0);
    assert(record_head.* >= 0 && record_head.* <= memory_size);
    assert(new_head <= memory_size);
    record_head.* = new_head;
}

serial_align_head_up :: (record_head: *s64, align: s8, memory_size: s64) {
    new_head := ceil_to_power_of_two_multiple(record_head.*, align);
    diff := new_head - record_head.*;
    if diff > 0 {
        serial_advance_head(record_head, diff, memory_size);
    } else assert(diff == 0);
}

// -----------------------------------------------------------------------------------

did_small_chunk_count_warning := false;

#import "Basic";
#import "Math";
#import "Bit_Operations";
#import "md5";
#import "File";

// MIT License
// Copyright (c) 2026 Trace Myers
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
