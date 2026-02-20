#module_parameters()(
    // must be true if you want to use TeRM vulkan renderer
    IMPORT_VULKAN := false
);

// -- sections --
// Misc
// Bit_Array
// Pool
// Struct_Of_Arrays
// Linear_Table
// CT_Table

// -----------------------------------------------------------------------------------
// ----------------------------------------------------------------------------- :Misc

// for a given bit collection (u64 in items array), send a mask that represents a specific 
// sequence of bits, and search for a sequence where no mask 1's match any of the collection 1's.
// for example, pretending a collection is 8 bits:
// sequence/mask: 111
// collection: 10001001
//  bit index: 76543210
//                ^
// sequence can be found here, at lsb index 4
// index = 0 if the pattern exists when it begins at the least significant bit
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

// -----------------------------------------------------------------------------------
// ------------------------------------------------------------------------ :Bit_Array

Bit_Array :: struct($IN_GROUP_BIT_COUNT: int) {
    #run,stallable assert(is_power_of_two(IN_GROUP_BIT_COUNT) && IN_GROUP_BIT_COUNT <= 64);
    items: [..]u64;
    groups_bit_size: s32;
    GROUP_BIT_COUNT :: IN_GROUP_BIT_COUNT;
    GROUPS_PER_U64 :: 64 / GROUP_BIT_COUNT;
    GROUP_INDEXING_SHIFT :: #run,stallable _bit_scan_forward(GROUPS_PER_U64) - 1;
    GROUP_BASE_MASK :: #run,stallable bit_array_group_base_mask(IN_GROUP_BIT_COUNT);
}

set_capacity :: inline (using array: *Bit_Array($COUNT), in_group_count: s64) {
    groups_bit_size = xx (in_group_count * GROUP_BIT_COUNT);
    items_count := div_ceil(in_group_count, GROUPS_PER_U64);
    array_resize(*items, items_count);
}

add_bit_set :: (using array: *Bit_Array($COUNT)) {
    _ := array_add(*items);
    groups_bit_size = items.count * GROUPS_PER_U64;
}

bit_array_group_base_mask :: inline (bit_group_count: int) -> u64  {
    return ifx bit_group_count == 64 then (~0).(u64) else ((1 << bit_group_count) - 1).(u64,force);
}

get_group_count :: inline (using array: *Bit_Array($COUNT)) -> s64 {
    return groups_bit_size / GROUP_BIT_COUNT;
}

get_count :: get_group_count;

single_bit_mask :: inline (using array: *Bit_Array($COUNT), group: s64, in_group_index: s64) -> s64, u64 {
    assert(group < get_group_count(array));
    assert(in_group_index >= 0 && in_group_index <= GROUP_BIT_COUNT);
    items_index := group >> GROUP_INDEXING_SHIFT;
    truncated_group_index := items_index << GROUP_INDEXING_SHIFT;
    group_index_in_u64 := group - truncated_group_index;
    bit_mask := (1 << (group_index_in_u64 * GROUP_BIT_COUNT + in_group_index)).(u64,no_check);
    return items_index, bit_mask;
}

group_bit_mask :: inline (using array: *Bit_Array($COUNT), group: s64) -> s64, u64 {
    assert(group < get_group_count(array));
    items_index := group >> GROUP_INDEXING_SHIFT;
    truncated_group_index := items_index << GROUP_INDEXING_SHIFT;
    group_index_in_u64 := group - truncated_group_index;
    return items_index, GROUP_BASE_MASK << (group_index_in_u64 * GROUP_BIT_COUNT);
}

set_bit :: inline (using array: *Bit_Array($COUNT), group: s64, in_group_index := 0) {
    assert(group < get_group_count(array), "group: %, groups bit size: %", group, groups_bit_size);
    index, mask := single_bit_mask(array, group, in_group_index);
    items[index] |= mask;
}

unset_bit :: inline (using array: *Bit_Array($COUNT), group: s64, in_group_index := 0) {
    assert(group < get_group_count(array));
    index, mask := single_bit_mask(array, group, in_group_index);
    items[index] &= ~mask;
}

is_bit_set :: inline (using array: *Bit_Array($COUNT), group: s64, in_group_index := 0) -> bool {
    assert(group < get_group_count(array));
    index, mask := single_bit_mask(array, group, in_group_index);
    return (items[index] & mask) != 0;
}

set_bit_group :: inline (using array: *Bit_Array($COUNT), group: s64) {
    assert(group < get_group_count(array));
    index, mask := group_bit_mask(array, group);
    items[index] |= mask;
}

unset_bit_group :: inline (using array: *Bit_Array($COUNT), group: s64) {
    assert(group < get_group_count(array));
    index, mask := group_bit_mask(array, group);
    items[index] &= ~mask;
}

any_bits_in_group_set :: inline (using array: *Bit_Array($COUNT), group: s64) -> bool {
    assert(group < get_group_count(array));
    index, mask := group_bit_mask(array, group);
    return (items[index] & mask) != 0;
}

all_bits_in_group_set :: inline (using array: *Bit_Array($COUNT), group: s64) -> bool {
    assert(group < get_group_count(array));
    index, mask := group_bit_mask(array, group);
    return (items[index] & mask) == mask;
}

