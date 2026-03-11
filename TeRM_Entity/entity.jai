// -----------------------------------------------------------------------------------
// --------------------------------------------------------------------------- :Entity

Entity_Ref :: struct {
    eid:   u32;
    index: s32;
}

Entity :: struct ($components: ..Component_Name, $declare_component_pointers := false, $using_component_pointers := false) {
    using ref: Entity_Ref;

    #if components.count > 0 {
        // a flag array for runtime inspection of what components an entity has
        component_flags: Flag_Array(Component_Name);

        #if declare_component_pointers then #insert -> string {
            builder: String_Builder;
            for components {
                field_lower := to_lower(tprint("%", it),,temp);
                #if using_component_pointers {
                    print(*builder, "\tusing %_pointer: *struct { using %: #run importer.component_declarations[%].type; };\n", field_lower, field_lower, cast(int) it);
                } else {
                    print(*builder, "\tusing %_pointer: *struct { %: #run importer.component_declarations[%].type; };\n", field_lower, field_lower, cast(int) it);
                }
            }
            return builder_to_string(*builder);
        } else #insert -> string {
            builder: String_Builder;
            for components {
                field_lower := to_lower(tprint("%\n", it),,temp);
                print(*builder, "\tcomponent_id_%: % = cast,trunc(%) 0xffff_ffff;\n", field_lower, importer.component_declarations[it].id_type, importer.component_declarations[it].id_type);
                // print(*builder, "\tcomponent_id_%: s16 = cast,trunc(s16) 0xffff_ffff;\n", field_lower);
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
            // array_add(*queued_component_releases, {component_name, component_id.*});
            invalidate_component_index(component_id);
            #if ent.declare_component_pointers {
                component_pointer.* = null;
            }
        }
    });
    ent.ref = {};
    clear_all(*ent.component_flags);
}

#scope_module

entity_id_counter: u32 = 1;

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
