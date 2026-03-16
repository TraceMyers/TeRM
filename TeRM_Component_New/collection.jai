
collect :: collect_components_by_name;

collect_components_by_id :: (ids: []Component_ID) -> []*Component_Array_Base {
    long_collection := alloc_component_collection(1, ids.count)[0];
    for *array : long_collection {
        array.* = *context.user_component_storage.arrays[ids[it_index]];
    }
    return long_collection;
}

collect_components_by_kind :: (kinds: []Component_Kind) -> []*Component_Array_Base {
    ids := make_dynamic_array(Component_ID, enum_highest_value(Component_ID)+1,, temp);
    for array : context.user_component_storage.arrays { 
        for kind : kinds {
            if array.kind == kind {
                array_add(*ids, array.id);
            }
            break;
        }
    }
    return collect_components_by_id(ids);
}

collect_components_by_name :: (names: []Component_Name) -> []*Component_Array_Base {
    ids := make_dynamic_array(Component_ID, enum_highest_value(Component_ID)+1,, temp);
    for array : context.user_component_storage.arrays { 
        for name : names {
            if array.name == name {
                array_add(*ids, array.id);
            }
            break;
        }
    }
    return collect_components_by_id(ids);
}

// this is typically considered the main feature of an ecs. I tried to make give it as little 
// code writing overhead as possible, which is typically not a feature of an ecs. 
//
// an example operation is 'get all position and velocity arrays, but only from kinds that have all 
// of said arrays'. in this module's parlance, an array's 'name' is bound to its component type. 
// a 'kind' is an arbitrary cross-name grouping of your design.
//
// imagine you have: 
// - a Character entity with a position and velocity.
// - a Monster entity with a position and a velocity.
// - a Tree entity with a position.
//
// a sensible way to describe these in component language would be that 'position' and 'velocity'
// are names, and 'Character', 'Monster' and 'Tree' are kinds. given that application, this code 
// would isolate the position and velocity of Character and Monster, leaving out Tree's position array:
//
// collection := filter_components(.[.POSITION, .VELOCITY]);
// for row : collection {
//
//      // convenience macro, defines position_components, velocity_components, and CIDs.
//      declare_typed_row(row, .[.POSITION, .VELOCITY]); 
//
//      // iterate over position and velocity arrays in parallel
//      for 0..position_components.count-1 {
//          entity_position := *position_components[it];
//          entity_velocity := *velocity_components[it];
//          
//          // you can use this to reference the entity, if needed
//          // the procedure is defined in your program, as part of the interface with the module.
//          entity := my_get_entity_from_cid(CIDs[it]);
//          ...
//      }
// }
//
// note that this procedure has a little bit of overhead to it, as it's n * m in the number
// of components * number of names. but, it returns pointers to arrays, so you could just
// call once per collection you need, per duration of the data.
filter_components :: (names: []Component_Name, must_be_kind: []Component_Kind = .[], must_not_be_kind: []Component_Kind = .[]) -> [][]*Component_Array_Base {
    kind_count     := enum_highest_value(Component_Kind) + 1;
    kind_is_active := make_static_array(bool, kind_count,, temp);
    per_name_id_arrays := make_static_array(s32,  kind_count + kind_count * names.count,, temp);

    if must_be_kind.count > 0 {
        assert(must_not_be_kind.count == 0);
        for kind : must_be_kind {
            kind_is_active[kind] = true;
        }
    } else if must_not_be_kind.count > 0 {
        for kind_enum : 0..enum_highest_value(Component_Kind) {
            found_in_list: bool;
            for kind : must_not_be_kind {
                if kind == cast(Component_Kind) kind_enum {
                    found_in_list = true;
                    break;
                }
            }
            if !found_in_list {
                kind_is_active[kind_enum] = true;
            }
        }
    } else for *active : kind_is_active {
        active.* = true;
    }

    kinds_that_have_all_names := make_dynamic_array(Component_Kind, kind_count,, temp);

    for array : context.user_component_storage.arrays {
        if !kind_is_active[array.kind] {
            continue;
        }
        id_array_size := *per_name_id_arrays[array.kind];
        id_array_data := *per_name_id_arrays[kind_count + cast(int) array.kind * names.count];
        if id_array_size.* >= names.count {
            continue;
        }
        for name, name_index : names {
            if array.name == name {
                // putting the component ids in the same order as the names because each set 
                // of component arrays is expected to be iterated over in parallel. each 
                // column / id location maps to a single name
                
                //                                .---names---.
                //                                v           v
                //
                //                       position arrays     velocity arrays
                //    .->  characters    [  char pos 1 ]     [  char vel 1 ]
                //    |                  [  char pos 2 ]     [  char vel 2 ]
                //  kinds                [  char pos 3 ]     [  char vel 3 ]
                //    |                  [     ...     ]     [     ...     ]
                //    |
                //    .->  monsters      [ mnstr pos 1 ]     [ mnstr vel 1 ]
                //                       [     ...     ]     [     ...     ]

                id_location  := id_array_data + name_index;
                id_location.* = xx array.id;
                id_array_size.* += 1;
                if id_array_size.* == names.count {
                    array_add(*kinds_that_have_all_names, array.kind);
                }
                break;
            }
        }
    }

    if kinds_that_have_all_names.count == 0 {
        return .[];
    }

    collection := alloc_component_collection(kinds_that_have_all_names.count, names.count);
    for kind, row : kinds_that_have_all_names {
        for *array : collection[row] {
            component_id := component_name_and_kind_to_id(names[it_index], kind);
            array.* = *context.user_component_storage.arrays[component_id];
        }
    }

    return collection;
}