set_all :: inline (using array: *Bit_Array($COUNT)) {
    if items.count > 0 {
        memset(items.data, 0xff, items.count * size_of(u64));
    }
}

unset_all :: inline (using array: *Bit_Array($COUNT)) {
    if items.count > 0 {
        memset(items.data, 0x00, items.count * size_of(u64));
    }
}

reset :: inline (using array: *Bit_Array($COUNT), keep_memory := false) {
    if keep_memory {
        array_reset_keeping_memory(*items);
    } else {
        array_reset(*items);
    }
}

// if in_group_index == -1, search for a group with any unset bits. else, search for a group with a bit unset at in_group_index
find_first_group_with_unset_bits :: (using array: *Bit_Array($COUNT), in_group_index := -1, start_group := 0, $ENFORCE_BITS_PER_GROUP:s64=0) -> group: s64 {
    // couldn't get modify to work for this
    #if ENFORCE_BITS_PER_GROUP != 0 {
        assert(ENFORCE_BITS_PER_GROUP == COUNT); 
    }
    start_item := start_group >> GROUP_INDEXING_SHIFT;
    start_group_in_item := start_group - (start_item << GROUP_INDEXING_SHIFT);
    if start_item >= items.count || start_item < 0 {
        return -1;
    }

    // the ability to start scanning from a specific group index adds significant complication in order
    // to keep this function as performant as possible for large data.
    // the first part here is checking to see if the first bit collection, excluding ignored groups at the
    // beginning, has the kind of gap that is being searched for

    ignore_groups_mask : u64 = 0;
    if start_group_in_item > 0 then for 0..start_group_in_item-1 {
        ignore_groups_mask |= GROUP_BASE_MASK << (it * GROUP_BIT_COUNT);
    }

    ref_mask, collection_mask := make_search_masks(array, in_group_index);

    first_bit_collection_with_ignored_groups := items[start_item] | ignore_groups_mask;
    if (first_bit_collection_with_ignored_groups & collection_mask) != collection_mask {
        #if GROUPS_PER_U64 == 64 {
            return_group_index_1_bit_groups(get_group_count(array), first_bit_collection_with_ignored_groups, start_item, true, true);
        } else {
            return_group_index_n_bit_groups(GROUPS_PER_U64, GROUP_BIT_COUNT, get_group_count(array), first_bit_collection_with_ignored_groups, start_item, ref_mask, true, true);;
        }
    }

    // after searching the first bit collection, it gets simpler to search the rest, because there are
    // no more ignored groups.

    iter_ct := items.count - start_item;
    if iter_ct > 1 {
        #if GROUPS_PER_U64 == 64 {
            for i: start_item+1..items.count-1 {
                bit_collection := items[i];
                if bit_collection == 0xffff_ffff_ffff_ffff {
                    continue;
                }
                return_group_index_1_bit_groups(get_group_count(array), bit_collection, i, true, true);
            }
        } else {
            for i: start_item+1..items.count-1 {
                bit_collection := items[i];
                if (bit_collection & collection_mask) == collection_mask {
                    continue;
                }
                return_group_index_n_bit_groups(GROUPS_PER_U64, GROUP_BIT_COUNT, get_group_count(array), bit_collection, i, ref_mask, true, true);
            }
        }
    }
    return -1;
}
find_first_unset_bit :: #bake_arguments find_first_group_with_unset_bits(ENFORCE_BITS_PER_GROUP=1);

// see comments in the forward search proc for some detail
find_last_group_with_unset_bits :: (using array: *Bit_Array($COUNT), in_group_index := -1, start_group := -1, $ENFORCE_BITS_PER_GROUP:=0) -> group: s64 {
    // couldn't get modify to work for this
    #if ENFORCE_BITS_PER_GROUP != 0 {
        assert(ENFORCE_BITS_PER_GROUP == COUNT); 
    }
    if start_group == -1 {
        start_group = get_group_count(array) - 1;
    }
    start_item := start_group >> GROUP_INDEXING_SHIFT;
    start_group_in_item := start_group - (start_item << GROUP_INDEXING_SHIFT);
    if start_item >= items.count || start_item < 0 {
        return -1;
    }

    ignore_groups_mask : u64 = 0;
    if start_group_in_item < (GROUPS_PER_U64 - 1) then for < start_group_in_item+1..GROUPS_PER_U64-1 {
        ignore_groups_mask |= GROUP_BASE_MASK << (it * GROUP_BIT_COUNT);
    }

    ref_mask, collection_mask := make_search_masks(array, in_group_index);

    first_bit_collection_with_ignored_groups := items[start_item] | ignore_groups_mask;
    if (first_bit_collection_with_ignored_groups & collection_mask) != collection_mask {
        #if GROUPS_PER_U64 == 64 {
            return_group_index_1_bit_groups(get_group_count(array), first_bit_collection_with_ignored_groups, start_item, false, true);
        } else {
            return_group_index_n_bit_groups(GROUPS_PER_U64, GROUP_BIT_COUNT, get_group_count(array), first_bit_collection_with_ignored_groups, start_item, ref_mask, false, true);;
        }
    }

    iter_ct := start_item + 1;
    if iter_ct > 1 {
        #if GROUPS_PER_U64 == 64 {
            for < i: 0..start_item-1 {
                bit_collection := items[i];
                if bit_collection == 0xffff_ffff_ffff_ffff {
                    continue;
                }
                return_group_index_1_bit_groups(get_group_count(array), bit_collection, i, false, true);
            }
        } else {
            for < i: 0..start_item-1 {
                bit_collection := items[i];
                if (bit_collection & collection_mask) == collection_mask {
                    continue;
                }
                return_group_index_n_bit_groups(GROUPS_PER_U64, GROUP_BIT_COUNT, get_group_count(array), bit_collection, i, ref_mask, false, true);
            }
        }
    }
    return -1;
}
find_last_unset_bit :: #bake_arguments find_last_group_with_unset_bits(ENFORCE_BITS_PER_GROUP=1);

