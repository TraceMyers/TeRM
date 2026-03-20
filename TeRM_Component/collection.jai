collect_components_by_id :: (ids: []Component_ID) -> []*Component_Array_Base {
    long_collection := alloc_component_collection(1, ids.count)[0].arrays;
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

Untyped_Component_Rows :: struct {
    kind: Component_Kind;
    section_index: s32;
    arrays: []*Component_Array_Base;
}

Component_Table :: struct($columns: []Component_Name, $array_suffix := "_components") {
    table: []Untyped_Component_Rows;
}

// convenience wrapper for filter_components_into_table that generates an iterable table of components
filter_components :: ($names: []Component_Name, must_be_kind: []Component_Kind = .[], must_not_be_kind: []Component_Kind = .[]) -> Component_Table(names) {
    collection := filter_components_into_table(names, must_be_kind, must_not_be_kind);
    return Component_Table(names).{collection};
}

// this is typically considered the main feature of an ecs. I tried to make give it as little 
// code writing overhead as possible, which is unfortunately often not a feature of an ecs. 
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
//     table := filter_components(.[.POSITION, .VELOCITY]);
//     
//     for table {
//          entity_position := *position_components[it];
//          entity_velocity := *velocity_components[it];
//
//          entity_position.* += entity_velocity.* * delta_time;
//          
//          // you can use this to reference the entity. the procedure is defined in your program, with a shared id type.
//          if component_kind == {
//          case .CHARACTER;
//              character := get_entity(ids[it], Character);
//          case .MONSTER;
//              monster := get_entity(ids[it], Monster);
//          }
//
//          ...
//      }
//
// note that this procedure has a little bit of overhead to it. but, it returns pointers to arrays that ostensibly are 
// staying in the same location for their lifetime, so you could just call once per collection you need.
//
// this is no_inline on purpose to keep it from being specified with the polymorphic wrapper filter_components()
// and dumping a bunch of duplicated code into the binary for no reason.
filter_components_into_table :: no_inline (names: []Component_Name, must_be_kind: []Component_Kind = .[], must_not_be_kind: []Component_Kind = .[]) -> []Untyped_Component_Rows {
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
        untyped_component_row := *collection[row];
        untyped_component_row.kind = kind;
        untyped_component_row.section_index = xx row;
        for *col : untyped_component_row.arrays {
            component_id := component_name_and_kind_to_id(names[it_index], kind);
            col.* = *context.user_component_storage.arrays[component_id];
        }
    }

    return collection;
}

for_expansion :: (table_input: Component_Table, body: Code, flags: For_Flags) #expand {
    assert((flags & .POINTER) == 0); // not sure what would be pointed to. there's a lot of things.

    `table := table_input.table;

    for <=((flags & .REVERSE) != 0) outer_index : 0..`table.count-1 {
        `it_index := outer_index;

        `table_section := table[outer_index];
        `ids := context.user_component_storage.entity_ids[`table_section.kind];
        `row_count := `table_section.arrays[0].untyped_array.count;
        `component_kind := `table_section.kind;

        #insert -> string {
            builder: String_Builder;
            for name, ni : table_input.columns {
                name_lower := to_lower(tprint("%", name));
                print(*builder, "assert(`table_section.arrays[%].name == .%);\n", ni, name);
                print(*builder, "`%% := cast,force([]#run component_types[Component_Name.%]) `table_section.arrays[outer_index].untyped_array;\n", name_lower, table_input.array_suffix, name, ni);
            }
            output := builder_to_string(*builder);
            return output;
        };

        for <=((flags & .REVERSE) != 0) j : 0..row_count-1 {
            `it := j;

            #insert (break=break outer_index) body;
        }
    }
}

#scope_file

alloc_component_collection :: (name_count: int, rows_per_name: int) -> []Untyped_Component_Rows {
    allocation_size_for_pointers_and_counts := name_count * size_of(Untyped_Component_Rows);
    allocation_size_for_array_datas         := name_count * rows_per_name * size_of(*Component_Array_Base);

    collection: []Untyped_Component_Rows;
    collection.data  = xx alloc(allocation_size_for_pointers_and_counts + allocation_size_for_array_datas);
    collection.count = name_count;

    for name : 0..name_count-1 {
        data_base := cast(*Component_Array_Base) (cast(*u8) collection.data) + collection.count * size_of(Untyped_Component_Rows);
        collection[name].arrays.data = xx (data_base + rows_per_name * name);
        collection[name].arrays.count = rows_per_name;
    }

    return collection;
}

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
