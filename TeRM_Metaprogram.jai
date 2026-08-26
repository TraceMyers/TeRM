// -- sections --
// Misc Metaprogramming
// Enumarray
// Offset_Buffer

// -----------------------------------------------------------------------------------
// -------------------------------------------------------------- Misc Metaprogramming

code_string :: ($code: Code) -> string #expand {
    builder: String_Builder;
    assert(Program_Print.print_expression(*builder, compiler_get_nodes(code)));
    return builder_to_string(*builder);
}

type_has_tag :: (T: Type, tag: Type_Info_Tag) -> bool {
    info := T.(*Type_Info);
    return info.type == tag;
}

align_of :: inline ($T: Type) -> int {
    return align_of(T.(*Type_Info));
}

align_of_element_type :: inline ($T: Type) -> int {
    info := T.(*Type_Info);
    assert(info.type == .ARRAY);
    array_info := T.(*Type_Info_Array);
    return type_alignment(info.element_type);
}

struct_alignment :: (info: *Type_Info, align_of_depth := 0, max_depth := 10) -> int {
    assert(info.type == .STRUCT);

    if align_of_depth >= max_depth {
        return 8;
    }

    struct_info := info.(*Type_Info_Struct);
    max_align: int = 1;

    for struct_info.members {
        max_align = max(max_align, align_of(xx it.type, align_of_depth, max_depth));
    }

    return max_align;
}

align_of :: inline (info: *Type_Info, start_depth := 0, max_depth := 10) -> int {
    use_info := info;

    i := start_depth;
    while i < max_depth {
        defer i += 1;
        if use_info.type == {
        case .INTEGER;
            return info.runtime_size;
        case .FLOAT;
            return info.runtime_size; 
        case .POINTER;
            return info.runtime_size;
        case .PROCEDURE;
            return info.runtime_size;
        case .ENUM;
            return info.runtime_size;
        case .BOOL;
            return info.runtime_size;
        case .STRING;
            return 8;
        case .STRUCT;
            return struct_alignment(use_info, i, max_depth);
        case .ARRAY;
            tinfo_array := cast(*Type_Info_Array) info;
            use_info = tinfo_array.element_type;
        case;
            break;
        }
    }

    return 8;
}

get_struct_field :: (s: *$struct_type, $field_type: Type) -> *field_type {
    field_offset : int : #run -> int {
        tinfo := cast(*Type_Info) struct_type;
        assert(tinfo.type == .STRUCT);
        tinfo_struct := cast(*Type_Info_Struct) tinfo;

        for member : tinfo_struct.members {
            if ((*member.type).(*Type)).* == field_type {
                return member.offset_in_bytes;
            }
        }
        return -1;
    }

    #if field_offset == -1 {
        return null;
    } else {
        field_ptr := cast(*field_type) ((cast(*u8) s) + field_offset);
        return field_ptr;
    }
}

type_2_is_pointer_to_type_1 :: (T1: Type, T2: Type) -> bool {
    tinfo := cast(*Type_Info) T2;
    if tinfo.type != .POINTER then return false;
    tinfo_ptr := cast(*Type_Info_Pointer) tinfo;
    return tinfo_ptr.pointer_to == cast(*Type_Info) T1;
}


Struct_Visit_Item :: struct {
    data: *u8;
    info: *Type_Info;
    member: *Type_Info_Struct_Member;
    iter_index: int;
    iter_index_matching_options: int;
}

Struct_Visit :: struct {
    using item: Struct_Visit_Item;
    parent_stack: []Struct_Visit_Item;
    path: *String_Stack;
}

Struct_Visitor_Command :: enum {
    CONTINUE;
    PUSH_MEMBER_OR_CONTINUE;
    POP_PARENT;
    EXIT;
}

Struct_Visitor :: #type (visit_data: *Struct_Visit, user_data: *void) -> command: Struct_Visitor_Command;

Struct_Visit_Options :: struct {
    visit_pointers      := true;
    visit_only_non_null_pointers := true;
    visit_procedures    := false;
    visit_constants     := false;
    visit_overlays      := false;
}

struct_visit :: (struct_data: *$T, user_data: *void, visitor: Struct_Visitor, options: Struct_Visit_Options = {}) {
    parent_stack: [..]Struct_Visit_Item;
    parent_stack.allocator = temp;
    array_reserve(*parent_stack, 16);

    cur_parent_tinfo := cast(*Type_Info_Struct) type_info(T);
    assert(cur_parent_tinfo.type == .STRUCT);
    array_add(*parent_stack, {xx struct_data, cur_parent_tinfo, null, 0, 0});
    
    struct_visit_impl(*parent_stack, user_data, visitor, options);
}

