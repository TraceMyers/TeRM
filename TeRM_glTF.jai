// do not use this. it's mid-development

// glTF 2.0 spec (includes GLB):
// https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html

// png: ignore non-square pixel ratios and embedded ICC profiles
// jpg: ignore embedded ICC profiles

// -----------------------------------------------------------------------------------
// ------------------------------------------------------------- :interface procedures

// alt name
load_gltf :: load_gltf_from_file;

load_gltf_from_file :: (file_path: string, shrink_allocations := true, log_errors := false) -> GLTF_Load_Result {
    on_enter_any_load_proc();

    file_data, success := read_entire_file(file_path, log_errors=log_errors,,temp);
    if !success then return {};

    load_gltf_from_string(file_data, shrink_allocations, log_errors);
    return context.gltf_load_result;
}

load_gltf_from_string :: (file_data: string, shrink_allocations := true, log_errors := false) -> GLTF_Load_Result {
    on_enter_any_load_proc();
    on_enter_main_load_proc(log_errors);

    parser := GLTF_Parser.{file=file_data};
    success := parse_file(*parser, log_errors);
    
    on_exit_main_load_proc(*parser, success, shrink_allocations, log_errors);
    return context.gltf_load_result;
}

// -----------------------------------------------------------------------------------
// ------------------------------------------------------------------ :interface types

GLTF_Load_Result :: struct {
    file_size: s32;
    // if there are any errors, they will be in this list. errors are not necessarily
    // fatal. if fatal, they will be marked. fatal errors mark an unsucessful load.
    // this array points into a buffer owned by the module, and it's valid until 
    // the next load or save.
    errors: []GLTF_Error;
    // for easier freeing
    allocator: Allocator;
    // if any errors caused loading to exit early, this will be true. if so,
    // the final error in the list is guaranteed to be a fatal one, but not necessarily the
    // inciting error. if the error list is truncated, the fatal error replaced a non-fatal one. 
    any_fatal_errors: bool;
    // if adding more errors would have overflowed the internal buffer, this is set
    errors_truncated: bool;
}

// -----------------------------------------------------------------------------------
// --------------------------------------------------------------------------- :errors

GLTF_Error_Code :: enum u16 {
    FILE_TOO_SMALL_FOR_HEADER;
    FILE_MAGIC_INVALID;
    FILE_VERSION_INVALID_OR_UNSUPPORTED;
    FILE_SIZE_DOES_NOT_MATCH_SIZE_REPORTED_IN_HEADER;
    READ_CHUNK_LENGTH_0;
    READING_CHUNK_OVERFLOWS_FILE;
    UNKNOWN_CHUNK_TYPE_AT_FILE_LOCATION;
    JSON_CHUNK_NOT_AT_INDEX_0;
    BIN_CHUNK_NOT_AT_INDEX_1;
    JSON_CHUNK_MISSING;
    JSON_ASSET_IS_NOT_OBJECT;
    JSON_ASSET_HAS_MORE_THAN_ONE_ELEMENT;
    JSON_ASSET_VERSION_INCORRECTLY_FORMATTED;
    DUPLICATE_ASSET_FIELD;
    DUPLICATE_SCENES_FIELD;
    DUPLICATE_SCENE_FIELD;
    DUPLICATE_NODES_FIELD;
    DUPLICATE_MESHES_FIELD;
    DUPLICATE_ACCESSORS_FIELD;
    DUPLICATE_BUFFER_VIEWS_FIELD;
    DUPLICATE_BUFFERS_FIELD;
    DUPLICATE_MATERIALS_FIELD;
    DUPLICATE_TEXTURES_FIELD;
    DUPLICATE_IMAGES_FIELD;
    DUPLICATE_SAMPLERS_FIELD;
    DUPLICATE_ANIMATIONS_FIELD;
    DUPLICATE_SKINS_FIELD;
    DUPLICATE_CAMERAS_FIELD;
    DUPLICATE_EXTENSIONS_FIELD;
    DUPLICATE_EXTENSIONS_USED_FIELD;
    DUPLICATE_EXTENSIONS_REQUIRED_FIELD;
    DUPLICATE_EXTRAS_FIELD;
}

GLTF_Error_Flags :: enum_flags u16 {
    FATAL;
    INTERNAL_UNPROCESSED;
}

GLTF_Error :: struct {
    code: GLTF_Error_Code; 
    flags: GLTF_Error_Flags;
    line: s32;
    column: s32;
    // converted to line,column on exit
    #overlay(line) _internal_file_position: s32 = ---;
}

#scope_file // -----------------------------------------------------------------------

