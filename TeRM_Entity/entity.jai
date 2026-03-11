
// -----------------------------------------------------------------------------------
// --------------------------------------------------------------------------- :Entity

Entity_Ref :: struct {
    eid:   u32;
    index: s32;
}

Entity :: struct ($base_type: Type, $components: ..Component_Name, $declare_component_pointers := false, $using_component_pointers := false) {
    using ref: Entity_Ref;
    using #as base: base_type;

    #if components.count > 0 {
        // a flag array for runtime inspection of what components an entity has
        component_flags: Flag_Array(Component_Name);

        #if declare_component_pointers then #insert -> string {
            builder: String_Builder;
            declarations := #ifx ENABLE_EXAMPLE then example_component_declarations else component_declarations;
            for components {
                field_lower := to_lower(tprint("%", it),,temp);
                #if using_component_pointers {
                    print(*builder, "\tusing %_pointer: *struct { using %: %; };\n", field_lower, field_lower, declarations[it].data_type);
                } else {
                    print(*builder, "\tusing %_pointer: *struct { %: %; };\n", field_lower, field_lower, declarations[it].data_type);
                }
            }
            return builder_to_string(*builder);
        } else #insert -> string {
            builder: String_Builder;
            declarations := #ifx ENABLE_EXAMPLE then example_component_declarations else component_declarations;
            for components {
                field_lower := to_lower(tprint("%\n", it),,temp);
                print(*builder, "\tcomponent_id_%: % = cast,trunc(%) 0xffff_ffff;\n", field_lower, declarations[it].id_type, declarations[it].id_type);
            }
            return builder_to_string(*builder);
        }
    }
}

// -----------------------------------------------------------------------------------
// ------------------------------------------------------------------ :init and deinit

// todo: spawns and destroys are all queued and done by the next frame.
// todo: think about multithreading model. probably just force spawning and destruction
// to be single threaded.

init :: (ent: *Entity) {
    assert(!are_any_set(*ent.component_flags));

    ent.eid = atomic_add(*entity_id_counter, 1);

    for_each_component(ent, #code {
        assert(!is_component_index_valid(component_id.*));
        #if ent.declare_component_pointers {
            component_pointer.* = xx array_add(component_array);
        } else {
            array_add(component_array);
            component_id.* = xx (component_array.count - 1);
        }
        set(*ent.component_flags, component_name);
    });
}

deinit :: (ent: *Entity) {
    for_each_component(ent, #code {
        if is_component_index_valid(component_id.*) {
            array_add(*queued_component_releases, {component_name, component_id.*});
            invalidate_component_index(component_id);
            #if ent.declare_component_pointers {
                component_pointer.* = null;
            }
        }
    });
    clear_all(*ent.component_flags);
}

#scope_module

entity_id_counter: u32;

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