#scope_file

// reducing code bloat by doing this part without generics
struct_visit_impl :: no_inline (parent_stack: *[..]Struct_Visit_Item, user_data: *void, visitor: Struct_Visitor, options: Struct_Visit_Options) {

    path: String_Stack;
    init(*path);
    defer free_path(*path);

    while parent_stack.count > 0 {

        cur_parent := *parent_stack.*[parent_stack.count-1];
        cur_parent_info := cast(*Type_Info_Struct) cur_parent.info;
        command: Struct_Visitor_Command = .CONTINUE;

        while cur_parent.iter_index < cur_parent_info.members.count {
            defer cur_parent.iter_index += 1;
            member := *cur_parent_info.members[cur_parent.iter_index];

            if !options.visit_constants  && (member.flags & .CONSTANT) != 0 {
                continue;
            }
            if !options.visit_overlays   && (member.flags & .OVERLAY) != 0 {
                continue;
            }
            if !options.visit_procedures && member.type.type == .PROCEDURE {
                continue; 
            }

            use_info := member.type;
            member_data := cur_parent.data + member.offset_in_bytes;

            if use_info.type == .POINTER {
                if !options.visit_pointers {
                    continue;
                }
                use_info    = (cast(*Type_Info_Pointer) use_info).pointer_to;
                member_data = (cast(**u8) member_data).*;

                if options.visit_only_non_null_pointers && member_data == null {
                    continue;
                }
            }

            defer cur_parent.iter_index_matching_options += 1;

            {
                if path.sizes.count == 0 {
                    push(*path, member.name);
                } else {
                    push(*path, ".%", member.name);
                }
                defer pop(*path);

                visit_data := Struct_Visit.{
                    item = {xx member_data, use_info, member, 0, 0},
                    parent_stack = parent_stack.*,
                    path = *path
                };

                command = visitor(*visit_data, user_data);
            }

            if command == {
            case .PUSH_MEMBER_OR_CONTINUE;
                if use_info.type == .STRUCT && member_data != null {
                    array_add(parent_stack, {member_data, use_info, member, 0, 0});
                    push(*path, ".%", member.name);
                    break;
                }
            case .POP_PARENT;
                break;
            case .EXIT;
                return;
            }
        }

        if command == .POP_PARENT || cur_parent.iter_index == cur_parent_info.members.count {
            parent_stack.count -= 1;
            if path.sizes.count > 0 {
                pop(*path);
            } else {
                assert(parent_stack.count == 0);
            }
        }
    }
}

#scope_export

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

generate_parallel_enum_and_array :: ($create_infos: ..Enumarray_Create_Info, enum_name: string, $enum_backing_type: Type, array_name: string, $array_item_type: Type, array_is_constant: bool) -> string {
    return generate_parallel_enum_and_array(..create_infos, enum_name, enum_backing_type, array_name, #run tprint("%", array_item_type), array_is_constant);
}

generate_parallel_enum_and_array :: ($create_infos: ..Enumarray_Create_Info, enum_name: string, $enum_backing_type: Type, array_name: string, $array_item_type_name: string, array_is_constant: bool) -> string {
    builder: String_Builder;
    print_to_builder(*builder, "% :: enum % {\n", enum_name, enum_backing_type);
    for create_infos {
        print_to_builder(*builder, "\t%;\n", it.name);
    }
    print_to_builder(*builder, "}\n\n");

    assignment_operator := ifx array_is_constant then "::" else ":=";
    print_to_builder(*builder, "% % %.[\n", array_name, assignment_operator, array_item_type_name);

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
        if it_index == create_infos.count - 1 {
            print_to_builder(*builder, "\t%\n", code_str);
        } else {
            print_to_builder(*builder, "\t%,\n", code_str);
        }
    }
    print_to_builder(*builder, "];");
    
    out_str := builder_to_string(*builder);
    return out_str;
}


// -----------------------------------------------------------------------------------
// --------------------------------------------------------------------- Offset_Buffer
// for using a single buffer that can resize over time without making pointers invalid,
// by saving offsets to pointer locations. assign() allows for assigning values
// deep into an offset-based structure (e.g. yourthing.array[0].children[2].name)
// by first creating the allocation for the new thing if needed (string, array), 
// traversing the ast and creating temp pointer-based locals, and assigning the value 
// to the assign location if called for. then, when all resizing is done, you can 
// convert all offsets to real pointers.
//
// this is really only useful if you can't just make/have a bigger buffer than you need and 
// allocate into that, then when finished, copy into a new, smaller buffer. so, maybe if you're space
// constrained.

