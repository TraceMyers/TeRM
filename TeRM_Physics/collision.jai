// todo: precalculate axes for collisions only. one long buffer.

Physics_Contact :: struct {
    // offset & normals are in world space. rotate them with the conjugate of the
    // body's orientation go get them in local space.
    a_contact_offset:  Vector3;
    b_contact_offset:  Vector3;
    a_surface_normal: Vector3;
    b_surface_normal: Vector3;
    contact_normal: Vector3;
    // time until the bodies make contact. if >= 0 and < delta_time, it is a contact.
    contact_time: float;
    // only if contact_time is 0
    overlap: float;
}

solve_contact :: (body_a: *Physics_Body_Internal, body_b: *Physics_Body_Internal) {
    contact: Physics_Contact;
    is_contact: bool;

    if body_a.collider.shape == {
    case .SPHERE;
        if body_b.collider.shape == {
        case .SPHERE;
            is_contact = solve_contact_sphere_sphere(body_a, body_b, *contact);
        case .PLANE;
            is_contact = solve_contact_sphere_plane(body_a, body_b, *contact);
        }
    case .PLANE;
        if body_b.collider.shape == {
        case .SPHERE;
            is_contact = solve_contact_sphere_plane(body_b, body_a, *contact);
            flip(*contact);
        case .PLANE;
        }
    }

    // todo: just to remember for later that movement has a time budget,
    // because we move forward in time in sorted order from earliest to latest.
    // note this also means that we can't just do 1. resolve collisions 2. move
    // because collision resolution and movement are integrated.
    if is_contact {
        a_moves := (get_flags(body_a) & .LOCK_TRANSLATION) == 0;
        b_moves := (get_flags(body_b) & .LOCK_TRANSLATION) == 0;
        // for now, just basic position resolution and velocity killing
        if !b_moves {
            if a_moves {
                if contact.contact_time == 0 {
                    body_a.next_position -= contact.contact_normal * contact.overlap;
                } else {
                    body_a.next_position += body_a.linear_velocity * contact.contact_time;
                }
            }
        } else if !a_moves {
            if contact.contact_time == 0 {
                body_b.next_position += contact.contact_normal * contact.overlap;
            } else {
                body_b.next_position += body_b.linear_velocity * contact.contact_time;
            }
        } else {
            if contact.contact_time == 0 {
                body_a.next_position -= contact.contact_normal * (contact.overlap * 0.5);
                body_b.next_position += contact.contact_normal * (contact.overlap * 0.5);
            } else {
                body_a.next_position += body_a.linear_velocity * contact.contact_time;
                body_b.next_position += body_b.linear_velocity * contact.contact_time;
            }
        }

        // todo: you know, stuff
        body_a.linear_velocity -= contact.contact_normal * dot(body_a.linear_velocity, contact.contact_normal);
        body_b.linear_velocity -= -contact.contact_normal * dot(body_b.linear_velocity, -contact.contact_normal);

        moving_body: *Physics_Body_Internal;
        static_body: *Physics_Body_Internal;
        surface_normal: Vector3;
        surface_speed: float;

        if a_moves && !b_moves {
            moving_body = body_a;
            static_body = body_b;
            surface_normal = contact.b_surface_normal;
            surface_speed  = length(body_a.linear_velocity);
        } else if !a_moves && b_moves {
            moving_body = body_b;
            static_body = body_a;
            surface_normal = contact.a_surface_normal;
            surface_speed  = length(body_b.linear_velocity);
        }
        
        if surface_speed > 0 {
            // might be other forces at work...
            // normal_force := world.gravity * dot(surface_normal, {z=1}) * moving_body.properties.mass;
            
            // friction := calculate_stribeck_friction(FRICTION_DEFAULT, normal_force, surface_speed);
            // friction_accel := friction * moving_body.properties.inv_mass;
            // friction_velocity_delta := friction_accel * world.delta_time;

            // new_surface_speed := max(surface_speed - friction_velocity_delta, 0);
            // moving_body.linear_velocity *= new_surface_speed / surface_speed;

            assert(moving_body.collider.shape == .SPHERE);
            axis_of_acceleration := cross(surface_normal, moving_body.linear_velocity);
            moving_body.angular_velocity += axis_of_acceleration / moving_body.collider.sphere.radius * world.delta_time;
            moving_body.linear_velocity = {};
        }
    }
}

