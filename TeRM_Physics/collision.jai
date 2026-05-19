Physics_Collider :: struct {
    using shape_data: union {
        half_height: float32;
        rectangle: Shape_Rectangle;
        cylinder: Shape_Cylinder;
        box: Shape_Box;
        pillbox: Shape_Pillbox;
        sphere: Shape_Sphere;
        capsule: Shape_Capsule;
    };
    shape:    Physics_Shape;
    // PADDING 3
    channels: Collision_Channel;
}

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
