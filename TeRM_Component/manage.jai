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

    // unrolled loop over all components of this entity type.
    // not unrolled for speed or anything, just for convenience of codewriting.
    #insert #run for_each_component_type(I.components, #code {

        array_resize(component_array, component_array.count + new_entities.count);
        if component_array.data != xx allocation_min_addresses[component_id] {
            component_moved_allocation[component_id] = true;
        }

        add_component_count := new_entities.count;

        for ent : new_entities {
            assigned_index := component_array.count - add_component_count;
            add_component_count -= 1;
            assert(component_id_is_valid(xx,trunc assigned_index));

            if ent.description_flags & .HAS_POINTERS_TO_COMPONENTS {
                pointer := get_component_pointer_at_index(ent, component_index);
                pointer.* = *component_array[assigned_index];
            } else {
                id := get_component_id_at_index(ent, component_index);
                id.* = xx assigned_index;
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
    // ---

    Index_Remap :: struct {
        old_index: u16;
        new_index: u16;
    }

    // ---

    if new_entities.count == 0 {
        return;
    }

    auto_release_temp();

    component_moved_allocation := make_static_array(bool, enum_highest_value(Component_Name) + 1,, temp);
    components_that_moved      := make_dynamic_array(Component_Name, I.components.count,, temp);

    // todo: really should only be collecting and sending the ranges for component arrays that
    // might change...
    allocation_min_addresses, allocation_max_addresses := prepare_rebase_entity_pointers();

    // prob more than we need is good
    components_per_entity_guess := 16;
    index_remaps := make_dynamic_array(Index_Remap, destroyed_entities.count * components_per_entity_guess,, temp);

    entity_array := cast,force([]I) context.entity_array_references.*[entity_array_index];

    #insert #run for_each_component_type(I.components, #code {

    });
    // per component type, dealloc and keep map of old index->new index

    // over all alive ents, if pointing past end, find remapping
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

            for 0..entity_array.count - 1 {
                entity_location := entity_array.data + array_ref.type_stride * it;
                entity_base := cast(*Component_Sentinel) (entity_location + array_ref.type_sentinel_offset);

                pointer := get_component_pointer_at_index(entity_base, component_index);
                address_of_pointer := cast(int) pointer.*;

                assert(prev_min_address <= address_of_pointer && address_of_pointer <= prev_max_address, "the % component array must have reallocated without an entity updating its pointer. component arrays should either only be managed by the TeRM Component system, or the user needs to rebase the entity component pointers manually.", component_id);

                pointer_offset := address_of_pointer - prev_min_address;
                pointer.* = entity_array.data + pointer_offset;
            }
        }
    }
}