find_last_group_with_set_bits :: (using array: *Bit_Array($COUNT), in_group_index := -1, start_group := -1, $ENFORCE_BITS_PER_GROUP:=0) -> group: s64 {
    // couldn't get modify to work for this
    #if ENFORCE_BITS_PER_GROUP != 0 {
        assert(ENFORCE_BITS_PER_GROUP == COUNT); 
    }
    if start_group == -1 {
        start_group = get_group_count(array) - 1;
    }
    start_item := start_group >> GROUP_INDEXING_SHIFT;
    start_group_in_item := start_group - (start_item << GROUP_INDEXING_SHIFT);
    if start_item >= items.count || start_item < 0 {
        return -1;
    }

    ignore_groups_mask : u64 = 0;
    if start_group_in_item < (GROUPS_PER_U64 - 1) then for < start_group_in_item+1..GROUPS_PER_U64-1 {
        ignore_groups_mask |= GROUP_BASE_MASK << (it * GROUP_BIT_COUNT);
    }
    ignore_groups_mask = ~ignore_groups_mask;

    ref_mask, collection_mask := make_search_masks(array, in_group_index);

    first_bit_collection_with_ignored_groups := items[start_item] & ignore_groups_mask;
    if (first_bit_collection_with_ignored_groups & collection_mask) != 0 {
        #if GROUPS_PER_U64 == 64 {
            return_group_index_1_bit_groups(get_group_count(array), first_bit_collection_with_ignored_groups, start_item, false, false);
        } else {
            return_group_index_n_bit_groups(GROUPS_PER_U64, GROUP_BIT_COUNT, get_group_count(array), first_bit_collection_with_ignored_groups, start_item, ref_mask, false, false);
        }
    }

    iter_ct := start_item + 1;
    if iter_ct > 1 {
        #if GROUPS_PER_U64 == 64 {
            for < i: 0..start_item-1 {
                bit_collection := items[i];
                if bit_collection == 0 {
                    continue;
                }
                return_group_index_1_bit_groups(get_group_count(array), bit_collection, i, false, false);
            }
        } else {
            for < i: 0..start_item-1 {
                bit_collection := items[i];
                if (bit_collection & collection_mask) == 0 {
                    continue;
                }
                return_group_index_n_bit_groups(GROUPS_PER_U64, GROUP_BIT_COUNT, get_group_count(array), bit_collection, i, ref_mask, false, false);
            }
        }
    }
    return -1;
}
find_last_set_bit :: #bake_arguments find_last_group_with_set_bits(ENFORCE_BITS_PER_GROUP=1);

find_first_group_with_set_bits :: (using array: *Bit_Array($COUNT), in_group_index := -1, start_group := 0, $ENFORCE_BITS_PER_GROUP:=0) -> group: s64 {
    // couldn't get modify to work for this
    #if ENFORCE_BITS_PER_GROUP != 0 {
        assert(ENFORCE_BITS_PER_GROUP == COUNT); 
    }
    start_item := start_group >> GROUP_INDEXING_SHIFT;
    start_group_in_item := start_group - (start_item << GROUP_INDEXING_SHIFT);
    if start_item >= items.count || start_item < 0 {
        return -1;
    }

    ignore_groups_mask : u64 = 0;
    if start_group_in_item > 0 then for 0..start_group_in_item-1 {
        ignore_groups_mask |= GROUP_BASE_MASK << (it * GROUP_BIT_COUNT);
    }
    ignore_groups_mask = ~ignore_groups_mask;

    ref_mask, collection_mask := make_search_masks(array, in_group_index);

    first_bit_collection_with_ignored_groups := items[start_item] & ignore_groups_mask;
    if (first_bit_collection_with_ignored_groups & collection_mask) != 0 {
        #if GROUPS_PER_U64 == 64 {
            return_group_index_1_bit_groups(get_group_count(array), first_bit_collection_with_ignored_groups, start_item, true, false);
        } else {
            return_group_index_n_bit_groups(GROUPS_PER_U64, GROUP_BIT_COUNT, get_group_count(array), first_bit_collection_with_ignored_groups, start_item, ref_mask, true, false);
        }
    }

    iter_ct := items.count - start_item;
    if iter_ct > 1 {
        #if GROUPS_PER_U64 == 64 {
            for i: start_item+1..items.count-1 {
                bit_collection := items[i];
                if bit_collection == 0 {
                    continue;
                }
                return_group_index_1_bit_groups(get_group_count(array), bit_collection, i, true, false);
            }
        } else {
            for i: start_item+1..items.count-1 {
                bit_collection := items[i];
                if (bit_collection & collection_mask) == 0 {
                    continue;
                }
                return_group_index_n_bit_groups(GROUPS_PER_U64, GROUP_BIT_COUNT, get_group_count(array), bit_collection, i, ref_mask, true, false);
            }
        }
    }
    return -1;
}
find_first_set_bit :: #bake_arguments find_first_group_with_set_bits(ENFORCE_BITS_PER_GROUP=1);

