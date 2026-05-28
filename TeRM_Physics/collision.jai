Physics_Collider :: struct {
    using shape_data: union {
        // the first field in every Shape struct is half_height (or radius for sphere, same thing).
        // it can be read from the shape itself or directly from the collider due to the fields being aligned.
        half_height:  float32;
        circle:       Shape_Circle;
        rectangle:    Shape_Rectangle;
        cylinder:     Shape_Cylinder;
        box:          Shape_Box;
        pillbox:      Shape_Pillbox;
        sphere:       Shape_Sphere;
        capsule:      Shape_Capsule;
        convex:       Shape_Convex;
    };
    shape:    Physics_Shape;
    // PADDING 3
    channels: Collision_Channel;
}

Collision_Mesh : struct {
    points: []Vector3;
    triangle_type: Physics_Shape = .TRIANGLE_U16;
    triangles: union {
        _u16: []Shape_Triangle_U16;
        _u32: []Shape_Triangle_U32 = ---;
    };
}

get_collider :: inline (in_body: *Physics_Body_Base) -> Physics_Collider {
    return (cast(*Physics_Body_Internal) in_body).collider;
}

set_collider :: (in_body: *Physics_Body_Base, collider: Physics_Collider) {
    make_collider_unique(in_body);
    body := cast(*Physics_Body_Internal) in_body;
    body.collider.* = collider;
}

is_unique :: inline (collider: *Physics_Collider) -> unique: bool, unique_index: s32 {
    using world;
    unique_index := collider - unique_colliders.items.data;
    if unique_index >= 0 && unique_index < unique_colliders.items.count {
        assert(is_pool_item_in_use(*unique_colliders, unique_index));
        return true, xx unique_index;
    }
    assert(is_data_from_template(xx collider));
    return false, -1;
}

make_collider_unique :: inline (in_body: *Physics_Body_Base) {
    body := cast(*Physics_Body_Internal) in_body;
    if !is_unique(body.collider) {
        new_collider_index := pool_acquire(*world.unique_colliders);
        new_collider := *world.unique_colliders[new_collider_index];
        new_collider.* = body.collider.*;
        body.collider = new_collider;
    }
}

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
