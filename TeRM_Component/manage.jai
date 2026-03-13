// this module expects you to store your entities contiguously rather than indirectly,
// and that each entity type gets its own array. so, on_create... and on_destroy...
// are each called once per set of entities of a certain type having been created.
//
// e.g.
//
// Entity_Person [   |   |   |   |   |   |   | P ]
//                                             ^-- a new Entity_Person was added to the end of this array
//
//                                     .--------- pass an array with a pointer to that entity
//                                     |          as well as the index of the array containing the entity
//                                     |           |
//                                     v           v
//      on_create_entities_of_a_type([*P], entity_persons_index);
//
// this was done because enforcing no constraints and just using brute force to clean
// up storage module-side leads to wasting a lot of compute time. this structure instead allows
// some freedom on your end, and makes things somewhat sane on this end.

// this pointer is expected to stay in the same place for the duration of its usage.
add_entity_array_reference :: (array: *[]$I/interface Component_Info) -> entity_array_index: int {
    index := context.entity_array_references.count;
    ref := array_add(context.entity_array_references);
    ref.ref = xx array;
    ref.components = I.components;
    ref.component_flags = make_flag_array(..I.components);
    ref.type_has_component_pointers = I.declare_component_pointers;
    dummy_array: [2]I = ---; // rarely do I have a reason this good for uninitialized data
    ref.type_stride        = cast(*u8) *dummy_array[1]                      - cast(*u8) *dummy_array[0];
    ref.type_sentinel_offset = cast(*u8) *dummy_array[0].component_sentinel - cast(*u8) *dummy_array[0];
    return index;
}

//todo: is remove_entity_array_reference necessary? maybe worthwhile, dunno. could make array refs a pool, then.

on_create_entities :: (new_entities: []*$I/interface Component_Info, entity_array_index: int) {
    if new_entities.count == 0 {
        return;
    }

    auto_release_temp();

    component_moved_allocation := make_static_array(bool, enum_highest_value(Component_Name) + 1,, temp);
    components_that_moved      := make_dynamic_array(Component_Name, I.components.count,, temp);

    // todo: really should only be collecting and sending the ranges for component arrays that
    // might change...
    allocation_min_addresses, allocation_max_addresses := prepare_rebase_entity_pointers();

    entity_array_ref   := context.entity_array_references.*[entity_array_index];
    entity_array       := cast,force([]I) entity_array_ref.ref.*;

    // unrolled loop over all components of this entity type.
    // not unrolled for speed or anything, just for convenience of codewriting.
    #insert #run for_each_component_type(I.components, #code {

        new_component_array_size := component_array.count + new_entities.count;

        array_resize(component_array, new_component_array_size);
        array_resize(*entity_pointer_arrays[component_id], new_component_array_size);

        if component_array.data != xx allocation_min_addresses[component_id] {
            component_moved_allocation[component_id] = true;
        }

        add_component_count := new_entities.count;

        for ent : new_entities {
            assigned_component_index := component_array.count - add_component_count;
            add_component_count -= 1;
            assert(component_id_is_valid(xx,trunc assigned_component_index));

            entity_index := ent - entity_array.data;
            assert(entity_index >= 0 && entity_index < entity_array.count); 

            // for each component, store a back-reference to the entity that owns it.
            // should have little to no cache perf hit except when the array
            // itself reallocates, because then the whole thing needs to be copied.
            // otherwise, you get only one cache line pull from it, per component free.
            entity_pointer_arrays[component_id][assigned_component_index] = {xx entity_array_index, xx entity_index};

            if ent.description_flags & .HAS_POINTERS_TO_COMPONENTS {
                pointer := get_component_pointer_at_index(ent, component_index);
                pointer.* = *component_array[assigned_component_index];
            } else {
                id := get_component_id_at_index(ent, component_index);
                id.* = xx assigned_component_index;
            }
        }
    });

    for alloc_did_move : component_moved_allocation {
        if alloc_did_move {
            array_add(*components_that_moved, xx it_index);
        }
    }

    if components_that_moved.count > 0 {
        execute_rebase_entity_pointers(components_that_moved, allocation_min_addresses, allocation_max_addresses);
    }
}

