#module_parameters(
    user_types: $I/interface Type_Provider_Default = Type_Provider_Default
) {
    Type_Provider_Default :: struct {
        entity_id_type      :: void;
        entity_to_id_proc   :: void;
        id_to_entity_proc   :: void;
    }
}

Component_Array :: struct ($component_type: Type) {
    components: [..]component_type;
    ids:        [..]user_types.entity_id_type;
    allocator: Allocator;
}

component_array_init :: (array: *Component_Array, size: int) {
    array_type :: #run type_of(array);

    array_reserve(*array.components, size);
    array_reserve(*array.ids, size);

    // locking allocation to keep pointers valid
    array.components.allocator = {};
    array.ids.allocator        = {};

    // saving allocator if user wants to free later
    array.allocator = context.allocator;
}

component_array_add :: (array: *Component_Array, id: user_types.entity_id_type) {
    assert(array.components.count == array.ids.count);

    array_type               :: #run type_of(array);
    component_type           :: #run array_type.component_type;
    component_pointer_offset :: #run get_component_pointer_offset(component_type);

    entity := user_types.id_to_entity_proc(id);
    component_ptr  := cast(**component_type) ((cast(*u8) entity) + component_pointer_offset);
    component_ptr.* = array_add(*array.components);
    array_add(*array.ids, id);
}

component_array_remove :: (array: *Component_Array, component: *type_of(array).component_type) {
    assert(array.components.count == array.ids.count);

    array_type               :: #run type_of(array);
    component_type           :: #run array_type.component_type;
    component_pointer_offset :: #run get_component_pointer_offset(component_type);

    index := component - array.components.data;
    assert(index >= 0 && index < array.components.count);

    entity := user_types.id_to_entity_proc(array.ids[index]);
    component_ptr  := cast(**component_type) ((cast(*u8) entity) + component_pointer_offset);
    component_ptr.* = null;

    if index < array.components.count - 1 {
        // swap back
        array.components[index] = array.components[array.components.count-1];
        array.ids[index]        = array.ids[array.components.count-1];
        entity_at_end          := user_types.id_to_entity_proc(array.ids[index]);
        component_ptr  = cast(**component_type) ((cast(*u8) entity_at_end) + component_pointer_offset);
        component_ptr.*         = *array.components[index];
    } 

    array.components.count -= 1;
    array.ids.count        -= 1;
}

#scope_module

entity_type :: #run -> Type {
    proc_tinfo := type_info(type_of(user_types.entity_to_id_proc));
    assert(proc_tinfo.argument_types[0].type == .POINTER);
    arg_pointer_tinfo := cast(*Type_Info_Pointer) proc_tinfo.argument_types[0];
    return (cast(*Type) *(arg_pointer_tinfo.pointer_to)).*;
}

get_component_pointer_offset :: (component_type: Type) -> int {
    entity_tinfo := cast(*Type_Info_Struct) type_info(entity_type);
    for member : entity_tinfo.members {
        if member.type.type == .POINTER {
            pointer_tinfo := cast(*Type_Info_Pointer) member.type;
            field_type := (cast(*Type) *(pointer_tinfo.pointer_to)).*;
            if field_type == component_type {
                return member.offset_in_bytes;
            }
        }
    }
    assert(false, "failed to find field of type *% on %", component_type, entity_type);
    return 0;
}

#import "Basic";

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
