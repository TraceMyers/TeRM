#module_parameters(
    user_types: $I/interface Type_Provider_Default = Type_Provider_Default
) {
    Type_Provider_Default :: struct {
        entity_base_type    :: void;
        entity_enum_type    :: void;
        entity_id_type      :: void;
        entity_to_id_proc   :: void;
        id_to_entity_proc   :: void;
        entity_to_enum_proc :: void;
    }
}

#add_context component_array_pointer_storage: []u8;

Term_Component_Plugin :: struct {
    using #as base: Metaprogram_Plugin;
    entity_type_names: [..]string;
    entity_type_names_lower: [..]string;
    // not used...
    entity_type_enums: [..]string;
    components: [..]Component_Metaprogram_Item;
    uniquely_typed_components: [..]*Component_Metaprogram_Item;
    uniquely_entity_typed_components: [..]*Component_Metaprogram_Item;
    generated_code: bool;
}

Component_Array_Set :: struct($T: Type) {
    items: [..]T;
    ids:   [..]user_types.entity_id_type;
}

get_plugin :: () -> *Metaprogram_Plugin {
    p := New(Term_Component_Plugin);
    p.message = message;
    return p;
}

message :: (p: *Metaprogram_Plugin, message: *Message) {
    plugin := cast(*Term_Component_Plugin) p;

    if plugin.generated_code {
        return;
    }

    if message.kind == .TYPECHECKED {
        m_typechecked := cast(*Message_Typechecked) message;
        for decl_typechecked : m_typechecked.declarations {
            decl := decl_typechecked.expression;

            is_entity_type_struct: bool;
            for decl.notes {
                if it.text == "EntityType" {
                    is_entity_type_struct = true;
                    break;
                }
            }

            if !is_entity_type_struct {
                continue;
            }

            expr := decl.expression;
            assert(expr.kind == .STRUCT);

            code_struct := cast(*Code_Struct) expr;
            entity_type := (cast(*Type) (*code_struct.defined_type)).*;

            entity_type_name := sprint("%", entity_type);

            array_add(*plugin.entity_type_names, entity_type_name);
            array_add(*plugin.entity_type_names_lower, to_lower(entity_type_name));
            array_add(*plugin.entity_type_enums, to_upper(entity_type_name));

            member_stack: [..]string;

            for member : code_struct.block.members {
                recursive_search_for_components(plugin, *member_stack, member);
            }
        }
    } else if message.kind == .PHASE {
        m_phase := cast(*Message_Phase) message;

        if m_phase.phase == .TYPECHECKED_ALL_WE_CAN {
            builder: String_Builder;

            add_build_string(tprint("ENTITY_COMPONENT_COUNT :: %;", plugin.components.count), message.workspace);

            array_struct_type, init_proc := generate_component_array_def_and_init_proc(plugin);

            add_build_string(array_struct_type, message.workspace);
            add_build_string(init_proc, message.workspace);

            handlers := generate_component_handler_procedures(plugin);

            add_build_string(handlers, message.workspace);

            plugin.generated_code = true;
        }
    }
}

get_pointer_array_set :: inline (index: int, $T: Type) -> *Component_Array_Set(T) {
    pointer_storage := cast,force([]*Component_Array_Set(T)) context.component_array_pointer_storage;
    return pointer_storage[index];
}

create_component :: (
    entity: *$T, 
    components: *[..]$component_type, 
    ids: *[..]user_types.entity_id_type, 
    $path_to_component: string, 
) -> *component_type {
    assert(components.count == ids.count);

    old_array_pointer := components.data;
    #insert #run tprint("entity.% = array_add(components);", path_to_component);

    if old_array_pointer != components.data {
        fix_pointers(T, components, ids, path_to_component, user_types.id_to_entity_proc);
    }

    array_add(ids, inline user_types.entity_to_id_proc(entity));
    #insert #run tprint("return entity.%;", path_to_component);
}

