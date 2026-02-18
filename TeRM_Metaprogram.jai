// -- sections --
// Misc Metaprogramming
// Enumarray

// -----------------------------------------------------------------------------------
// -------------------------------------------------------------- Misc Metaprogramming

code_string :: ($code: Code) -> string #expand {
    builder: String_Builder;
    assert(Program_Print.print_expression(*builder, Compiler.compiler_get_nodes(code)));
    return builder_to_string(*builder);
}

type_has_tag :: (T: Type, tag: Type_Info_Tag) -> bool {
    info := T.(*Type_Info);
    return info.type == tag;
}

align_of :: inline ($T: Type) -> u8 {
    return align_of(T.(*Type_Info));
}

align_of_element_type :: inline ($T: Type) -> u8 {
    info := T.(*Type_Info);
    assert(info.type == .ARRAY);
    array_info := T.(*Type_Info_Array);
    return type_alignment(info.element_type);
}

struct_alignment :: (info: *Type_Info) -> u8 {
    assert(info.type == .STRUCT);
    struct_info := info.(*Type_Info_Struct);
    max_align : u8 = 1;
    for struct_info.members {
        max_align = max(max_align, align_of(xx it.type));
    }
    return max_align;
}

align_of :: inline (info: *Type_Info) -> u8 {
    t := info.type;
    if t == .INTEGER    then return xx info.runtime_size;
    if t == .FLOAT      then return xx info.runtime_size; 
    if t == .POINTER    then return xx info.runtime_size;
    if t == .PROCEDURE  then return xx info.runtime_size;
    if t == .ENUM       then return xx info.runtime_size;
    if t == .BOOL       then return xx info.runtime_size;
    if t == .STRING     then return 8;
    if t == .STRUCT     then return struct_alignment(info);
    if t == .ARRAY      then return 8;
    return 1;
}

// -----------------------------------------------------------------------------------
// ------------------------------------------------------------------------- Enumarray

// for generating an enum and array parallel to each other. I really don't like maintaining order between the enum and the array.
//
// usage:
//
// Some_Struct :: struct { a: int; };
//
// EXAMPLE_CREATE_INFOS :: EnumArray_Create_Info.[
//      "ENUM_VALUE_1", .{
//          a=1
//      },
//      "ENUM_VALUE_2", .{
//          a=500
//      }
// ];
// 
// #insert #run generate_parallel_enum_and_array(..EXAMPLE_CREATE_INFOS, "Some_Enum", u8, "Some_Structs", Some_Struct, true);
//
// this will generate...
//
// Some_Enum :: { ENUM_VALUE_1; ENUM_VALUE_2; }  
// Some_Structs :: Some_Struct.[.{a=1}, .{a=500}];
// 

Enumarray_Create_Info :: struct {
    name: string;
    props: Code;
}

generate_parallel_enum_and_array :: ($create_infos: ..Enumarray_Create_Info, enum_name: string, $enum_backing_type: Type, array_name: string, $struct_type: Type, array_is_constant: bool) -> string {
    builder: String_Builder;
    print_to_builder(*builder, "% :: enum % {\n", enum_name, enum_backing_type);
    for create_infos {
        print_to_builder(*builder, "\t%;\n", it.name);
    }
    print_to_builder(*builder, "}\n\n");

    assignment_operator := ifx array_is_constant then "::" else ":=";
    print_to_builder(*builder, "% % %.[\n", array_name, assignment_operator, struct_type);

    for create_infos {
        code_str := code_string(it.props);
        for *c : code_str {
            if c.* == #char ";" {
                c.* = #char " ";
            }
            if c.* == #char "\n" {
                c.* = #char " ";
            }
        }
        print_to_builder(*builder, "\t%,\n", code_str);
    }
    print_to_builder(*builder, "];");

    return builder_to_string(*builder);
}

#scope_file

S64_MAX :: 0x7fff_ffff_ffff_ffff;

Compiler :: #import "Compiler";
Program_Print :: #import "Program_Print";
#import "Basic";

// MIT License
// Copyright (c) 2026 Trace Myers
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
