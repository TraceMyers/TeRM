// a component system for entities. see how_to.jai for long form documentation

#module_parameters()(importer: $I/interface Type_Importer_Default = Type_Importer_Default) {
    Type_Importer_Default :: struct {
        component_declarations :: *void.[];
        component_decl_type    :: void;
        uppercase_enum_names   :: false;
    }
};

// for telling the module where your entity component storage is.
// e.g. context.entity_component_arrays = entity_component_storage;
#add_context entity_component_arrays: [][..]u8;
#add_context entity_pointer_arrays:   [][..]_Entity_Pointer;
#add_context entity_array_references: *[..]Entity_Array_Reference;

_Entity_Pointer :: struct {
     array: s32; 
     entity: s32; 
}

Entity_Array_Reference :: struct {
    ref: *[]u8;

    // components information stored two ways: 
    // array for iterating over 
    components: []Component_Name;
    // flags for checking if the entity type has a component
    component_flags: Flag_Array(Component_Name);

    type_stride: int;
    type_sentinel_offset: int;
    type_has_component_pointers: bool;
}

// optional convenience string generator. #insert #run wherever you want your entity component storage.
generate_entity_component_storage_declaration :: (
    components_name := "entity_component_storage",
    pointers_name   := "entity_pointer_storage",
    entities_name   := "entity_storage_references"
) -> string {
    return tprint(
#string HERE
%: [%][..]u8;
%: [%][..]s32;
%: [..]Entity_Array_Reference;
HERE,
        components_name, importer.component_declarations.count,
        pointers_name,   importer.component_declarations.count,
        entities_name
    );
}

// the component enum, generated from your input in the same order
Component_Name :: enum u16 {
    #insert -> string {
        builder: String_Builder;
        for t : importer.component_declarations {
            name := t.name;
            if importer.uppercase_enum_names {
                name = to_upper(name,,temp);
            }
            print(*builder, "\t%;\n", name);
        }
        return builder_to_string(*builder);
    }
}

#load "component.jai";
#load "manage.jai";

#import "Basic";
#import "Atomics";
#import "Basic";
#import "Math";

#import "TeRM/TeRM_String";
#import "TeRM/TeRM_FlagArray";
#import "TeRM/TeRM_Storage";
#import "TeRM/TeRM_LogHelpers";
#import "TeRM/TeRM_Metaprogram";
#import "TeRM/TeRM_Math";
#import "TeRM/TeRM_Allocation";
#import "TeRM/TeRM_Array";

#scope_module

Component_Declaration :: importer.component_decl_type;
