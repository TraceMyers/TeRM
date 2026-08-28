// -- sections --
// Misc
// Bit_Array Helpers
// Pool
// Struct_Of_Arrays
// Hybrid_Array
// Ring_Buffer

// -----------------------------------------------------------------------------------
// ----------------------------------------------------------------------------- :Misc

// for a given bit collection (u64), send a mask that represents a specific 
// sequence of bits, and search for a sequence where no mask 1's match any of the collection 1's.
// for example, pretending a collection is 8 bits:
// sequence/mask: 111
//              111     < matched below to 000
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
// ---------------------------------------------------------------- :Bit_Array Helpers
// just a couple of for expansions for iterating over only cleared or only set bits. reverse
// iteration was also added, where the base for expansion did not implement that.
//
// this is particularly useful for allocation algorithms that want to find the front or back bit
// that is set or cleared, since they will exit the loop on the front valid slot.
//
// in other words...
//
// for bit arrays that looks something like this (imagining slots are 8 bits instead of 64)
// 
// [ 1 1 1 1 1 1 1 1 ] [ 1 1 1 1 1 1 1 1 ] [ 1 1 0 1 1 0 1 0 ]
//
// and given you want to find the front cleared bit, you clearly don't need to search
// into the front two slots. only when you reach slot 3 should you search the bits to find a 0.
//
// when the bit array becomes hundreds or thousands of slots long, this two stage search
// save a lot of time.

// for expansion for iterating over only '1' bits in a bit array. 
// usage looks like...
// for :only_set_bits your_bit_array { ... }
only_set_bits     :: #bake_arguments only_set_or_only_cleared_bits(set_or_cleared=.SET);
// for expansion for iterating over only '0' bits in a bit array. 
// usage looks like...
// for :only_cleared_bits your_bit_array { ... }
only_cleared_bits :: #bake_arguments only_set_or_only_cleared_bits(set_or_cleared=.CLEARED);

