// external type made to avoid changing shared properties on accident.
Physics_Body :: Physics_Body_Base(void, void);
// cast to this type for easy access to physics properties.
Physics_Body_Internal :: Physics_Body_Base(Physics_Properties, Physics_Collider);

Physics_Body_Base :: struct($properties_type: Type, $collider_type: Type) {
    linear_velocity: Vector3;
    angular_velocity: Vector3;

    prev_position: Vector3;
    next_position: Vector3;
    prev_orientation: Quaternion;
    next_orientation: Quaternion;

    // this data is calculated every physics step (that the body is awake).
    // it represents the most up-to-date information the body had on
    // the frame of the last physics step, so it may not be accurate to the frame.
    // if the field is not up to date and it is requested through get_...
    // then it will be updated on-demand.
    using per_step: struct {
        axes: [3]Vector3 = .[{1, 0, 0}, {0, 1, 0}, {0, 0, 1}];
        linear_speed: float;

        #overlay(axes[0]) x_axis:     Vector3;
        #overlay(axes[1]) y_axis:     Vector3;
        #overlay(axes[2]) z_axis:     Vector3;
    }

    properties: *properties_type;
    collider: *collider_type;
    
    move_input: Vector2;

    #if user_types.extra_body_data != void {
        extra_data: user_types.extra_body_data;
    }
}

// a template which will be used to spawn bodies. templates are used in order
// to encourage reusing physics properties. that is, if you create a body
// from a template, its properties pointer is pointing to the properties instance
// owned by the template. so, for all bodies with identical properties, you
// get more cache-efficient reads for free during physics. note that
// if properties are to be changed and you don't want to alter the template,
// you need to call the 'change_property' procedure.
// the body.properties pointer should be kept null, as it isn't used for anything.
Physics_Body_Template :: struct {
    flags:              Physics_Body_Flags;
    collision_channels: Collision_Channel;
    properties:         Physics_Properties;
    collider:           Physics_Collider;
}

Physics_Body_Flags :: enum_flags u32 {
    AWAKE;
    LOCK_TRANSLATION;
    LOCK_YAW;
    LOCK_PITCH;
    LOCK_ROLL;
    UPRIGHT;
    CALCULATED_AXES;
    CALCULATED_LINEAR_SPEED;
}

PER_STEP_PHYSICS_BODY_FLAGS : Physics_Body_Flags : .CALCULATED_AXES | .CALCULATED_LINEAR_SPEED;

create_physics_body :: (template_name: string, entity_id: user_types.entity_id_type) -> *Physics_Body {
    assert(entity_id != get_null_entity_id());
    template := table_get(*world.body_templates, template_name);
    return create_physics_body(template, entity_id);
}

create_physics_body :: (template: *Physics_Body_Template, entity_id: user_types.entity_id_type) -> *Physics_Body {
    using world;

    soa_add(*body_data);
    i := soa_count(*body_data) - 1;
    body_data.flags[i]              = template.flags;
    body_data.collision_channels[i] = template.collision_channels;
    body_data.bodies[i].properties  = *template.properties;
    body_data.bodies[i].collider    = *template.collider;
    body_data.entity_ids[i]         = entity_id;

    return xx *body_data.bodies[i];
}

// if the body that was destroyed displaced another body, the entity pointers to
// bodies (if you are doing things that way) will now be invalid. 
destroy_physics_body :: (in_body: *Physics_Body_Base) -> need_repoint: bool, id_to_repoint: user_types.entity_id_type {
    using world;

    body := cast(*Physics_Body_Internal) in_body;

    need_repoint: bool;
    id_to_repoint := get_null_entity_id();
    
    body_index := get_index(in_body);
    body_count := soa_count(*body_data);
    assert(body_index >= 0 && body_index < body_count);

    props_are_unique, unique_index := is_unique(body.properties);
    if props_are_unique {
        pool_release(*unique_properties, unique_index);
    }

    if body_index < body_count - 1 {
        need_repoint  = true;
        id_to_repoint = body_data.entity_ids[body_count-1];
    }

    soa_unordered_remove_by_index(*body_data, body_index);

    return need_repoint, id_to_repoint;
}

create_physics_body_template :: (name: string, template: Physics_Body_Template) {
    using world;

    template_copy := template;
    assert(template_copy.properties.mass > 0);
    template_copy.properties.inv_mass = 1.0 / template_copy.properties.mass;

    _, success := table_set(*body_templates, name, template_copy, .ONLY_ADD);
    // todo: probably should make it so the tables have hash collision resolution...
    assert(success, "table failed to add template % either because of a hash collision or because a template has already been added under that name", name);
    #if DEBUG_INVALIDATED_TEMPLATE_PROPERTIES {
        array_add(*debug_template_properties, template_copy.properties);
    }
}

