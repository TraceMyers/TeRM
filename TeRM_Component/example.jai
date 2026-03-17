// declare your component types

Transform :: struct {
    position:    Vector3;
    orientation: Quaternion;
}

Entity_Move :: struct {
    velocity:     Vector3;
    ground_accel: float;
    air_accel:    float;
    flags:        enum {};
}

// need an id type to uniquely identify an entity in order to communicate with the module

Entity_Ref :: struct {
    id: u32;    
    index: u32;
    #overlay(index)          index_bytes: [4]u8;
    #overlay(index_bytes[3]) type: Entity_Type;
}

// the module needs an enum for identifying groups of components called 'kinds'. in the simplest case,
// this can just be an enum shadowing your entity types.

Entity_Type :: enum u8 {
    CAMERA;
    CHARACTER;
    STATIC_GEOMETRY;
}

// the module needs an enum identifier per component type, as well as an array of the component types.
// this is a thing I like to use that declares the enum and the array at the same time.

NAME_AND_TYPE_CREATE_INFOS :: Enumarray_Create_Info.[
    {"TRANSFORM", Transform},
    {"MOVE",      Entity_Move}
];

#insert #run generate_parallel_enum_and_array(..NAME_AND_TYPE_CREATE_INFOS, "Component_Name", u16, "COMPONENT_TYPES", "Type", true);

// the module needs a way to bring all of the data together. the fields as shown here must
// be on your version of the struct, but yours can also have extra fields.

Component_Definition :: struct {
    kind: Entity_Type;
    name: Component_Name;
    // if you want to override the Component_ID name. otherwise, it will be
    // the kind + name joined together with an underscore.
    id_name_override := ""; 
    array_name_override := "";
}

// the module needs a procedure to get an ID when you pass an entity, ...

get_cid :: (entity: *$T) -> Entity_Ref {
    return entity.ref;
}

// ... and to get a pointer to the component manifest on the entity, from said ID.

get_sentinel :: (ref: Entity_Ref) -> *Component_Sentinel_Header {
    // in reality, need to check ID on ref against ID on entity
    index := ref.index & 0xffffff;
    if #complete ref.type == {
    case .CAMERA;
        return *cameras[index].component_sentinel_header;
    case .CHARACTER;
        return *characters[index].component_sentinel_header;
    case .STATIC_GEOMETRY;
        // would need to NOT use entity kind as the type because this.
        return *trees[index].component_sentinel_header;
    }
}

// the import statement requires passing all of the data described before in the form
// of a type definition, as well as the component definitions array.

#import "TeRM/TeRM_Component"(
    user_types = struct {
        Component_Definition_Type :: Component_Definition;
        Component_Name_Type       :: Component_Name;
        Component_Kind_Type       :: Entity_Type;
        Entity_ID_Type            :: Entity_Ref;
        component_type_array      :: COMPONENT_TYPES;
        // here are the definitions. every unique combination of kind + name/type creates a new component.
        component_definitions     :: Component_Definition.[
            {kind=.CAMERA,           name=.TRANSFORM},
            {kind=.CAMERA,           name=.MOVE},
            {kind=.CHARACTER,        name=.TRANSFORM},
            {kind=.CHARACTER,        name=.MOVE},
            {kind=.STATIC_GEOMETRY,  name=.TRANSFORM}
        ];
        entity_to_entity_id       :: get_cid;
        entity_id_to_sentinel     :: get_sentinel;
    }
);

// declaring some entity types for example usage
// todo: should need to be using the sentinel, so an entity can have multiple.

Character :: struct {
    ref: Entity_Ref;
    using #as components: Component_Sentinel(.CHARACTER, true);
}

Camera :: struct {
    using #as components: Component_Sentinel(.CAMERA);
    ref: Entity_Ref;
}

Tree :: struct {
    name: string;
    ref: Entity_Ref;
    using #as components: Component_Sentinel(.STATIC_GEOMETRY);
}

// your entity arrays
characters: [..]Character;
cameras:    [..]Camera;
trees:      [..]Tree;

// pretend queues for post-entity allocation / mid-spawn.
// entities in the queues will have their components allocated.
new_characters: [..]*Character;
new_cameras: [..]*Camera;
new_trees: [..]*Tree;

// pretend queues for pree-entity free / mid-despawn.
// entities in the queues will have their components freed.
destroyed_characters: [..]*Character;
destroyed_cameras: [..]*Camera;
destroyed_trees: [..]*Tree;

// the Component module data, that you can declare anywhere and have multiple of if that serves your purposes.
// essentially, the module's context.
component_storage: Component_Storage;