destroy_component :: (
    entity: *$T, 
    components: *[..]$component_type, 
    ids: *[..]user_types.entity_id_type, 
    realloc_if_using_less_than_proportion := 0.35,
    remove_free_proportion := 0.75,
    minimum_allocated := 8,
    $path_to_component: string, 
) {
    assert(components.count == ids.count);

    #insert #run tprint("component := entity.%;", path_to_component);
    #insert #run tprint("entity.% = null;", path_to_component);

    component_index := component - components.data;
    entity_id := inline user_types.entity_to_id_proc(entity);
    assert(ids.*[component_index] == entity_id);
    
    if component_index != components.count - 1 {
        final_entity := cast(*T) inline user_types.id_to_entity_proc(ids.*[components.count-1]);
        components.*[component_index] = components.*[components.count-1];
        ids.*[component_index]        = ids.*[components.count-1];
        #insert #run tprint("final_entity.% = *components.*[component_index];", path_to_component);
    }

    components.count -= 1;
    ids.count        -= 1;

    old_array_pointer := components.data;
    array_shrink_if_small_enough(components, realloc_if_using_less_than_proportion, remove_free_proportion, minimum_allocated);
    array_shrink_if_small_enough(ids, realloc_if_using_less_than_proportion, remove_free_proportion, minimum_allocated);

    if old_array_pointer != components.data {
        fix_pointers(T, components, ids, path_to_component, user_types.id_to_entity_proc); 
    }
}

component_module_entity_base_type :: user_types.entity_base_type;

Component_Metaprogram_Item :: struct {
    entity_type_name: string;
    entity_type_name_lower: string;
    field_name: string;
    type: Type;
    type_name: string;
    lower_type_name: string;
    struct_path: string;
    entity_enum: string;
    array_pointer_index: int;
}

// dummy procedures if the entity type has no components
create_components :: (ptr: *void) {}
destroy_components :: (ptr: *void) {}

#scope_file

generate_component_handler_procedures :: (plugin: *Term_Component_Plugin) -> string {
    builder: String_Builder;

    items_by_type: [..][..]*Component_Metaprogram_Item;

    for *plugin.components {
        cmp := it;

        found_match: bool;
        for *list : items_by_type {
            if list.*[0].entity_type_name == cmp.entity_type_name {
                array_add(list, cmp);
                found_match = true;
                break;
            }
        }
        if !found_match {
            array_add(*items_by_type);
            array_add(*items_by_type[items_by_type.count-1], cmp);
        }

        print(*builder,
#string HERE
create_%_% :: inline (entity: *%) {
    arrays := get_pointer_array_set(%, %);
    create_component(entity, *arrays.items, *arrays.ids, path_to_component="%");
}

destroy_%_% :: inline (entity: *%) {
    arrays := get_pointer_array_set(%, %);
    destroy_component(entity, *arrays.items, *arrays.ids, path_to_component="%");
}

HERE,
            it.entity_type_name_lower, it.field_name, it.entity_type_name,
            it.array_pointer_index, it.type_name,
            it.struct_path, 
            it.entity_type_name_lower, it.field_name, it.entity_type_name,
            it.array_pointer_index, it.type_name,
            it.struct_path
        );
    }

    for list : items_by_type {
        print(*builder, "create_components :: (entity: *%) {\n", list[0].entity_type_name);
        for item : list {
            print(*builder, "    create_%_%(entity);\n", item.entity_type_name_lower, item.field_name);
        }
        print(*builder, "}\n\n");
        print(*builder, "destroy_components :: (entity: *%) {\n", list[0].entity_type_name);
        for item : list {
            print(*builder, "    destroy_%_%(entity);\n", item.entity_type_name_lower, item.field_name);
        }
        print(*builder, "}\n\n");
    }

    return builder_to_string(*builder);
}

