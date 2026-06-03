Physics_Contact :: struct {
    a_local_space_contact_point:  Vector3;
    b_local_space_contact_point:  Vector3;
    a_world_space_surface_normal: Vector3;
    b_world_space_surface_normal: Vector3;
    contact_normal: Vector3;
    contact_time: float;
    // only if contact_time is negative one
    overlap: float;
}

solve_contact_sphere_sphere :: (body_a: *Physics_Body_Internal, body_b: *Physics_Body_Internal, contact: *Physics_Contact) -> bool {
    assert(body_a.collider.shape == .SPHERE && body_b.collider.shape == .SPHERE);
    using world;

    radius_sum       := body_a.collider.sphere.radius + body_b.collider.sphere.radius;

    cur_position_diff = body_b.next_position - body_a.next_position;
    cur_distance_sq  := length_squared(cur_position_diff);

    if cur_distance_sq <= square(radius_sum) {
        contact.a_local_space_contact_point  = {z= 1}
        contact.b_local_space_contact_point  = {z=-1}
        contact.a_world_space_surface_normal = {z= 1}
        contact.b_world_space_surface_normal = {z=-1}
        contact.contact_normal               = {z= 1};
        contact.contact_time                 = -1;
        contact.overlap                      = radius_sum;
        return true;
    }

    // worked out on paper but I'm usually wrong the first time
    // t = (r1 + r2 - len(d) - dhat * px1 + dhat * px2) / (dhat * vx1 - dhat * vx2)
    cur_distance          := sqrt(cur_distance_sq);
    contact.contact_normal = cur_position_diff / cur_distance;
    dhat_px1              := dot(body_a.next_position,   contact.normal);
    dhat_px2              := dot(body_b.next_position,   contact.normal);
    dhat_vx1              := dot(body_a.linear_velocity, contact.normal);
    dhat_vx2              := dot(body_b.linear_velocity, contact.normal);
    contact.contact_time   = (radius_sum - cur_distance - dhat_px1 + dhat_px2) / (dhat_vx1 - dhat_vx2);

    if contact.contact_time >= 0 && contact.contact_time <= delta_time {
        contact.a_local_space_contact_point  = rotate(contact.contact_normal, conjugate(body_a.next_rotation));
        contact.b_local_space_contact_point  = rotate(contact.contact_normal, conjugate(body_b.next_rotation));
        contact.a_world_space_surface_normal =  contact.contact_normal;
        contact.b_world_space_surface_normal = -contact.contact_normal;
        contact.overlap                      = 0;
        return true;
    } else return false;
}

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
