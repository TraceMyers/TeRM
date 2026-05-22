Physics_Body:: struct {
    linear_velocity: Vector3;
    angular_velocity: Vector3;

    prev_position: Vector3;
    next_position: Vector3;
    prev_orientation: Quaternion;
    next_orientation: Quaternion;
    
    using properties: *Physics_Properties;
}

Physics_Body_Flags :: enum_flags u32 {
    LOCK_TRANSLATION;
    LOCK_YAW;
    LOCK_PITCH;
    LOCK_ROLL;
    UPRIGHT;
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
}

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
    body_data.entity_ids[i]         = entity_id;

    return *body_data.bodies[i];
}

// if the body that was destroyed displaced another body, the entity pointers to
// bodies (if you are doing things that way) will now be invalid. 
destroy_physics_body :: (body: *Physics_Body) -> need_repoint: bool, id_to_repoint: user_types.entity_id_type {
    using world;

    need_repoint: bool;
    id_to_repoint := get_null_entity_id();
    
    body_index := get_index(body);
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
    _, success := table_set(*body_templates, name, template, .ONLY_ADD);
    // todo: probably should make it so the tables have hash collision resolution...
    assert(success, "table failed to add template % either because of a hash collision or because a template has already been added under that name", name);
    #if DEBUG_INVALIDATED_TEMPLATE_PROPERTIES {
        array_add(*debug_template_properties, template.properties);
    }
}

get_physics_body_template :: (name: string) -> *Physics_Body_Template {
    return table_get(*world.body_templates, name);
}

get_flags :: inline (body: *Physics_Body) -> Physics_Body_Flags {
    return world.body_data.flags[get_index(body)];
}

set_flags :: inline (body: *Physics_Body, flags: Physics_Body_Flags) {
    world.body_data.flags[get_index(body)] = flags;
}

add_flags :: inline (body: *Physics_Body, flags: Physics_Body_Flags) {
    world.body_data.flags[get_index(body)] |= flags;
}

remove_flags :: inline (body: *Physics_Body, flags: Physics_Body_Flags) {
    world.body_data.flags[get_index(body)] &= ~flags;
}

can_translate :: inline (body: *Physics_Body) -> bool {
    return (world.body_data.flags[get_index(body)] & .LOCK_TRANSLATION) == 0;
}

can_rotate :: inline (body: *Physics_Body) -> bool {
    ALL_AXES_LOCKED : Physics_Body_Flags : .LOCK_YAW | .LOCK_PITCH | .LOCK_ROLL;
    return (world.body_data.flags[get_index(body)] & ALL_AXES_LOCKED) != ALL_AXES_LOCKED;
}

#scope_module

get_index :: inline (body: *Physics_Body) -> int {
    return body - world.body_data.bodies.data;
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

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