group_to_bit_index :: inline (using array: *Bit_Array($COUNT), group: s64, in_group_index := 0) -> s64 {
    return group * GROUP_BIT_COUNT + in_group_index;
}

// needed to bring this in from Bit_Operations module, and make it *not* a macro, otherwise crash when using at compile time. not clear why.
_bit_scan_forward :: inline (input: $T) -> s32 {  // One plus the index of the first bit, when searching from LSB to MSB. A result of 0 means the input was 0.
    BITS :: size_of(T)*8;
    #if CPU == .X64 {
        #if BITS == 8 {  // There's no bsf for 8 bits. Sad.
            result: s16 = -1;
            #asm {
                movzxbw   temp:, input;
                bsf.16    result, temp;
            }
        } else {
            result: T = xx,no_check -1;
            #asm {
                bsf?T     result, input;
            }
        }
        return (result + 1).(s32,trunc);
    } else {
        // @Speed: Slow fallback for other CPUs.
        for i: 0..BITS-1 {
            if input & cast,no_check(T) (1 << i) return (i + 1).(s32);
        }
        return 0;
    }
}

#scope_file 

make_search_masks :: inline (using array: *Bit_Array($COUNT), in_group_index: s64) -> ref_mask: u64, collection_mask: u64 {
    ref_mask, collection_mask: u64 = ---;
    #if GROUPS_PER_U64 == 64 {
        collection_mask = 0xffff_ffff_ffff_ffff;
    } else {
        if in_group_index == -1 {
            ref_mask = GROUP_BASE_MASK;
            collection_mask = 0xffff_ffff_ffff_ffff;
        } else {
            _, ref_mask = single_bit_mask(array, 0, in_group_index);
            collection_mask = 0;
            for g: 0..GROUPS_PER_U64-1 {
                collection_mask |= ref_mask << (GROUP_BIT_COUNT * g);
            }
        }
    }
    return ref_mask, collection_mask;
}

