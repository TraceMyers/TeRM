// this is close to the simplest thing you can reasonably call an "entity component system",
// or at least the "component system" part. store all components of a type in a single
// array, then associate an entity ID with its component, which allows for automatic tight
// packing of components + management of the component pointers on the entities when
// component data moves around.
//
// when importing this module, you need to pass one type and two procedures. (replace 'your' entries with your stuff)
//
// #import "TeRM/TeRM_Component"(
//     user_types = struct {
//         entity_id_type      :: Your_Entity_ID;       // your entity id data type
//         entity_to_id_proc   :: your_entity_to_id;    // your procedure, type: (*entity) -> entity id
//         id_to_entity_proc   :: your_id_to_entity;    // your procedure, type: (entity id) -> *entity
//     }
// );
//
// 'entity' in this case just means a struct that has a pointer to an instance of the relevant component type. 
// the first pointer of the component's type on said entity struct is assumed to be the relevant component pointer.
//
// e.g. 
// {
//      entity_cheeks: Component_Array(Entity_Cheek);
//
//      Entity :: struct {
//          id: u64;
//          left_cheek:  *Entity_Cheek; <----------- only the first pointer will be valid
//          right_cheek: *Entity_Cheek;              after component_array_add()
//      }                                              |
//                                                     |
//      e := Entity.{id=1};                            |
//                                                     |
//      component_array_add(*entity_cheeks, e.id); o---+
//      component_array_add(*entity_cheeks, e.id, *e.right_cheek); <-- setting the other cheek
// }
//
// the consistency and simplicity of this approach makes it easier to manage than other implementations.
//
// the intended way to use this module:
//  
// Entity_Components :: struct {
//      hair_components: Component_Array(Hair);
//      personality_components: Component_Array(Personality);
// }
//
// World :: struct {
// ...
//      using entity_components: Entity_Components;
// ...
// }
//
// spawn_entity :: () -> *Entity {
// ...
//      component_array_add(*world.hair_components, new_entity.id);
//      component_array_add(*world.personality_components, new_entity.id);
// ...
// }
//
// style_entity_hairs :: () {
// ...
//      for world.hair_components {
//          entity := your_id_to_entity(it.entity_id); // get associated entity if you need to
//          style_hair(it.component);
//      }
// ...
// }
// 
// destroy_entity :: (entity: *Entity) {
// ...
//      component_array_remove(*world.hair_components, entity.id);
//      component_array_remove(*world.personality_components, entity.id);
// ...
// } -

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
    initialized: bool;
}

Component_Array_Iteration :: struct($component_type: Type) {
    component: *component_type;
    entity_id: user_types.entity_id_type;
}

for_expansion :: (array: Component_Array, body: Code, flags: For_Flags) #expand {
    iteration_type :: Component_Array_Iteration(array.component_type);
    
    for <=((flags & .REVERSE) != 0) i : 0..array.components.count-1 {
        `it_index  := i;
        `it        := iteration_type.{*array.components[i], array.ids[i]};

        #insert body;
    }
}

component_array_init :: (array: *Component_Array, size: int) {
    array_type :: #run type_of(array);
    array_reserve(*array.components, size);
    array_reserve(*array.ids, size);
    array.initialized = true;
}

component_array_add :: (array: *Component_Array($component_type), id: user_types.entity_id_type, component: **component_type = null) {
    assert(array.components.count == array.ids.count);

    component_ptr: **component_type;
    component_ptr_offset: int;
    data_after, data_before: *component_type;

    // scoped so that 'entity' var isn't accidentally used below when looping over entities via their components
    {
        entity := user_types.id_to_entity_proc(id);
        component_ptr, component_ptr_offset := get_component_pointer_and_offset(array, entity, component);
        data_before = array.components.data;
        component_ptr.* = array_add(*array.components);
        data_after  = array.components.data;
        array_add(*array.ids, id);
    }
    
    // potential hotspot here. for very long component arrays, try preallocating more than you need.
    if data_after != data_before {
        fix_component_pointers(array, component_ptr_offset);
    }
}

// pass 'component' (pointer to the component member on the entity) for additional validation.
component_array_remove :: (array: *Component_Array($component_type), id: user_types.entity_id_type, component: **component_type = null, auto_shrink := false) {
    assert(array.components.count == array.ids.count);

    entity := user_types.id_to_entity_proc(id);
    component_ptr, component_ptr_offset := get_component_pointer_and_offset(array, entity, component);
    if component != null {
        assert(component_ptr.* == component.*);
    }

    index := component_ptr.* - array.components.data;
    assert(array.ids[index] == id); // make sure we're not removing a component out from under another entity

    component_ptr.* = null;

    if index < array.components.count - 1 {
        // swap back
        array.components[index] = array.components[array.components.count-1];
        array.ids[index]        = array.ids[array.components.count-1];
        entity_at_end          := user_types.id_to_entity_proc(array.ids[index]);
        component_ptr           = cast(**component_type) ((cast(*u8) entity_at_end) + component_ptr_offset);
        component_ptr.*         = *array.components[index];
    } 

    array.components.count -= 1;
    array.ids.count        -= 1;

    // potential hotspot here. for very long component arrays, try setting auto_shrink to false
    if auto_shrink && component_array_shrink_if_small_enough(array) {
        fix_component_pointers(array, component_ptr_offset);
    }
}

