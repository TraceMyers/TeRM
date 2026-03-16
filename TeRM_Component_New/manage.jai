
Component_Allocation_Request :: struct {
    kind:       Component_Kind;
    components: []Component_ID;
    header:     *Component_Sentinel_Header; 
    entity_id:  Entity_ID;
}

prepare_component_allocations :: (requests: *[..]Component_Allocation_Request, new_entities: []*$I/interface Component_Sentinel) {
    array_reserve(requests, requests.count + new_entities.count);
    for ent : new_entities {
        kind   := I.in_kind;
        id     := entity_to_entity_id(ent);
        header := *ent.component_sentinel_header;
        array_add(requests, {kind, I.COMPONENTS, header, id});
    }
}

free_components :: (request: *[..]Component_Allocation_Request) -> bool {
    if requests.count == 0 {
        return false;
    }
}

allocate_components :: (requests: *[..]Component_Allocation_Request) -> bool {
    if requests.count == 0 {
        return false;
    }

    Component_Allocation :: struct {
        request_index: s32;
        component_index: s32;
    }

    component_allocations: [component_definitions.count][..]Component_Allocation;

    for request, ri : requests.* {
        for component, ci : request.components {
            allocations := *component_allocations[component];
            if allocations.count == 0 {
                allocations.allocator = temp;
                array_reserve(allocations, requests.count);
            }
            array_add(allocations, {xx ri, xx ci});
        }
        // id array is parallel to all of the component arrays of a kind.
        // adding this now because it's convenient to do so. components will be handed out in
        // such an order as to make the component allocations parallel to this id.
        array_add(*context.user_component_storage.entity_ids[request.kind], request.entity_id);
    }

    for allocation_set, asi : component_allocations {
        if allocation_set.count != 0 {
            component_id := cast(*Component_ID) asi;
            component_array := *context.user_component_storage.arrays[asi];
            current_max     := component_array.untyped_array.allocated;
            new_count       := component_array.untyped_array.count + allocation_set.count;
            elem_size       := component_array.type_size;

            if new_count > current_max {
                reserve_count := new_count * 2;
                array_reserve(cast(*Resizable_Array) *component_array.untyped_array, reserve_count, elem_size);

                // if the component type has no initializer, zero the memory now. else,
                // when the components are handed out, their initializers will get called.
                if component_array.type_initializer == null {
                    using component_array;
                    begin_zero := untyped_array.data + untyped_array.count * type_size;
                    end_zero   := untyped_array.data + new_count   * type_size;
                    zero_size  := end_zero - begin_zero;
                    memset(begin_zero, 0, zero_size);
                }
            }

            // todo: fix pointers by storing an array of ids to entities with pointers,
            // handling that here.

            component_array.untyped_array.count = new_count;
            allocation_index := component_array.untyped_array.count - allocation_set.count;

            for allocation : allocation_set {
                assert(component_id_is_valid(xx allocation_index));
                request := requests.*[allocation.request_index];
                sentinel_header := request.header;
                component_memory := component_array.untyped_array.data + (allocation_index * component_array.type_size);

                if sentinel_header.component_flags & .HAS_POINTERS_TO_COMPONENTS {
                    pointer := get_component_pointer_at_index(sentinel_header, allocation.component_index);
                    pointer.* = component_memory;
                } else {
                    id := get_component_id_at_index(sentinel_header, allocation.component_index);
                    id.* = xx allocation_index;
                }

                if component_array.type_initializer != null {
                    component_array.type_initializer(component_memory);
                }

                allocation_index += 1;
            }
        }
    }

    return true;
}