return_group_index_1_bit_groups :: (in_group_count: s64, bit_collection: u64, collection_index: s64, $SEARCH_FORWARD: bool, $FINDING_GAP: bool) -> s64 #expand {
    #if SEARCH_FORWARD {
        #if FINDING_GAP {
            bit_index := ifx bit_collection == 0 then 0 else (_bit_scan_forward(~bit_collection) - 1).(s64);
        } else {
            bit_index := ifx bit_collection == 0 then 0 else (_bit_scan_forward(bit_collection) - 1).(s64);
        }
    } else {
        #if FINDING_GAP {
            bit_index := ifx bit_collection == 0 then 0 else (_bit_scan_reverse(~bit_collection) - 1).(s64);
        } else {
            bit_index := ifx bit_collection == 0 then 0 else (_bit_scan_reverse(bit_collection) - 1).(s64);
        }
    }
    group_index := collection_index * 64 + bit_index;
    `return ifx group_index >= in_group_count then -1 else group_index;
}

return_group_index_n_bit_groups :: (groups_per_u64: s64, group_bit_count: s64, in_group_count: s64, bit_collection: u64, collection_index: s64, mask: u64, $SEARCH_FORWARD: bool, $FINDING_GAP: bool) -> s64 #expand {
    #if SEARCH_FORWARD {
        for g: 0..groups_per_u64-1 {
            #if FINDING_GAP {
                match := (bit_collection & mask) != mask;
            } else {
                match := (bit_collection & mask) != 0;
            }
            if match {
                group_index := collection_index * groups_per_u64 + g;
                `return ifx group_index >= in_group_count then -1 else group_index;
            }
            mask <<= group_bit_count;
        }
    } else {
        for < g: 0..groups_per_u64-1 {
            reverse_search_mask := mask << (group_bit_count * g);
            #if FINDING_GAP {
                match := (bit_collection & reverse_search_mask) != reverse_search_mask;
            } else {
                match := (bit_collection & reverse_search_mask) != 0;
            }
            if match {
                group_index := collection_index * groups_per_u64 + g;
                `return ifx group_index >= in_group_count then -1 else group_index;
            }
        }
    }
    assert(false, tprint("failed to find a group with an unset bit even though the reference mask indicated it should exist. bit collection: 0x%, ref mask: %, u64 mask: %", _fib16(bit_collection,16), _fib16(`ref_mask,16), _fib16(`collection_mask,16)));
}


// tbh I just copied this because I had to copy the other one and I only need the two from the module.
_bit_scan_reverse :: inline (input: $T) -> s32 #expand {  // One plus the index of the first bit, when searching from MSB to LSB. A result of 0 means the input was 0.
    BITS :: size_of(T)*8;

    #if CPU == .X64 {
        #if BITS == 8 {
            result: s16 = -1;
            #asm {
                movzxbw   temp:, input;
                bsr.16    result, temp;
            }
        } else {
            result: T = xx,no_check -1;
            #asm {
                bsr?T     result, input;
            }
        }

        return cast,trunc(s32)(result + 1);
    } else {
        // @Speed: Slow fallback for other CPUs.
        for <i: 0..BITS-1 {
            if input & cast,no_check(T) (1 << i) return cast(s32) (i + 1);
        }

        return 0;
    }
}

is_power_of_two :: inline (val: $T) -> bool {
    return val > 0 && (val & (val - 1)) == 0;
}

// -----------------------------------------------------------------------------------
// ----------------------------------------------------------------------------- :Pool
#scope_export

Pool_Resize_Behavior :: enum {
    DEFAULT;
    ALLOW;
    DISALLOW;
}

Pool :: struct($Item_Type: Type) {
    items: [..]Item_Type;
    in_use: Bit_Array(1);
    top := -1;
    shrink_to_min : s32 = 0;
    allow_grow_default := true;
    allow_shrink_default := true;
}

pool_init :: (pool: *Pool, cap: s64) {
    pool.* = {};
    pool.items.allocator = context.allocator;
    pool.in_use.items.allocator = context.allocator;
    set_capacity(pool, cap);
}

pool_set_capacity :: (using pool: *Pool($T), cap: s64) {
    array_resize(*items, cap);
    set_capacity(*in_use, cap);    
}

pool_lock_allocation :: (using pool: *Pool($T)) {
    items.allocator = no_allocator;
    in_use.items.allocator = no_allocator;
    allow_grow_default = false;
    allow_shrink_default = false;
}

pool_reset :: (using pool: *Pool($T), deinit_item_proc: (*T) = null, keep_memory := false) {
    if in_use.items.count > 0 {
        assert(items.count <= get_group_count(*in_use));
        for 0..items.count-1 {
            if is_bit_set(*in_use, it) {
                deinit_item_proc(*items[it]);
            }
        }
        reset(*in_use, keep_memory);
        if keep_memory {
            array_reset_keeping_memory(*items);
        } else {
            array_reset(*items);
        }
    } else {
        assert(items.count == 0);
    }

    top = -1;
}

pool_acquire :: (using pool: *Pool($T), init_item_proc: (*T) = null, grow_behavior := Pool_Resize_Behavior.DEFAULT) -> s64 {
    index := find_first_unset_bit(*in_use);
    if index != -1 {
        set_bit(*in_use, index);
        if index > top then top = index;
        if init_item_proc then init_item_proc(*items[index]);
        return index;
    }

    do_allow_grow := ifx grow_behavior == .DEFAULT then allow_grow_default else grow_behavior == .ALLOW;
    if !do_allow_grow {
        return -1;
    }

    index = items.count;
    top = items.count;

    new_item_count := max(items.count * 2, 8);
    array_resize(*items, new_item_count);
    set_capacity(*in_use, new_item_count);
    set_bit(*in_use, index);
    if init_item_proc then init_item_proc(*items[index]);

    return index;
}

pool_release :: (using pool: *Pool($T), i: s64, deinit_item_proc: (*T) = null, shrink_behavior := Pool_Resize_Behavior.DEFAULT) {
    if deinit_item_proc then deinit_item_proc(*items[i]);

    unset_bit(*in_use, i);

    if i == top {
        top = find_last_set_bit(*in_use);
        do_allow_shrink := ifx shrink_behavior == .DEFAULT 
            then allow_shrink_default 
            else shrink_behavior == .ALLOW;

        if do_allow_shrink && items.count > shrink_to_min {
            required_count := top + 1;
            required_count = max(required_count, shrink_to_min);
            if required_count >= items.count then return;

            // div by 2 repeatedly until we find the threshold we're under
            test_threshold := items.count >> 1;
            while required_count < test_threshold {
                test_threshold >>= 1;
            }

            // only shrink by up to half the space we could shrink, to leave room for incoming adds
            test_threshold <<= 1;
            if test_threshold >= items.count then return;

            new_count := max(test_threshold, shrink_to_min);
            array_resize(*items, new_count);
            set_capacity(*in_use, new_count);
        }
    }
}

operator *[] :: inline (using pool: *Pool($T), i: s64) -> *T {
    assert(is_bit_set(*in_use, i));
    return *items[i];
}

pool_get :: inline (using pool: *Pool($T), i: s64) -> *T {
    return *items[i];
}

pool_find :: (using pool: *Pool($T1), user_data: $T2, compare_proc: (*T1, T2) -> bool) -> s64 {
    i := -1;
    while true {
        pre_iter_i := i;
        i = find_first_set_bit(*in_use, -1, i+1);
        if i == -1 then break;
        if compare_proc(*items[i], user_data) then return i;
        if i == pre_iter_i then i += 1;
    }
    return -1;
}

pool_get_index :: (using pool: *Pool($T), item: *T) -> s64 {
    i := item - items.data;
    if i < 0 || i > items.count {
        return -1;
    }
    return i;
}

pool_is_empty :: inline (using pool: *Pool($T)) -> bool {
    return top == -1;
}

is_pool_item_in_use :: inline (using pool: *Pool($T), i: s64) -> bool {
    return is_bit_set(*in_use, i);
}

// for pool { ... }
for_expansion :: (pool: Pool, body: Code, flags: For_Flags) #expand {
    if pool.top >= 0 then for <=((flags & .REVERSE) != 0) item_index : 0..pool.top {
        `it_index := item_index;
        if !is_item_in_use(*pool, item_index) {
            continue;
        }
        #if (flags & .POINTER) {
            `it := *pool.items[item_index];
        } else {
            `it := pool.items[item_index];
        }
        #insert body;
    }
}