// example usage:
offset_buffer_example :: () {
    Thing       :: struct { name: string; }
    Some_Struct :: struct { things: []Thing; allocations: string; allocator: Allocator; }

    offbuff: Offset_Buffer("s");

    s: Some_Struct;

    // allocate an array of strings at s.things. s.things's data pointer is not a real pointer, but an 
    // offset into offbuff's resize array.
    assign(*offbuff, s.things, new_offset_array(Thing, 10));

    // copies "hey there" into the single buffer.
    // the string at s.things[0].name also has an offset into that buffer for its 'data' field.
    assign(*offbuff, s.things[0].name, "a good name for a thing");

    // will log "a good name for a thing". can use get() while pointers are still offsets.
    log("first name: %", get(*offbuff, s.things[0].name)); 

    // convert the offsets to pointers, so you don't have to use get() anymore.
    s.things = convert_to_pointer_array(*offbuff, s.things);
    for *thing : s.things {
        thing.name = convert_to_pointer_string(*offbuff, thing.name);
    }

    // s owns the allocation. (maybe shrink right before?)
    s.allocations = string.{offbuff.buffer.count, offbuff.buffer.data};
    s.allocator = offbuff.buffer.allocator;
    offbuff = {};

    // go do stuff...

    // come back later and just free once for all allocations
    free(s.allocations.data);
    s = {};
}

Offset_Buffer :: struct($begin_hosting_ident_name: string, $max_traverse_ast_steps := 16) {
    buffer: [..]u8;
}

assign :: (offset: *Offset_Buffer, $assign_location: Code, value: $T) #expand {
    #insert -> string {
        value_tinfo := cast(*Type_Info) T;
        // if the value is a string or array type, it it needs to be allocated first so the traversal
        // doesn't end up with invalid pointers
        if value_tinfo.type == {
        case .STRING;
            return tprint("\tallocation_for_value := copy_to_offset_string(offset, value);\n");
        case .ARRAY;
            return tprint("\tallocation_for_value := make_offset_array(offset, value);\n");
        }
        return "";
    }

    #insert #run,stallable generate_offset_buffer_pointer(type_of(offset), assign_location, T);

    #insert -> string {
        value_tinfo := cast(*Type_Info) T;
        // if the value is a string or array type, it it needs to be allocated first so the traversal
        // doesn't end up with invalid pointers
        if value_tinfo.type == {
        case .STRING;
            return tprint("\toffset_buffer_pointer.* = allocation_for_value;\n");
        case .ARRAY;
            return tprint("\toffset_buffer_pointer.* = allocation_for_value;\n");
        }
        return "offset_buffer_ptr.* = xx value;";
    }
}

// traverse the code ast in 'value_of_location' and find its place in the offset buffer,
// returning the value. note that if T is a struct and T has offset pointer members,
// trying to access/log those pointers will crash unless you convert them to real pointers.
get :: (offset: *Offset_Buffer, $value_of_location: Code) -> $T #expand 
#modify {
    root := compiler_get_nodes(value_of_location);
    assert(root.kind == .BINARY_OPERATOR);
    bin_op := cast(*Code_Binary_Operator) root;

    if bin_op.operator_type == .ARRAY_SUBSCRIPT {
        assert(bin_op.left.kind == .BINARY_OPERATOR, "left ident kind: %", bin_op.left.kind);
        left_bin_op := cast(*Code_Binary_Operator) bin_op.left;
        assert(left_bin_op.right.kind == .IDENT);

        right_ident := cast(*Code_Ident) left_bin_op.right;
        if right_ident.type.type == {
        case .STRING;
            T = u8;
            return true;
        case .ARRAY;
            array_tinfo := cast(*Type_Info_Array) right_ident.type;
            T = (cast(*Type) *array_tinfo.element_type).*;
            return true;
        case;
            assert(false);
        }
    } else if bin_op.operator_type == #char "." {
        assert(bin_op.right.kind == .IDENT);
        right_ident := cast(*Code_Ident) bin_op.right;
        T = (cast(*Type) *right_ident.type).*;
        return true;
    }

    T = void;
    return false;
} {
    #insert #run generate_offset_buffer_pointer(type_of(offset), value_of_location, T);
    #insert -> string {
        value_tinfo := cast(*Type_Info) T;
        if value_tinfo.type == {
        case .STRING;
            return tprint("return convert_to_pointer_string(offset, offset_buffer_pointer.*);");
        case .ARRAY;
            return tprint("return convert_to_pointer_array(offset, offset_buffer_pointer.*);");
        case .POINTER;
            assert(false, "(for now) getting pointers values is disallowed because they can be interpreted in three different ways: pointer to external, offset to internal, or index to internal");
        case;
            return tprint("return offset_buffer_pointer.*;");
        }
        return "return null";
    }
}

