
Component_Management_Handshake :: struct {
    component_allocation_counts: [component_definitions.count]s32;
}

Component_Allocation_Description :: struct {
    components: []Component_ID;
    count: s32;
    has_pointers: bool;
}

make_allocation_description :: ($user_type: Type, count: int) -> Component_Allocation_Description {
    return {
        user_type.COMPONENTS, 
        xx count, 
        user_type.component_references_are_pointers,
    };
}

allocate_components :: (handshake: *Component_Management_Handshake, descriptions: ..Component_Allocation_Description) -> bool {
    
    allocating_any_components: bool;

    for description : descriptions {
        if description.count == 0 {
            continue;
        }
        for component : description.components {
            handshake.component_allocation_counts[component] += xx description.count;
            allocating_any_components = true;
        }
    }

    if !allocating_any_components {
        return false;
    }

    for alloc_count, aci : handshake.component_allocation_counts {
        component_id := cast(*Component_ID) aci;
        if alloc_count != 0 {
            component_array := *context.user_component_storage.arrays[aci];
            current_max     := component_array.array.allocated;
            new_count       := component_array.array.count + alloc_count;
            if new_count > current_max {
                reserve_count := new_count * 2;
                elem_size := component_array.type_size;
                array_reserve(cast(*Resizable_Array) *component_array.array, reserve_count, elem_size);

                // if the component type has no initializer, zero the memory now. else,
                // when the components are handed out, their initializers will get called.
                if !component_array.type_has_initializer {
                    using component_array;
                    begin_zero := array.data + array.count * type_size;
                    end_zero   := array.data + new_count   * type_size;
                    zero_size := end_zero - begin_zero;
                    memset(begin_zero, 0, zero_size);
                }
            }
            component_array.array.count = new_count;
            array_resize(*component_array.ids, new_count);
        }
    }

    return true;
}

hand_out_components :: (handshake: *Component_Management_Handshake, new_entities: []*$I/interface Component_Sentinel) {
    Data_Package :: struct($T: Type) {
        handshake: *Component_Management_Handshake;
        new_entities: []*T;
        entity_ids: []CID;
    }

    hand_out_components_of_id :: ($component_id: Component_ID, component_index: int, data_pkg: *Data_Package(I)) {
        component_array := cast(*Component_Array(component_id)) *context.user_component_storage.arrays[component_id];
        component_type :: component_array.component_type;

        for ent : data_pkg.new_entities {
            components_remaining := *data_pkg.handshake.component_allocation_counts[component_id];
            assigned_component_index := component_array.array.count - components_remaining.*;
            components_remaining.* -= 1;
            assert(components_remaining.* >= 0);

            assert(component_id_is_valid(xx,trunc assigned_component_index));

            // for each component, store a back-reference to the entity that owns it.
            // should have only a small cache perf hit except when the array
            // itself reallocates, because then the whole thing needs to be copied.
            // otherwise, you get only one cache line pull from it, per component free.
            component_array.ids[assigned_component_index] = data_pkg.entity_ids[it_index];

            if ent.component_flags & .HAS_POINTERS_TO_COMPONENTS {
                pointer := get_component_pointer_at_index(ent, component_index);
                pointer.* = *component_array.array[assigned_component_index];
            } else {
                id := get_component_id_at_index(ent, component_index);
                id.* = xx assigned_component_index;
            }

            // memory was already zeroed if there is no initializer.
            // there is an initializer only if a struct sets any values explicitly in its definition.
            ini :: #run initializer_of(component_type);
            #if ini {
                inline ini(*component_array.array[assigned_component_index]);
            }
        }
    }

    // --------

    if new_entities.count == 0 {
        return;
    }

    entity_ids := make_static_array(CID, new_entities.count,, temp);
    for *id : entity_ids {
        id.* = component_sentinel_to_cid(new_entities[it_index]);
    }

    data_pkg := Data_Package(I).{handshake, new_entities, entity_ids};
    call_over_ids(hand_out_components_of_id, I.COMPONENTS, *data_pkg);
}
