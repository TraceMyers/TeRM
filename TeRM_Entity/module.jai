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
#load "storage.jai";

// -----------------------------------------------------------------------------------
// -------------------------------------------------------------------------- :globals

// the components array for the module was put on the context for this reason:
//
// the actual array data is declared wherever you like. this is just a pointer and a count.
// so, if you just want a single global set of arrays, just set this field once 
// (see term_entity_example()). or, if you want, say, one set of arrays per world, you
// might map one world to one context, and so each time you push a world's context, also
// set the world's component arrays.
#add_context entity_component_arrays: [][..]int; 

#insert component_enum_def;         // declaring generated enum name definition
#insert component_enum_to_type_def; // declaring generated enum name -> type procedure

#if ENABLE_EXAMPLE { // --------------------------------------------------------------
// -------------------------------------------------------------------------- :example

    ENTITY_COMPONENT_COUNT :: 3;

    Example_Transform :: struct {
        position: Vector3;
        velocity: Vector3;
        orientation: Quaternion;
    }

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
        {name = "orientation", id_type = s16, data_type = Quaternion},
        {name = "transform",   id_type = s16, data_type = Example_Transform}
    ];

    // create strings containing component system definitions.
    component_arrays_def, component_enum_def, component_enum_to_type_def :: 
        #run generate_entity_system_declarations(..example_component_declarations);

    // declaring the component arrays once in the global scope.
    #insert component_arrays_def;

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
        declare_component_pointers = true,
        using_component_pointers = true,
        ..components =
            .TRANSFORM,
    );

    // call this for an explanatory printout
    term_entity_example :: () {
        // tell this module where the allocators are
        context.entity_component_arrays = entity_component_arrays;

        ent_a: My_Entity_A;        
        init(*ent_a);
        log("an initialized entity with three components: %\n\n", _fmt_verbose(ent_a));
        log("entity a has component velocity: %\n\n", has_component(*ent_a, .VELOCITY));

        ent_b: My_Entity_B;
        log("an uninitialized entity with only a position component: %\n\n", _fmt_verbose(ent_b));
        log("entity b has component velocity: %\n\n", has_component(*ent_b, .VELOCITY));

        ent_c: My_Entity_C;
        init(*ent_c);
        log("an initialized entity with a transform component and pointer storage: %\n\n", _fmt_verbose(ent_c));

        ent_c.velocity += {1,1,1};
        ent_c.orientation = {};

        log("ent_c.position = %", ent_c.position);
        log("ent_c.velocity = %", ent_c.velocity);
        log("ent_c.orientation = %\n\n", ent_c.orientation);

        array := get_component_array(.TRANSFORM);
        log("transform component [0] after entity c velocity change: %\n\n", array.*[0]);

        get_component(*ent_a, .POSITION).x -= 2;
        pos := get_component(*ent_a, .POSITION);
        pos.y = 100/5;
        log("entity a position after getting component and changing x and y: %\n\n", pos.*);
        
        deinit(*ent_a);
        log("entity a after deinit: %\n\n", ent_a);

        log(LONG_EXPLANATION);
    }

} else { // --------------------------------------------------------------------------

    ENTITY_COMPONENT_COUNT :: #run component_declarations.count;

    component_arrays_def, component_enum_def, component_enum_to_type_def :: 
        #run generate_entity_system_declarations(..component_declarations);

}

#scope_file

LONG_EXPLANATION :: #string,\% HERE
the default storage behavior is, for each component an entity 
has, declare an int id on the entity. that id is then used to 
index into that particular component's array. optionally, maybe 
for special types who need to reference their component from an 
individual perspective a lot, the entity can instead store a 
pointer to each component. by default, the top-level field has 
the 'using' keyword on it, meaning the component can be referred 
to as if it were declared directly on the entity struct,
without a pointer deref.

My_Entity_C {
    using *transform wrapper {
        transform: Example_Transform;       
    }
}

... in some scope
{
    ent_c.transform = {velocity={1,1,1}};
}

the data was bundled into a transform type in this example 
because throwing a bunch of pointers on the entity could pollute 
the cache. 

three individual pointers, rather than one, referring to a Vec3, 
Vec3 and a Quat, puts 8+8+8=24 bytes of pointer storage on 
the entity, compared to 12+12+16=40 bytes of data storage in
the component array. that's a 60\% increase in the amount of 
data required to represent this architecture decision to
add indirection. 

raw or proportional data size alone isn't enough to understand how 
this will effect cache performance, since you can technically
have lots of cold pointers sitting around never getting accessed,
and that only hurts you as much as they overlap with cache lines
that are being used.

now, an extra 24 bytes per entity is not the end of the 
world, but the more components you add, the more this effect adds up.

in any case, turning three pointers into one makes for only a 20\%
increase in data, which is much less likely to matter. if bundling
that date works out bulk-processing wise, it's a win-win.

also, as an added convenience, you can tell the system 'using' on 
the component as well, achieving this effect:

My_Entity_C {
    using *transform wrapper {  <---- wrapper pointer, declared on Entity
        using transform {       <---- the component, stored in an array
            position: Vector3;        <---- these fields can be referred 
            velocity: Vector3;              to as if they were declared
            orientation: Quaternion;        directly on the entity.
        }
    }
}

... in some scope
{
    ent_c.velocity += {1,1,1};
}

HERE

#import "Atomics";

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