get_physics_body_template :: (name: string) -> *Physics_Body_Template {
    return table_get(*world.body_templates, name);
}

accelerate :: inline (body: *Physics_Body_Base, accel: Vector3) {
    if world.step_state != .PAUSED {
        body.linear_velocity += accel * PHYSICS_DELTA_TIME;
    }
}

push :: inline (body: *Physics_Body_Base, force: Vector3) {
    // todo: inv mass and probably that matrix thing I can't remember
    if world.step_state != .PAUSED {
        accel := force * body.inv_mass;
        body.linear_velocity += accel * PHYSICS_DELTA_TIME;
    }
}

get_flags :: inline (body: *Physics_Body_Base) -> Physics_Body_Flags {
    return world.body_data.flags[get_index(body)];
}

set_flags :: inline (body: *Physics_Body_Base, flags: Physics_Body_Flags) {
    world.body_data.flags[get_index(body)] = flags;
}

add_flags :: inline (body: *Physics_Body_Base, flags: Physics_Body_Flags) {
    world.body_data.flags[get_index(body)] |= flags;
}

remove_flags :: inline (body: *Physics_Body_Base, flags: Physics_Body_Flags) {
    world.body_data.flags[get_index(body)] &= ~flags;
}

can_translate :: inline (body: *Physics_Body_Base) -> bool {
    return (world.body_data.flags[get_index(body)] & .LOCK_TRANSLATION) == 0;
}

can_rotate :: inline (body: *Physics_Body_Base) -> bool {
    ALL_AXES_LOCKED : Physics_Body_Flags : .LOCK_YAW | .LOCK_PITCH | .LOCK_ROLL;
    return (world.body_data.flags[get_index(body)] & ALL_AXES_LOCKED) != ALL_AXES_LOCKED;
}

get_x_axis :: (body: *Physics_Body_Base) -> Vector3 {
    calculate_axes_if_needed(body);
    return body.x_axis;
}

get_y_axis :: (body: *Physics_Body_Base) -> Vector3 {
    calculate_axes_if_needed(body);
    return body.y_axis;
}

get_z_axis :: (body: *Physics_Body_Base) -> Vector3 {
    calculate_axes_if_needed(body);
    return body.z_axis;
}

#scope_module

calculate_axes_if_needed :: inline (body: *Physics_Body_Base) {
    flags := get_flags(body);
    if (flags & .CALCULATED_AXES) == 0 {
        calculate_axes(body, true);
    }
}

calculate_axes :: (body: *Physics_Body_Base) {
    body.x_axis = get_right_direction(body.next_orientation);
    body.y_axis = get_fore_direction(body.next_orientation);
    body.z_axis = normalize(cross(body.x_axis, body.y_axis));

    flags := get_flags(body) | .CALCULATED_AXES;
    if abs(body.z_axis.x) < VERY_SMALL_NUMBER && abs(body.z_axis.y) < VERY_SMALL_NUMBER && abs(body.z_axis.z - 1) <= VERY_SMALL_NUMBER {
        flags |= .UPRIGHT;
    } else {
        flags &= ~.UPRIGHT;
    }
    set_flags(body, flags);
}

get_index :: inline (body: *Physics_Body_Base) -> int {
    return cast(*Physics_Body_Internal) body - world.body_data.bodies.data;
}

// todo: maybe this is making a bad assumption, but tbh it's pretty reasonable
get_null_entity_id :: () -> user_types.entity_id_type {
    tinfo :: #run type_info(user_types.entity_id_type);

    #if tinfo.type == .INTEGER || tinfo.type == .FLOAT {
        return 0;
    } else #if tinfo.type == .STRUCT {
        return {};
    } else #if tinfo.type == .POINTER {
        return null;
    } else {
        #run log("invalid id type. must be a number, struct or pointer");
        #assert(false);
    }
}

is_data_from_template :: (data: *u8) -> bool {
    using world;
    shared_byte_diff := data - cast(*u8) body_templates.values.data;
    shared_byte_end  := size_of(type_of(body_templates.values[0])) * body_templates.values.count;
    return shared_byte_diff >= 0 && shared_byte_diff < shared_byte_end;
}

#scope_module


// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
