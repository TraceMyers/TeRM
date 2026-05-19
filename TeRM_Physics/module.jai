#module_parameters(
    collision_channels : []string = string.[],
    raycast_channels   : []string = string.[]
);

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


#load "core_types.jai";
#load "properties.jai";
#load "world.jai";
#load "collision.jai";
#load "raycast.jai";
#load "raycast_simple.jai";
#load "shape.jai";

#scope_module

world: *Physical_World;

#import "TeRM/TeRM_Allocation";
#import "TeRM/TeRM_Storage";

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
