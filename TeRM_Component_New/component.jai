// a non-polymorphic header to grab onto when acting type-agnostically
Component_Sentinel_Header :: struct {
    // for inspection of what components an entity has
    has_components: Flag_Array(Component_ID);
    // for whatever
    component_flags: Component_Sentinel_Flags;
}

Component_Sentinel :: struct(
    $kind: Component_Kind, 
    $component_references_are_pointers := false, 
    $set_these_pointers_to_using: ..Component_Name 
) {
    COMPONENTS :: #run get_component_ids_at_compile_time(kind);

    using header := Component_Sentinel_Header.{
        has_components  = #run make_flag_array(..COMPONENTS),
        component_flags = 0
    };

    #if component_references_are_pointers {

        header.component_flags = .HAS_POINTERS_TO_COMPONENTS;

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
    } else {
        #insert -> string {
            builder: String_Builder;
            first_name: string;
            for component : COMPONENTS {
                name := component_id_to_name(component);
                field_lower := to_lower(tprint("%", name),,temp);
                if it_index == 0 {
                    first_name = field_lower;
                }
                print(*builder, "\t%_id: u16 = 0xffff;\n", field_lower);
            }
            print(*builder, "\t#overlay(%_id) component_indices: [%]u16;", first_name, COMPONENTS.count);
            return builder_to_string(*builder);
        }
    }
}

Component_Sentinel_Flags :: enum_flags u8 {
    HAS_POINTERS_TO_COMPONENTS;
}

// 'index' is not the component enum, but a true index. if the component info has 5 component pointers, 
// it's like indexing into a 5-length array of those pointers. this returns a pointer TO the pointer,
// not the pointer field itself.
get_component_pointer_at_index :: (sent: *Component_Sentinel, index: int) -> **void {
    assert((sent.component_flags & .HAS_POINTERS_TO_COMPONENTS) != 0);
    return xx (((cast(*u8) sent) + OFFSET_FROM_TOP_OF_ENTITY_TO_FIRST_POINTER) + (index * size_of(*void)));
}

get_component_id_at_index :: (sent: *Component_Sentinel, index: int) -> *u16 {
    assert((sent.component_flags & .HAS_POINTERS_TO_COMPONENTS) == 0);
    return xx (((cast(*u8) sent) + OFFSET_FROM_TOP_OF_ENTITY_TO_FIRST_ID) + (index * size_of(u16)));
}

component_id_is_valid :: inline (index: u16) -> bool {
    return index != 0xffff;
}

invalidate_component_id :: inline (index: *u16) {
    index.* = 0xffff;
}

#scope_module

// used for indexing to an component info's pointers
OFFSET_FROM_TOP_OF_ENTITY_TO_FIRST_POINTER :: #run -> int {
    ends_with :: (#import "String").ends_with;
    cinfo : Component_Sentinel(kind = cast(Component_Kind) 0, true);
    tinfo := cast(*Type_Info_Struct) type_of(cinfo);
    for member : tinfo.members {
        if ends_with(member.name, "_pointer") {
            return member.offset_in_bytes;
        }
    }
    return 0;
}

OFFSET_FROM_TOP_OF_ENTITY_TO_FIRST_ID :: #run -> int {
    ends_with :: (#import "String").ends_with;
    cinfo : Component_Sentinel(kind = cast(Component_Kind) 0, false);
    tinfo := cast(*Type_Info_Struct) type_of(cinfo);
    for member : tinfo.members {
        if ends_with(member.name, "_id") {
            return member.offset_in_bytes;
        }
    }
    return 0;
}
