// a way to store pointers to compact data meant to be iterated over in-order.
// pass a list of Component_Handler_Declarations to generate the boilerplate procedures
// as well as the meta-procedures for all entity types to create and destroy all of their components.
// assumes all entity types cast to a base type. e.g. using #as base: Entity_Base; field in all entities,
// also assumes you have a runtime type enum mirroring the compile time type.
// where said type is the type referred to in id_to_entity and entity_to_id.

// example implementation:

// #insert #run generate_component_handlers(
//    My_Entity_Base,
//    My_Entity_Type_Enum,
//    "my_entity_to_id_proc",
//    "my_id_to_entity_proc",
//    "my_entity_to_type_enum"
//    {
//        My_Entity_Type_Enum.PLAYER_CHARACTER,
//        Skeletal_Mesh_Instance,
//        "context.world.skeletal_mesh_instances",
//        "context.world.skeletal_mesh_instance_ids",
//        "skeletal_mesh"
//    },
//    {
//        My_Entity_Type_Enum.MONSTER,
//        Skeletal_Mesh_Instance,
//        "context.world.skeletal_mesh_instances",
//        "context.world.skeletal_mesh_instance_ids",
//        "skeletal_mesh"
//    },
//    {
//        My_Entity_Type_Enum.PARTICLE,
//        Particle_Transform,
//        "context.world.particle_transforms",
//        "context.world.particle_transform_ids",
//        "transform"
//    }
// );

Component_Handler_Declaration :: struct($enum_type: Type) {
    entity_type: enum_type;
    component_type: Type;
    component_array: string; 
    id_array: string; 
    path_to_component: string;
}

generate_component_handlers :: (
    $entity_base_type: Type,
    $entity_enum_type: Type,
    entity_to_id: string, 
    id_to_entity: string,
    entity_to_type_enum: string,
    handlers: ..Component_Handler_Declaration(entity_enum_type)
) -> string {
    auto_release_temp();

    builder: String_Builder;
    builder.allocator = temp;

    entity_types_lower := make_dynamic_array(string, 1024,, temp);
    unique_entity_types := make_dynamic_array(string, 1024,, temp); [..]string;
    all_type_strings := make_dynamic_array(string, 1024,, temp); [..]string;

    for handlers {
        type_str := tprint("%", it.entity_type);
        array_add(*entity_types_lower, to_lower(type_str,, temp));
        array_add(*all_type_strings, type_str);
        array_add_if_unique(*unique_entity_types, type_str);

        print(*builder,
#string HERE
create_%_% :: (entity: *%) {
    create_array_component(
        entity,
        *%,
        *%,
        path_to_component="%",
        %,
        %
    );

}

destroy_%_% :: (entity: *%) {
    destroy_array_component(
        entity,
        *%,
        *%,
        path_to_component="%",
        %,
        %
    );
}

HERE,
            entity_types_lower[it_index], it.component_type, entity_base_type, it.component_array, it.id_array, it.path_to_component,
            entity_to_id, id_to_entity,
            entity_types_lower[it_index], it.component_type, entity_base_type, it.component_array, it.id_array, it.path_to_component,
            entity_to_id, id_to_entity,
        );
    }

    print(*builder, 
#string HERE
create_array_components :: (entity: *%) {
    type_enum := %(entity);
    if type_enum == {
HERE, 
        entity_base_type, entity_to_type_enum
    );

    for type : unique_entity_types {
        print(*builder, "        case .%;\n", type);
        for handlers {
            if all_type_strings[it_index] == type {
                print(*builder, "            create_%_%(entity);\n", entity_types_lower[it_index], it.component_type);
            }
        }
    }

    print(*builder,
#string HERE
    }
}

HERE);


    print(*builder, 
#string HERE
destroy_array_components :: (entity: *%) {
    type_enum := %(entity);
    if type_enum == {
HERE, 
        entity_base_type, entity_to_type_enum
    );

    for type : unique_entity_types {
        print(*builder, "        case .%;\n", type);
        for handlers {
            if all_type_strings[it_index] == type {
                print(*builder, "            destroy_%_%(entity);\n", entity_types_lower[it_index], it.component_type);
            }
        }
    }

    print(*builder,
#string HERE
    }
}

HERE);

    out_str := builder_to_string(*builder);
    print("%", out_str);
    return out_str;
}

#scope_file

create_array_component :: (
    entity: *$entity_type, 
    components: *[..]$component_type, 
    ids: *[..]$id_type, 
    $path_to_component: string, 
    $entity_to_id: (*entity_type) -> id_type, 
    $id_to_entity: (id_type) -> *entity_type
) -> *component_type {
    assert(components.count == ids.count);

    old_array_pointer := components.data;
    #insert #run tprint("entity.% = array_add(components);", path_to_component);

    if old_array_pointer != components.data {
        fix_pointers(entity_type, components, ids, path_to_component, id_to_entity);
    }
    array_add(ids, inline entity_to_id(entity));
    #insert #run tprint("return entity.%", path_to_component);
}

destroy_array_component :: (
    entity: *$entity_type, 
    components: *[..]$component_type, 
    ids: *[..]$id_type, 
    realloc_if_using_less_than_proportion := 0.35,
    remove_free_proportion := 0.75,
    minimum_allocated := 8,
    $path_to_component: string, 
    $entity_to_id: (*entity_type) -> id_type, 
    id_to_entity: (id_type) -> entity_type
) {
    assert(components.count == ids.count);

    #insert #run tprint("component := *entity.%;", path_To_component);
    #insert #run tprint("entity.% = null;", path_to_component);

    component_index := component - components.data;
    entity_id := entity_to_id(entity);
    assert(ids[component_index] == entity_id);
    
    if component_index != components.count - 1 {
        final_entity := inline id_to_entity(ids[components.count-1]);
        components[component_index] = components[components.count-1];
        ids[component_index]        = ids[components.count-1];
        #insert #run tprint("final_entity.% = *components[component_index];");
    }

    components.count -= 1;
    ids.count        -= 1;

    old_array_pointer := components.data;
    array_shrink_if_small_enough(components, realloc_if_using_less_than_proportion, remove_free_proportion, minimum_allocated);
    array_shrink_if_small_enough(ids, realloc_if_using_less_than_proportion, remove_free_proportion, minimum_allocated);

    if old_array_pointer != components.data {
        fix_pointers(entity_type, components, ids, path_to_component, id_to_entity); 
    }
}

fix_pointers :: (
    $entity_type: Type,
    components: *[..]$component_type,
    ids: *[..]$id_type,
    $path_to_component: string,
    $id_to_entity: (id_type) -> entity_type,
) {
    for id : ids.* {
        entity := inline id_to_entity(id);
        #insert #run tprint("entity.% = *components.*[it_index];", path_to_component);
    }
}


#import "TeRM/TeRM_Array";
#import "TeRM/TeRM_String";
#import "Basic";