alloc_component_collection :: (name_count: int, rows_per_name: int) -> [][]*Component_Array_Base {
    allocation_size_for_pointers_and_counts := name_count * size_of([]*Component_Array_Base);
    allocation_size_for_array_datas         := name_count * rows_per_name * size_of(*Component_Array_Base);

    collection: [][]*Component_Array_Base;
    collection.data  = xx alloc(allocation_size_for_pointers_and_counts + allocation_size_for_array_datas);
    collection.count = name_count;

    for name : 0..name_count-1 {
        data_base := cast(*Component_Array_Base) (cast(*u8) collection.data) + collection.count * size_of([]*Component_Array_Base);
        collection[name].data = xx (data_base + rows_per_name * name);
        collection[name].count = rows_per_name;
    }

    return collection;
}

// compile time convenience caster for a row in a collection, e.g.:
// collection := filter_components(.[.TRANSFORM, .MOVE]);
// for row : collection {
//      declare_typed_row(row, .[.TRANSFORM, .MOVE]);
//      for 0..transform_components.count-1 {
//          entity_transform := *transform_components[it];
//          entity_move      := *move_components[it];
//          ...
//      }
// }
declare_typed_row :: (untyped_row: []*Component_Array_Base, $names: []Component_Name, $suffix := "_components", $all_arrays_in_row_must_have_same_count := true) #expand {
    assert(untyped_row.count == names.count);

    assert(untyped_row.count == names.count);
    #if all_arrays_in_row_must_have_same_count {
        if untyped_row.count > 1 then for 1..untyped_row.count-1 {
            assert(untyped_row[it].untyped_array.count == untyped_row[0].untyped_array.count);
        }
    }

    #insert -> string {
        builder: String_Builder;
        for name, ni : names {
            name_lower := to_lower(tprint("%", name));
            print(*builder, "assert(untyped_row[%].name == .%);\n", ni, name);
            print(*builder, "`%% := cast,force([]#run component_types[Component_Name.%]) untyped_row[%].untyped_array;\n", name_lower, suffix, name, ni);
        }
        output := builder_to_string(*builder);
        return output;
    };
}

