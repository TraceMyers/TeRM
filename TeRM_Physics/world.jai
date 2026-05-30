// todo: debug proc to validate that templates aren't being altered
Physical_World :: struct {
    body_templates: Linear_Table(string, Physics_Body_Template);
    unique_properties: Pool(Physics_Properties);
    unique_colliders: Pool(Physics_Collider);
    body_data: Physics_Body_SOA;

    step_state: Physics_Step_State;
    collision_iteration_count := 5;

    start_time: float64;
    update_timestamp: float64;
    time_scale: float32;
    step_count: int;

    #if DEBUG_INVALIDATED_TEMPLATE_PROPERTIES {
        debug_template_properties: [..]Physics_Properties;
    }

    gravity := 9.8;

    allocator: Allocator;
}

create_physical_world :: (bodies_max := 32768, body_templates_max := 128, unique_properties_max := 4096, unique_colliders_max := 32768) -> Physical_World {
    out_world: Physical_World;

    table_init(*out_world.body_templates, body_templates_max, true);
    pool_init(*out_world.unique_properties, unique_properties_max, true);
    pool_init(*out_world.unique_colliders, unique_colliders_max, true);

    if bodies_max > 0 {
        soa_reserve(*out_world.body_data, bodies_max);
    }
    soa_set_allocator(*out_world.body_data, no_allocator);

    out_world.allocator = context.allocator;
    return out_world;
}

destroy_physical_world :: (in_world: *Physical_World) {
    // does not destroy shared properties. that allocation (probably static) is managed by the user.
    save_allocator := context.allocator;
    context.allocator = in_world.allocator;
    defer context.allocator = save_allocator;

    table_set_allocator(*in_world.body_templates, in_world.allocator);
    table_reset(*in_world.body_templates);

    pool_set_allocator(*in_world.unique_properties, in_world.allocator);
    pool_reset(*in_world.unique_properties);

    soa_set_allocator(*in_world.body_data, in_world.allocator);
    soa_reset(*in_world.body_data);
    
    in_world.* = {};
}

set_physical_world :: (in_world: *Physical_World) {
    world = in_world;
}

Physics_Step_State :: enum {
    RUN_PHYSICS;
    STEP_ONCE;
    PAUSED;
    PAUSE_ON_COLLISION;
}

Physics_Body_Combined_Data :: struct {
    flags:              Physics_Body_Flags;
    collision_channels: Collision_Channel;
    entity_id:          user_types.entity_id_type;
    using body:         Physics_Body_Internal;
}

Physics_Body_SOA :: struct {
    flags:              [..]Physics_Body_Flags;
    collision_channels: [..]Collision_Channel;
    entity_ids:         [..]user_types.entity_id_type;
    bodies:             [..]Physics_Body_Internal;
    
    item_type   :: Physics_Body_Combined_Data;
    item_fields :: string.["flags", "collision_channels", "entity_id", "body"];
}

#scope_module


// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