// -----------------------------------------------------------------------------------
// ----------------------------------------------------------------- :Struct_Of_Arrays

// implementation that converts a type into a struct wherein each field is an array 
// corresponding a field of the struct.
// in other words, instead of storing your data like so:
//
// vectors: [..]Vector3;
//
// you can store it like so:
//
// vectors: Struct_Of_Arrays(Vector3, "xs", "ys", "zs");
//
// where the above type looks like this:
// {
//      xs: [..]float;
//      ys: [..]float;
//      zs: [..]float;
// }

Struct_Of_Arrays :: struct($item_type: Type, $array_field_names: ..string) {
    #insert -> string {
        builder: String_Builder;
        tinfo := item_type.(*Type_Info);
        assert(tinfo.type == .STRUCT);
        tinfo_struct := tinfo.(*Type_Info_Struct);

        field_index := 0;
        for member : tinfo_struct.members {
            if member.flags != 0 then continue;
            member_tinfo := member.type;
            member_type := (*member_tinfo).(*Type).*;
            print(*builder, "\t%: [..]%;\n", array_field_names[field_index], member_type);
            field_index += 1;
        }

        print(*builder, "ITEM_FIELD_NAMES :: string.[");
        for member : tinfo_struct.members {
            if member.flags != 0 then continue;
            print(*builder, "\"%\",", member.name);
        }
        print(*builder, "];\n");

        type_str := builder_to_string(*builder);
        return type_str;
    };
}

soa_for_each_array :: (soa: *Struct_Of_Arrays, operation: string, $declare_item_field_var := false) #expand {
    #insert -> string {
        builder: String_Builder;
        for 0..soa.array_field_names.count-1 {
            array_field_name := soa.array_field_names[it];
            item_field_name := soa.ITEM_FIELD_NAMES[it];
            print(*builder, "\t{\n");
            print(*builder, "\t\tarray := *soa.%;\n", array_field_name);
            #if declare_item_field_var {
                print(*builder, "\t\tfield := *`item.%;\n", item_field_name);
            }
            print(*builder, "#insert operation;");
            print(*builder, "\t}\n");
        }
        return builder_to_string(*builder);
    }
}

soa_set_allocator :: (soa: *Struct_Of_Arrays, allocator: Allocator) {
    soa_for_each_array(soa, "array.allocator = `allocator;");
}

soa_add :: (soa: *Struct_Of_Arrays, item: soa.item_type) {
    soa_for_each_array(soa, "array_add(array, field.*);", true);
}

soa_set :: (soa: *Struct_Of_Arrays, i: s64, item: soa.item_type) {
    soa_for_each_array(soa, "array.*[`i] = field.*;", true);
}

soa_get :: (soa: *Struct_Of_Arrays, i: s64) -> soa.item_type {
    item: soa.item_type = ---;
    soa_for_each_array(soa, "field.* = array.*[`i];", true);
    return item;
}

soa_unordered_remove_by_index :: (soa: *Struct_Of_Arrays, i: s64) {
    soa_for_each_array(soa, "array_unordered_remove_by_index(array, `i);");
}

soa_ordered_remove_by_index :: (soa: *Struct_Of_Arrays, i: s64) {
    soa_for_each_array(soa, "array_ordered_remove_by_index(array, `i);");
}

soa_resize :: (soa: *Struct_Of_Arrays, count: s64) {
    soa_for_each_array(soa, "array_resize(array, `count);");
}

soa_reserve :: (soa: *Struct_Of_Arrays, count: s64) {
    soa_for_each_array(soa, "array_reserve(array, `count);");
}

soa_reset :: (soa: *Struct_Of_Arrays) {
    soa_for_each_array(soa, "array_reset(array);");
}

soa_reset_keeping_memory :: (soa: *Struct_Of_Arrays) {
    soa_for_each_array(soa, "array_reset_keeping_memory(array);");
}

// -----------------------------------------------------------------------------------
// ----------------------------------------------------------------------- :Table_Base
// table interface

