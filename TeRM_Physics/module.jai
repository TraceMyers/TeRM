#module_parameters()(
    collision_channels : []string = string.[],
    raycast_channels   : []string = string.[],
    PHYSICS_DELTA_TIME := 1.0 / 100.0,
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
    #insert -> string {
        builder: String_Builder;
        for channel : collision_channels {
            print(*builder, "%;\n", channel);
        }
        return builder_to_string(*builder);
    }
}

Raycast_Channel :: enum_flags u32 {
    #insert -> string {
        builder: String_Builder;
        for channel : raycast_channels {
            print(*builder, "%;\n", channel);
        }
        return builder_to_string(*builder);
    }
}

#load "properties.jai";
#load "world.jai";
#load "collision.jai";
#load "raycast.jai";
#load "raycast_simple.jai";
#load "shape.jai";
#load "body.jai";
#load "update.jai";
#load "derive.jai";
#load "overlap.jai";
#load "convex.jai";

#scope_module

world: *Physical_World;

#import "Math";
#import "Basic";

#import "TeRM/TeRM_Storage";
#import "TeRM/TeRM_Allocation";
#import "TeRM/TeRM_Math";

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