// definition for the above for expansions
only_set_or_only_cleared_bits :: (array: *Bit_Array, body: Code, flags: For_Flags, $set_or_cleared: enum {SET; CLEARED;}) #expand {
    #assert((flags & .POINTER) == 0);

    // you already know whether it's set or cleared, so this is sort of performative,
    // but I figured it makes sense to keep it this way for consistency with
    // the base for expansion def
    `it := #ifx set_or_cleared == .SET then 1 else 0;

    // the other reason this exists is to add reverse iteration, which the pool uses.
    for <=((flags & .REVERSE) != 0) slot, slot_index: array.slots {

        // one reason this expansion exists. skip over slots that have no candidate bits.
        #if set_or_cleared == .SET {
            if slot == 0 then continue;
        } else {
            if slot == BIT_ARRAY_SLOT_MAX_VALUE then continue;
        }
        
        base_index := slot_index * BIT_ARRAY_SLOT_BIT_COUNT;
        limit      := min(array.count - base_index - 1, BIT_ARRAY_SLOT_BIT_COUNT - 1);  // Don't go past the number of bits that are actually stored.

        #if (flags & .REVERSE) != 0 {
            bit := 1 << limit;
        } else {
            bit := 1;
        }

        for i: 0..limit {
            #if set_or_cleared == .SET {
                found_set_or_cleared_bit := (slot & bit) != 0;
            } else { // CLEARED
                found_set_or_cleared_bit := (slot & bit) == 0;
            }

            #if (flags & .REVERSE) != 0 {
                bit >>= 1;
            } else {
                bit <<= 1;
            }

            if found_set_or_cleared_bit {
                #if (flags & .REVERSE) != 0 {
                    `it_index := base_index + (limit - i);
                } else {
                    `it_index := base_index + i;
                }

                #insert (remove=#assert(false), break=break slot) body;
            }
        }            
    }
}

// -----------------------------------------------------------------------------------
// ----------------------------------------------------------------------------- :Pool

Pool_Resize_Behavior :: enum {
    DEFAULT;
    ALLOW;
    DISALLOW;
}

Pool :: struct($Item_Type: Type) {
    items: [..]Item_Type;
    in_use: Bit_Array;
    top := -1;
    shrink_to_min : s32 = 0;
    allow_grow_default := true;
    allow_shrink_default := true;
}

pool_init :: (pool: *Pool, cap: s64, lock_allocation := false) {
    pool.* = {};
    pool_set_allocator(pool, context.allocator);
    pool_set_capacity(pool, cap);
    if lock_allocation {
        pool_lock_allocation(pool);
    }
}

pool_set_capacity :: (using pool: *Pool($T), cap: s64) {
    array_resize(*items, cap);
    resize_in_use(pool, cap);
}

pool_set_allocator :: (using pool: *Pool($T), allocator: Allocator) {
    items.allocator = allocator;
    in_use.allocator = allocator; 
}

pool_lock_allocation :: (using pool: *Pool($T)) {
    pool_set_allocator(pool, no_allocator);
    allow_grow_default = false;
    allow_shrink_default = false;
}

pool_reset :: (using pool: *Pool($T), deinit_item_proc: (*T) = null) {
    if deinit_item_proc != null {
        for *(pool.*) {
            deinit_item_proc(it);
        }
    }
    array_reset(*items);
    resize_in_use(pool, 0);
    top = -1;
}

pool_reset_keeping_memory :: (using pool: *Pool($T), deinit_item_proc: (*T) = null) {
    if deinit_item_proc != null {
        for *(pool.*) {
            deinit_item_proc(it);
        }
    }
    clear_all_bits(*in_use);
    top = -1;
}

pool_borrow :: (using pool: *Pool($T), init_item_proc: (*T) = null, grow_behavior := Pool_Resize_Behavior.DEFAULT) -> s64 {
    index: s64 = -1;

    if items.data != null then for :only_cleared_bits in_use {
        index = it_index;
        break;
    }

    if index != -1 {
        set_bit(*in_use, index);
        if index > top then top = index;
        if top >= items.count {
            assert(top < items.allocated);
            items.count = top + 1;
        }
        #if type_info(T).type == .STRUCT {
            items[index] = {};
        } else {
            items[index] = 0;
        }
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
    pool_set_capacity(pool, new_item_count);
    set_bit(*in_use, index);
    #if type_info(T).type == .STRUCT {
        items[index] = {};
    } else {
        items[index] = 0;
    }
    if init_item_proc then init_item_proc(*items[index]);

    return index;
}

pool_return :: inline (pool: *Pool($T), item: *T, deinit_item_proc: (*T) = null, shrink_behavior := Pool_Resize_Behavior.DEFAULT) {
    pool_return(pool, pool_get_index(pool, item), deinit_item_proc, shrink_behavior);
}

pool_return :: (using pool: *Pool($T), i: s64, deinit_item_proc: (*T) = null, shrink_behavior := Pool_Resize_Behavior.DEFAULT) {
    if deinit_item_proc then deinit_item_proc(*items[i]);

    clear_bit(*in_use, i);

    if i == top {
        top = -1;
        for < :only_set_bits in_use {
            top = it_index;
            break;
        }

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
            new_cap := max(test_threshold << 1, required_count);
            if new_cap < items.count {
                pool_set_capacity(pool, new_cap);
            }
        }
    }
}

operator *[] :: inline (using pool: *Pool($T), i: s64) -> *T {
    return pool_get(pool, i);
}

pool_get :: inline (using pool: *Pool($T), i: s64) -> *T {
    assert(in_use[i]);
    return *items[i];
}

pool_find :: (using pool: *Pool($T1), user_data: $T2, compare_proc: (*T1, T2) -> bool) -> s64 {
    i := -1;
    for :only_set_bits in_use {
        if compare_proc(*items[it_index], user_data) then return it_index;
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

// todo: delete? meh
is_pool_item_in_use :: inline (using pool: *Pool($T), i: s64) -> bool {
    return in_use[i];
}

// for my_pool { ... }
for_expansion :: (pool: Pool($T), body: Code, flags: For_Flags) #expand {
    if pool.top >= 0 {
        for <=((flags & .REVERSE) != 0) item_index : 0..pool.top {
            `it_index := item_index;
            if !is_pool_item_in_use(*pool, item_index) {
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
}

#scope_file

resize_in_use :: (using pool: *Pool($T), new_count: s64) {
    if new_count == 0 {
        deinit(*in_use);
        in_use.count = 0;
        in_use.slots.count = 0;
    } else if new_count > in_use.count {
        old_allocation := in_use.slots.data;
        old_allocation_size := in_use.slots.count * BIT_ARRAY_SLOT_SIZE;
        in_use.count = 0;
        in_use.slots.count = 0;
        in_use.slots.data = null;
        init_bit_array(*in_use, new_count);
        if old_allocation_size > 0 {
            new_allocation_size := in_use.slots.count * BIT_ARRAY_SLOT_SIZE;
            memcpy(in_use.slots.data, old_allocation, old_allocation_size);
            free(old_allocation,, in_use.allocator);
        }
    }
}

#scope_export

// -----------------------------------------------------------------------------------
// ----------------------------------------------------------------- :Struct_Of_Arrays

// example SOA declaration
// Physics_Body_SOA :: SOA(struct{
//     flags:              Physics_Body_Flags;
//     collision_channels: Collision_Channel;
//     entity_id:          user_types.entity_id_type;
//     axes:               [3]u64;
//     using body:         Physics_Body_Internal;
// });
// the anonymous struct's type can be accessed via Physics_Body_SOA.item_type

soa_member_type :: ($item_type: Type, member_index: s64) -> Type {
    tinfo := cast(*Type_Info_Struct) type_info(item_type);
    member := tinfo.members[member_index];
    return (cast(*Type) *member.type).*;
}

// wrapping each member type of the SOA so that the types don't need to be known to this file,
// I believe because it keeps the type generic until the SOA specialization is instantiated.
SOA_Member_Type :: struct(item_type: Type, member_index: s64) {
    T :: #run soa_member_type(item_type, member_index);
}

SOA :: struct($item_type: Type) {
    #insert -> string {
        tinfo := cast(*Type_Info_Struct) type_info(item_type);
        assert(tinfo.type == .STRUCT);

        builder: String_Builder;

        INVALID_MEMBER : Type_Info_Struct_Member.Flags = .CONSTANT | .OVERLAY;

        for member, member_index : tinfo.members {
            if member.flags & INVALID_MEMBER {
                continue;
            }
            if member.type.runtime_size == 0 {
                continue;
            }
            print(*builder, "\t%: [..]SOA_Member_Type(item_type, %).T;\n", member.name, member_index);
        }

        return builder_to_string(*builder);
    }
}

