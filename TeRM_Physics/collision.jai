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

solve_contact_sphere_sphere :: (body_a: *Physics_Body_Internal, body_b: *Physics_Body_Internal, contact: *Physics_Contact) -> bool {
    assert(body_a.collider.shape == .SPHERE && body_b.collider.shape == .SPHERE);
    using world;

    radius_sum       := body_a.collider.sphere.radius + body_b.collider.sphere.radius;

    cur_position_diff = body_b.next_position - body_a.next_position;
    cur_distance_sq  := length_squared(cur_position_diff);

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
        contact.contact_time = calculate_contact_time(contact.normal, body_a.next_position, body_b.next_position, body_a.linear_velocity, body_b.linear_velocity, cur_distance, radius_sum);
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

    sphere_center_projection_onto_plane, distance_from_plane := project_point_onto_plane(body_a.next_position, body_b.next_position, body_b.z_axis);

    if distance_from_plane <= SMALL_NUMBER {
        // ?    
    }

    // assuming side

    contact.normal       = -body_b.z_axis;
    contact.contact_time = calculate_contact_time(contact.normal, body_a.next_position, body_b.next_position, body_a.linear_velocity, body_b.linear_velocity, distance_from_plane, body_a.collider.sphere.radius);

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
calculate_contact_time :: (contact_normal: Vector3, a_position: Vector3, b_position: Vector3, a_velocity: Vector3, b_velocity: Vector3, cur_distance: float, buffer_distance: float) -> float #expand {
    dhat_px1 := dot(a_position, contact_normal);
    dhat_px2 := dot(b_position, contact_normal);
    dhat_vx1 := dot(a_velocity, contact_normal);
    dhat_vx2 := dot(b_velocity, contact_normal);
    return (buffer_distance - cur_distance - dhat_px1 + dhat_px2) / (dhat_vx1 - dhat_vx2);
}

return_is_contact :: () {
    `return `contact.contact_time >= 0 && `contact.contact_time < world.delta_time;
}

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
