// -----------------------------------------------------------------------------------
// ------------------------------------------------------------------- :Component_Info

// a header/map of every Component_Info, for navigating it at runtime.
Component_Sentinel :: struct {
    // for inspection of what components an entity has
    component_flags:   Flag_Array(Component_Name);
    // for whatever
    description_flags: Component_Description_Flags;
}

Component_Info :: struct (
    $components:                ..Component_Name, 
    $declare_component_pointers := false, 
    $using_component_pointers   := false
) {
    comptime_cid :: #run -> int { value := component_info_type_id_counter; component_info_type_id_counter += 1; return value; };

    #if components.count > 0 {
        #if declare_component_pointers {
            using #as component_sentinel := Component_Sentinel.{
                component_flags        = #run make_flag_array(..components),
                description_flags      = .HAS_POINTERS_TO_COMPONENTS
            };
            #insert -> string {
                builder: String_Builder;
                for components {
                    field_lower := to_lower(tprint("%", cast(Component_Name) it),,temp);
                    #if using_component_pointers {
                        print(*builder, "\tusing %_pointer: *struct { using %: #run importer.component_declarations[%].type; };\n", field_lower, field_lower, cast(int) it);
                    } else {
                        print(*builder, "\tusing %_pointer: *struct { %: #run importer.component_declarations[%].type; };\n", field_lower, field_lower, cast(int) it);
                    }
                }
                return builder_to_string(*builder);
            }
        } else {
            using #as component_sentinel := Component_Sentinel.{
                component_flags        = #run make_flag_array(..components),
                description_flags      = 0
            };
            #insert -> string {
                builder: String_Builder;
                for components {
                    field_lower := to_lower(tprint("%", cast(Component_Name) it),,temp);
                    print(*builder, "\t%_id: u16 = 0xffff;\n", field_lower);
                }
                return builder_to_string(*builder);
            }
        }
    }
}

Component_Description_Flags :: enum_flags u8 {
    HAS_POINTERS_TO_COMPONENTS;
}

// -----------------------------------------------------------------------------------
// ------------------------------------------------------- :type-stripped interactions
// for when the component info's owner type is unknown, still need information from it.

per_component :: (sent: *Component_Sentinel, body: Code, flags: For_Flags) #expand {
    `it_index: int;
    for i : 0..enum_highest_value(Component_Name) {
        `it := cast(Component_Name) i;
        if has_component(sent, `it) {
            defer it_index += 1;
            `component_array := *context.entity_component_arrays[it];
            #insert body;
        }
    }
}

// 'index' is not the component enum, but a true index. if the component info has 5 component pointers, 
// it's like indexing into a 5-length array of those pointers. this returns a pointer TO the pointer,
// not the pointer field itself.
get_component_pointer_at_index :: (sent: *Component_Sentinel, index: int) -> **void {
    return xx (((cast(*u8) sent) + OFFSET_FROM_TOP_OF_ENTITY_TO_FIRST_POINTER) + (index * size_of(*void)));
}

get_component_id_at_index :: (sent: *Component_Sentinel, index: int) -> *u16 {
    return xx (((cast(*u8) sent) + OFFSET_FROM_TOP_OF_ENTITY_TO_FIRST_ID) + (index * size_of(u16)));
}

// -----------------------------------------------------------------------------------
// ---------------------------------------------------------------------- :basic query

to_type :: inline (name: Component_Name) -> Type {
    return COMPONENT_TYPES[name.(int)];
}

component_id_is_valid :: inline (index: u16) -> bool {
    return index != 0xffff;
}

invalidate_component_id :: (index: *u16) {
    index.* = 0xffff;
}

has_component :: inline (sent: *Component_Sentinel, name: Component_Name) -> bool {
    return is_set(*sent.component_flags, name);
}

// -----------------------------------------------------------------------------------
// ------------------------------------------------------------------------------ :get

// if you're referring to a component whose name is known at compile time, you can have 
// it typecasted automatically. it's a little more convenient and less error prone to say
// 
// position_array := get_component_array(.POSITION);
//
// ... than it is to say...
//
// position_array := cast(*[..]Vector3) *context.component_arrays[Component_Name.POSITION];
get_component_array :: ($name: Component_Name) -> *[..]$T 
#modify {
    T = importer.component_declarations[xx name].type;
    return true;
} {
    return cast(*[..]T) *context.entity_component_arrays[name];
}