// these entities will have their components deallocated and their Component_Info struct will be cleared.
on_destroy_entities :: (destroyed_entities: []*$I/interface Component_Info, entity_array_index: int) {
    if new_entities.count == 0 {
        return;
    }

    auto_release_temp();

    entity_array               := cast,force([]I) context.entity_array_references.*[entity_array_index];
    components_that_moved      := make_dynamic_array(Component_Name, I.components.count,, temp);
    allocation_min_addresses, allocation_max_addresses := prepare_rebase_entity_pointers();

    #insert #run for_each_component_type(I.components, #code {
        for ent : destroyed_entities {
            entity_index := ent - entity_array.data;
            assert(entity_index >= 0 && entity_index < entity_array.count); 

            assigned_component_index: u16;

            if ent.description_flags & .HAS_POINTERS_TO_COMPONENTS {
                pointer := get_component_pointer_at_index(ent, component_index);
                assigned_component_index = xx (cast(*component_type) pointer - component_array.data);
                pointer.* = null;
            } else {
                id := get_component_id_at_index(ent, component_index);
                assigned_component_index = id.*;
                id.* = 0xffff;
            }

            assert(component_array.count > 0);
            if assigned_component_index == component_array.count - 1 {
                component_array.count -= 1;
            } else {
                // remove-swap with last element in components array
                component_array[assigned_component_index] = component_array[component_array.count-1];
                component_array.count -= 1;

                //                            .------------------ 1. this component was just removed because 
                //                            |                      the entity that owned it was destroyed
                //                            v
                // some component array [   | x |   |   | o ] 
                //                            ^           |^        
                //                            |           || 
                //      2. the end component  .-----------.|
                //      is copied into the old             | 3. this entity owns this component, which just moved.
                //      component's place                  |    so, we need to re-point it to the new location
                //                                         |
                // some entity array [   |   |   |   |   | e |   ]

                index_based_pointer := entity_pointer_arrays[component_id][assigned_component_index];

                owning_entity_array_ref := entity_array_references.*[index_based_pointer.array];
                owning_entity_array     := owning_entity_array_ref.ref.*;
                type_stride             := owning_entity_array_ref.type_stride;
                sentinel_offset         := owning_entity_array_ref.sentinel_offset;

                owning_entity_location  := cast(*u8) owning_entity_array + type_stride * index_based_pointer.entity;
                owning_sentinel         := (*Component_Sentinel) (owning_entity_location + sentinel_offset);

                for :per_component owning_sentinel {
                    if it != component_id {
                        continue;
                    }

                    if owning_sentinel.description_flags & .HAS_POINTERS_TO_COMPONENTS {
                        pointer := get_component_pointer_at_index(owning_sentinel, component_index);
                        pointer.* = *component_array[assigned_component_index];
                    } else {
                        id := get_component_id_at_index(ent, component_index);
                        id.* = xx assigned_component_index;
                    }

                    break;
                }
            }
        }

        // todo make minium_count a parameter per array
        if array_shrink_if_small_enough(*component_array, minimum_count = 256) {
            array_add(*components_that_moved, component_id);
        }
    });

    if components_that_moved.count > 0 {
        execute_rebase_entity_pointers(components_that_moved, allocation_min_addresses, allocation_max_addresses);
    }
}

on_move_entity_memory_location :: (*$I/interface *Component_Info, old_entity_index: s32, old_array_index: s32, new_array_index: s32) {

}

prepare_rebase_entity_pointers :: () -> []int, []int {
    // making two arrays from one allocation because they're parallel.
    // base address and max address, so we can later check which entities were inside one of those
    // ranges.
    array_len := context.entity_component_arrays.count;
    allocation_min_addresses := make_static_array(int, array_len * 2,, temp);
    allocation_max_addresses := allocation_min_addresses;
    allocation_min_addresses.count -= array_len;
    allocation_max_addresses.data  += array_len;
    allocation_max_addresses.count -= array_len;

    for array : context.entity_component_arrays {
        allocation_min_addresses[it_index] = cast(int) array.data;
        allocation_max_addresses[it_index] = cast(int) (array.data + (array.count - 1));
    }
    return allocation_min_addresses, allocation_max_addresses;
}

execute_rebase_entity_pointers :: (components_with_new_allocations: []Component_Name, prev_min_addresses: []int, prev_max_addresses: []int) {
    for array_ref : context.entity_array_references.* {
        if !array_ref.type_has_component_pointers {
            continue;
        }
        for component_id, component_index : array_ref.components {
            entity_type_has_component: bool;
            for components_with_new_allocations {
                if component_id == it {
                    entity_type_has_component = true;
                }
            }
            if !entity_type_has_component {
                continue;
            }

            entity_array     := array_ref.ref.*;
            prev_min_address := prev_min_addresses[component_id];
            prev_max_address := prev_max_addresses[component_id];
            new_min_address  := cast(int) entity_array.data;
            new_max_address  := cast(int) (entity_array.data + (entity_array.count - 1));

            for 0..entity_array.count - 1 {
                entity_location := entity_array.data + array_ref.type_stride * it;
                entity_base := cast(*Component_Sentinel) (entity_location + array_ref.type_sentinel_offset);

                pointer := get_component_pointer_at_index(entity_base, component_index);
                address_of_pointer := cast(int) pointer.*;

                assert((prev_min_address <= address_of_pointer && address_of_pointer <= prev_max_address) || (new_min_address <= address_of_pointer && address_of_pointer <= new_max_address), "the % component array must have reallocated without an entity updating its pointer, or an entity must have moved without the component system being informed. options are: 1. let the TeRM component system manage the component arrays (and inform the system when entity allocations move), 2. don't make use of the component pointers option, or 3. you need to rebase the entity component pointers when you make changes to the component arrays.", component_id);

                pointer_offset := address_of_pointer - prev_min_address;
                pointer.* = entity_array.data + pointer_offset;
            }
        }
    }
}
