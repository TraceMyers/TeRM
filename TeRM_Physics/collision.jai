Physics_Collider :: struct {
    using shape_data: union {
        // the first field in every Shape struct is half_height (or radius for sphere, same thing).
        // it can be read from the shape itself or directly from the collider due to the fields being aligned.
        half_height: float32;
        circle:      Shape_Circle;
        rectangle:   Shape_Rectangle;
        cylinder:    Shape_Cylinder;
        box:         Shape_Box;
        pillbox:     Shape_Pillbox;
        sphere:      Shape_Sphere;
        capsule:     Shape_Capsule;
        convex:      Shape_Convex;
    };
    shape:    Physics_Shape;
    // PADDING 3
    channels: Collision_Channel;
}

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