Table_Base :: struct($key_type: Type, $value_type: Type, $use_simple_key_hash: bool) {}

table_hash :: (table: *Table_Base, key: table.key_type) -> u32 {
    KEY_IS_STRING :: #run table.key_type == string;
    KEY_IS_ARRAY :: #run table.key_type.(*Type_Info).type == .ARRAY;
    hash_input: string = ---;
    #if KEY_IS_STRING && !table.use_simple_key_hash {
        hash_input = key;
    } else #if KEY_IS_ARRAY && !table.use_simple_key_hash {
        tinfo_array := table.key_type.(*Type_Info_Array);
        element_type := (*tinfo_array.element_type).(*Type).*;
        hash_input.data  = xx key.data;
        hash_input.count = key.count * size_of(element_type);
    } else {
        hash_input.data  = xx *key;
        hash_input.count = size_of(table.key_type);
    }
    return get_hash(hash_input);
}

// -----------------------------------------------------------------------------------
// --------------------------------------------------------------------- :Linear_Table
// a hash table that just does a linear lookup of the hash. stores stuff in parallel arrays
// so the hash lookup is cache friendly. value references remain valid until any operation 
// that causes a reallocation of the backing arrays

Table_Edit_Condition :: enum {
    ONLY_ADD;
    ONLY_CHANGE;
    ADD_OR_CHANGE;
}

Linear_Table :: struct($key_type: Type, $value_type: Type, $use_simple_key_hash := false) {
    Item :: struct {
        key_hash: u32;
        value: value_type;
    }
    using #as base: Table_Base(key_type, value_type, use_simple_key_hash);
    using #as soa: Struct_Of_Arrays(Item, "key_hashes", "values");
}

table_init :: (table: *Linear_Table, reserve_count := 64) {
    soa_reset_keeping_memory(*table);
    soa_reserve(*table, 64);
}

// return true if the value was added
table_set :: (table: *Linear_Table, key: table.key_type, value: table.value_type, edit_if := Table_Edit_Condition.ADD_OR_CHANGE) -> made_edit: bool, added_item: bool {
    key_hash := table_hash(table, key);
    existing_value := table_get_by_hash(table, key_hash);
    made_edit: bool;
    added_item: bool;

    if existing_value != null {
        #if edit_if == .ONLY_CHANGE || edit_if == .ADD_OR_CHANGE {
            existing_value.* = value;
            made_edit = true;
        }
    } else {
        #if edit_if == .ONLY_ADD || edit_if == .ADD_OR_CHANGE {
            soa_add(table, {key_hash, value});
            made_edit = true;
            added_item = true;
        }
    }

    return made_edit, added_item;
}

table_get :: (table: *Linear_Table, key: table.key_type) -> *table.value_type {
    key_hash := table_hash(table, key);
    return table_get_with_key_hash(table, key_hash); 
}

table_get_by_key_hash :: (table: *Linear_Table, key_hash: u32) -> *table.value_type {
    for table.key_hashes {
        if key_hash == key_hash {
            return *table.values[it_index];
        }
    }
    return null;
}

table_remove_by_key :: (table: *Linear_Table, key: table.key_type) -> bool {
    key_hash := table_hash(table, key);
    return table_remove_with_key_hash(table, key_hash);
}

table_remove_by_key_hash :: (table: *Linear_Table, key_hash: u32) -> bool {
    value := table_get_with_key_hash(table, key_hash);
    if value != null {
        index := value - table.values.data;
        soa_unordered_remove_by_index(table, index);
        return true;
    } else {
        return false;
    }
}

table_remove_by_value :: (table: *Linear_Table, value: table.value_type) {
    for table.values {
        if it == value {
            soa_unordered_remove_by_index(table, it_index);
            return true;
        }
    }
    return false;
}

operator *[] :: inline (table: *Linear_Table, key: table.key_type) -> *table.value_type {
    return table_get(table, key);
}

// -----------------------------------------------------------------------------------
// ------------------------------------------------------------------------- :CT_Table
// constant time lookup hash table, as in O(1) for average case
// stores values in intrusive lists (linked lists embedded in array)
// just a wild guess, probably overall better than Linear_Table for > 400 elements
// definitely not the final boss of tables, but good for me.

CT_Table_KV_Container :: struct($value_type: Type) {
    value: value_type;
    key_hash: u32;
    prev: s32 = -1;
    next: s32 = -1;
}

CT_Table :: struct($key_type: Type, $value_type: Type, $lookup_table_size := 8192) {
    using #as base: Table_Base(key_type, value_type, use_simple_key_hash);
    masked_hash_to_index: [lookup_table_size]s32;
    kv_containers: Pool(CT_Table_KV_Container);

    #run assert(is_power_of_two(lookup_table_size));
    #run assert(lookup_table_size >= 8);
    #run assert(lookup_table_size < U32_MAX_VALUE);
}

table_init :: (table: *CT_Table, reserve_count := 256) {
    for *table.masked_hash_to_index {
        it.* = -1;
    }
    pool_init(*table.kv_containers, reserve_count);
}

