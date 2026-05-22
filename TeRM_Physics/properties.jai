Physics_Properties :: struct {
    mass:              float;
    linear_damping:    float; // todo: curve?
    angular_damping:   float; // todo: curve?
    pointing_friction: float; // todo: curve?
    slide_friction:    float; // todo: curve?
    air_resistance:    float; // todo: curve?

    collider: Physics_Collider;
}

change_property :: (body: *Physics_Body, $property_name: string, new_value: $T) {
    PROPERTY_OFFSET :: #run -> int {
        props_tinfo := type_info(Physics_Properties);
        for member : props_tinfo.members {
            if member.name == property_name {
                member_type := (cast(*Type) *member.type).*;
                assert(member_type == T, "in Physics_Properties, % has type %, but a value of type % was passed to change_property", property_name, member_type, T);
                return member.offset_in_bytes;
            }
        }
        assert(false, "found no physics property with the name %", property_name);
        return 0;
    }

    make_properties_unique(body);
    property_ptr := cast(*T) ((cast(*u8) body.properties) + PROPERTY_OFFSET);
    property_ptr.* = new_value;
}

make_properties_unique :: (body: *Physics_Body) {
    if !is_unique(body.properties) {
        new_properties_index := pool_acquire(*world.unique_properties);
        new_properties := *world.unique_properties[new_properties_index];
        new_properties.* = body.properties.*;
        body.properties = new_properties;
    }
}

is_unique :: inline (properties: *Physics_Properties) -> shared: bool, unique_index: s32 {
    using world;
    unique_index := properties - unique_properties.items.data;
    if unique_index >= 0 && unique_index < world.unique_properties.items.count {
        assert(is_pool_item_in_use(*world.unique_properties, unique_index));
        return true, xx unique_index;
    }
    shared_byte_diff := cast(*u8) properties - cast(*u8) body_templates.values.data;
    shared_byte_end  := size_of(type_of(body_templates.values[0])) * body_templates.values.count;
    assert(shared_byte_diff >= 0 && shared_byte_diff < shared_byte_end);
    return false, -1;
}

// if DEBUG_INVALIDATED_TEMPLATE_PROPERTIES (module param) is true, this can be called
// any time by the user to make a point in time they know the template properties
// to be valid.
debug_mark_template_properties_valid :: () {
    #if DEBUG_INVALIDATED_TEMPLATE_PROPERTIES {
        using world;
        assert(body_templates.values.count == debug_template_properties.count);
        for 0..body_templates.values.count-1 {
            debug_template_properties[it] = body_templates.values[it].properties;
        }
    }
}

// if DEBUG_INVALIDATED_TEMPLATE_PROPERTIES (module param) is true, this can be called
// any time by the user to make sure they aren't invalidating their own templates. it
// will also be called automatically during the physics update.
debug_validate_template_properties :: () {
    #if DEBUG_INVALIDATED_TEMPLATE_PROPERTIES {
        using world;
        assert(body_templates.values.count == debug_template_properties.count);
        for 0..body_templates.values.count-1 {
            assert(body_templates.values[it].properties == debug_template_properties[it]);
        }
    }
}

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
