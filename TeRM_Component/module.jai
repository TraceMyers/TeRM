// a component system for entities. see how_to.jai for long form documentation

// todo: assert that the data fed in at import makes sense

#module_parameters()(importer: $I/interface Type_Importer_Default = Type_Importer_Default) {
    Type_Importer_Default :: struct {
        component_declarations :: *void.[];
        component_decl_type    :: void;
        uppercase_enum_names   :: false;
        cmp_get_id             :: void;
        cmp_get_sentinel       :: void;
    }
};

// for telling the module where your entity component storage is.
// e.g. context.entity_component_arrays = entity_component_storage;
#add_context entity_component_arrays: []Component_Array_Untyped;
#add_context entity_id_arrays:        [][..]s64;  // todo: rename
#add_context tracked_entity_arrays:   *[..]*void; // todo: rename

#insert -> string {
    builder: String_Builder;
    for 0..enum_highest_value(Component_ID) {
        print(*builder, "component_array_prototype_%: Component_Array(.%);\n", it, cast(Component_ID) it);
    }
    return builder_to_string(*builder);
}

Component_Array_Base :: struct {
    id:   Component_ID;
    name: Component_Name;
    kind: Component_Kind;
    type_stride: s16; // todo: set this
}

Component_Array_Untyped :: struct {
    array: [..]u8;
    using #as base: Component_Array_Base;
}

Component_Array :: struct($in_id: Component_ID) {
    array: []#run importer.component_declarations[in_id].type;
    using #as base := Component_Array_Base.{
        id   = in_id,
        name = #insert -> string { return tprint(".%;", importer.component_declarations[in_id].name); },
        kind = #insert -> string { return tprint(".%;", importer.component_declarations[in_id].kind); },
        type_stride = #run size_of(type_of(array[0]))
    };
}


// todo: one big init step
initialize_entity_component_arrays :: () {
    for *array : context.entity_component_arrays {
        array.id = cast(Component_ID) it_index;

    }
}

declare_component_arrays_by_id :: ($ids: ..Component_ID) #expand {
    #insert -> string {
        builder: String_Builder;
        for id : ids {
            array_name := to_lower(tprint("%", id));
            print(*builder, "`%: Component_Array(Component_ID.%);\n", array_name, id);
            print(*builder, "`%.array = xx,force context.entity_component_arrays[Component_ID.%].array;\n", array_name, id);
        }
        return builder_to_string(*builder);
    }
}

collect :: (names: []Component_Name, must_be_kind: []Component_Kind = .[], must_not_be_kind: []Component_Kind = .[]) -> [][]*Component_Array_Untyped {
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

    for array : context.entity_component_arrays {
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
                // putting the component ids in the same order as the names
                // because each set of component arrays is iterated over in parallel,
                // the expection being that each column / id location represents one name
                
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
                log("found id: %", array.id);
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

    allocation_size_for_pointers_and_counts := kinds_that_have_all_names.count * size_of([]*Component_Array_Untyped);
    allocation_size_for_array_datas         := kinds_that_have_all_names.count * names.count * size_of(*Component_Array_Untyped);

    collection: [][]*Component_Array_Untyped;
    collection.data  = xx alloc(allocation_size_for_pointers_and_counts + allocation_size_for_array_datas);
    collection.count = kinds_that_have_all_names.count;

    for kind, set_of_arrays : kinds_that_have_all_names {
        collection[set_of_arrays].data = xx ((cast(*u8) collection.data) + collection.count * size_of([]*Component_Array_Untyped) + set_of_arrays * size_of(*Component_Array_Untyped));
        collection[set_of_arrays].count = names.count;
        for *array : collection[set_of_arrays] {
            component_id := (*per_name_id_arrays[kind_count + cast(int) kind * names.count] + it_index).*;
            array.* = *context.entity_component_arrays[component_id];
        }
    }

    return collection;
}

// declare_component_bridge_array_by_name_and_kind :: ($must_have_all_names: ..Component_Name, $kind_filter: []Component_Kind) #expand {

// }

// user proc looks like:
// move_entities :: (transforms: [][]Transform, moves: [][]Entity_Move)

// note: making this an array, or maybe using it at all, seems to have shunted a 0.25 second
// stall into compilation
// Component_Array_Package :: struct($ids: []Component_ID) {
//     #insert -> string {
//         builder: String_Builder;
//         print(*builder, "#as base: Component_Array_Package_Base;\n");
//         for id : ids {
//             print(*builder, "%: Component_Array(Component_ID.%);\n", to_lower(tprint("%", id)), id);
//         }
//         first_id := to_lower(tprint("%", ids[0]));
//         print(*builder, "#overlay(%) all_arrays: [%]Component_Array(xx 0);\n", first_id, ids.count);
//         return builder_to_string(*builder);
//     }
// }

// optional convenience string generator. #insert #run wherever you want your entity component storage.
generate_entity_component_storage_declaration :: (
    components_name := "entity_component_storage",
    pointers_name   := "entity_id_storage",
    tracked_name    := "tracked_entity_storage"
) -> string {
    return tprint(
#string HERE
%: [%]Component_Array_Untyped;
%: [%][..]s64;
%: [..]*void;
HERE,
        components_name, importer.component_declarations.count,
        pointers_name,   importer.component_declarations.count,
        tracked_name
    );
}

Component_ID :: enum u16 {
    #insert -> string {
        builder: String_Builder;
        for decl : importer.component_declarations {
            print(*builder, "\t%_%;\n", decl.kind, decl.name);
        }
        return builder_to_string(*builder);
    }
}

// the component enum, generated from your input in the same order
Component_Name :: enum u16 {
    #insert -> string {
        builder: String_Builder;
        unique_names: [..]string;
        for decl : importer.component_declarations {
            array_add_if_unique(*unique_names, decl.name);
        }
        for name : unique_names {
            print(*builder, "\t%;\n", name);
        }
        return builder_to_string(*builder);
    }
}

Component_Kind :: enum u16 {
     #insert -> string {
        builder: String_Builder;
        unique_kinds: [..]string;
        for decl : importer.component_declarations {
            array_add_if_unique(*unique_kinds, decl.kind);
        }
        for kind : unique_kinds {
            print(*builder, "\t%;\n", kind);
        }
        return builder_to_string(*builder);
    }   
}

#load "component.jai";
#load "manage.jai";

#import "Basic";
#import "Atomics";
#import "Basic";
#import "Math";

#import "TeRM/TeRM_String";
#import "TeRM/TeRM_FlagArray";
#import "TeRM/TeRM_Storage";
#import "TeRM/TeRM_LogHelpers";
#import "TeRM/TeRM_Metaprogram";
#import "TeRM/TeRM_Math";
#import "TeRM/TeRM_Allocation";
#import "TeRM/TeRM_Array";

#scope_module

Component_Declaration :: importer.component_decl_type;