soa_for_each_array :: (soa: *SOA, operation: string, $declare_item_field_var := false, only_front_array := false) #expand {
    #insert -> string {
        builder: String_Builder;

        tinfo := type_info(soa.item_type);
        assert(tinfo.type == .STRUCT);
        tinfo_struct := cast(*Type_Info_Struct) tinfo;

        INVALID_MEMBER : Type_Info_Struct_Member.Flags = .CONSTANT | .OVERLAY;

        i := 0;
        for member : tinfo_struct.members {
            if member.flags & INVALID_MEMBER {
                continue;
            }
            if member.type.runtime_size == 0 {
                continue;
            }
            defer i += 1;
            print(*builder, "\t{\n");
            print(*builder, "\t\tarray := *soa.%;\n", member.name);
            #if declare_item_field_var {
                print(*builder, "\t\tfield := *`item.%;\n", member.name);
            }
            print(*builder, "#insert operation;");
            print(*builder, "\t}\n");
            if only_front_array {
                break;
            }
        }

        return builder_to_string(*builder);
    }
}

soa_set_allocator :: (soa: *SOA, allocator: Allocator) {
    soa_for_each_array(soa, "array.allocator = `allocator;");
}

soa_add :: (soa: *SOA) {
    soa_for_each_array(soa, "array_add(array);");
}

soa_add :: (soa: *SOA, item: soa.item_type) {
    soa_for_each_array(soa, "array_add(array, field.*);", true);
}

soa_set :: (soa: *SOA, i: s64, item: soa.item_type) {
    soa_for_each_array(soa, "array.*[`i] = field.*;", true);
}

soa_get :: (soa: *SOA, i: s64) -> soa.item_type {
    item: soa.item_type = ---;
    soa_for_each_array(soa, "field.* = array.*[`i];", true);
    return item;
}

soa_unordered_remove_by_index :: (soa: *SOA, i: s64) {
    soa_for_each_array(soa, "array_unordered_remove_by_index(array, `i);");
}

soa_ordered_remove_by_index :: (soa: *SOA, i: s64) {
    soa_for_each_array(soa, "array_ordered_remove_by_index(array, `i);");
}

soa_resize :: (soa: *SOA, count: s64) {
    soa_for_each_array(soa, "array_resize(array, `count);");
}

soa_reserve :: (soa: *SOA, count: s64) {
    soa_for_each_array(soa, "array_reserve(array, `count);");
}

