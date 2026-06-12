// todo: detecting common bugs like double-put or forgetting to remove
// todo: optimization, instead of doing a full remove, re-place, do a diff placement.

Contact_Cell   :: Hybrid_Array(u16);
Contact_Island :: Contact_Cell;

Contact_Pair :: struct {
    a: u16;
    b: u16;
}

run_contacts_broad_phase :: () {
    using world;

    array_reset_keeping_memory(*contact_pairs);
    for *contact_islands {
        array_reset(it);
    }
    array_reset_keeping_memory(*contact_islands);

    seen_body       := make_bit_array(body_data.bodies.count,, temp);
    body_island_ids := make_static_array(u16, body_data.bodies.count,, temp);
    for *body_island_ids {
        it.* = 0xffff;
    }

    // todo: rotation being ignored because it's annoying. don't do that.
    SHOULD_VISIT_QUESTION : Physics_Body_Flags : .PLACED_INTO_CONTACT_GRID | .AWAKE | .LOCK_TRANSLATION; 
    SHOULD_VISIT_ANSWER   : Physics_Body_Flags : .PLACED_INTO_CONTACT_GRID | .AWAKE;

    for *body, bi : body_data.bodies {
        flags := body_data.flags[bi];

        if (flags & SHOULD_VISIT_QUESTION) != SHOULD_VISIT_ANSWER {
            continue;
        }

        // seen self = easy way to never pair with self
        seen_body[bi] = true;
        body_aabb := calculate_aabb(body);

        for_all_cells_in_overlap(body, false, true, #code {
            for obi : cell {
                // only visit bodies with indexes higher than this one...
                if obi < bi {
                    other_flags := body_data.flags[obi];
                    // ... but only as long as the other body already iterated
                    if (other_flags & SHOULD_VISIT_QUESTION) == SHOULD_VISIT_ANSWER {
                        continue;
                    }
                }

                if seen_body[obi] {
                    continue;
                }
                seen_body[obi] = true;

                other_body_aabb := calculate_aabb(*body_data.bodies[obi]);

                if is_overlap_aabb_aabb(body_aabb, other_body_aabb) {
                    array_add(*contact_pairs, {xx bi, xx obi});
                    place_pair_on_island(body_island_ids, xx bi, xx obi);
                }
            }
        });

        clear_all_bits(*seen_body);
    }
}

place_pair_on_island :: (body_island_ids: []u16, body_a: u16, body_b: u16) {
    using world;

    island_id_a := *body_island_ids[body_a];
    island_id_b := *body_island_ids[body_b];

    if island_id_a.* == island_id_b.* {
        if island_id_a.* == 0xffff && island_id_b.* == 0xffff {
            array_add(*contact_islands, {});
            island_id := cast(u16) (contact_islands.count - 1);
            assert(island_id < 0xffff);
            island := *contact_islands[island_id];
            array_add(island, body_a);
            array_add(island, body_b);
            island_id_a.* = island_id;
            island_id_b.* = island_id;
        }
    } else if island_id_a.* == 0xffff {
        island := *contact_islands[island_id_b.*];
        array_add(island, body_a);
        island_id_a.* = island_id_b.*;
    } else if island_id_b.* == 0xffff {
        island := *contact_islands[island_id_a.*];
        array_add(island, body_b);
        island_id_b.* = island_id_a.*;
    } else {
        island_id: u16 = ---;
        merge_island_id: u16 = ---;

        if island_id_a.* < island_id_b.* {
            island_id       = island_id_a.*;
            merge_island_id = island_id_b.*;
        } else {
            island_id       = island_id_b.*;
            merge_island_id = island_id_a.*;
        }

        island := *contact_islands[island_id];

        merge_island := *contact_islands[merge_island_id];
        for body_id : merge_island {
            array_add(island, body_id);
            body_island_ids[body_id] = island_id;
        }

        last_island_id := contact_islands.count - 1;
        if merge_island_id != last_island_id {
            copy_back_island := *contact_islands[last_island_id];
            for body_id : copy_back_island {
                body_island_ids[body_id] = merge_island_id;
            }
        }

        array_unordered_remove_by_index(*contact_islands, last_island_id);
    }
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
    inv_grid_scale := splat(1 / world.grid_scale, 2);
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

for_all_cells_in_overlap :: (_body: *Physics_Body_Base, $allocate_cell_if_empty: bool, $use_coords_on_body: bool, $code: Code) -> bool #expand {
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

    if !for_all_cells_in_overlap(_body, true, false, #code array_add(cell, body_index)) {
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

    for_all_cells_in_overlap(_body, false, true, #code array_unordered_remove_by_value(cell, body_index));

    // intentionally invalid (max < min)
    _body.contact_grid_min_x = 0;
    _body.contact_grid_min_y = 0;
    _body.contact_grid_max_x = -1;
    _body.contact_grid_max_y = -1;

    remove_flags(_body, .PLACED_INTO_CONTACT_GRID);
}

diff_place_into_contact_grid :: (_body: *Physics_Body_Base) {
    using world;

    body := cast(*Physics_Body_Internal) _body;

    if !has_extent(body.collider.shape) {
        remove_from_contact_grid(body);
        return;
    }

    new_min, new_max := calculate_grid_overlap(_body);

    if new_min.x == body.contact_grid_min_x
    && new_min.y == body.contact_grid_min_y
    && new_max.x == body.contact_grid_max_x
    && new_max.y == body.contact_grid_max_y {
        return;
    }

    body_index: u16 = xx get_index(body);

    for y : new_min.y..new_max.y {
        for x : new_min.x..new_max.x {
            if is_point_in_box_2d(x, y, body.contact_grid_min_x, body.contact_grid_min_y, body.contact_grid_max_x, body.contact_grid_max_y) {
                continue;
            }
            cell := get_contact_cell({_s16=.[xx x, xx y]}, true);
            array_add(cell, body_index);
        }
    }

    for y : body.contact_grid_min_y..body.contact_grid_max_y {
        for x : body.contact_grid_min_x..body.contact_grid_max_x {
            if is_point_in_box_2d(x, y, new_min.x, new_min.y, new_max.x, new_max.y) {
                continue;
            }
            cell := get_contact_cell({_s16=.[xx x, xx y]}, true);
            array_unordered_remove_by_value(cell, body_index);
        }
    }

    body.contact_grid_min_x = xx new_min.x;
    body.contact_grid_min_y = xx new_min.y;
    body.contact_grid_max_x = xx new_max.x;
    body.contact_grid_max_y = xx new_max.y;

    add_flags(_body, .PLACED_INTO_CONTACT_GRID);
}

get_contact_cell :: inline (coords: Vector2i) -> *Contact_Cell {
    return get_contact_cell({_u16=.[xx coords.x, xx coords.y]});
}

get_contact_cell :: inline (key: num32, allocate_if_empty := false) -> *Contact_Cell {
    cell := table_get_by_key_hash(*world.contact_grid, key._u32);
    if cell == null && allocate_if_empty {
        table_set(*world.contact_grid, key._u32, {external.allocator = world.contact_grid_cell_allocator});
        cell = table_get_by_key_hash(*world.contact_grid, key._u32);
    }
    return cell;
}