generate_component_array_def_and_init_proc :: (plugin: *Term_Component_Plugin) -> struct_def: string, init_proc: string {

    for *comp : plugin.components {
        already_at_index := -1;
        for plugin.uniquely_typed_components {
            if it.type_name == comp.type_name {
                already_at_index = it_index;
                break;
            }
        }
        if already_at_index == -1 {
            comp.array_pointer_index = plugin.uniquely_typed_components.count;
            array_add(*plugin.uniquely_typed_components, comp);
        } else {
            comp.array_pointer_index = already_at_index;
        }
    }

    proc_builder: String_Builder;
    print(*proc_builder, "initialize_component_array_pointers :: (manifest: *Component_Array_Manifest) {\n");
    print(*proc_builder,
#string HERE
    byte_storage := *context.component_array_pointer_storage;
    need_size := ENTITY_COMPONENT_COUNT * size_of(*void);

    if byte_storage.count < need_size {
        if byte_storage.count > 0 {
            array_free(byte_storage.*);
        }
        byte_storage.* = make_static_array(u8, need_size);
    }

    pointer_storage := cast,force(*[]*void) byte_storage;
    i := 0;
HERE);
    
    array_builder: String_Builder;
    print(*array_builder, "Component_Array_Manifest :: struct {\n");

    for plugin.uniquely_typed_components {
        print(*array_builder, "    %_components: Component_Array_Set(%);\n", it.lower_type_name, it.type_name);
        print(*proc_builder,  "    pointer_storage.*[i] = *manifest.%_components; i += 1;\n", it.lower_type_name);
    }

    print(*array_builder, "}\n");
    print(*proc_builder, "}\n");

    return builder_to_string(*array_builder), builder_to_string(*proc_builder);
}

recursive_search_for_components :: (plugin: *Term_Component_Plugin, stack: *[..]string, member: *Code_Scope_Entry) {
    // too deep, take too long.. or not the right thing
    if stack.count > 8 || member.kind != .DECLARATION {
        return;
    }
    
    decl := cast(*Code_Declaration) member;

    if decl.type.type == .POINTER {
        for note : decl.notes {
            if note.text == "AutoComponent" {
                type := (cast(*Type) (*decl.type)).*;
                pointer_to_type := (cast(*Type) *((cast(*Type_Info_Pointer) decl.type).pointer_to)).*;
                type_name := tprint("%", pointer_to_type);
                lower_type_name := to_lower(type_name,, temp);

                path: String_Builder;
                for stack.* {
                    print(*path, "%.", it);
                }
                print(*path, "%", decl.name);
                item := Component_Metaprogram_Item.{plugin.entity_type_names[plugin.entity_type_names.count-1], plugin.entity_type_names_lower[plugin.entity_type_names_lower.count-1], decl.name, type, type_name, lower_type_name, builder_to_string(*path), plugin.entity_type_enums[plugin.entity_type_enums.count-1], 0};
                array_add(*plugin.components, item);
                break;
            }
        }
    } else if decl.type.type == .STRUCT {
        inst := decl.type_inst;

        if inst == null || inst.type_valued_expression == null || inst.type_valued_expression.kind != .IDENT {
            return;
        }

        type_ident := cast(*Code_Ident) inst.type_valued_expression;
        type_decl  := type_ident.resolved_declaration;

        if type_decl.expression == null || type_decl.expression.kind != .STRUCT {
            return;
        }

        code_struct := cast(*Code_Struct) type_decl.expression;

        array_add(stack, decl.name);
        for member : code_struct.block.members {
            recursive_search_for_components(plugin, stack, member);
        }
        stack.count -= 1;
    }
}

fix_pointers :: (
    $entity_type: Type,
    components: *[..]$component_type,
    ids: *[..]$id_type,
    $path_to_component: string,
    $id_to_entity: (id_type) -> *user_types.entity_base_type,
) {
    for id : ids.* {
        entity := cast(*entity_type) inline id_to_entity(id);
        #insert #run tprint("entity.% = *components.*[it_index];", path_to_component);
    }
}

#import "TeRM/TeRM_Array";
#import "TeRM/TeRM_String";
#import "Basic";
#import "Compiler";