new_offset_array :: inline ($T: Type, count: int) -> []T {
    dummy: []T = ---;
    dummy.data = null;
    dummy.count = count;
    return dummy;
}

make_offset_array :: inline ($T: Type, offset: int, count: int) -> []T {
    offset_array: []T = ---;
    offset_array.data = xx offset;
    offset_array.count = count;
    return offset_array;
}

make_offset_array :: (offset: *Offset_Buffer, $T: Type, count: int) -> []T {
    TYPE_SIZE  :: #run size_of(T);
    TYPE_ALIGN :: #run align_of(T);
    buffer_pos := offset.buffer.count;
    buffer_pos_plus_align_offset := ceil_to_power_of_two_multiple(buffer_pos, TYPE_ALIGN);
    align_offset := buffer_pos_plus_align_offset - buffer_pos;
    array_resize(*offset.buffer, buffer_pos_plus_align_offset + TYPE_SIZE * count);
    return make_offset_array(T, buffer_pos + align_offset, count);
}

make_offset_array :: inline (offset: *Offset_Buffer, array: []$T) -> []T {
    assert(array.data == null);
    return make_offset_array(offset, T, array.count);
}

make_offset_string :: inline (offset: *Offset_Buffer, count: int) -> string {
    array := make_offset_array(offset, u8, count);
    return string.{array.count, array.data};
}

copy_to_offset_string :: inline (offset: *Offset_Buffer, str: string) -> string {
    hosted_str := make_offset_string(offset, str.count);
    pointer_str := convert_to_pointer_string(offset, hosted_str);
    memcpy(pointer_str.data, str.data, pointer_str.count);
    return hosted_str;
}

convert_to_pointer :: inline (offset: *Offset_Buffer, offset_by: int) -> *u8 {
    return offset.buffer.data + offset_by;
}

convert_to_pointer_string :: inline (offset: *Offset_Buffer, str: string) -> string {
    return string.{str.count, convert_to_pointer(offset, xx str.data)};
}

convert_to_pointer_array :: inline (offset: *Offset_Buffer, array: []$T) -> []T {
    out_array: []T = ---;
    out_array.data = xx convert_to_pointer(offset, xx array.data);
    out_array.count = array.count;
    return out_array;
}