component_array_shrink_if_small_enough :: (array: *Component_Array, realloc_if_using_leq_proportion := 0.35, remove_free_proportion := 0.75, minimum_allocated := 8) -> bool {
    if array_shrink_if_small_enough(*array.components, realloc_if_using_leq_proportion, remove_free_proportion, minimum_allocated) {
        array.ids.count = array.components.count;
        array_shrink(*array.ids, remove_free_proportion);
        return true;
    } else return false;
}

// iterate over all entities owning this component and fix the component pointers so they're pointing 
// into the component array. this should not need to be called outside this module, but it's 
// potentially useful for debugging.
fix_component_pointers :: inline (array: *Component_Array, component_ptr_offset_override: int = -1) {
    component_type             :: #run type_of(array.*).component_type;
    first_component_ptr_offset :: #run get_first_component_pointer_offset(component_type);
    component_ptr_offset := ifx component_ptr_offset_override == -1 then first_component_ptr_offset else component_ptr_offset_override;

    for 0..array.ids.count-1 { 
        entity     := user_types.id_to_entity_proc(array.ids[it]);
        e_cmp_ptr  := cast(**component_type) ((cast(*u8) entity) + component_ptr_offset);
        e_cmp_ptr.* = *array.components[it];
    }
}

get_component_pointer_and_offset :: inline (array: *Component_Array($component_type), entity: *$Entity_Type, component_ptr_override: **component_type) -> **component_type, int {
    first_component_ptr_offset :: #run get_first_component_pointer_offset(component_type);

    component_ptr_offset: int = -1;
    component_ptr: **component_type;

    if component_ptr_override {
        component_ptr_offset = cast(*u8) component_ptr_override - cast(*u8) entity;
        component_ptr        = component_ptr_override;
        // todo: debug on = do check at runtime that there is truly component of that type at the override offset
    } else {
        component_ptr_offset = first_component_ptr_offset;
        component_ptr = cast(**component_type) ((cast(*u8) entity) + component_ptr_offset);
    }

    assert(component_ptr_offset >= 0 && component_ptr_offset < size_of(type_of(entity.*)));
    return component_ptr, component_ptr_offset;
}

// pass a pointer to an instance of a struct that has component array members
// and validate that those arrays are initialized. useful if you put all of
// your component arrays on one struct - makes it a runtime error to add a new component
// array without initializing it.
debug__validate_component_arrays_initialized :: (entity_components: *$Entity_Components) {
    components_info := cast(*Type_Info_Struct) type_info(Entity_Components);
    assert(components_info.type == .STRUCT);
    for member : components_info.members {
        if !is_subclass_of(member.type, "Component_Array") {
            continue;
        }
        // all component array types specializations have their members at the same offsets.
        // so, (void) just means the specialization doesn't matter.
        component_array := cast(*Component_Array(void)) (cast(*u8) entity_components + member.offset_in_bytes);
        assert(component_array.initialized, "entity component array % uninitialized!", member.name);
    }
}

debug__validate_component_pointers :: (array: *Component_Array, component_ptr_offset_override: int = -1) {
    component_type             :: #run type_of(array.*).component_type;
    first_component_ptr_offset :: #run get_first_component_pointer_offset(component_type);
    component_ptr_offset := ifx component_ptr_offset_override == -1 then first_component_ptr_offset else component_ptr_offset_override;

     for id : array.ids {
        e := user_types.id_to_entity_proc(id);
        e_cmp_ptr  := cast(**type_of(array.*).component_type) ((cast(*u8) e) + component_ptr_offset);
        assert(e_cmp_ptr.* == *array.components[it_index]);
    }
}

#scope_module

entity_type :: #run -> Type {
    proc_tinfo := type_info(type_of(user_types.entity_to_id_proc));
    assert(proc_tinfo.argument_types[0].type == .POINTER);
    arg_pointer_tinfo := cast(*Type_Info_Pointer) proc_tinfo.argument_types[0];
    return (cast(*Type) *(arg_pointer_tinfo.pointer_to)).*;
}

get_first_component_pointer_offset :: (component_type: Type) -> int {
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
#import "Compiler";

#import "TeRM/TeRM_Array";

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
