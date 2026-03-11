#module_parameters()(
    ENABLE_EXAMPLE := false,
    // supply the set components your entities will be using.
    // note: enabling the example is mutually exclusive with supplying your own declarations 
    component_declarations: []Component_Declaration = .[]
) {
    // bringing these imports to your doorstep
    #import "Basic";
    #import "Math";
    #import "TeRM/TeRM_FlagArray";
    #import "TeRM/TeRM_Storage";
    #import "TeRM/TeRM_String";
    #import "TeRM/TeRM_LogHelpers";
    #import "TeRM/TeRM_Metaprogram";
    #import "TeRM/TeRM_Math";
    #import "TeRM/TeRM_Allocation";

    Component_Declaration :: struct { name: string; id_type: Type; data_type: Type; }
};

// -----------------------------------------------------------------------------------
// -------------------------------------------------------------------------- :globals

// the ecs data pools array for the module was put on the context for this reason:
//
// the actual array data is declared wherever you like. this is just a pointer and a count.
// so, if you just want a single global set of pools, just set this field once 
// (see term_ecs_example()). or, if you want, say, one set of pools per world, you
// might map one world to one context, and so each time you push a world's context, also
// set the world's ecs pools.
#add_context ecs_component_pools: []Pool(int); 

#insert ecs_enum_def;         // declaring generated enum name definition
#insert ecs_enum_to_type_def; // declaring generated enum name -> type procedure

#if ENABLE_EXAMPLE { // --------------------------------------------------------------
// -------------------------------------------------------------------------- :example

    ECS_COMPONENT_COUNT :: 3;

    example_component_declarations := Component_Declaration.[
        // each of these entries represents:
        //     - an entry in the Component_Name enum             (e.g. Component_Name.POSITION)
        //     - an optional index field on any Entity subclass  (e.g. component_id_position: s16)
        //     - an array of the given data type                 (e.g. ecs_positions: [..]Vector3)
        //
        // id_type determines the maximum number of entities that can have the given component.
        // because velocity has id_type s16, the maximum number of entities that can have
        // a velocity component is 32,767.
        {name = "position",    id_type = s32, data_type = Vector3},
        {name = "velocity",    id_type = s16, data_type = Vector3},
        {name = "orientation", id_type = s16, data_type = Quaternion}
    ];

    // create strings containing ecs system definitions.
    ecs_allocators_def, ecs_enum_def, ecs_enum_to_type_def :: #run declare_ecs_fields(
        ..example_component_declarations
    );

    // declaring the component pools once in the global scope.
    #insert ecs_allocators_def;

    Entity_Gadget :: struct {
        handle: s32;
    }

    My_Entity_A :: Entity ( 
        struct {
            gadgets: []Entity_Gadget;
        },
        .POSITION, 
        .VELOCITY, 
        .ORIENTATION
    );

    My_Entity_B :: Entity ( 
        struct {
            gadgets: []Entity_Gadget;
        },
        .POSITION, 
    );

    // this guy has a pointer to a struct on it that looks like
    // for convenience's sake. also, 
    My_Entity_C :: Entity ( 
        base_type = struct {
            gadgets: []Entity_Gadget;
        },
        declare_pointers = true,
        ..components =
            .POSITION, 
            .VELOCITY, 
            .ORIENTATION
    );

    term_ecs_example :: () {
        // tell this module where the allocators are
        context.ecs_component_pools = ecs_component_pools;

        ent_a: My_Entity_A;        
        init(*ent_a);
        log("an initialized entity with three components: %", _fmt_verbose(ent_a));
        log("\ntype a has component velocity: %\n--", has_component(*ent_a, .VELOCITY));

        ent_b: My_Entity_B;
        // init(*ent_b);
        log("an uninitialized entity with only a position component: %", _fmt_verbose(ent_b));
        log("\ntype b has component velocity: %\n--", has_component(*ent_b, .VELOCITY));

        pool := get_component_pool(.POSITION);
        log("pool type: %", pool.*);

        ent_c: My_Entity_C;
        init(*ent_c);
        log("an initialized entity with three components and pointer storage: %", _fmt_verbose(ent_c));

        ent_c.velocity += {1,1,1};
        ent_c.orientation = {};
        log("--\nentities with pointer storage can access those fields as if they were declared on the struct."); 
        log("you don't use normal pointer ref/deref syntax. because of keyword 'using', everything auto-derefs.\n--");
        log("ent_c.position = %", ent_c.position);
        log("ent_c.velocity = %", ent_c.velocity);
        log("ent_c.orientation = %", ent_c.orientation);
    }

} else { // --------------------------------------------------------------------------

    ECS_COMPONENT_COUNT :: #run component_declarations.count;

    ecs_allocators_def, ecs_enum_def, ecs_enum_to_type_def :: #run declare_ecs_fields(
        ..component_declarations
    );

}

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
// ----------------------------------------------------------------------- :components