generate_offset_buffer_pointer :: ($buf_type: Type, $pointer_to_location: Code, $T: Type) -> string {
    auto_release_temp();

    ast: [..]*Code_Node;
    array_reserve(*ast, buf_type.max_traverse_ast_steps,,temp);

    root, _ := compiler_get_nodes(pointer_to_location);
    assert(root.kind == .BINARY_OPERATOR);
    bin_op := cast(*Code_Binary_Operator) root;

    // traverse top-down over binary tree ast like 'yourthing.array[0].name'
    //                      .
    //                    /   \
    //                  []     name
    //                /    \
    //              .       0
    //            /   \
    //   yourthing     array
    for 0..buf_type.max_traverse_ast_steps-1 {
        if bin_op.left.kind == .BINARY_OPERATOR {
            if bin_op.right.kind == .IDENT || bin_op.right.kind == .LITERAL {
                array_add(*ast, bin_op.right);
                array_add(*ast, bin_op);
            } else {
                assert(false, "invalid right op kind: %", bin_op.right.kind);
            }
            bin_op = cast(*Code_Binary_Operator) bin_op.left;
        } else {
            if bin_op.right.kind == .IDENT {
                array_add(*ast, bin_op.right);
                assert(bin_op.left.kind == .IDENT || bin_op.left.kind == .CONTEXT);
                array_add(*ast, bin_op);
                array_add(*ast, bin_op.left);
            } else {
                assert(false);
            }
            break;
        }
    }
    assert(ast[0].kind == .IDENT || ast[0].kind == .LITERAL);

    prev_local: string;
    name_id_counter: int;
    active_operator : enum {DOT::1; SUBSCRIPT;} = 0;

    code_builder: String_Builder;
    code_builder.allocator = temp;

    found_key: bool;

    // iterating over ast in reverse, which is forward as it's expressed in code/text
    for < ast {
        // a new local value will represent a conversion from offset-based pointer/string/array
        // to pointer-based, if it is used.
        new_local := tprint("_local_value_%", name_id_counter);
        name_id_counter += 1;

        // every other operator must be a . or a []
        if it.kind == .BINARY_OPERATOR {
            bin_op := cast(*Code_Binary_Operator) it;
            if bin_op.operator_type == .ARRAY_SUBSCRIPT {
                assert(active_operator == 0);
                active_operator = .SUBSCRIPT;
            } else if bin_op.operator_type == #char "." {
                assert(active_operator == 0);
                active_operator = .DOT;
            } else {
                assert(false);
            }
        // every other operator must be an Ident, as in a code node that identifies
        // a constant or variable value, which may or may not have runtime storage.
        } else if it.kind == .CONTEXT {
            assert(it_index == ast.count-1);
            prev_local = "context";
        } else if it.kind == .LITERAL {
            assert(active_operator == .SUBSCRIPT);

            literal := cast(*Code_Literal) it;
            assert(literal.value_type == .NUMBER);
            assert((literal.value_flags & .FLOAT) == 0);

            if it_index == 0 {
                // at the end of the reversed ast, the ident at the end of the expression
                // e.g. 'name' in 'context.gltf_asset.name'
                print(*code_builder, "\toffset_buffer_pointer := *%[%];\n", prev_local, literal._u64);
            } else {
                // creating a local that points into an array.
                // the literal is an int subscript
                print(*code_builder, "\t% := *%[%];\n", new_local, prev_local, literal._u64);
                prev_local = new_local;
            }

            active_operator = 0;
        } else if it.kind == .IDENT {
            ident := cast(*Code_Ident) it;
            defer active_operator = 0;

            if !found_key {
                // if we haven't found the key yet, then we're just replaying the 
                // ast as typed. no offset-based storage yet
                if ident.name == buf_type.begin_hosting_ident_name {
                    // found a match to the key that tells us to begin offset-based storage
                    found_key = true;
                }
                if active_operator == .DOT {
                    prev_local = tprint("%.%", prev_local, ident.name);
                } else if active_operator == .SUBSCRIPT {
                    prev_local = tprint("%[%]", prev_local, ident.name);
                } else {
                    assert(it_index == ast.count-1);
                    prev_local = tprint("`%", ident.name);
                }
                continue;
            }

            if active_operator == .DOT {
                if it_index == 0 {
                    // at the end of the reversed ast, the ident at the end of the expression
                    // e.g. 'name' in 'context.gltf_asset.name'
                    print(*code_builder, "\toffset_buffer_pointer := *%.%;\n", prev_local, ident.name);
                } else {
                    next_bin_op := cast(*Code_Binary_Operator)(ast[it_index-1]);
                    if next_bin_op.operator_type == .ARRAY_SUBSCRIPT {
                        if ident.type.type == .ARRAY {
                            // field is an array. creating a local temp that converts the array's
                            // 'data' field into a pointer.
                            print(*code_builder, "\t% := convert_to_pointer_array(offset, %.%);\n", new_local, prev_local, ident.name);
                            prev_local = new_local;
                        } else if ident.type.type == .STRING {
                            // field is a string. creating a local temp that converts the strings's
                            // 'data' field into a pointer.
                            print(*code_builder, "\t% := convert_to_pointer_string(offset, %.%);\n", new_local, prev_local, ident.name);
                            prev_local = new_local;
                        } else {
                            assert(false);
                        }
                    } else {
                        if ident.type.type == .POINTER {
                            // field is a pointer. creating a local temp that converts the 
                            // offset stored at the pointer's location intoa real pointer.
                            print(*code_builder, "\t% := convert_to_pointer(offset, %.%);\n", new_local, prev_local, ident.name);
                            prev_local = new_local;
                        } else {
                            // field isn't a pointer. nothing to convert.
                            prev_local = tprint("%.%", prev_local, ident.name);
                        }
                    }
                }
            } else if active_operator == .SUBSCRIPT {
                // creating a local that points into an array
                print(*code_builder, "\t% := *%[`%];\n", new_local, prev_local, ident.name);
                prev_local = new_local;
            } else {
                assert(false);
            }
        }
    }

    procedure_body := builder_to_string(*code_builder);
    log("%\n-", procedure_body);
    return procedure_body;
}

#scope_file

is_power_of_two :: inline (val: $T) -> bool {
    return val > 0 && (val & (val - 1)) == 0;
}

ceil_to_power_of_two_multiple :: inline (n: $T, power_of_two_size: T) -> T {
    assert(is_power_of_two(power_of_two_size));
    return (n + power_of_two_size-1) & ~(power_of_two_size-1);
}

S64_MAX :: 0x7fff_ffff_ffff_ffff;

#import "Basic";
#import "Compiler";
Program_Print :: #import "Program_Print";

#import "TeRM/TeRM_String";

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
