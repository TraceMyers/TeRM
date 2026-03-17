Component_Memory_Modification :: struct {
    kind:       Component_Kind;
    components: []Component_ID;
    header:     *Component_Sentinel_Header; 
    entity_id:  Entity_ID;
}

prepare_component_memory_modification :: (requests: *[..]Component_Memory_Modification, new_entities: []*$I/interface Component_Sentinel) {
    array_reserve(requests, requests.count + new_entities.count);
    for ent : new_entities {
        kind   := I.in_kind;
        id     := entity_to_entity_id(ent);
        header := *ent.component_sentinel_header;
        array_add(requests, {kind, I.COMPONENTS, header, id});
    }
}

allocate_components :: (requests: *[..]Component_Memory_Modification) -> bool {
    if requests.count == 0 {
        return false;
    }

    Component_Allocation :: struct {
        request_index: s32;
        component_index_on_entity: s32;
    }

    component_allocations: [component_definitions.count]s32;

    // for each entity requesting a set of components, set its component index and take counts
    // of how many components need to be allocated
    for request, ri : requests.* {

        entity_ids_for_kind := *context.user_component_storage.entity_ids[request.kind];

        request.header.component_index = xx entity_ids_for_kind.count;
        array_add(entity_ids_for_kind, request.entity_id);

        for component, ci : request.components {
            allocation_count := *component_allocations[component];
            component_array  := *context.user_component_storage.arrays[component];
            assert(request.header.component_index == component_array.untyped_array.count + allocation_count.*);
            allocation_count.* += 1;
        }
    }

    // increase component counts and reallocate if necessary
    for allocation_count, aci : component_allocations {
        if allocation_count == 0 then continue;

        component_array := *context.user_component_storage.arrays[aci];
        component_id    := cast(*Component_ID) aci;
        current_max     := component_array.untyped_array.allocated;
        new_count       := component_array.untyped_array.count + allocation_count;
        elem_size       := component_array.type_size;

        if new_count > current_max {
            reserve_count := new_count * 2;
            array_reserve(cast(*Resizable_Array) *component_array.untyped_array, reserve_count, elem_size);

            // if the component type has no initializer, zero the memory
            if component_array.type_initializer == null {
                using component_array;
                begin_zero := untyped_array.data + untyped_array.count * type_size;
                end_zero   := untyped_array.data + new_count   * type_size;
                zero_size  := end_zero - begin_zero;
                memset(begin_zero, 0, zero_size);
            // else iterate and initialize. the initializer can't be inlined because it was
            // gotten at runtime, but we have the benefit of being able to use it type agnostically.
            } else for component_index : component_array.untyped_array.count..new_count {
                component_memory := component_array.untyped_array.data + (component_index * elem_size);
                component_array.type_initializer(component_memory);
            }
        }

        component_array.untyped_array.count = new_count;
    }

    // set all the pointers, for entities that have pointers to their components
    for request, ri : requests.* {
        if (request.header.component_flags & .HAS_POINTERS_TO_COMPONENTS) {
            for component, ci : request.components {
                component_array := *context.user_component_storage.arrays[component];
                elem_size       := component_array.type_size;
                pointer         := get_component_pointer_at_index(request.header, ci);
                pointer.*        = component_array.untyped_array.data + (cast(int) request.header.component_index * elem_size);
            }
        }
    }

    // todo: fix pointers

    return true;
}

free_components :: (requests: *[..]Component_Memory_Modification) -> bool {
    if requests.count == 0 {
        return false;
    }
    
    for request, ri : requests.* {
        ids := *context.user_component_storage.entity_ids[request.kind];       
        defer ids.count -= 1;

        index_of_removal := request.header.component_index;
        request.header.component_index = 0xffff;

        removing_end_component := index_of_removal == ids.count - 1;
        header_owning_end_component: *Component_Sentinel_Header;

        if !removing_end_component {
            id_of_entity_owning_end_component          := ids.*[ids.count-1];
            ids.*[index_of_removal]                     = id_of_entity_owning_end_component;

            header_owning_end_component                 = entity_id_to_sentinel(id_of_entity_owning_end_component);
            header_owning_end_component.component_index = index_of_removal;
        }

        //                            .------------------ 1. this component was just removed because 
        //                            |                      the entity that owned it was destroyed
        //                            v
        // some component array [   | x |   |   | o ] 
        //                            ^           |^        
        //                            |           || 
        //      2. the end component  .-----------.|
        //      is copied into the old             | 3. this entity owns this component, 
        //      component's place                  |    which just moved. so, we need to
        //                                         |    re-point it to the new location
        //                                         |    over all components shared by this kind
        // some entity array [   |   |   |   |   | e |   ]

        for component, ci : request.components {
            component_array  := *context.user_component_storage.arrays[component];
            elem_size        := component_array.type_size;
            array_count      := component_array.untyped_array.count;
            assert(ids.count == array_count);

            defer component_array.untyped_array.count -= 1;

            component_memory: *u8;

            if request.header.component_flags & .HAS_POINTERS_TO_COMPONENTS {
                pointer := get_component_pointer_at_index(request.header, ci);
                component_memory = pointer.*;
                assert(component_memory == component_array.untyped_array.data + (cast(int) index_of_removal * elem_size));
                pointer.* = null;
            } else {
                component_memory = component_array.untyped_array.data + (cast(int) index_of_removal * elem_size);
            }

            end_component_memory := component_array.untyped_array.data + ((array_count - 1) * elem-size);
            memcpy(component_memory, end_component_memory, elem_size);

            if !removing_end_component && header_owning_end_component.component_flags & .HAS_POINTERS_TO_COMPONENTS {
                pointer  := get_component_pointer_at_index(header_owning_end_component, ci);
                pointer.* = component_memory;
            }
        }
    }   

    // todo: shrink component array allocations as called for
    // todo: fix pointers
    
    return true;
}

#scope_file

