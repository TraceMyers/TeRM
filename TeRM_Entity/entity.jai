
// -----------------------------------------------------------------------------------
// --------------------------------------------------------------------------- :Entity

Entity :: struct ($base_type: Type, $components: ..Component_Name, $declare_pointers := false) {
    using #as base: base_type;

    #if components.count > 0 {
        // a flag array for runtime inspection of what components an entity has
        component_flags: Flag_Array(Component_Name);

        #if declare_pointers then #insert -> string {
            builder: String_Builder;
            declarations := #ifx ENABLE_EXAMPLE then example_component_declarations else component_declarations;
            for components {
                field_lower := to_lower(tprint("%", it),,temp);
                print(*builder, "\tusing %_pointer: *struct { %: %; };\n", field_lower, field_lower, declarations[it].data_type);
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

init :: (ent: *Entity) {
    for_each_component(ent, #code {
        #if ent.declare_pointers {
            id := pool_acquire(component_pool);
            component_pointer.* = xx *(component_pool.*)[id];
        } else {
            component_id.* = xx pool_acquire(component_pool);
        }
        set(*ent.component_flags, component_name);
    });
}