add_load_error :: (code: GLTF_Error_Code, file_position: s64, flags: GLTF_Error_Flags = 0) {
    using context;

    if flags & .FATAL {
        gltf_load_result.any_fatal_errors = true;
    }

    error := GLTF_Error.{
        code=code, flags=flags|.INTERNAL_UNPROCESSED, _internal_file_position=xx file_position
    };

    if gltf_errors.count == gltf_error_buffer.count {
        if gltf_load_result.any_fatal_errors {
            // make sure at least the final fatal error is recorded, even if the errors are truncated.
            gltf_error_buffer[gltf_error_buffer.count-1] = error;
        }
        gltf_load_result.errors_truncated = true;
        return;
    }

    gltf_errors.count += 1;
    gltf_errors[gltf_errors.count-1] = error;
}

// -----------------------------------------------------------------------------------
// ---------------------------------------------------------------- :types for parsing

GLTF_Parser :: struct {
    file: string;
    pos: int;
    header: GLTF_Header;

    json_chunk: GLTF_Chunk;
    binary_chunk: GLTF_Chunk;
    
    field_visited: GLTF_Field_Flags;
    any_load_failures: bool;
    asset_version_validated: bool;
}

GLTF_Header :: struct {
    magic: string;
    version: u32;
    length: u32;
}

GLTF_Chunk :: struct {
    type: string;
    bytes: string;
}

GLTF_Field_Flags :: enum_flags u64 {
    ASSET;
    SCENES;
    SCENE;
    NODES;
    MESHES;
    ACCESSORS;
    BUFFER_VIEWS;
    BUFFERS;
    MATERIALS;
    TEXTURES;
    IMAGES;
    SAMPLERS;
    ANIMATIONS;
    SKINS;
    CAMERAS;
    EXTENSIONS;
    EXTENSIONS_USED;
    EXTENSIONS_REQUIRED;
    EXTRAS;
}

// -----------------------------------------------------------------------------------
// ----------------------------------------------------------------------- :parse_file

parse_file :: (parser: *GLTF_Parser, log_errors: bool) -> success: bool {
    if parser.file.count < 12 {
        add_load_error(.FILE_TOO_SMALL_FOR_HEADER, 0, .FATAL);
        return false;
    }

    success := parse_file_header(parser);
    if !success then return false;

    reported_file_size := parser.header.length;
    if reported_file_size != parser.file.count {
        // not fatal, will keep trying to load
        add_load_error(.FILE_SIZE_DOES_NOT_MATCH_SIZE_REPORTED_IN_HEADER, 8);
    }
 
    success = parse_chunks(parser);
    if !success then return false;

    // this guy is everywhere
    jason := load_json_from_string(parser.json_chunk.bytes, false, false, log_errors,, temp);
    if jason.any_fatal_errors then return false;

    for_each_element(*jason, xx load_gltf_using_parsed_json, parser);
    parser.any_load_failures |= parser.asset_version_validated;

    return !parser.any_load_failures;
}

parse_file_header :: (using parser: *GLTF_Parser) -> valid_header: bool {
    header_u32         := read_u32(parser);
    header.magic.data   = xx *header_u32;
    header.magic.count  = 4;
    header.version      = read_u32(parser);
    header.length       = read_u32(parser);
    if header.magic != "glTF" {
        add_load_error(.FILE_MAGIC_INVALID, 0, .FATAL);
        return false;
    }
    if header.version != 2 {
        add_load_error(.FILE_VERSION_INVALID_OR_UNSUPPORTED, 4, .FATAL);
        return false;
    }
    return true;
}

parse_chunks :: (parser: *GLTF_Parser) -> likely_success: bool {
    chunk_count := 0;

    while true {
        chunk := ifx chunk_count == 0 then *parser.json_chunk else *parser.binary_chunk;
        success := parse_chunk(parser, chunk);
        if !success then break;

        CHUNK_HEADER_SIZE :: 8;
        chunk_location := parser.pos - (chunk.bytes.count + CHUNK_HEADER_SIZE);

        if chunk.type == "JSON" {
            if chunk_count != 0 {
                add_load_error(.JSON_CHUNK_NOT_AT_INDEX_0, chunk_location, .FATAL);
                return false;
            }
            chunk_count += 1;
        } else if chunk.type == "BIN" {
            if chunk_count != 1 {
                add_load_error(.BIN_CHUNK_NOT_AT_INDEX_1, chunk_location, .FATAL);
                return false;
            }
            chunk_count += 1;
            break;
        } else {
            break;
        }
    }
    
    if chunk_count == 0 {
        add_load_error(.JSON_CHUNK_MISSING, 12, .FATAL);
        return false;
    }

    return true;
}

