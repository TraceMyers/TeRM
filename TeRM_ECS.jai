#module_parameters()(
    ENABLE_EXAMPLE := false,
    DECLARE_POOLS_ON_CONTEXT := false,
    component_declarations: []Component_Declaration = .[]
) {
    Component_Declaration :: struct {
        name: string;
        T: Type;
    }
}

#if ENABLE_EXAMPLE {
    Entity_Gadget :: struct {
        shizz_factor: int;
    }

    My_Entity :: Entity ( 
        struct {
            name := "an entity!";
            gadgets: []Entity_Gadget = .[{2}];
        },
        .POSITION,
        .VELOCITY, 
        .ORIENTATION
    );

    term_ecs_example :: () {
        ent_a: My_Entity;        
        init(*ent_a);
        log("ent: %", _fmt_verbose(ent_a));

        ent_b: My_Entity;
        init(*ent_b);
        log("ent: %", _fmt_verbose(ent_b));
    }

}

Component_Name :: enum u16 {
    // #insert -> string {
    //     builder: String_Builder;
    //     for component_declarations {
    //         print(*builder, "        %;\n", it.name);
    //     }
    //     return builder_to_string(*builder);
    // }
    // #if ENABLE_EXAMPLE {
    #insert #string HERE
        POSITION;
        VELOCITY;
        ORIENTATION;
    HERE;
    // }
}

COMPONENT_NAME_TO_TYPE :: Type.[
    // #insert -> string {
    //     builder: String_Builder;
    //     for component_declarations {
    //         print(*builder, "        %,\n", it.T);
    //     }
    //     return builder_to_string(*builder);
    // }
    // #if ENABLE_EXAMPLE {
    // #insert #string HERE
        Vector3,
        Vector3,
        Quaternion
    // HERE
    // }
];

EXAMPLE_COMPONENT_COUNT :: #run #ifx ENABLE_EXAMPLE then 3 else 0;
ECS_COMPONENT_POOL_COUNT :: #run component_declarations.count + EXAMPLE_COMPONENT_COUNT;

#if DECLARE_POOLS_ON_CONTEXT {
    #add_context ecs_component_pools: [ECS_COMPONENT_POOL_COUNT]Pool(int);
} else {
    ecs_component_pools: [ECS_COMPONENT_POOL_COUNT]Pool(int);
}

Entity :: struct ($T: Type, $components: ..Component_Name) {
    using #as base: T;

    #if components.count > 0 {
        component_flags: Flag_Array(Component_Name);

        #insert -> string {
            builder: String_Builder;
            for components {
                field_lower := to_lower(tprint("%\n", it),,temp);
                print(*builder, "id_%: u16 = 0xffff;\n", field_lower);
            }
            return builder_to_string(*builder);
        }
    }
}

init :: (ent: *Entity) {
    ecs_for_each_component(ent, #code {
        component_id.* = xx pool_acquire(component_pool);
        set(*ent.component_flags, component_name);
    });
}

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

#scope_file

// for a given component, create a space of variables and constants where the
// inserted code can work on the component, the pool of the component, the component
// id on the entity, etc.
ecs_component_do_impl :: (ent: *Entity, $name: Component_Name, $body: string) #expand {
    `component_name  :: name;
    `component_id    := #insert #run tprint("*ent.id_%;", to_lower(tprint("%", name)));
    `component_pool  := cast(*Pool(COMPONENT_NAME_TO_TYPE[name])) *ecs_component_pools[name];
    #insert body;
}

#import "Basic";
#import "Math";

#import "TeRM/TeRM_FlagArray";
#import "TeRM/TeRM_Storage";
#import "TeRM/TeRM_String";
#import "TeRM/TeRM_LogHelpers";
#import "TeRM/TeRM_Metaprogram";
