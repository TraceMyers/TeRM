
INVALID_COMPONENT_INDEX : Component_Index : #run cast,trunc(Component_Index) 0xffff_ffff_ffff_ffff;

// a non-polymorphic header to grab onto when acting type-agnostically
// the ordering (index, kind, flags) gives 8 bytes when component index type is 4 bytes and kind is 2.
// in general probably should keep component index first, kind second, flags 3rd, since that is likely
// a decreasing-to-equal order in size most of the time.
Component_Sentinel_Header :: struct {
    component_index := INVALID_COMPONENT_INDEX;
    kind: Component_Kind;
    component_flags: Component_Sentinel_Flags;
}

Component_Sentinel :: struct(
    $in_kind: Component_Kind, 
    $declare_pointers_to_components := false, 
    $set_these_pointers_to_using: ..Component_Name 
) {
    COMPONENTS :: #run,stallable get_component_ids(in_kind);

    using component_sentinel_header := Component_Sentinel_Header.{ kind = in_kind };

    #if declare_pointers_to_components {

        component_sentinel_header.component_flags = .HAS_POINTERS_TO_COMPONENTS;

        #insert -> string {
            builder: String_Builder;
            first_name: string;
            for component : COMPONENTS {
                name := component_id_to_name(component);
                field_lower := to_lower(tprint("%", name),,temp);

                if it_index == 0 {
                    first_name = field_lower;
                }

                using_insert := "";
                for using_name : set_these_pointers_to_using {
                    if using_name == name {
                        using_insert = "using ";
                        break;
                    }
                }
                print(*builder, "\tusing %_pointer: *struct { %%: #run component_id_to_type(.%); };\n", field_lower, using_insert, field_lower, component);
            }
            print(*builder, "\t#overlay(%_pointer) component_pointers: [%]*void;", first_name, COMPONENTS.count);
            return builder_to_string(*builder);
        }
    }
}

Component_Sentinel_Flags :: enum_flags u8 {
    HAS_POINTERS_TO_COMPONENTS;
}

get_component :: inline (entity: *$I/interface Component_Sentinel_Header, $name: Component_Name) -> *$T 
#modify {
    T = component_types[name];
    return true;
} {
    component_id    :: #run component_name_and_kind_to_id(name, I.in_kind);
    component_array := cast(*Component_Array(component_id)) *context.user_component_storage.arrays[component_id];
    return *component_array.array[entity.component_index];
}


is_valid_component_index :: inline (i: Component_Index) -> bool {
    #if (cast(*Type_Info_Integer) Component_Index).signed {
        return i >= 0;
    } else {
        return i != INVALID_COMPONENT_INDEX;
    }
}

// 'index' is not a component enum, but a true index into the logical array of components on this 
// header's sentinel. if the sentinel has 5 component pointers, it's like indexing into a 5-length array 
// of those pointers. this returns a pointer TO the pointer, not the pointer field itself.
get_component_pointer_at_index :: (sent: *Component_Sentinel_Header, index: int) -> **void {
    assert((sent.component_flags & .HAS_POINTERS_TO_COMPONENTS) != 0);
    return xx (((cast(*u8) sent) + OFFSET_FROM_TOP_OF_ENTITY_TO_FIRST_POINTER) + (index * size_of(*void)));
}

// pass a procedure with this signature to specialze_call_for_each_id. 'data' should be a pointer,
// but it doesn't necessarily need to be a void pointer as in the signature here.
specialize_call_for_each_id_proc_type :: #type ($id: Component_ID, it_index: int, data: *void);

// for each compile-time known id in the list, specialize (= instantiate a non-polymorphic definition with 
// specific param types) and call the procedure 'proc'. the procedure should have the above signature.
specialize_call_for_each_id :: ($proc: Code, $component_ids: []Component_ID, data: *void = null) #expand {
    #insert -> string {
        builder: String_Builder;
        proc_name :: #run code_string(proc);
        for id : component_ids {
            print(*builder, "`%(.%, %, xx data);\n", proc_name, id, it_index);
        }
        return builder_to_string(*builder);
    }
}

// for all component ids, specialize (= instantiate a non-polymorphic definition with 
// specific param types) and call the procedure 'proc'. see above for more info.
specialize_call_for_all_ids :: ($proc: Code, data: *void = null) #expand {
    #insert -> string {
        builder: String_Builder;
        proc_name :: #run code_string(proc);
        for 0..enum_highest_value(Component_ID) {
            id := cast(Component_ID) it;
            print(*builder, "`%(.%, %, xx data);\n", proc_name, id, it);
        }
        return builder_to_string(*builder);
    }
}

#scope_module

// used for indexing to an component info's pointers
OFFSET_FROM_TOP_OF_ENTITY_TO_FIRST_POINTER :: #run -> int {
    header_size := size_of(Component_Sentinel_Header);
    remainder := header_size % 8;
    if remainder == 0 {
        return header_size;
    } else {
        return header_size + (8 - remainder);
    }
    // ends_with :: (#import "String").ends_with;
    // cinfo : Component_Sentinel(in_kind = cast(Component_Kind) 0, true);
    // tinfo := cast(*Type_Info_Struct) type_of(cinfo);
    // for member : tinfo.members {
    //     if ends_with(member.name, "_pointer") {
    //         return member.offset_in_bytes;
    //     }
    // }
    // return 0;
}

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
