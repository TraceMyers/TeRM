#module_parameters()(
    ENABLE_EXAMPLE := false,
    // supply the set components your entities will be using.
    // note: enabling the example is mutually exclusive with supplying your own declarations 
    component_declarations: []Component_Declaration = .[]
) {
    // bringing these imports to your doorstep
    #import "TeRM/TeRM_FlagArray";
    #import "TeRM/TeRM_Storage";
    #import "TeRM/TeRM_String";
    #import "TeRM/TeRM_LogHelpers";
    #import "TeRM/TeRM_Metaprogram";

    Component_Declaration :: struct { name: string; T: Type; }
};

// the ecs data pools array for the module was put on the context for this reason:
//
// the actual array data is declared wherever you like. this is just a pointer and a count.
// so, if you just want a single global set of pools, just set this field once 
// (see term_ecs_example()). or, if you want, say, one set of pools per world, you
// might map one world to one context, and so each time you push a world's context, also
// set the world's ecs pools.
#add_context ecs_component_pools: []Pool(int); 

#insert ecs_enum_def;    // declaring generated enum name definition
#insert ecs_to_type_def; // declaring generated enum name -> type procedure

// -----------------------------------------------------------------------------------
// -------------------------------------------------------------------------- :example

#if ENABLE_EXAMPLE {
    ECS_COMPONENT_COUNT :: 3;

    // create strings containing ecs system definitions.
    ecs_pools_def, ecs_enum_def, ecs_to_type_def :: #run declare_ecs_fields(
        // each of these entries represents:
        //     - an entry in the Component_Name enum             (e.g. Component_Name.POSITION)
        //     - an optional index field on any Entity subclass  (e.g. component_id_position: u16)
        //     - an array of the given data type                 (e.g. ecs_positions: [..]Vector3)
        {name = "position",    T = Vector3},
        {name = "velocity",    T = Vector3},
        {name = "orientation", T = Quaternion}
    );

    // declaring the component pools once in the global scope.
    // it's actually just a string literal, provided for convenience. 
    // if you just want to declare the pools directly in code and name it whatever you want, 
    // the declaration looks like 'whatever_you_want: [ECS_COMPONENT_COUNT]Pool(int);'
    #insert ecs_pools_def;

    Entity_Gadget :: struct {
        handle: s32;
    }

    My_Entity :: Entity ( 
        struct {
            gadgets: []Entity_Gadget;
        },
        .POSITION, 
        .VELOCITY, 
        .ORIENTATION
    );

    term_ecs_example :: () {
        // tell this module where the pools are
        context.ecs_component_pools = ecs_component_pools;

        ent_a: My_Entity;        
        init(*ent_a);
        log("ent: %", _fmt_verbose(ent_a));

        ent_b: My_Entity;
        init(*ent_b);
        log("ent: %", _fmt_verbose(ent_b));
    }
} else {
    ECS_COMPONENT_COUNT :: #run component_declarations.count;

    ecs_pools_def, ecs_enum_def, ecs_to_type_def :: #run declare_ecs_fields(
        ..component_declarations
    );
}

// -----------------------------------------------------------------------------------
// --------------------------------------------------------------------------- :Entity

INVALID_COMPONENT_ID : s16 : 0xffff;

Entity :: struct ($T: Type, $components: ..Component_Name) {
    using #as base: T;

    #if components.count > 0 {
        // a flag array for runtime inspection of what components an entity has
        component_flags: Flag_Array(Component_Name);

        #insert -> string {
            builder: String_Builder;
            for components {
                field_lower := to_lower(tprint("%\n", it),,temp);
                print(*builder, "component_id_%: s16 = INVALID_COMPONENT_ID;\n", field_lower);
            }
            return builder_to_string(*builder);
        }
    }
}

// -----------------------------------------------------------------------------------
// --------------------------------------------------------------- :declare_ecs_fields

// call this once in your program to declare the entity fields that will be handled by
// this system

declare_ecs_fields :: (declarations: ..Component_Declaration) -> pools: string, enum_def: string, component_to_type_proc_def: string {
    enum_builder: String_Builder;
    to_type_builder: String_Builder;

    print(*enum_builder, "Component_Name :: enum u16 {\n");
    print(*to_type_builder, "component_to_type :: Type.[\n");

    for decl : declarations {
        assert(decl.name != "");
        enum_name := to_upper(decl.name,,temp);
        
        print(*enum_builder, "    %;\n", enum_name);
        print(*to_type_builder, "\t%,\n", decl.T);
    }

    print(*enum_builder, "}\n");
    print(*to_type_builder, "];\n");

    pools    := tprint("ecs_component_pools: [%]Pool(int);\n", declarations.count);
    enum_def := builder_to_string(*enum_builder);
    to_type  := builder_to_string(*to_type_builder);

    return pools, enum_def, to_type;
}

// -----------------------------------------------------------------------------------
// ------------------------------------------------------------------ :init and deinit

init :: (ent: *Entity) {
    ecs_for_each_component(ent, #code {
        component_id.* = xx pool_acquire(component_pool);
        set(*ent.component_flags, component_name);
    });
}

// -----------------------------------------------------------------------------------
// ------------------------------------------------- :per-entity component interaction

// run arbitrary code over all components on an entity
ecs_for_each_component :: inline (ent: *Entity, $body: Code) {
    #insert -> string {
        builder: String_Builder;
        for cmp, ci : ent.components {
            print(*builder, 
#string HERE
    {
        ecs_component_do_impl(ent, .%, #run code_string(body));
    }
HERE,
                cmp
            );
        }
        output := builder_to_string(*builder);
        log(output);
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
ecs_component_do_impl :: (ent: *Entity, $name: Component_Name, $body: string) #expand {
    `component_name  :: name;
    `component_id    := #insert #run tprint("*ent.component_id_%;", to_lower(tprint("%", name)));
    `component_pool  := cast(*Pool(component_to_type[name])) *context.ecs_component_pools[name];
    #insert body;
}

#scope_export

#import "Basic";
#import "Math";
