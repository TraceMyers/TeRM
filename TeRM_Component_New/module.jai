// maybe nobody will read this, but just in case...
// this module is replacing the old version. the replacement is happening for a few reasons:

// in the old version, type-resolving dependencies ping-ponged across the program <-> module boundary 
// a lot, causing silly long resolution chains that the compiler (sort of) mistook for cycles.

// there was too much metaprogramming. there is still quite a bit, but it was much worse. this version
// is easier to read (and will be better when documentation is added back and reorganized).

// the interface needed work. what came before 'collection.jai' wasn't very good. this interface is
// exactly what I was aiming for: 

//      - the data layout is very directly defined by the user, but isn't cumbersome.
//      - arrays stay parallel without you having to think about it, and without management overhead.
//      - filtering components and database-like functionality doesn't require making any new types.
//      - filtering components and database-like functionality takes very little code, like this:
//
//         collection := filter_components(.[.POSITION, .VELOCITY]);
//         for row : collection {
//        
//              // convenience macro, defines position_components, velocity_components, and CIDs.
//              declare_typed_row(row, .[.POSITION, .VELOCITY]); 
//        
//              // iterate over position and velocity arrays in parallel
//              for 0..position_components.count-1 {
//                  entity_position := *position_components[it];
//                  entity_velocity := *velocity_components[it];

//                  // you can use this to reference the entity, if needed. the procedure is 
//                  // defined in your program, as part of the interface with the module.
//                  entity := my_get_entity_from_cid(CIDs[it]);
//                  ...
//              }
//          }

// todo: one entity id array per kind rather than per component

#module_parameters(
    user_types : $I/interface Type_Provider_Default = Type_Provider_Default
) {
    Type_Provider_Default :: struct {
        Component_Definition_Type   :: void;
        Component_Name_Type         :: void;
        Component_Kind_Type         :: void;
        component_type_array        :: void;
        component_definitions       :: void;
        component_sentinel_to_cid   :: void;
        cid_to_component_sentinel   :: void;
    }
}

CID :: s64;

#add_context user_component_storage: *Component_Storage;

#load "component.jai";
#load "collection.jai";
#load "manage.jai";

component_id_to_type :: inline (id: Component_ID) -> Type {
    component_name := component_definitions[id].name;
    return component_types[component_name];
}

component_id_to_name :: inline (id: Component_ID) -> Component_Name {
    return component_definitions[id].name;
}

component_id_to_kind :: inline (id: Component_ID) -> Component_Kind {
    return component_definitions[id].kind;
}

component_name_and_kind_to_id :: (name: Component_Name, kind: Component_Kind) -> Component_ID {
    for context.user_component_storage.arrays {
        if it.name == name && it.kind == kind {
            return it.id;
        }
    }
    return 0xffff; 
}

get_component_ids :: (kind: Component_Kind) -> []Component_ID {
    ids := make_dynamic_array(Component_ID, enum_highest_value(Component_ID)+1);
    for def : component_definitions {
        if def.kind == kind {
            array_add(*ids, xx it_index);
        }
    }
    return ids;
}

get_component_ids :: (name: Component_Name) -> []Component_ID {
    ids := make_dynamic_array(Component_ID, enum_highest_value(Component_ID)+1);
    for def : component_definitions {
        if def.name == name {
            array_add(*ids, xx it_index);
        }
    }
    return ids;
}

// represents all data storage for this module. you declare (an) instance(s)
// anywhere in your program. if you are, say, moving back and forth
// between worlds with persistent entity data, you would just do this
// when changing worlds:
// context.user_component_storage = *world.component_storage;
Component_Storage :: struct {
    /* example layout with 3 components:

    character_position_components: Component_Array(.CHARACTER_POSITION);
    character_velocity_components: Component_Array(.CHARACTER_VELOCITY);
    monster_position_components:   Component_Array(.MONSTER_POSITION);

    #overlay(character_position_components) arrays: [3]Component_Array_Untyped; */

    #insert -> string {
        builder: String_Builder;
        first_array_name: string;
        for def, di : component_definitions {
            array_name: string;
            if def.array_name_override.count != 0 {
                array_name = def.array_name_override;
            } else {
                kind_lower := to_lower(tprint("%", def.kind));
                name_lower := to_lower(tprint("%", def.name));
                array_name = tprint("%_%_components", kind_lower, name_lower);
            }
            if di == 0 {
                first_array_name = array_name;
            }
            print(*builder, "%: Component_Array(xx %);\n", array_name, di);
        }
        print(*builder, "#overlay(%) arrays: [%]Component_Array_Untyped;", first_array_name, component_definitions.count);
        return builder_to_string(*builder);
    }
}

