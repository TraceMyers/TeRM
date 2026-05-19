Physics_Properties :: struct {
    mass:              float;
    linear_damping:    float; // curve?
    angular_damping:   float; // curve?
    pointing_friction: float; // curve?
    slide_friction:    float; // curve?
    air_resistance:    float;

    // move input only
    linear_move_acceleration:  float;
    angular_move_acceleration: float;
}

change_property :: (props: *Physics_Properties, $property_name: string, new_value: $T) {
    PROPERTY_OFFSET :: #run -> int {
        physics_tinfo := type_info(Physics_Body);
        for member : physics_tinfo.members {
            if member.name == property_name {
                member_type := (cast(*Type) *member.type).*;
                assert(member_type == T, "in Physics_Body, % has type %, but a value of type % was passed to change_property", property_name, member_type, T);
                return member.offset_in_bytes;
            }
        }
        assert(false, "found no physics property with the name %", property_name);
        return 0;
    }

    if is_shared(props) {
        new_properties_index := pool_acquire(*context.world.physics_properties_pool);
        new_properties := *context.world.physics_properties_pool[new_properties_index];
        new_properties.base = props.*;
        new_properties.template = get_template(body.properties);
        props.* = new_properties;
    }

    property_ptr := cast(*T) ((cast(*u8) body) + PROPERTY_OFFSET);
    property_ptr.* = new_value;
}

properties_are_shared :: inline (properties: *Physics_Properties) -> bool {
    distance := properties - world.shared_properties.data;
    return distance >= 0 && distance < world.shared_properties.count;
}

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
