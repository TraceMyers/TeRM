#module_parameters()(importer: $I/interface Type_Importer_Default = Type_Importer_Default) {
    Type_Importer_Default :: struct {
        component_declarations :: *void.[];
        component_decl_type    :: void;
        uppercase_enum_names   :: false;
    }
};

// for telling the module where your entity component storage is.
// e.g. context.entity_component_arrays = entity_component_storage;
#add_context entity_component_arrays: [][..]int;

// optional convenience string generator. #insert #run wherever you want your entity component storage.
generate_entity_component_storage_declaration :: (name := "entity_component_storage") -> string {
    return tprint("%: [%][..]int;", name, importer.component_declarations.count);
}

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


#load "entity.jai";
#load "component.jai";

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

#scope_module

Component_Declaration :: importer.component_decl_type;

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