// if you're referring to a component whose name is known at compile time, you can have 
// it typecasted automatically. it's a little more convenient and less error prone to say
// 
// position_pool := get_component_pool(.POSITION);
//
// ... than it is to say...
//
// position_pool := cast(*Pool(Vector3)) *context.ecs_component_pools[Component_Name.POSITION];
get_component_pool :: inline ($name: Component_Name) -> *Pool(component_to_type[xx name]) {
    return cast(*Pool(component_to_type[xx name])) *context.ecs_component_pools[name];
}

// -----------------------------------------------------------------------------------
// ------------------------------------------------------------------ :init and deinit

init :: (ent: *Entity) {
    ecs_for_each_component(ent, #code {
        #if ent.declare_pointers {
            id := pool_acquire(component_pool);
            component_pointer.* = xx *(component_pool.*)[id];
        } else {
            component_id.* = xx pool_acquire(component_pool);
        }
        set(*ent.component_flags, component_name);
    });
}

// -----------------------------------------------------------------------------------
// ------------------------------------------------- :per-entity component interaction

has_component :: inline (e: *Entity, name: Component_Name) -> bool {
    return is_set(*e.component_flags, name);
}

// run arbitrary code over all components on an entity
ecs_for_each_component :: inline (ent: *Entity, $body: Code) {
    #insert -> string {
        builder: String_Builder;
        for cmp, ci : ent.components {
            print(*builder, 
#string HERE
    {
        ecs_component_do_impl(ent, .%, #run code_string(body), %);
    }
HERE,
                cmp, ci
            );
        }
        output := builder_to_string(*builder);
        return output;
    }
}

// run arbitrary code for a given component.
ecs_component_do :: (ent: *Entity, $name: Component_Name, $body: Code) #expand {
    ecs_component_do_impl(ent, name, #run code_string(body));
}

// -----------------------------------------------------------------------------------

#scope_file

// for a given component, create a space of variables and constants where the
// inserted code can work on the component, the pool of the component, the component
// id on the entity, etc.
ecs_component_do_impl :: (ent: *Entity, $name: Component_Name, $body: string, $declare_component_index := -1) #expand {
    `component: *component_to_type[name] = null;

    `component_name  :: name;
    `component_pool  := cast(*Pool(component_to_type[name])) *context.ecs_component_pools[name];

    #if declare_component_index >= 0 {
        `component_index := declare_component_index;
    }

    #if ent.declare_pointers {
        `component_pointer := #insert #run tprint("*ent.%_pointer;", to_lower(tprint("%", name)));
        `component = #insert #run tprint("*ent.%;", to_lower(tprint("%", name)));
        `component_id: int;
        if `component == null {
            `component_id    = -1;
        } else {
            `component_id    = `component - `component_pool.items.data;
        }
    } else {
        `component_id    := #insert #run tprint("*ent.component_id_%;", to_lower(tprint("%", name)));
        if `component_id.* != cast,trunc(type_of(`component_id.*)) 0xffff_ffff {
            `component    = *(`component_pool.*)[`component_id.*];
        }
    }

    #insert body;
}

declare_ecs_fields :: (declarations: ..Component_Declaration) -> allocators: string, enum_def: string, component_to_type_proc_def: string {
    enum_builder: String_Builder;
    to_type_builder: String_Builder;

    print(*enum_builder, "Component_Name :: enum u16 {\n");
    print(*to_type_builder, "component_to_type :: Type.[\n");

    for decl : declarations {
        assert(decl.name != "");
        enum_name := to_upper(decl.name,,temp);
        
        print(*enum_builder, "    %;\n", enum_name);
        print(*to_type_builder, "\t%,\n", decl.data_type);
    }

    print(*enum_builder, "}\n");
    print(*to_type_builder, "];\n");

    allocators := tprint(
#string HERE
ecs_component_pools: [%]Pool(int);
HERE, declarations.count);
    enum_def   := builder_to_string(*enum_builder);
    to_type    := builder_to_string(*to_type_builder);

    return allocators, enum_def, to_type;
}

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