Component_Array_Base :: struct {
    id:   Component_ID;
    name: Component_Name;
    kind: Component_Kind;
    type_size: s16;
    type_has_initializer: bool;
}

Component_Array_Untyped :: struct {
    array: [..]u8;
    ids:   [..]s64;
    using #as base: Component_Array_Base;
}

Component_Array :: struct($in_id: Component_ID) {
    component_type :: #run component_id_to_type(in_id);
    array: [..]#run component_type;
    ids:   [..]s64;
    using #as base := Component_Array_Base.{
        id   = in_id,
        name = #run component_definitions[in_id].name,
        kind = #run component_definitions[in_id].kind,
        type_size = #run size_of(component_type),
        type_has_initializer = #run initializer_of(component_type) != null
    };
}

Component_ID :: enum u16 {
    #insert -> string {
        builder: String_Builder;
        for def : component_definitions {
            if def.id_name_override.count != 0 {
                print(*builder, "%;\n", def.id_name_override);
            } else {
                print(*builder, "%_%;\n", def.kind, def.name);
            }
        }
        return builder_to_string(*builder);
    }
}

#import "Basic";
#import "Math";

#import "TeRM/TeRM_String";
#import "TeRM/TeRM_Array";
#import "TeRM/TeRM_FlagArray";
#import "TeRM/TeRM_Metaprogram";

#scope_module

Component_Kind        :: user_types.Component_Kind_Type;
Component_Name        :: user_types.Component_Name_Type;
component_definitions :: user_types.component_definitions;
component_types       :: user_types.component_type_array;
component_sentinel_to_cid   :: user_types.component_sentinel_to_cid;
cid_to_component_sentinel   :: user_types.cid_to_component_sentinel;

    // this scope is a reference for how to pass your types into the import

    // the boat by which you ship your types into the module
    // Type_Provider_Default :: struct {
    //     Component_Definition_Type   :: Component_Definition_Default;
    //     Component_Name_Type         :: Component_Name_Default;
    //     Component_Kind_Type         :: Component_Kind_Default;
    //     Component_Name_To_Type      :: Component_Name_To_Type_Default;
    //     component_definitions       :: COMPONENT_DEFINITIONS_DEFAULT;
    // }

    // // each entry here represents a unique component, and an of that component's type.
    // COMPONENT_DEFINITIONS_DEFAULT :: Component_Definition_Default.[
    //     {kind=.CAMERA,           name=.TRANSFORM},
    //     {kind=.CAMERA,           name=.MOVE},
    //     {kind=.CHARACTER,        name=.TRANSFORM},
    //     {kind=.CHARACTER,        name=.MOVE},
    //     {kind=.STATIC_GEOMETRY,  name=.TRANSFORM}
    // ];

    // // a component is described by its kind, name, id and type. 'kind' and 'name' are supplied here. 
    // // 'name' is bound to 'type' via the tagged union Component_Name_To_Type, and an 'id' is derived 
    // // from the combination of kind + name.
    // Component_Definition_Default :: struct {
    //     kind: Component_Kind_Default;
    //     name: Component_Name_Default;
    //     // if you want to override the Component_ID name. otherwise, it will be
    //     // the kind + name joined together with an underscore.
    //     id_name_override := "";
    //     // if you want to override the name of the component array, this is it
    //     array_name_override := "";
    // }

    // // what kind of thing uses the component. a very reasonable (and maybe the most managable) version
    // // of this is to define one kind per entity type.
    // Component_Kind_Default :: enum u16 {
    //     CAMERA;
    //     CHARACTER;
    //     STATIC_GEOMETRY;
    // }

    // // one entry per component type
    // Component_Name_Default :: enum u16 {
    //     TRANSFORM;
    //     MOVE;
    // }

    // // map component name enum to its respective type
    // Component_Name_To_Type_Default :: union type: Component_Name_Default {
    //     .TRANSFORM,, transform := Example_Transform_Component;
    //     .MOVE     ,, move      := Example_Move_Component;
    // }

    // Example_Transform_Component :: struct {
    //     position: Vector3;
    //     orientation: Quaternion;
    // }

    // Example_Move_Component :: struct {
    //     velocity:     Vector3;
    //     ground_accel: float;
    //     air_accel:    float;
    //     flags:        enum_flags {};
    // }
