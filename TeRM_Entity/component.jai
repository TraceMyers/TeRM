// -----------------------------------------------------------------------------------
// ---------------------------------------------------------------------- :basic query

to_type :: inline (name: Component_Name) -> Type {
    return COMPONENT_TYPES[name.(int)];
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
get_component_array :: ($name: Component_Name) -> *[..]extract_type(importer.component_declarations[xx name]).type {
    return cast(*[..]COMPONENT_TYPES[xx name]) *context.entity_component_arrays[name];
}

// -----------------------------------------------------------------------------------
// ------------------------------------------------- :per-entity component interaction

get_component :: (ent: *Entity, $name: Component_Name) -> *$T 
#modify {
    T = importer.component_declarations[xx name].type;
    return true;
} {
    #if ent.declare_component_pointers {
        return #insert #run tprint("*ent.%;", to_lower(tprint("%", name)));
    } else {
        component_array := cast(*[..]T) *context.entity_component_arrays[name];
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
    `component_type :: #run importer.component_declarations[name].type;
    `component: *component_type = null;

    `component_name :: name;
    `component_array := cast(*[..]`component_type) *context.entity_component_arrays[name];

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

// this is used to get the compiler to allow me to define the return type by indexing into a Type.[],
// as in:
// proc :: ($name: Component_Name) -> extract_type(COMPONENT_TYPES[name]).T
// if I don't wrap, compiler complains that you can't index with an enum or that you can't use []
extract_type :: struct ($decl: Component_Declaration) { type :: decl.type; }

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
