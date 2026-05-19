body_can_translate :: inline (body_i: int) -> bool {
    return (world.physics_bodies[body_i].flags & .LOCK_TRANSLATION) == 0;
}

body_can_rotate :: inline (body_i: int) -> bool {
    ALL_AXES_LOCKED : Physics_Body_Flags : .LOCK_YAW | .LOCK_PITCH | .LOCK_ROLL
    return (world.physics_bodies[body_i].flags & ALL_AXES_LOCKED) != ALL_AXES_LOCKED;
}

Physics_Body_Combined_Data :: struct {
    flags:               Physics_Body_Flags;
    collision_channels:  Collision_Channel;
    using body:          Physics_Body;
}

Physics_Body_Flags :: enum_flags u32 {
    LOCK_TRANSLATION;
    LOCK_YAW;
    LOCK_PITCH;
    LOCK_ROLL;
    UPRIGHT;
}

Physics_Body:: struct {
    linear_velocity: Vector3;
    angular_velocity: Vector3;

    move_input: Vector2;
    received_move_input_last_physics_step: bool;
    last_nonzero_move_input: Vector2;

    prev_position: Vector3;
    next_position: Vector3;
    prev_orientation: Quaternion;
    next_orientation: Quaternion;
    
    using properties: *Physics_Properties;
}

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