parse_chunk :: (using parser: *GLTF_Parser, chunk: *GLTF_Chunk) -> success: bool {
    // all chunks are 4-byte aligned.
    align_4(*pos);

    MIN_READ_BYTES :: 8;
    if pos + MIN_READ_BYTES > file.count { 
        return false;
    }

    chunk_length := read_u32(parser);
    chunk.type    = read_string_safe(parser, 4); // points into file buffer, no overflow
    chunk.bytes   = read_string(parser, chunk_length); // points into file buffer, no overflow

    if chunk_length == 0 {
        add_load_error(.READ_CHUNK_LENGTH_0, pos-MIN_READ_BYTES);
        // can't have 0 len chunk for the data that tells you how to load stuff
        return chunk.type != "JSON"; 
    }
    if pos > file.count {
        add_load_error(.READING_CHUNK_OVERFLOWS_FILE, pos, .FATAL);
        return false;
    }

    return true;
}

load_gltf_using_parsed_json :: (parent_stack: []JSON_Element_Container, element: JSON_Element_Container, element_index: int, parent_element_count: int, parser: *GLTF_Parser) -> bool, bool {
    if element.has_key {
        if element.key == {
        case "asset";
            if parser.field_visited & .ASSET {
                add_load_error(.DUPLICATE_ASSET_FIELD, 0, .FATAL);
                parser.any_load_failures = true;
            } else {
                parse_asset_field(parser, element);
                parser.field_visited |= .ASSET;
            }
        case "scenes";
        case "scene";
        case "nodes";
        case "meshes";
        case "accessors";
        case "bufferViews";
        case "buffers";
        case "materials";
        case "textures";
        case "images";
        case "samplers";
        case "animations";
        case "skins";
        case "cameras";
        case "extensions";
        case "extensionsUsed";
        case "extensionsRequired";
        case "extras";
        }
    }
    return !parser.any_load_failures /* keep iterating */, false /* only iterate over top level elements */; 
}

parse_asset_field :: (parser: *GLTF_Parser, element: JSON_Element_Container) {
    if parser.field_visited & .ASSET {
        add_load_error(.DUPLICATE_ASSET_FIELD, 0, .FATAL);
        parser.any_load_failures = true;
        return;
    }

    parser.field_visited |= .ASSET;

    if element.value.type != .OBJECT {
        add_load_error(.JSON_ASSET_IS_NOT_OBJECT, 0, .FATAL);
        parser.any_load_failures = true;
    } else if element.value.object.elements.count == 0 {
        add_load_error(.JSON_ASSET_HAS_MORE_THAN_ONE_ELEMENT, 0, .FATAL);
        parser.any_load_failures = true;
    } else {
        for subelement : element.value.object.elements {
            if subelement.key.str    == "version" 
            && subelement.value.type == .STRING 
            && subelement.value.str.count >= 3
            // according to spec, all minor versions must be backward compatible, so 
            // supporting 2.0 means supporting 2.x to an extent
            && begins_with(subelement.value.str, "2.") { 
                parser.asset_version_validated = true;
                break;
            }
        }
        if !parser.asset_version_validated {
            add_load_error(.JSON_ASSET_VERSION_INCORRECTLY_FORMATTED, 0, .FATAL);
            parser.any_load_failures = true;
        }
    }
}

// -----------------------------------------------------------------------------------
// ---------------------------------------------------------------- :on enter and exit

