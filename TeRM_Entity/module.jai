#module_parameters()(
    ENABLE_EXAMPLE := false,
    // supply the set components your entities will be using here.
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

#load "entity.jai";
#load "component.jai";

// -----------------------------------------------------------------------------------
// -------------------------------------------------------------------------- :globals

// the component pools array for the module was put on the context for this reason:
//
// the actual array data is declared wherever you like. this is just a pointer and a count.
// so, if you just want a single global set of pools, just set this field once 
// (see term_entity_example()). or, if you want, say, one set of pools per world, you
// might map one world to one context, and so each time you push a world's context, also
// set the world's component pools.
#add_context entity_component_pools: []Pool(int); 

#insert component_enum_def;         // declaring generated enum name definition
#insert component_enum_to_type_def; // declaring generated enum name -> type procedure

#if ENABLE_EXAMPLE { // --------------------------------------------------------------
// -------------------------------------------------------------------------- :example

    ENTITY_COMPONENT_COUNT :: 3;

    // example decls. normally you supply them through the module import param
    example_component_declarations := Component_Declaration.[
        // each of these entries represents:
        //     - an entry in the Component_Name enum             (e.g. Component_Name.POSITION)
        //     - an optional index field on any Entity subclass  (e.g. component_id_position: s16)
        //     - an array of the given data type                 (e.g. component_positions: [..]Vector3)
        //
        // id_type determines the maximum number of entities that can have the given component.
        // because velocity has id_type s16, the maximum number of entities that can have
        // a velocity component is 32,767.
        {name = "position",    id_type = s32, data_type = Vector3},
        {name = "velocity",    id_type = s16, data_type = Vector3},
        {name = "orientation", id_type = s16, data_type = Quaternion}
    ];

    // create strings containing component system definitions.
    component_pools_def, component_enum_def, component_enum_to_type_def :: #run declare_entity_components(
        ..example_component_declarations
    );

    // declaring the component pools once in the global scope.
    #insert component_pools_def;

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

    term_entity_example :: () {
        // tell this module where the allocators are
        context.entity_component_pools = entity_component_pools;

        ent_a: My_Entity_A;        
        init(*ent_a);
        log("an initialized entity with three components: %", _fmt_verbose(ent_a));
        log("\ntype a has component velocity: %\n--", has_component(*ent_a, .VELOCITY));

        ent_b: My_Entity_B;
        // init(*ent_b);
        log("an uninitialized entity with only a position component: %", _fmt_verbose(ent_b));
        log("\ntype b has component velocity: %\n--", has_component(*ent_b, .VELOCITY));


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

        pool := get_component_pool(.VELOCITY);
        log("velocity pool after a velocity change: %", pool.*);
    }

} else { // --------------------------------------------------------------------------

    ENTITY_COMPONENT_COUNT :: #run component_declarations.count;

    component_pools_def, component_enum_def, component_enum_to_type_def :: #run declare_entity_components(
        ..component_declarations
    );

}