soa_reset :: (soa: *SOA) {
    soa_for_each_array(soa, "array_reset(array);");
}

soa_reset_keeping_memory :: (soa: *SOA) {
    soa_for_each_array(soa, "array_reset_keeping_memory(array);");
}

soa_count :: (soa: *SOA) -> int {
    count: int = ---;
    soa_for_each_array(soa, "`count = array.count;", false, true);
    return count;
}

// -----------------------------------------------------------------------------------
// --------------------------------------------------------------------- :Hybrid_Array
// an internal/external storage hybrid array wherein data is stored on-struct until
// it's too big. you can preset the allocator since that is not overwritten by 
// internal data (unless internal buffer overflow).

Hybrid_Array :: struct($T: Type) {
    allocation: Hybrid_Array_Allocation = .INTERNAL;
    internal_count: s32;
    external: [..]T;
    #overlay(external) internal_items: [INTERNAL_COUNT]T;

    INTERNAL_COUNT :: #run size_of(Resize_Array_Partial) / size_of(T);
}

data :: inline (using array: *Hybrid_Array($T)) -> *T {
    return ifx allocation == .INTERNAL then internal_items.data else external.data;
}

count :: inline (using array: *Hybrid_Array) -> int {
    return ifx allocation == .INTERNAL then internal_count else external.count;
}

array_view :: inline (using array: *Hybrid_Array($T)) -> []T {
    slice: []T = ---;
    if allocation == .INTERNAL {
        slice.data  = internal_items.data;
        slice.count = internal_count;
    } else {
        slice = external;
    }
    return slice;
}

operator *[] :: (using array: *Hybrid_Array($T), i: int) -> *T {
    return ifx allocation == .INTERNAL then internal_items[i] else external[i];
}

operator []= :: (using array: *Hybrid_Array($T), i: int, x: T) {
    if allocation == .INTERNAL {
        assert(i < internal_count);
        internal_items[i] = x;
    } else {
        external[i] = x;
    }
}

// make sure the context has the right allocator set when calling
array_add :: (using array: *Hybrid_Array($T), item: T) {
    if allocation == .INTERNAL {
        if internal_count < internal_items.count {
            internal_items[internal_count] = item;
            internal_count += 1;
            return;
        }

        assert(internal_count == internal_items.count);
        move_to_external_allocation(array, internal_items.count * 2);
    } 

    array_add(*external, item);
}

array_unordered_remove_by_value :: (using array: *Hybrid_Array($T), item: T) {
    if allocation == .EXTERNAL {
        array_unordered_remove_by_value(*external, item);   
        if external.count <= #run Hybrid_Array(T).internal_items.count / 2 {
            move_to_internal_allocation(array);
        }
    } else {
        if internal_count > 0 then for 0..internal_count-1 {
            if internal_items[it] == item {
                if it != internal_count - 1 {
                    internal_items[it] = internal_items[internal_count-1];
                }
                internal_count -= 1;
                return;
            }
        }
    }
}

array_reserve :: (array: *Hybrid_Array($T), reserve_count: int) {
    if allocation == .EXTERNAL {
        if reserve_count > external.allocated {
            array_reserve(*external, reserve_count);
        }
    } else {
        if reserve_count > internal_items.count {
            move_to_external_allocation(array, reserve_count);            
        }
    }
}

array_reset :: hybrid_array_reset;

hybrid_array_reset :: (using array: *Hybrid_Array) {
    if allocation == .EXTERNAL {
        free(external.data,, external.allocator);
    }
    array.* = .{};
}

for_expansion :: (array: *Hybrid_Array($T), body: Code, flags: For_Flags) #expand {
    items := array_view(array);

    for item, ind : items {
        `it := item;
        `it_index := ind;

        #insert body;
    }
}

Hybrid_Array_Allocation :: enum u32 {
    EXTERNAL;
    INTERNAL;
}

#scope_file

Resize_Array_Partial :: struct {
    count: s64;
    data: *void;
    allocated: s64;
}

move_to_internal_allocation :: inline (using array: *Hybrid_Array) {
    assert(external.count <= internal_items.count);

    allocation = .INTERNAL;

    data := external.data;
    internal_count = xx external.count;
    if internal_count > 0 {
        memcpy(internal_items.data, data, internal_count * size_of(T));
    }

    free(data,, external.allocator);
}

