// note that this module is in flux and not quite ready yet.

// on ecs

// in general, if you are using ecs-style storage and not primarily
// doing builk processing over the components, you're probably not
// getting much if any of the benefit. actually, [ecs] + [not bulk]
// can easily make your performance worse than if you had just declared
// every component directly on the entity instead. 

// i don't think ecs-style storage is generally a better approach.
// actually, it's worse in many respects. becoming kind of passe lately, 
// the term "entity component system", is often used to point and laugh 
// in the direction of unnecessary, time-consuming, complicated optimizations.

// that's all true, until you know you need something like it.
// i made this module to smooth away the pain points.

// - it allows you to store your components wherever you like, as well
// as having multiple sets of components (say, for multiple worlds). 

// - optionally, it allows you to define pointers on your entity that auto-deref
// to their respective component, so that you can treat the component as if it
// were stored on the struct, whenever convenience needs call for it.

// - storage is managed, but pretty simple. dense arrays are maintained
// via regular calls (made by your program) to upkeep procedures

// - entity init and deinit boilerplate is generated module-side.

// - flags on the entity can be used for runtime inspection of what components
// and entity has.

// - there is a helper macro to have your code operate on every component an
// entity has.

// --------------------------------------------------------------------------

// this is a compilable example. make sure TeRM is in your import 
// path, then copy this file into your project, #load it, and call 
// term_entity_example().

// --------------------------------------------------------------------------

// - step-by-step instructions for bringing it into your project next

// - see main() farther below for example usage at runtime.

// - see bottom of the page for a blurb about using indices vs pointers to reference components.

// note that the step-by-step stuff is only in this order for explanatory reasons.
// the code can be in whatever order, as is typical with programs in this language.

// 1. declare this type. it can be called whatever, but it needs these fields.
// if you want to add extra fields for bookkeeping, that won't mess anything up.

Component_Declaration :: struct {
    name: string;
    type: Type;
    id_type: Type;
}

// 2. declare any component types that the Entity module isn't aware of.
// Entity imports Math and some other things, so you already have vectors, matrices, etc.

Static_Transform :: struct {
    position: Vector3;
    orientation: Quaternion;
}

// 3. declare a constant array of Component_Declarations. each of these
// will represent a.) a component that can be declared on an entity, and
// b.) an array of the given component type.

COMPONENT_DECLARATIONS :: Component_Declaration.[
    {"position",            Vector3},
    {"velocity",            Vector3},
    {"orientation",         Quaternion},
    {"static_transform",    Static_Transform}
];

// the names must be unique, because they will be used to generate an enum.

// 4. import

#import "TeRM/TeRM_Component"(
    // defining a type with constant fields is how we move types into the module.
    // the module parameter 'importer' is of type 'Type', you are defining a type.
    // the fields must be constant.
    importer = struct {
        // array of component types
        component_declarations :: COMPONENT_DECLARATIONS;
        // pass this type so the module knows how to interpret data in the declarations array
        component_decl_type    :: Component_Declaration;
        // an enum called Component_Name will be generated in the module.
        // this param decides whether the component enum names will be all caps
        uppercase_enum_names   :: false;
    }
);


// 5. declare the entity storage wherever you want. you can put it anywhere (global, world, whatever), 

#insert #run generate_entity_component_storage_declaration();

// but if you want to declare it on a context, this won't work. instead, use this line:
// #add_context entity_component_storage: [COMPONENT_DECLARATIONS.count][..]int;

// (they are declared as int arrays for ease of use, then typecasted by the module when used.)
// you tell the module where the storage is at runtime, so the name doesn't have to be anything
// in particular.

// 6. declare your entity types with their components

Camera :: struct {
    // NOTE : must be using #as / #as using!
    using #as base: Component_Info(
        ..components =
            Component_Name.static_transform,
        // declare_component_pointers=true, 
        // using_component_pointers=true
    );
}

term_entity_example :: () {
    // 7. make sure the module knows where the entity component storage is. if you are, say, bouncing 
    // around between worlds, just make sure you set this value every time so that the storage is 
    // correct for the entities being used.

    context.entity_component_arrays = entity_component_storage;

    // 8. go make a game or something

    // todo: add more management, to Entity then come back and add more example here.

    cam: Camera;
    init(*cam);
    log("camera: %", cam.base);
    transform := get_component(*cam, .static_transform);
    transform.position += {1,1,1};
    deinit(*cam);
    log("camera: %", cam);

}

// on indices vs pointers

// for this module, the default storage behavior is, for each component 
// an entity has, declare an int id on the entity. that id is then used 
// to index into that particular component's array.

// optionally, maybe for special types who need to reference their component 
// from an individual perspective a lot, the entity can instead store a 
// pointer to each component. by default, the top-level field has 
// the 'using' keyword on it, meaning the component can be referred 
// to as if it were declared directly on the entity struct,
// without a pointer deref.

// My_Entity_C {
//     using *transform wrapper {        <---- wrapper pointer, declared on Entity
//         transform: Example_Transform; <---- the component, stored in an array     
//     }
// }

// ... in some scope
// {
//     ent_c.transform = {velocity={1,1,1}};
// }

// the data was bundled into a transform type in this example 
// because throwing a bunch of pointers on the entity could pollute 
// the cache. 

// three individual pointers, rather than one, referring to a Vec3, 
// Vec3 and a Quat, puts 8+8+8=24 bytes of pointer storage on 
// the entity, compared to 12+12+16=40 bytes of data storage in
// the component array. that's a 60\% increase in the amount of 
// data required to represent this architecture decision to
// add indirection. 

// raw or proportional data size alone isn't enough to understand how 
// this will effect cache performance, since you can technically
// have lots of cold pointers sitting around never getting accessed,
// and that only hurts you as much as they overlap with cache lines
// that are being used.

// now, an extra 24 bytes per entity is not the end of the 
// world, but the more components you add, the more this effect adds up.

// in any case, turning three pointers into one makes for only a 20\%
// increase in data, which is much less likely to matter. if bundling
// that date works out bulk-processing wise, it's a win-win.

// also, as an added convenience, you can tell the system 'using' on 
// the component as well, achieving this effect:

// My_Entity_C {
//     using *transform wrapper {  <---- wrapper pointer, declared on Entity
//         using transform {       <---- the component, stored in an array
//             position: Vector3;        <---- these fields can be referred 
//             velocity: Vector3;              to as if they were declared
//             orientation: Quaternion;        directly on the entity.
//         }
//     }
// }

// ... in some scope
// {
//     ent_c.velocity += {1,1,1};
// }

#import "Math";
#import "Basic";
#import "Math";