table_set :: (table: *CT_Table, key: table.key_type, value: table.value_type, edit_if := Table_Edit_Condition.ADD_OR_CHANGE) -> made_edit: bool, added_item: bool {
    key_hash := table_hash(table, key);
    existing_value, searched_up_to_index := table_get_by_hash(table, key_hash);
    made_edit: bool;
    added_item: bool;

    if existing_value != null {
        #if edit_if == .ONLY_CHANGE || edit_if == .ADD_OR_CHANGE {
            existing_value.* = value;

            made_edit = true;
        }
    } else {
        #if edit_if == .ONLY_ADD || edit_if == .ADD_OR_CHANGE {
            container_index : s32 = xx pool_acquire(*table.kv_containers);
            if searched_up_to_index == -1 {
                // container list is empty
                lut_i := lut_index(table, key_hash);
                table.masked_hash_to_index[lut_i] = container_index;
            } else {
                // append to end of container list
                kv_containers[searched_up_to_index].next = container_index;
            }

            new_container := *kv_containers[container_index];
            new_container.key_hash = key_hash;
            new_container.value = value;
            new_container.prev = searched_up_to_index;
            new_container.next = -1;

            added_item = true;
            made_edit = true;
        }
    }

    return made_edit, added_item;
}

table_get :: (table: *CT_Table, key: table.key_type) -> *table.value_type {
    key_hash := table_hash(table, key);
    return table_get_with_key_hash(table, key_hash); 
}

table_get_by_key_hash :: (table: *CT_Table, key_hash: u32) -> value: *table.value_type, searched_up_to_index: s32 {
    lut_i := lut_index(table, key_hash);
    itm_i := table.masked_hash_to_index[lut_i];

    if itm_i == -1 then return null, -1;

    container := *table.kv_containers[itm_i];
    assert(container.prev == -1);

    ITER_MAX :: kv_containers.count;
    i := 0;
    while i < ITER_MAX {
        defer i += 1;
        if container.key_hash == key_hash    then return *container.value, itm_i;
        if container.next == -1              then break;
        itm_i = container.next;
        container = *table.kv_containers[itm_i];
    }

    return null, itm_i;
}

table_remove_by_key :: (table: *CT_Table, key: table.key_type) -> bool {
    key_hash := table_hash(table, key);
    return table_remove_with_key_hash(table, key_hash);
}

table_remove_by_key_hash :: (table: *CT_Table, key_hash: u32) -> bool {
    value, searched_up_to_index := table_get_by_key_hash(table, key_hash);
    if value == null {
        return false;
    }
    container := container_of_value(value);
    table_remove_container(table, container);
    return true;
}


table_remove_by_value :: (table: *CT_Table, value: table.value_type) {
    for *table.kv_containers {
        if it.value == value {
            table_remove_container(table, it);
            return true;
        }
    }
    return false;
}

operator *[] :: inline (table: *CT_Table, key: table.key_type) -> *table.value_type {
    return table_get(table, key);
}

#scope_file

lut_index :: inline (table: *CT_Table, hash: u32) -> u32 {
    return hash & (table.lookup_table_size.(u32) - 1);
}

container_of_value :: inline (table: *CT_Table, value: *table.value_type) -> *CT_Table_KV_Container {
    dummy_container_ptr: *CT_Table_KV_Container = null;
    byte_offset_to_value_in_container := (*dummy_container_ptr.value).(s64);
    container := ((value.(s64) - byte_offset_to_value_in_container)).(*CT_Table_KV_Container);
    return container;
}

table_remove_container :: (table: *CT_Table, container: *CT_Table_KV_Container) {
    // --- 

    update_list_head :: () #expand {
        lut_i := lut_index(`table, `container.key_hash);
        assert(`table.masked_hash_to_index[lut_i] == `container_index);
        `table.masked_hash_to_index[lut_i] = `container.next;
    }

    // ---

    container_index : s32 = xx (container - table.kv_containers.items.data);

    if container.prev != -1 {
        // this container has a parent that needs to be updated
        assert(table.kv_containers[container.prev].next == container_index);
        table.kv_containers[container.prev].next = container.next;
    } else {
        // this container is first in list, so need to move the head
        update_list_head();
    }

    if container.next != -1 {
        // this container has a child that needs to be updated
        assert(table.kv_containers[container.next].prev == container_index);
        table.kv_containers[container.next].prev = container.prev;
        if container.prev == -1 {
            // if this container was the head of the list, need to move the head
            update_list_head();
        }
    }

    pool_release(*table.kv_containers, container_index); 
}

// ------

#scope_file

div_ceil :: inline (a: $Int_Type, b: Int_Type) -> Int_Type 
#modify {
    return Int_Type.(*Type_Info).type == .INTEGER;
} {
    assert(a >= 0 && b > 0);
    return ((a - 1) / b) + 1;
}

_fib16 :: (int_val: $T, min_digits := 0) -> FormatInt #expand {
    return FormatInt.{value=int_val, base=16, minimum_digits=min_digits};
}

U32_MAX_VALUE :: 0xffff_ffff;

#import "Basic";
#import "String";
#import "Hash";

#if IMPORT_VULKAN {
    #import "TeRM/TeRM_Render/vulkan-jai";
}

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