move_to_external_allocation :: inline (using array: *Hybrid_Array, reserve_count: int) {
    allocation = .EXTERNAL;

    external_temp: [..]T;
    external_temp.allocator = context.allocator;

    array_resize(*external_temp, reserve_count);
    external_temp.count = internal_count;
    if internal_count > 0 {
        memcpy(external_temp.data, internal_items.data, internal_count * size_of(T));
    }

    external = external_temp;
}

#scope_export

BIT_ARRAY_SLOT_SIZE :: size_of(s64);
BIT_ARRAY_SLOT_MAX_VALUE : s64 : 0xffff_ffff_ffff_ffff;
BIT_ARRAY_SLOT_BIT_COUNT :: BIT_ARRAY_SLOT_SIZE * 8;

// -----------------------------------------------------------------------------------
// ---------------------------------------------------------------------- :Ring_Buffer

#scope_export

Ring_Buffer :: struct($T: Type) {
    items: []T;
    front: u32 = EMPTY;
    back:  u32;

    on_erasure: #type (erasing: *T, replacement: *T);

    EMPTY :: U32_MAX;
}

operator *[] :: inline (using buffer: *Ring_Buffer($T), index: int) -> *T {
    return buffer.items[index];
}

operator []= :: inline (using buffer: *Ring_Buffer($T), index: int, value: T) {
    buffer.items[index] = value;
}

make_ring_buffer :: inline ($T: Type, size: int) -> Ring_Buffer(T) {
    assert(size >= 0);
    return ifx size == 0 then Ring_Buffer(T).{} else Ring_Buffer(T).{items=NewArray(size, T)};
}

push_front :: (using buffer: *Ring_Buffer($T), item: T) {
    assert(items.count > 0);
    push_impl(buffer, item, *front, *back, decrement_wrap);
}

push_back :: (using buffer: *Ring_Buffer($T), item: T) {
    assert(items.count > 0);
    push_impl(buffer, item, *back, *front, increment_wrap);
}

pop_front :: (using buffer: *Ring_Buffer($T)) -> T {
    assert(items.count > 0 && front != EMPTY);
    return pop_impl(buffer, *front, increment_wrap);
}

pop_back :: (using buffer: *Ring_Buffer($T)) -> T {
    assert(items.count > 0 && front != EMPTY);
    return pop_impl(buffer, *back, decrement_wrap);
}

count :: (using buffer: *Ring_Buffer) -> int {
    if front == EMPTY {
        return 0;
    } else if back >= front {
        return back - front + 1;
    } else {
        return (items.count - front) + (back + 1);
    }
}

make_array :: (using buffer: *Ring_Buffer($T)) -> []T {
    if front == EMPTY {
        return .[];
    }

    buf_i := front;
    out_array := NewArray(count(buffer), T);

    for 0..out_array.count-1 {
        out_array[it] = items[buf_i];
        buf_i = increment_wrap(buf_i, cast(u32) 0, cast(u32) (items.count-1));
    }

    return out_array;
}

#scope_file

// implements both push_front and push_back
push_impl :: (using buffer: *Ring_Buffer($T1), item: T1, pushing: *u32, other: *u32, $move_action: $T2) #expand {
    if front == EMPTY {
        front = 0;
        back  = 0;
    } else {
        if count(buffer) == items.count {
            if on_erasure != null {
                on_erasure(*items[other.*], *item);
            }
            other.* = move_action(other.*,  cast(u32) 0, cast(u32) (items.count-1));
        }
        pushing.* = move_action(pushing.*, cast(u32) 0, cast(u32) (items.count-1));
    }
    items[pushing.*] = item;
}

// implements both pop_front and pop_back
pop_impl :: (using buffer: *Ring_Buffer($T1), pushing: *u32, $move_action: $T2) -> T1 #expand {
    item := items[pushing.*];
    if front == back {
        front = EMPTY;
    } else {
        pushing.* = move_action(pushing.*, cast(u32) 0, cast(u32) (items.count-1));
    }
    return item;
}

// --------------

#scope_file

_fib16 :: (int_val: $T, min_digits := 0) -> FormatInt #expand {
    return FormatInt.{value=int_val, base=16, minimum_digits=min_digits};
}

#import "Basic";
#import "String";
#import "Hash";
#import "Bit_Array";
#import "Math";

#import "TeRM/TeRM_Allocation";
#import "TeRM/TeRM_Math";
#import "TeRM/TeRM_Metaprogram";

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
