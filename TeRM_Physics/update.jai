// example physics update:
// my_physics_update :: () {
    // update_physics(delta_time);
    // physical_entity_transform_update(#code {
        // e := get_entity(entity_id);
        // e.position = lerp(body.prev_position, body.next_position, physics_transform_alpha);
        // e.orientation = interp_rotate_with_alpha(body.prev_orientation, body.next_orientation, physics_transform_alpha);
    // k});
// }

physics_delta_time :: () -> float #expand {
    return PHYSICS_DELTA_TIME * world.time_scale;
}

// returns how many steps ran
update_physics :: (in_time_scale: float) -> int {
    using world;

    if step_state == .PAUSED {
        return 0;
    }

    if start_time == 0 {
        start_time = seconds_since_init();
    }

    update_timestamp        = seconds_since_init();
    total_simulation_time  := update_timestamp - start_time;
    total_simulation_steps := cast(int) (total_simulation_time * INV_PHYSICS_DELTA_TIME);
    run_steps_this_frame   := total_simulation_steps - step_count;

    if run_steps_this_frame <= 0 {
        return 0;
    }

    if step_state == .STEP_ONCE {
        step_state = .PAUSED;
    }

    // only updating time scale right before stepping, because this is exactly when it is used.
    time_scale = in_time_scale;
    step_count = total_simulation_steps;

    for 0..run_steps_this_frame-1 {
        run_physics_step(it);
    }

    return run_steps_this_frame;
}

// if consecutive_step_index is 0, some extra initialization is done, as well
// as (todo) warm starting
run_physics_step :: (consecutive_step_index: int = 0) {
    using world;

    delta_time = physics_delta_time();

    for *body, bi : world.body_data.bodies {
        if (get_flags(body) & .SKIP_UPDATE) != 0 {
            continue;
        }

        if consecutive_step_index == 0 {
            body.prev_position = body.next_position;
        }

        if body.properties.call_per_step != null {
            body.properties.call_per_step(xx body);
        }
        
        if body.move_input != {} {
            input_accel := body.move_input * body.properties.move_input_acceleration;
            body.linear_velocity.xy += input_accel * delta_time;
            body.move_input = {};
        }

        calculate_axes(body);

        linear_speed_sq := length_squared(body.linear_velocity.xy);

        if linear_speed_sq > 0 {
            // todo: apply gravity as a force, naturally resulting against friction against surfaces with z-up components
            pointing_friction := body.properties.pointing_friction * world.gravity;
            friction_delta_speed := pointing_friction * delta_time;

            if square(friction_delta_speed) > linear_speed_sq {
                body.linear_velocity = {};
                body.linear_speed    = 0;
            } else {
                // todo: introduce movement against contact surface, which is where friction is generated.
                linear_speed            := sqrt(linear_speed_sq);
                velocity_direction      := body.linear_velocity / linear_speed;
                friction_velocity_delta := -velocity_direction * friction_delta_speed;
                body.linear_velocity    += friction_velocity_delta;
                body.linear_speed        = length(body.linear_velocity);
            }

            // velocity applied after friction to allow for static friction (no movement)
            body.next_position += body.linear_velocity * delta_time;
        } else {
            body.linear_speed = 0;
        }
    }
}

physical_entity_transform_update :: (loop_body: Code) #expand {
    LOCK_TRANSLATE_AND_ROTATE : Physics_Body_Flags : .LOCK_TRANSLATION | .LOCK_YAW | .LOCK_PITCH |.LOCK_ROLL;

    `physics_transform_alpha := get_physical_entity_transform_alpha();

    for *b, bi : world.body_data.bodies {
        `flags := get_flags(cast(*Physics_Body) b);
        // if (`flags & .AWAKE) == 0 {
        //     continue;
        // }
        if (`flags & LOCK_TRANSLATE_AND_ROTATE) == LOCK_TRANSLATE_AND_ROTATE {
            continue;
        }
        `body      := cast(*Physics_Body) b;
        `it_index  := bi;
        `entity_id := world.body_data.entity_ids[bi];

        #insert loop_body;
    }
}

get_physical_entity_transform_alpha :: () -> float32 {
    using world;
    total_simulation_time  := start_time - update_timestamp;
    simulated_time         := world.step_count * PHYSICS_DELTA_TIME;
    remainder              := total_simulation_time - simulated_time;
    return xx clamp(remainder * INV_PHYSICS_DELTA_TIME, 0, 1);
}
