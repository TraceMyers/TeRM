// -----------------------------------------------------------------------------------
// ---------------------------------------------------------------------- :basic query

to_type :: inline (name: Component_Name) -> Type {
    return component_to_type[name.(int)];
}

is_component_index_valid :: (index: $T) -> bool {
    #if #run (cast(*Type_Info_Integer) T).signed {
        return index >= 0;
    } else {
        return index != #run max_value(T);
    }
}

invalidate_component_index :: (index: *$T) {
    #if #run (cast(*Type_Info_Integer) T).signed {
        index.* = -1;
    } else {
        index.* = #run max_value(T);
    }
}

// -----------------------------------------------------------------------------------
// ----------------------------------------------------------------------- :components

// if you're referring to a component whose name is known at compile time, you can have 
// it typecasted automatically. it's a little more convenient and less error prone to say
// 
// position_array := get_component_array(.POSITION);
//
// ... than it is to say...
//
// position_array := cast(*[..]Vector3) *context.component_arrays[Component_Name.POSITION];
get_component_array :: ($name: Component_Name) -> *[..]extract_type(component_to_type[xx name]).T {
    return cast(*[..]component_to_type[xx name]) *context.entity_component_arrays[name];
}

// -----------------------------------------------------------------------------------
// ------------------------------------------------- :per-entity component interaction

get_component :: (ent: *Entity, $name: Component_Name) -> *extract_type(component_to_type[xx name]).T {
    #if ent.declare_component_pointers {
        return #insert #run tprint("*ent.%;", to_lower(tprint("%", name)));
    } else {
        component_array := cast(*[..]component_to_type[name]) *context.entity_component_arrays[name];
        component_id := #insert #run tprint("*ent.component_id_%;", to_lower(tprint("%", name)));
        if component_id.* != cast,trunc(type_of(component_id.*)) 0xffff_ffff {
            return *(component_array.*)[component_id.*];
        } else return null;
    }
}

has_component :: inline (e: *Entity, name: Component_Name) -> bool {
    return is_set(*e.component_flags, name);
}

// run arbitrary code over all components on an entity
for_each_component :: inline (ent: *Entity, $body: Code) {
    #insert -> string {
        builder: String_Builder;
        for cmp, ci : ent.components {
            print(*builder, 
#string HERE
    {
        component_do_impl(ent, .%, #run code_string(body), %);
    }
HERE,
                cmp, ci
            );
        }
        output := builder_to_string(*builder);
        return output;
    }
}

// run arbitrary code for a given component.
component_do :: (ent: *Entity, $name: Component_Name, $body: Code) #expand {
    component_do_impl(ent, name, #run code_string(body));
}

// -----------------------------------------------------------------------------------

#scope_module

// for a given component, create a space of variables and constants where the
// inserted code can work on the component, the array of the component, the component
// id on the entity, etc.
component_do_impl :: (ent: *Entity, $name: Component_Name, $body: string, $declare_component_index := -1) #expand {
    `component: *component_to_type[name] = null;

    `component_name :: name;
    `component_array := cast(*[..]component_to_type[name]) *context.entity_component_arrays[name];

    #if declare_component_index >= 0 {
        `component_index := declare_component_index;
    }

    #if ent.declare_component_pointers {
        `component_pointer := #insert #run tprint("*ent.%_pointer;", to_lower(tprint("%", name)));
        `component = #insert #run tprint("*ent.%;", to_lower(tprint("%", name)));
        `component_id_value: int = -1;
        `component_id := *component_id_value;
        if `component != null {
            component_id_value = `component - `component_array.data;
        } 
    } else {
        `component_id := #insert #run tprint("*ent.component_id_%;", to_lower(tprint("%", name)));
        if `component_id.* != cast,trunc(type_of(`component_id.*)) 0xffff_ffff {
            `component = *(`component_array.*)[`component_id.*];
        }
    }

    #insert body;
}

generate_entity_system_declarations :: (declarations: ..Component_Declaration) -> allocators: string, enum_def: string, component_to_type_proc_def: string {
    enum_builder: String_Builder;
    to_type_builder: String_Builder;

    print(*enum_builder, "Component_Name :: enum u16 {\n");
    print(*to_type_builder, "component_to_type :: Type.[\n");

    for decl : declarations {
        assert(decl.name != "");
        enum_name := to_upper(decl.name,,temp);
        
        print(*enum_builder, "    %;\n", enum_name);
        print(*to_type_builder, "\t%,\n", decl.data_type);
    }

    print(*enum_builder, "}\n");
    print(*to_type_builder, "];\n");

    allocators := tprint(
#string HERE
entity_component_arrays: [%][..]int;
HERE, declarations.count);
    enum_def   := builder_to_string(*enum_builder);
    to_type    := builder_to_string(*to_type_builder);

    return allocators, enum_def, to_type;
}

// this is used to get the compiler to allow me to define the return type by indexing into a Type.[],
// as in:
// proc :: ($name: Component_Name) -> extract_type(component_to_type[name]).T
// if I don't wrap, compiler complains that you can't index with an enum or that you can't use []
extract_type :: struct ($T: Type) { thing: T; }

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
