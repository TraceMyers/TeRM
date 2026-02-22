#module_parameters()(
    // must be true if you want to use TeRM vulkan renderer
    IMPORT_VULKAN := false
);

// -- sections --
// Misc
// Bit_Array Helpers
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
// ---------------------------------------------------------------- :Bit_Array Helpers
// just a couple of for expansions for iterating over only cleared or only set bits. reverse
// iteration was also added, where the base for expansion did not implement that.
//
// this is particularly useful for allocation algorithms that want to find the first or last bit
// that is set or cleared, since they will exit the loop on the first valid slot.
//
// in other words...
//
// for bit arrays that looks something like this (imagining slots are 8 bits instead of 64)
// 
// [ 1 1 1 1 1 1 1 1 ] [ 1 1 1 1 1 1 1 1 ] [ 1 1 0 1 1 0 1 0 ]
//
// and given you want to find the first cleared bit, you clearly don't need to search
// into the first two slots. only when you reach slot 3 should you search the bits to find a 0.
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

    // the other reason this exists is to add reverse iteration, which the pool uses.
    for <=((flags & .REVERSE) != 0) slot, slot_index: array.slots {

        // primary reason this expansion exists. skip over slots that have no candidate bits.
        // for algorithms finding, say, the first set bit, that code will be able to
        // exit the loop the first time this is true.
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
                // you already know whether it's set or cleared, so this is sort of performative,
                // but I figured it makes sense to keep it this way for consistency with
                // the base for expansion def
                `it := #ifx set_or_cleared == .SET then 1 else 0;

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

pool_init :: (pool: *Pool, cap: s64) {
    pool.* = {};
    pool.items.allocator = context.allocator;
    pool.in_use.allocator = context.allocator;
    pool_set_capacity(pool, cap);
}

pool_set_capacity :: (using pool: *Pool($T), cap: s64) {
    array_resize(*items, cap);
    resize_in_use(pool, cap);
}

pool_lock_allocation :: (using pool: *Pool($T)) {
    items.allocator = no_allocator;
    in_use.allocator = no_allocator; 
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

pool_acquire :: (using pool: *Pool($T), init_item_proc: (*T) = null, grow_behavior := Pool_Resize_Behavior.DEFAULT) -> s64 {
    index: s64 = -1;

    if items.data != null then for :only_cleared_bits in_use {
        index = it_index;
        break;
    }

    if index != -1 {
        set_bit(*in_use, index);
        if index > top then top = index;
        items[index] = {};
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
    items[index] = {};
    if init_item_proc then init_item_proc(*items[index]);

    return index;
}

pool_release :: (using pool: *Pool($T), i: s64, deinit_item_proc: (*T) = null, shrink_behavior := Pool_Resize_Behavior.DEFAULT) {
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
            test_threshold <<= 1;
            if test_threshold >= items.count then return;

            new_count := max(test_threshold, shrink_to_min);
            pool_set_capacity(pool, new_count);
        }
    }
}

operator *[] :: inline (using pool: *Pool($T), i: s64) -> *T {
    assert(in_use[i]);
    return *items[i];
}

pool_get :: inline (using pool: *Pool($T), i: s64) -> *T {
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

// for pool { ... }
for_expansion :: (pool: Pool($T), body: Code, flags: For_Flags) #expand {
    if pool.top >= 0 then for <=((flags & .REVERSE) != 0) item_index : 0..pool.top {
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
table_set :: (table: *Linear_Table, key: table.key_type, value: table.value_type, $edit_if := Table_Edit_Condition.ADD_OR_CHANGE) -> made_edit: bool, added_item: bool {
    key_hash := table_hash(table, key);
    existing_value := table_get_by_key_hash(table, key_hash);
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
    return table_get_by_key_hash(table, key_hash); 
}

table_get_by_key_hash :: (table: *Linear_Table, key_hash: u32) -> *table.value_type {
    for table.key_hashes {
        if it == key_hash {
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
    value := table_get_by_key_hash(table, key_hash);
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
    existing_value, searched_up_to_index := table_get_by_key_hash(table, key_hash);
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
    return table_get_by_key_hash(table, key_hash); 
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

get_bit_array_slot_size_and_max_value :: () -> s64, s64 {
    bit_array: Bit_Array;
    // bit_array.slots.data = xx *bit_array; // no null deref
    // bit_array.slots.count = 1;
    byte_size := size_of(type_of(bit_array.slots[0]));
    bit_count := byte_size * 8;
    max_value := ((((1).(s64) << (bit_count - 1)) - 1) << 1) | 1;
    return byte_size, max_value;
}

U32_MAX_VALUE :: 0xffff_ffff;
BIT_ARRAY_SLOT_SIZE, BIT_ARRAY_SLOT_MAX_VALUE :: #run get_bit_array_slot_size_and_max_value();
BIT_ARRAY_SLOT_BIT_COUNT :: BIT_ARRAY_SLOT_SIZE * 8;

#import "Basic";
#import "String";
#import "Hash";
#import "Bit_Array";

#if IMPORT_VULKAN {
    #import "TeRM/TeRM_Render/vulkan-jai";
}

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
