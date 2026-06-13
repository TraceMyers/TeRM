#module_parameters()(
    collision_channels : string = "",
    raycast_channels   : string = "",
    PHYSICS_DELTA_TIME := 1.0 / 100.0,
    MIN_BODY_SPEED_ALONG_AXIS := 0.000001,
    user_types: $I/interface Type_Provider_Default = Type_Provider_Default,
    DEBUG_INVALIDATED_TEMPLATE_PROPERTIES := false
) {
    Type_Provider_Default :: struct {
        entity_id_type  :: void;
        extra_body_data :: void;
    }
}

INV_PHYSICS_DELTA_TIME :: 1.0 / PHYSICS_DELTA_TIME;

Collision_Channel :: enum_flags u32 {
    #insert collision_channels;
}

Raycast_Channel :: enum_flags u32 {
    #insert raycast_channels;
}

#load "properties.jai";
#load "world.jai";
#load "collision.jai";
#load "collider.jai";
#load "raycast.jai";
#load "raycast_simple.jai";
#load "shape.jai";
#load "body.jai";
#load "update.jai";
#load "derive.jai";
#load "overlap.jai";
#load "convex.jai";
#load "config.jai";
#load "friction.jai";
#load "collision_broad_phase.jai";
#load "collision_narrow_phase.jai";

#scope_module

world: *Physical_World;

#import "Math";
#import "Basic";
#import "Bit_Array";
#import "Bit_Operations";

#import "TeRM/TeRM_Storage";
#import "TeRM/TeRM_Allocation";
#import "TeRM/TeRM_Math";
#import "TeRM/TeRM_Metaprogram";
#import "TeRM/TeRM_NumberInterpretation";
#import "TeRM/TeRM_Array";
#import "TeRM/TeRM_Compression";

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