main :: () {
    // passing the pointer to your storage, as well as setting some internal data 
    initialize_component_module(*component_storage);


    // spawning / destruction
    // ----------------------

    // pretend spawn code
    alloc_character_ct := 9;
    alloc_camera_ct := 1;

    array_reserve(*characters, 100);
    array_reserve(*new_characters, 100);
    for 0..alloc_character_ct-1 {
        char := array_add(*characters);
        char.ref.id = xx entity_id_counter;
        char.ref.index = xx (characters.count - 1);
        char.ref.type = .CHARACTER;
        entity_id_counter += 1;
        array_add(*new_characters, char);
    }

    array_reserve(*cameras, 100);
    array_reserve(*new_cameras, 100);
    for 0..alloc_camera_ct-1 {
        cam := array_add(*cameras);
        cam.ref.id = xx entity_id_counter;
        cam.ref.index = xx (cameras.count - 1);
        cam.ref.type = .CAMERA;
        entity_id_counter += 1;
        array_add(*new_cameras, cam);
    }

    // after the entities exist in memory, their components can be spawned.
    my_spawn_components();

    // some guys died this frame
    array_add(*destroyed_characters, *characters[0]);
    array_add(*destroyed_characters, *characters[characters.count-1]);
    array_add(*destroyed_characters, *characters[3]);

    // before the entities have been removed from memory, free their components.
    my_destroy_components();


    // component data interaction
    // --------------------------
    
    char := *characters[1];

    // entities with pointers to their components can access and use them as if they
    // were declared directly on the entity. they are automatically dereferenced, so you
    // don't have to .* to use them.
    // ('define_pointers' is a compile time parameter on Component_Sentinel)
    log("character move: %", char.transform);
    log("character move: %", char.move);

    // you can also iterate over their pointers.
    for 0..char.component_pointers.count-1 {
        component := characters[0].COMPONENTS[it];
        log("character % pointer: %", component, char.component_pointers[it]);
    }

    // if the entity doesn't have pointers, they get their component with get_component()
    // it is not an expensive operation. just indexing into an array.
    cam_tform := get_component(*cameras[0], .TRANSFORM);
    cam_tform.position += {1, 0, 0};

    // this makes an iterable table of component arrays that look like this:
    //                           .--- names/types ---.
    //                           v                   v
    //                         moves             transforms
    //    .-> cameras     [  cam move 1 ]     [  cam tform 1 ]
    //    |               [  cam move 2 ]     [  cam tform 2 ]
    //  kinds             [  cam move 3 ]     [  cam tform 3 ]
    //    |               [     ...     ]     [     ...      ]
    //    |
    //    .-> characters  [ char move 1 ]     [ char tform 1 ]
    //                    [     ...     ]     [     ...      ]

    table := filter_components(.[.MOVE, .TRANSFORM]);
     
    // this is a nested for loop. using the above example, 
    // - outer loop is cameras, characters
    // - inner loop is over moves and transforms of the outer loop type.
    // see for_expansion of Component_Table for details and for all vars defined in the scope.
    for table {
        entity_move      := *move_components[it];
        entity_transform := *transform_components[it];

        entity_transform.position += entity_move.velocity * delta_time;

        if component_kind == {
        case .CHARACTER;
            character := get_entity(ids[it], Character);
        case .CAMERA;
            camera := get_entity(ids[it], Camera);
        }
    }
}

my_spawn_components :: () {
    auto_release_temp();
    requests := make_dynamic_array(Component_Memory_Modification,, temp);

    prepare_component_memory_modification(*requests, new_characters);
    prepare_component_memory_modification(*requests, new_cameras);
    prepare_component_memory_modification(*requests, new_trees);
    allocate_components(*requests);
}

my_destroy_components :: () {
    auto_release_temp();
    requests := make_dynamic_array(Component_Memory_Modification,, temp);

    prepare_component_memory_modification(*requests, destroyed_characters);
    prepare_component_memory_modification(*requests, destroyed_cameras);
    prepare_component_memory_modification(*requests, destroyed_trees);
    free_components(*requests);
}



// -----

delta_time := 1.0 / 120.0;
entity_id_counter: s64 = 1;

get_entity :: (ref: Entity_Ref, $T: Type) -> *T {
    index := ref.index & 0xffffff;
    #if T == {
    case Camera;
        return *cameras[index];
    case Character;
        return *characters[index];
    case Tree;
        // would need to NOT use entity kind as the type because this.
        return *trees[index];
    }
}

#import "Math";
#import "Basic";
#import "Math";

#import "TeRM/TeRM_Metaprogram";
#import "TeRM/TeRM_LogHelpers";
#import "TeRM/TeRM_Array";