solve_contact_sphere_sphere :: (body_a: *Physics_Body_Internal, body_b: *Physics_Body_Internal, contact: *Physics_Contact) -> bool {
    assert(body_a.collider.shape == .SPHERE && body_b.collider.shape == .SPHERE);
    using world;

    radius_sum        := body_a.collider.sphere.radius + body_b.collider.sphere.radius;

    cur_position_diff := body_b.next_position - body_a.next_position;
    cur_distance_sq   := length_squared(cur_position_diff);

    if cur_distance_sq <= VERY_SMALL_NUMBER {
        contact.a_contact_offset = {z= body_a.collider.sphere.radius};
        contact.b_contact_offset = {z=-body_b.collider.sphere.radius};
        contact.a_surface_normal = {z= 1};
        contact.b_surface_normal = {z=-1};
        contact.contact_normal   = {z= 1};
        contact.contact_time     = 0;
        contact.overlap          = radius_sum;
        return true;
    }

    cur_distance          := sqrt(cur_distance_sq);
    contact.contact_normal = cur_position_diff / cur_distance;

    if cur_distance > radius_sum {
        contact.contact_time = calculate_contact_time(contact.contact_normal, body_a.next_position, body_b.next_position, body_a.linear_velocity, body_b.linear_velocity, cur_distance, radius_sum);
        contact.overlap      = 0;
    } else {
        contact.contact_time = 0;
        contact.overlap      = radius_sum - cur_distance;
    }

    contact.a_contact_offset =  contact.contact_normal * body_a.collider.sphere.radius;
    contact.b_contact_offset = -contact.contact_normal * body_b.collider.sphere.radius;
    contact.a_surface_normal =  contact.contact_normal;
    contact.b_surface_normal = -contact.contact_normal;

    return_is_contact();
}

solve_contact_sphere_plane :: (body_a: *Physics_Body_Internal, body_b: *Physics_Body_Internal, contact: *Physics_Contact) -> bool {
    assert(body_a.collider.shape == .SPHERE && body_b.collider.shape == .PLANE);
    using world;

    sphere_center_projection_onto_plane, distance_from_plane := project_point_onto_plane(body_a.next_position, body_b.next_position, z_axis(body_b));

    contact.contact_normal = -z_axis(body_b);

    // todo: negative side
    if distance_from_plane <= body_a.collider.sphere.radius {
        if distance_from_plane < -body_a.collider.sphere.radius {
            return false;
        }
        contact.a_contact_offset = contact.contact_normal * body_a.collider.sphere.radius;
        contact.b_contact_offset = sphere_center_projection_onto_plane - body_b.next_position;
        contact.a_surface_normal = contact.contact_normal;
        contact.b_surface_normal = -contact.contact_normal;
        contact.contact_time     = 0;
        contact.overlap          = body_a.collider.sphere.radius - distance_from_plane;
        return true;
    }

    // assuming side

    contact.contact_time   = calculate_contact_time(contact.contact_normal, body_a.next_position, body_b.next_position, body_a.linear_velocity, body_b.linear_velocity, distance_from_plane, body_a.collider.sphere.radius);

    contact_point := body_a.next_position + body_a.linear_velocity * contact.contact_time + contact.contact_normal * body_a.collider.sphere.radius;

    contact.a_contact_offset =  contact.contact_normal * body_a.collider.sphere.radius;
    contact.b_contact_offset =  contact_point - body_b.next_position;
    contact.a_surface_normal =  contact.contact_normal;
    contact.b_surface_normal = -contact.contact_normal;
    contact.overlap          = 0;

    return_is_contact();
}

#scope_file

// worked out on paper but I'm usually wrong the first time
// if spheres, buffer distance is r1 + r2, giving
// t = (r1 + r2 - len(d) - dhat * px1 + dhat * px2) / (dhat * vx1 - dhat * vx2)
calculate_contact_time :: (contact_normal: Vector3, a_position: Vector3, b_position: Vector3, a_velocity: Vector3, b_velocity: Vector3, cur_distance: float, buffer_distance: float) -> float {
    dhat_px1 := dot(a_position, contact_normal);
    dhat_px2 := dot(b_position, contact_normal);
    dhat_vx1 := dot(a_velocity, contact_normal);
    dhat_vx2 := dot(b_velocity, contact_normal);
    return (buffer_distance - cur_distance - dhat_px1 + dhat_px2) / (dhat_vx1 - dhat_vx2);
}

return_is_contact :: () #expand {
    `return `contact.contact_time >= 0 && `contact.contact_time < world.delta_time;
}

flip :: inline (using contact: *Physics_Contact) {
    a_contact_offset, b_contact_offset = b_contact_offset, a_contact_offset;
    a_surface_normal, b_surface_normal = b_surface_normal, a_surface_normal;
    contact_normal *= -1;
}

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
