// todo: detecting common bugs like double-put or forgetting to remove
// todo: optimization, instead of doing a full remove, re-place, do a diff placement.

Collision_Cell :: struct {
    external: [..]u16;
    #overlay(external) internal : struct {
        // prob dont' need to explicitly align to 8. correct sizing only thing that matters,
        // unless instances are being made outside of allocations returned by heap allocators,
        // because those will all be aligned to 8 bytes.
        allocation: enum u8 {
            EXTERNAL :: 0x00;
            INTERNAL :: 0x80;
        };
        count: s8;
        bodies: [INTERNAL_BODY_COUNT]u16;
    }
    INTERNAL_BODY_COUNT :: #run (size_of([..]u16) - 2) / 2;
}

initialize_broad_phase :: () {
    using world;
}

calculate_grid_overlap :: (_body: *Physics_Body_Base) -> Vector2i, Vector2i {
    body       := cast(*Physics_Body_Internal) _body;
    aabb       := calculate_aabb(body);
    aabb_swept := sweep_aabb(aabb, body.linear_velocity * world.delta_time);
    aabb_swept.extent *= 1.25;

    aabb_swept.center -= {xy=world.world_center_2d};
    aabb_swept.center *= world.collision_grid_scale;
    aabb_swept.extent *= world.collision_grid_scale;

    min        := to_vector2i(aabb_swept.center.xy - aabb_swept.extent.xy, true);
    max_float  := aabb_swept.center.xy + aabb_swept.extent.xy;
    add_to_x : s32 = ifx max_float.x > 0 then cast(s32) 1 else cast(s32) 0;
    add_to_y : s32 = ifx max_float.y > 0 then cast(s32) 1 else cast(s32) 0;
    max        := to_vector2i(max_float) + Vector2i.{add_to_x, add_to_y};

    assert(min.x <= max.x);
    assert(min.y <= max.y);

    return min, max;
}

for_all_cells_in_overlap :: (_body: *Physics_Body_Base, $code: Code) #expand {
    `min, `max := calculate_grid_overlap(_body);

    for `y : min.y..max.y {
        for `x : min.y..max.y {
            `cell := get_collision_cell({_s16=.[xx x, xx y]});
            #insert code;
        }
    }
}

place_into_contact_grid :: (_body: *Physics_Body_Base) {
    using world;

    assert(!has_flags(_body, .PLACED_INTO_CONTACT_GRID));

    body_index: u16 = xx get_index(_body);

    for_all_cells_in_overlap(_body, #code add_to_cell(cell, body_index));

    _body.contact_grid_min_x = xx min.x;
    _body.contact_grid_min_y = xx min.y;
    _body.contact_grid_max_x = xx max.x;
    _body.contact_grid_max_y = xx max.y;

    add_flags(_body, .PLACED_INTO_CONTACT_GRID);
}

remove_from_contact_grid :: (_body: *Physics_Body_Base) {
    using world;

    if !has_flags(_body, .PLACED_INTO_CONTACT_GRID) {
        return;
    }

    body_index: u16 = xx get_index(_body);

    for_all_cells_in_overlap(_body, #code remove_from_cell(cell, body_index));

    // intentionally invalid (max < min)
    _body.contact_grid_min_x = 0;
    _body.contact_grid_min_y = 0;
    _body.contact_grid_max_x = -1;
    _body.contact_grid_max_y = -1;

    remove_flags(_body, .PLACED_INTO_CONTACT_GRID);
}

// NOTE: assumes cell needs to be created if it doesn't exist
get_collision_cell :: inline (key: num32) -> *Collision_Cell {
    cell := table_get_by_key_hash(*world.contact_grid, key._u32);
    if cell == null {
        table_set(*world.contact_grid, key._u32, {});
        cell = table_get_by_key_hash(*world.contact_grid, key._u32);
        cell.internal.allocation = .INTERNAL;
    }
    return cell;
}

add_to_cell :: (using cell: *Collision_Cell, body: u16) {
    if internal.allocation == .INTERNAL {
        if internal.count < internal.bodies.count {
            internal.bodies[internal.count] = body;
            internal.count += 1;
            return;
        }

        assert(internal.count == internal.bodies.count);

        internal.allocation = .EXTERNAL;

        external_temp: [..]u16;
        external_temp.allocator = world.contact_grid_cell_allocator;

        array_resize(*external_temp, internal.bodies.count * 2);
        external_temp.count = internal.bodies.count;
        memcpy(external_temp.data, internal.bodies.data, internal.bodies.count * size_of(u16));

        external = external_temp;
    } 

    assert(internal.allocation == .EXTERNAL);
    assert(external.count > Collision_Cell.internal.bodies.count && external.count < 0xffff_ffff);
    array_add(*external, body);
}

remove_from_cell :: (using cell: *Collision_Cell, body: u16) {
    if internal.allocation == .EXTERNAL {
        assert(external.count > Collision_Cell.bodies.count && external.count < 0xffff_ffff);
        array_unordered_remove_by_value(*external, body);   
        if external.count <= #run Collision_Cell.bodies.count / 2 {
            data  := external.data;
            count := external.count;
            memcpy(internal.bodies.data, data, count * size_of(u16));
            internal.count      = xx count;
            internal.allocation = .INTERNAL;
        }
        return;
    }

    assert(cell.allocation == .INTERNAL);
    if internal.count > 0 then for 0..internal.count-1 {
        if internal.bodies[it] == body {
            if it != internal.count - 1 {
                internal.bodies[it] = internal.bodies[internal.count-1];
            }
            internal.count -= 1;
            return;
        }
    }
}