on_enter_any_load_proc :: () #expand {
    `_mark := get_temporary_storage_mark();
    `defer if context.allocator.proc != temp.proc then set_temporary_storage_mark(`_mark);
}

on_enter_main_load_proc :: (log_errors: bool) { 
    context.gltf_load_result = {allocator=context.allocator};
    context.gltf_errors.data = context.gltf_error_buffer.data;
    context.gltf_errors.count = 0;
}

on_exit_main_load_proc :: (parser: *GLTF_Parser, parse_success: bool, shrink_allocations: bool, log_errors: bool) {
    // -----------------------------------------------------

    _increment_wrap :: inline (x: $T, min: T, max: T) -> T {
        if x >= max {
            return min;
        } else return x + 1;
    }

    // -----------------------------------------------------

    using context;

    if parse_success && shrink_allocations && gltf_load_result.allocator.proc != temp.proc {
        // array_shrink_if_small_enough(*parser.elements, 0.9);
        // array_shrink_if_small_enough(*parser.strings, 0.9);
    }

    // post_process_success := post_process_collections(*parser.elements, parser.strings);

    // if parse_success && post_process_success {
        // gltf_load_result.elements = parser.elements;
        // gltf_load_result.strings = parser.strings;
    // } else {
    //     array_reset(*parser.elements);
    //     array_reset(*parser.strings);
    // }

    gltf_load_result.errors = gltf_errors;

    file_context_lines: [8]string;
    fcl_indices: [file_context_lines.count]int;
    fcl_i := 0;

    if parser.file.count > 0 && gltf_errors.count > 0 {
        next_text_covered_size := 0;

        // each error originally is only recorded at a file position
        // convert that to line, column
        for :per_line line, line_index : parser.file {
            text_covered_size := next_text_covered_size;
            next_text_covered_size += line.count;

            line_file_position_begin := line.data - parser.file.data;
            line_file_position_end   := line_file_position_begin + line.count;

            processed_error_count := 0;

            file_context_lines[fcl_i] = line;
            defer fcl_i = _increment_wrap(fcl_i, 0, file_context_lines.count-1);

            for *err : gltf_errors {
                if (err.flags & .INTERNAL_UNPROCESSED) == 0 {
                    processed_error_count += 1;
                    continue;
                }

                if err._internal_file_position >= line_file_position_begin 
                && err._internal_file_position <= line_file_position_end {
                    err.column = xx (err._internal_file_position - line_file_position_begin);
                    err.line = xx line_index;
                    err.flags &= ~.INTERNAL_UNPROCESSED;

                    space_buffer: [128]u8 = ---;
                    space_count := min(space_buffer.count, err.column);
                    memset(space_buffer.data, " ", space_count);
                    spaces := string.{space_count, space_buffer.data};

                    // getting cached line indices, oldest to newest
                    fcl_indices[0] = _increment_wrap(fcl_i, 0, file_context_lines.count-1);
                    if fcl_indices.count > 1 then for 1..fcl_indices.count-1 {
                        fcl_indices[it] = _increment_wrap(fcl_indices[it-1], 0, file_context_lines.count-1);
                    }

                    if log_errors {
                        error_string_builder: String_Builder;
                        print(*error_string_builder,
#string HERE


    error code : %
    flags      : %
    line #     : %
    column #   : %
HERE,
                            err.code, 
                            err.flags, 
                            err.line, 
                            err.column
                        );

                        // print the file lines so the user can see the error location in the text
                        // for fcl_indices {
                        //     if it_index == 0 {
                        //         print(*error_string_builder, "    text       : %\n", file_context_lines[it]);
                        //     } else {
                        //         print(*error_string_builder, "                 %\n", file_context_lines[it]);
                        //     }
                        // }
                        // // caret points at the problem location
                        // print(*error_string_builder,         "                 %^\n", spaces);

                        report_module_error(builder_to_string(*error_string_builder));
                    }

                    processed_error_count += 1;
                }
            }

            if processed_error_count == gltf_errors.count {
                break;
            }
        }
    }
}

// -----------------------------------------------------------------------------------
// ----------------------------------------------------------------------------- :misc

report_module_error :: (fmt: string, args: ..Any) #expand {
    trm_log(fmt=fmt, args=..args, header="TeRM/GLTF");
}

// align to multiple of 4
align_4 :: inline (value: *int)  {
    remainder := value.* & 0x3;
    if remainder != 0 {
        value.* = value.* + (4 - remainder);
    }
}

read_u32 :: inline (using parser: *GLTF_Parser) -> u32 {
    u32_val := (cast(*u32) (parser.file.data + parser.pos)).*;
    parser.pos += 4;
    return u32_val;
}

read_string_safe :: inline (using parser: *GLTF_Parser, max_read_count: int) -> string {
    str := to_string_safe(file.data + pos, max_read_count);
    pos += 4;
    return str;
}

read_string :: inline (using parser: *GLTF_Parser, count: int) -> string {
    str := to_string(file.data + pos, count);
    pos += xx count;
    return str;
}

// -----------------------------------------------------------------------------------

// errors are cleared and added per-load and per-save, for each thread. 
// if the number of errors maxes out, errors are no longer stored.
// adding these to the context so they can be thread-local, allowing for multithreaded processing
#add_context gltf_error_buffer:       [32]GLTF_Error;
#add_context gltf_errors:             [..]GLTF_Error;
#add_context gltf_load_result:        GLTF_Load_Result;

#import "Basic";
#import "File";
#import "String";

#import "TeRM/TeRM_JSON";
#import "TeRM/TeRM_Log";
#import "TeRM/TeRM_String";
