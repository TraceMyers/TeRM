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
        component_index_on_entity: Component_Index;
    }

    component_allocations: [component_definitions.count]s32;

    // for each entity requesting a set of components, take counts of how many components need to be allocated
    for request, ri : requests.* {
        for component, ci : request.components {
            allocation_count := *component_allocations[component];
            component_array  := *context.user_component_storage.arrays[component];
            allocation_count.* += 1;
        }
    }

    fix_pointers_for_kind: [COMPONENT_KIND_COUNT]bool;

    // increase component counts and reallocate if necessary
    for allocation_count, aci : component_allocations {
        if allocation_count == 0 then continue;

        component_array := *context.user_component_storage.arrays[aci];
        component_id    := cast(Component_ID) aci;
        current_max     := component_array.untyped_array.allocated;
        new_count       := component_array.untyped_array.count + allocation_count;
        elem_size       := component_array.type_size;

        if new_count > current_max {
            component_kind := component_id_to_kind(component_id);
            fix_pointers_for_kind[component_kind] = true;

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

    // if there were reallocations, existing pointers need to be fixed
    fix_entity_pointers_to_components_for_these_kinds(fix_pointers_for_kind);

    // hand out component indexes and pointers to entities
    for request, ri : requests.* {

        entity_ids_for_kind := *context.user_component_storage.entity_ids[request.kind];

        // manage the array of id's referring to entities with pointers, because they need to be updated anytime
        // allocations change.
        if request.header.component_flags & .HAS_POINTERS_TO_COMPONENTS {
            if store_ids_to_entities_with_pointers[request.kind] == {
            case .DO_NOT_STORE;
                // haven't come across any pointer entities in this kind yet
                store_ids_to_entities_with_pointers[request.kind] = .USE_ENTITY_IDS_ARRAY;
            case .USE_ENTITY_IDS_ARRAY;
                // under the impression that all entities of this kind have pointers
            case .USE_IDS_OF_ENTITIES_WITH_POINTERS_ARRAY;
                // already mixed. add to the special array.
                entity_ids_with_pointers := *context.user_component_storage.ids_of_entities_with_pointers[request.kind];
                array_add(entity_ids_with_pointers, request.entity_id);
            }
        } else if store_ids_to_entities_with_pointers[request.kind] == .USE_ENTITY_IDS_ARRAY {
            entity_ids_with_pointers := *context.user_component_storage.ids_of_entities_with_pointers[request.kind];
            assert(entity_ids_with_pointers.count == 0);
            // under the impression that all entities of this kind have pointers. need to fix.
            store_ids_to_entities_with_pointers[request.kind] = .USE_IDS_OF_ENTITIES_WITH_POINTERS_ARRAY;
            // copy all current ids to special ids array
            if entity_ids_for_kind.count > 0 {
                array_resize(entity_ids_with_pointers, entity_ids_for_kind.count);
                memcpy(entity_ids_with_pointers.data, entity_ids_for_kind.data, entity_ids_for_kind.count * size_of(Entity_ID));
            }
        }

        request.header.component_index = xx entity_ids_for_kind.count;
        array_add(entity_ids_for_kind, request.entity_id);

        if (request.header.component_flags & .HAS_POINTERS_TO_COMPONENTS) {
            fix_entity_pointers_to_components(request.header, request.components);
        }
    }

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
        request.header.component_index = INVALID_COMPONENT_INDEX;

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

            end_component_memory := component_array.untyped_array.data + ((array_count - 1) * elem_size);
            memcpy(component_memory, end_component_memory, elem_size);

            if !removing_end_component && header_owning_end_component.component_flags & .HAS_POINTERS_TO_COMPONENTS {
                pointer  := get_component_pointer_at_index(header_owning_end_component, ci);
                pointer.* = component_memory;
            }
        }

        if request.header.component_flags & .HAS_POINTERS_TO_COMPONENTS 
        && store_ids_to_entities_with_pointers[request.kind] == .USE_IDS_OF_ENTITIES_WITH_POINTERS_ARRAY {
            entity_ids_with_pointers := *context.user_component_storage.ids_of_entities_with_pointers[request.kind];
            for id, i : entity_ids_with_pointers.* {
                if inline user_types.entity_ids_equal(id, request.entity_id) {
                    array_unordered_remove_by_index(entity_ids_with_pointers, i);
                    break;
                }
            }
        }
    }

    // unrolled iterate over all component arrays and shrink them if they're below some usage proportion
    // doing this with typed arrays rather than untyped because their 'count' and 'allocated' fields
    // are just more easily managed with the existing array_shrink... by knowing their type.

    shrink_component_array_of_id :: ($id: Component_ID, unused: int, fix_pointers: *[COMPONENT_KIND_COUNT]bool) {
        array := cast,force(*Component_Array(id)) *context.user_component_storage.arrays[id];
        if array_shrink_if_small_enough(*array.array, 0.6, 0.5) {
            kind := component_definitions[id].kind;
            fix_pointers.*[kind] = true;
        }
    }

    // if the arrays shrank for a kind, that index will be set to true
    fix_pointers_for_kind: [COMPONENT_KIND_COUNT]bool;
    specialize_call_for_all_ids(shrink_component_array_of_id, *fix_pointers_for_kind);

    // for all arrays that shrank, fix the pointers entities have to their components
    fix_entity_pointers_to_components_for_these_kinds(fix_pointers_for_kind);

    return true;
}

fix_entity_pointers_to_components_for_these_kinds :: (set_pointers_for_kind: []bool) {
    assert(set_pointers_for_kind.count == COMPONENT_KIND_COUNT);

    // todo: fix pointers
    for should_set_pointers, ki : set_pointers_for_kind {
        if !should_set_pointers then continue;

        kind := cast(Component_Kind) ki;
        ids: []Entity_ID;

        if store_ids_to_entities_with_pointers[kind] == {
        case .DO_NOT_STORE;
            // no pointer guys
            continue;
        case .USE_ENTITY_IDS_ARRAY;
            ids = context.user_component_storage.entity_ids[kind];
        case .USE_IDS_OF_ENTITIES_WITH_POINTERS_ARRAY;
            ids = context.user_component_storage.ids_of_entities_with_pointers[kind];
        }

        for entity_id : ids {
            sent := entity_id_to_sentinel(entity_id);
            components := COMPONENT_IDS_PER_KIND[kind];
            fix_entity_pointers_to_components(sent, components);
        }
    }
}

fix_entity_pointers_to_components :: inline (header: *Component_Sentinel_Header, components: []Component_ID) {
    for component, ci : components {
        component_array := *context.user_component_storage.arrays[component];
        elem_size       := component_array.type_size;
        pointer         := get_component_pointer_at_index(header, ci);
        pointer.*        = component_array.untyped_array.data + (cast(int) header.component_index * elem_size);
    }
}