// returns array of indices to entity arrays
get_entities_that_have_component :: (name: Component_Name) -> []s32 {
    arrays: [..]s32;
    arrays.allocator = temp;
    array_reserve(*arrays, min(context.entity_array_references.count, 256));

    for ref, ref_index : context.entity_array_references.* {
        if is_set(*ref.component_flags, name) {
            array_add(*arrays, ref_index);
            break;
        }
    }

    return arrays;
}

// -----------------------------------------------------------------------------------
// -------------------------------------------------------------------------- :codegen

get_component :: (sent: *Component_Sentinel, $name: Component_Name) -> *$T 
#modify {
    T = importer.component_declarations[xx name].type;
    return true;
} {
    #if sent.declare_component_pointers {
        return #insert #run tprint("*sent.%;", to_lower(tprint("%", name)));
    } else {
        component_array := cast(*[..]T) *context.entity_component_arrays[name];
        component_id := #insert #run tprint("*sent.%_id;", to_lower(tprint("%", name)));
        if component_id_is_valid(component_id.*) {
            return *(component_array.*)[component_id.*];
        } else return null;
    }
}

// for each of the component types in the list (known at compile time), generate
// a scope with the component's id, type and array to refer to, and insert a block
// of code into that scope. in other words, an unrolled loop.
//
// this isn't a macro because macro backtick declarations are all put into the outer scope,
// which piles them all into the same scope, which causes a redefine error per 
// declaration x number of components. loops don't have this problem, but this isn't a loop.
for_each_component_type :: ($components: []Component_Name, body: Code) -> string {
    builder: String_Builder;
    body_str := code_string(body);
    for components {
        print(*builder, 
#string HERE
    {
        component_index :: %;
        component_id    :: Component_Name.%;
        component_type  :: #run importer.component_declarations[component_id].type;
        component_array := cast(*[..]component_type) *context.entity_component_arrays[component_id];
        %
    }
HERE,
            it_index, it, body_str
        );
    }
    output := builder_to_string(*builder);
    return output;
}

for_every_component_type :: (body: Code) -> string {
    builder: String_Builder;
    body_str := code_string(body);
    for 0..enum_highest_value(Component_Name) {
        print(*builder, 
#string HERE
    {
        component_index :: %;
        component_id    :: Component_Name.%;
        component_type  :: #run importer.component_declarations[component_id].type;
        component_array := cast(*[..]component_type) *context.entity_component_arrays[component_id];
        %
    }
HERE,
            it, cast(Component_Name) it, body_str
        );
    }
    output := builder_to_string(*builder);
    return output;
}

// -----------------------------------------------------------------------------------

#scope_module

component_info_type_id_counter: u16 = 0;

// for a given component, create a space of variables and constants where the
// inserted code can work on the component, the array of the component, the component
// id on the entity, etc.
// component_do_impl :: ($name: Component_Name, $body: string) -> string {
//     `component_type  :: #run importer.component_declarations[name].type;
//     `component_id    :: name;
//     `component_array := cast(*[..]`component_type) *context.entity_component_arrays[name];
//     #insert body;
// }

// this is used to get the compiler to allow me to define the return type by indexing into a Type.[],
// as in:
// proc :: ($name: Component_Name) -> extract_type(COMPONENT_TYPES[name]).T
// if I don't wrap, compiler complains that you can't index with an enum or that you can't use []
extract_type :: struct ($decl: Component_Declaration) { type :: decl.type; }

// used for indexing to an component info's pointers
OFFSET_FROM_TOP_OF_ENTITY_TO_FIRST_POINTER :: #run -> int {
    ends_with :: (#import "String").ends_with;
    cinfo : Component_Info(..components = cast(Component_Name) 0, declare_component_pointers=true, true);
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
    cinfo : Component_Info(..components = cast(Component_Name) 0, declare_component_pointers=false);
    tinfo := cast(*Type_Info_Struct) type_of(cinfo);
    for member : tinfo.members {
        if ends_with(member.name, "_id") {
            return member.offset_in_bytes;
        }
    }
    return 0;
}

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
