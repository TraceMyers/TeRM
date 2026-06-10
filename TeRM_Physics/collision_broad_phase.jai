// todo: detecting common bugs like double-put or forgetting to remove
// todo: optimization, instead of doing a full remove, re-place, do a diff placement.

Contact_Cell :: struct {
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

body_count :: (cell :*Contact_Cell) -> int {
    if cell.internal.allocation == .INTERNAL {
        return cell.internal.count;
    } else return cell.external.count;
}

for_expansion :: (cell: *Contact_Cell, body: Code, flags: For_Flags) #expand {
    bodies: []u16 = ---;
    if cell.internal.allocation == .INTERNAL {
        bodies.data  = cell.internal.bodies.data;
        bodies.count = cell.internal.count;
    } else {
        bodies = cell.external;
    }

    for b, bi : bodies {
        `it := cast(*Physics_Body) *world.body_data.bodies[b];
        `it_index := bi;

        #insert body;
    }
}

initialize_broad_phase :: () {
    using world;
}

calculate_grid_overlap :: (_body: *Physics_Body_Base) -> Vector2i, Vector2i {
    body       := cast(*Physics_Body_Internal) _body;
    aabb       := calculate_aabb(body);
    aabb_swept := sweep_aabb(aabb, body.linear_velocity * world.delta_time);
    aabb_swept.extent *= 1.25;

    min := world_to_grid(aabb_swept.center - aabb_swept.extent);
    max := world_to_grid(aabb_swept.center + aabb_swept.extent);

    assert(min.x <= max.x);
    assert(min.y <= max.y);

    return min, max;
}

world_to_grid :: inline (v: Vector3) -> Vector2i {
    transformed := v.xy;
    transformed -= world.grid_origin;
    transformed *= world.grid_scale;
    transformed = clamp(transformed, {0, 0}, {xx (world.grid_width - 1), xx (world.grid_width - 1)});
    return to_vector2i(transformed);
}

Grid_To_World_Placement :: enum { UPPER_LEFT; CENTER; LOWER_RIGHT; }

grid_to_world :: inline (v: Vector2i, $placement := Grid_To_World_Placement.UPPER_LEFT) -> Vector3 {
    transformed := Vector2.{xx v.x, xx v.y};
    inv_grid_scale := splat(1.0 / world.grid_scale, 2);
    transformed *= inv_grid_scale;

    #if placement == {
    case .UPPER_LEFT;
        transformed += world.grid_origin;
    case .CENTER;
        transformed += world.grid_origin + inv_grid_scale * 0.5;
    case .LOWER_RIGHT;
        transformed += world.grid_origin + inv_grid_scale;
    }

    return Vector3.{xy=transformed};
}

for_all_cells_in_overlap :: (_body: *Physics_Body_Base, $code: Code, $allocate_cell_if_empty: bool, $use_coords_on_body: bool) -> bool #expand {
    body := cast(*Physics_Body_Internal) _body;
    if !has_extent(body.collider.shape) {
        return false;
    }

    #if use_coords_on_body {
        `min := Vector2i.{body.contact_grid_min_x, body.contact_grid_min_y};
        `max := Vector2i.{body.contact_grid_max_x, body.contact_grid_max_y};
    } else {
        `min, `max := calculate_grid_overlap(_body);
    }

    for `y : min.y..max.y {
        for `x : min.x..max.x {
            `cell := get_contact_cell({_s16=.[xx x, xx y]}, allocate_cell_if_empty);
            #insert code;
        }
    }
    return true;
}

place_into_contact_grid :: (_body: *Physics_Body_Base) {
    using world;

    // modification of grid is only allowed until the first body is placed into it.
    // todo: make reset feature?
    world.grid_in_use = true;

    assert(!has_flags(_body, .PLACED_INTO_CONTACT_GRID));

    body_index: u16 = xx get_index(_body);

    if !for_all_cells_in_overlap(_body, #code add_to_cell(cell, body_index), true, false) {
        return;
    }

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

    for_all_cells_in_overlap(_body, #code remove_from_cell(cell, body_index), false, true);

    // intentionally invalid (max < min)
    _body.contact_grid_min_x = 0;
    _body.contact_grid_min_y = 0;
    _body.contact_grid_max_x = -1;
    _body.contact_grid_max_y = -1;

    remove_flags(_body, .PLACED_INTO_CONTACT_GRID);
}

get_contact_cell :: inline (coords: Vector2i) -> *Contact_Cell {
    return get_contact_cell({_u16=.[xx coords.x, xx coords.y]});
}

// NOTE: assumes cell needs to be created if it doesn't exist
get_contact_cell :: inline (key: num32, allocate_if_empty := false) -> *Contact_Cell {
    cell := table_get_by_key_hash(*world.contact_grid, key._u32);
    if cell == null && allocate_if_empty {
        table_set(*world.contact_grid, key._u32, {});
        cell = table_get_by_key_hash(*world.contact_grid, key._u32);
        cell.internal.allocation = .INTERNAL;
    }
    return cell;
}

add_to_cell :: (using cell: *Contact_Cell, body: u16) {
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
    assert(external.count > Contact_Cell.internal.bodies.count && external.count < 0xff_ffff);
    array_add(*external, body);
}

remove_from_cell :: (using cell: *Contact_Cell, body: u16) {
    if internal.allocation == .EXTERNAL {
        assert(external.count > Contact_Cell.internal.bodies.count && external.count < 0xffff_ffff);
        array_unordered_remove_by_value(*external, body);   
        if external.count <= #run Contact_Cell.internal.bodies.count / 2 {
            data  := external.data;
            count := external.count;
            memcpy(internal.bodies.data, data, count * size_of(u16));
            internal.count      = xx count;
            internal.allocation = .INTERNAL;
        }
        return;
    }

    assert(internal.allocation == .INTERNAL);
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
