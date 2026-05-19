// todo: have a build binary step
// todo: find all of the required headers and package them in the module

debug_dump := true;

unwrap_typedefs := string.[
    "uint8",
    "uint16",
    "uint32",
    "uint64",
    "Real",
    "Real3",
    "RVec3",
    "RVec3Arg",
    "RMat44",
    "RMat44Arg",
    "Vec3Arg",
    "DVec3Arg",
    "Vec4Arg",
    "UVec4Arg",
    "BVec16Arg",
    "QuatArg",
    "Mat44Arg",
    "DMat44Arg",
];

replace_typedefs :: Typedef_Replacement.[
    {"Vec2",   CType.{hardcoded_jai_string="Vector2"}},
    {"Vec3",   CType.{hardcoded_jai_string="Vector3"}},
    {"Float3",   CType.{hardcoded_jai_string="Vector3"}},
    {"Real3",   CType.{hardcoded_jai_string="Vector3"}},
    {"RVec3",   CType.{hardcoded_jai_string="Vector3"}},
    {"RVec3Arg",   CType.{hardcoded_jai_string="Vector3"}},
    {"Double3",   CType.{hardcoded_jai_string="Vector3d"}},
    {"DVec3",   CType.{hardcoded_jai_string="Vector3d"}},
    {"Vec4",   CType.{hardcoded_jai_string="Vector4"}},
    {"Float4",   CType.{hardcoded_jai_string="Vector4"}},
    {"RVec4",   CType.{hardcoded_jai_string="Vector4"}},
    {"RVec4Arg",   CType.{hardcoded_jai_string="Vector4"}},
    {"DVec4",  CType.{hardcoded_jai_string="Vector4d"}},
    {"UVec4",  CType.{hardcoded_jai_string="Vector4u"}},
    {"UVec4Arg",  CType.{hardcoded_jai_string="Vector4u"}},
    {"Mat44",  CType.{hardcoded_jai_string="Matrix4"}},
    {"RMat44",  CType.{hardcoded_jai_string="Matrix4"}},
    {"RMat44Arg",  CType.{hardcoded_jai_string="Matrix4"}},
    {"DMat44", CType.{hardcoded_jai_string="Matrix4d"}},
    {"DMat44Arg", CType.{hardcoded_jai_string="Matrix4d"}},
    {"Quat",   CType.{hardcoded_jai_string="Quaternion"}},
    {"QuatArg",   CType.{hardcoded_jai_string="Quaternion"}},
];

#run {
    set_build_options_dc({do_output=false});

    if debug_dump {
        dump_file = file_open("dump.txt", for_writing=true);
    }
    defer if debug_dump then file_close(*dump_file);

    system_filename: string;
    using options: Generate_Bindings_Options;

    log_stripped_declarations = false;
    // omit_global_declarations = true;

    #if OS == .WINDOWS {
        array_add(*library_search_paths, "windows");
        system_filename = "windows.jai";
    }

    array_add(*include_paths, "src");

    array_add(*system_include_paths, "C:/Program Files (x86)/Windows Kits/10/Include/10.0.26100.0/shared");
    array_add(*system_include_paths, "C:/Program Files (x86)/Windows Kits/10/Include/10.0.26100.0/ucrt");
    array_add(*system_include_paths, "C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/14.44.35207/include");

    array_add(*libraries, {filename="Jolt_Release"});
    array_add(*source_files, "Jolt/Jolt.h"); 
    array_add(*source_files, "Jolt/Physics/PhysicsSystem.h"); 
    array_add(*extra_clang_arguments, 
        "-x",  // set language..
        "c++", // .. to c++
        "-D_CRT_SECURE_NO_WARNINGS",
        "-DWIN32_LEAN_AND_MEAN", // smaller binary? faster build process
        "--std=c++17",
    );
    array_add(*flatten_namespaces, "JPH");

    visitor = jolt_visitor;

    if generate_bindings(options, system_filename) {
        log("succesfully generated bindings");
    } else {
        log("failed to generate bindings");
    }
}

jolt_visitor :: (decl: *Declaration, parent_decl: *Declaration) -> Declaration_Visit_Result {
    if decl.kind == .TYPEDEF {
        def := cast(*Typedef) decl;
        for unwrap_typedefs {
            if def.name == it {
                def.unwrap = true;
                decl.decl_flags |= .OMIT_FROM_OUTPUT;
                return .STOP;
            }
        }
        for *replace_typedefs {
            if def.name == it.old_type_name {
                decl.decl_flags |= .OMIT_FROM_OUTPUT;
                return .STOP;
            }
        }
    } else if decl.kind == .STRUCT {
        for *replace_typedefs {
            if decl.name == it.old_type_name {
                decl.decl_flags |= .OMIT_FROM_OUTPUT;
                return .STOP;
            }
        }
    } else if decl.kind == .FUNCTION {
        function_type := decl.type.type_of_function;
        if starts_with(decl.name, "operator") {
            decl.decl_flags |= .OMIT_FROM_OUTPUT;
            return .STOP;
        }
        for arg : function_type.arguments {
            if arg.type != null {
                if arg.type.type_of_typedef != null {
                    // log("typedef name: %", arg.type.type_of_typedef.name);
                    for replace_typedefs {
                        if arg.type.type_of_typedef.name == it.old_type_name {
                            arg.type = *it.replacement_type;
                            break;
                        }
                    }
                }
            }
        }
    }

    return .RECURSE;
}

debug_write :: (str: string, args: ..Any) {
    if debug_dump {
        out_str := tprint(str, ..args);
        file_write(*dump_file, out_str);
    }
}

dump_file: File;

Typedef_Replacement :: struct {
    old_type_name: string;
    replacement_type: CType;
}

#import "Basic";
#import "Compiler";
#import "Bindings_Generator";
#import "File";
#import "String";
