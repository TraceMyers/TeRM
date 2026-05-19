Physical_World :: struct {
    // declare an array of constant physics properties and assign this view to point to it,
    // or allocate an array at runtime to represent the set of properties that should
    // not change. either way is fine, but if you do make a constant array, you need
    // to set this view so that the module can help you avoid crashing by 
    // attempting changes to constant memory.
    shared_properties: []Physics_Properties;
    unique_properties: Pool(Physics_Properties);
    body_data: Struct_Of_Arrays(
        Physics_Body_Combined_Data,
        "flags", "collision_channels", "bodies"
    );
    allocator: Allocator;
}

create_physical_world :: (shared_properties: []Physics_properties, bodies_max := 32768, unique_properties_max := 4096) -> Physical_World {
    out_world: Physical_World;
    out_world.shared_properties = shared_properties;
    pool_init(*out_world.unique_properties, unique_properties_max, true);
    if reserve_bodies > 0 {
        soa_reserve(*out_world.body_data, bodies_max);
        soa_set_allocator(*out_world.body_data, no_allocator);
    }
    out_world.allocator = context.allocator;
    return out_world;
}

destroy_physical_world :: (in_world: *Physical_World) {
    // does not destroy shared properties. that allocation (probably static) is managed by the user.
    save_allocator := context.allocator;
    context.allocator = in_world.allocator;
    defer context.allocator = save_allocator;
    in_world.unique_properties.items.allocator = in_world.allocator;
    in_world.unique_properties.in_use.allocator = in_world.allocator;
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

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
