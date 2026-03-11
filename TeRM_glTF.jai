// do not use this. it's mid-development

// glTF 2.0 spec (includes GLB):
// https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html

// png: ignore non-square pixel ratios and embedded ICC profiles
// jpg: ignore embedded ICC profiles

// -----------------------------------------------------------------------------------
// ------------------------------------------------------------- :interface procedures

// alt name
load_gltf :: load_gltf_from_file;

load_gltf_from_file :: (file_path: string, out_asset: *Asset_3D, shrink_allocations := true, log_errors := false) -> GLTF_Load_Result {
    on_enter_any_load_proc();

    file_data, success := read_entire_file(file_path, log_errors=log_errors,,temp);
    if !success then return {};

    load_gltf_from_string(file_data, out_asset, shrink_allocations, log_errors, file_path);
    return context.gltf_load_result;
}

load_gltf_from_string :: (file_data: string, out_asset: *Asset_3D, shrink_allocations := true, log_errors := false, file_path := "") -> GLTF_Load_Result {
    assert(out_asset != null);
    assert(out_asset.cpu_self_allocation.data == null);
    assert(out_asset.cpu_buffers_allocation.data == null);
    out_asset.* = {};

    on_enter_any_load_proc();
    on_enter_main_load_proc(log_errors);

    parser := GLTF_Parser.{file=file_data};
    context.gltf_asset = out_asset;

    defer context.gltf_asset = null;
    context.gltf_parser = *parser;
    defer context.gltf_parser = null;

    context.gltf_load_result.asset = out_asset;

    if file_path.count > 0 {
        absolute_path := get_absolute_path(file_path,,temp);
        context.gltf_asset.file_path = gltf_copy_string(absolute_path);
    }

    success := parse_file(*parser, log_errors);
    
    on_exit_main_load_proc(*parser, success, shrink_allocations, log_errors);
    return context.gltf_load_result;
}

// -----------------------------------------------------------------------------------
// ------------------------------------------------------------------ :interface types

GLTF_Load_Result :: struct {
    asset: *Asset_3D;
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
    FAILED_PARSING_JSON_CHUNK;
    JSON_CHUNK_MISSING;
    JSON_OBJECT_EXPECTED;
    JSON_ARRAY_EXPECTED;
    JSON_INT_EXPECTED;
    JSON_NON_NEGATIVE_INTEGER_EXPECTED;
    JSON_ASSET_HAS_ZERO_ELEMENTS;
    JSON_ASSET_VERSION_INCORRECTLY_FORMATTED;
    JSON_ASSET_VERSION_NOT_2;
    JSON_ASSET_MIN_VERSION_NOT_2_0;
    NO_SCENES;
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
    ASSET_FIELD_UNIMPLEMENTED;
    SCENES_FIELD_UNIMPLEMENTED;
    SCENE_FIELD_UNIMPLEMENTED;
    NODES_FIELD_UNIMPLEMENTED;
    MESHES_FIELD_UNIMPLEMENTED;
    ACCESSORS_FIELD_UNIMPLEMENTED;
    BUFFER_VIEWS_FIELD_UNIMPLEMENTED;
    BUFFERS_FIELD_UNIMPLEMENTED;
    MATERIALS_FIELD_UNIMPLEMENTED;
    TEXTURES_FIELD_UNIMPLEMENTED;
    IMAGES_FIELD_UNIMPLEMENTED;
    SAMPLERS_FIELD_UNIMPLEMENTED;
    ANIMATIONS_FIELD_UNIMPLEMENTED;
    SKINS_FIELD_UNIMPLEMENTED;
    CAMERAS_FIELD_UNIMPLEMENTED;
    EXTENSIONS_FIELD_UNIMPLEMENTED;
    EXTENSIONS_USED_FIELD_UNIMPLEMENTED;
    EXTENSIONS_REQUIRED_FIELD_UNIMPLEMENTED;
    EXTRAS_FIELD_UNIMPLEMENTED;
    ASSET_DOWNLOAD_FROM_INTERNET_UNSUPPORTED;
}

GLTF_Error_Flags :: enum_flags u16 {
    FATAL;
    INTERNAL_UNPROCESSED;
}

GLTF_Error :: struct {
    code: GLTF_Error_Code; 
    flags: GLTF_Error_Flags;
    file_position: s32;
}

#scope_file // -----------------------------------------------------------------------

add_process_load_error :: (code: GLTF_Error_Code, file_position: s64, flags: GLTF_Error_Flags = 0) #expand {
    context.gltf_parser.any_load_failures = true;
    add_load_error(code, file_position, flags);
}

add_load_error :: (code: GLTF_Error_Code, file_position: s64, flags: GLTF_Error_Flags = 0) {
    using context;

    if flags & .FATAL {
        gltf_load_result.any_fatal_errors = true;
    }

    error := GLTF_Error.{
        code=code, flags=flags|.INTERNAL_UNPROCESSED, file_position=xx file_position
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

    buffer_views: []Buffer_View_Internal;
    accessors: []Accessor_Internal;
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

parse_file :: no_inline (parser: *GLTF_Parser, log_errors: bool) -> success: bool {
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
    if jason.any_fatal_errors {
        add_load_error(.FAILED_PARSING_JSON_CHUNK, parser.pos, .FATAL);
        return false;
    }

    init_buffer();

    for_each_element(*jason, xx load_gltf_using_parsed_json, parser);
    parser.any_load_failures |= parser.asset_version_validated;

    success = post_process_asset(context.gltf_asset);
    if !success then return false;

    {
        using context.gltf_asset;
        module_log("asset: %", _fmt_verbose(context.gltf_asset.*));
        module_log("asset self allocation size: %", context.gltf_asset.cpu_self_allocation.count);
        // module_log("file path: %", file_path);
        // module_log("roots: %", scene_roots);
        // module_log("meshes: %", meshes);
    }

    return !parser.any_load_failures;
}

post_process_asset :: (using asset: *Asset_3D) -> bool {
    for *scene_real : scenes {
        scene := cast(*Scene_3D_Internal) scene_real;
        for 0..scene.children.count-1 {
            if cast(s64) scene.children[it] == it {
                // todo: fatal error
                return false;
            }
        }

        if (scene._internal_transform_flags & (.TRANSLATION | .ROTATION | .SCALE)) != 0 {
            // set the transform from input TRS
            translation_vec: Vector3 = ---;
            rotation_quat: Quaternion = ---;
            scale_vec: Vector3 = ---;

            if (scene._internal_transform_flags & .TRANSLATION) != 0 {
                translation_vec = scene._internal_translation;
            } else {
                translation_vec = {};
            }
            if (scene._internal_transform_flags & .ROTATION) != 0 {
                rotation_quat = scene._internal_rotation;
            } else {
                rotation_quat = {};
            }
            if (scene._internal_transform_flags & .SCALE) != 0 {
                scale_vec = scene._internal_scale;
            } else {
                scale_vec = {1,1,1};
            }

            // gltf is            +Y up    +Z fore  -X right
            // this rebases it to +Y fore  +Z up    +X right
            basis_change := Matrix3.{_11=-1, _32=1, _23=1};
            rotation_quat = change_basis_forward(rotation_quat, basis_change);

            mat3by3 := Matrix3_Identity;
            scale(*mat3by3, scale_vec);
            mat3by3 = rotate(mat3by3, rotation_quat);
            scene.transform = make_matrix4(mat3by3);
            translate(*scene.transform, translation_vec);

        } else if (scene._internal_transform_flags & .MATRIX) == 0 {
            // no transform input, assume identity is wanted
            scene.transform = Matrix4_Identity;
        } // else matrix was loaded
    }

    for *material : materials {
        if (material.flags & (.ALBEDO_TEXTURE_SET | .ALBEDO_FACTOR_SET)) == .ALBEDO_TEXTURE_SET {
            // if the albedo texture was set but not the factor, set the factor to white
            // so that it doesn't turn stuff magenta. magenta is to indicate nothing is set.
            material.albedo_factor = COLOR4F_WHITE;
            material.flags |= .ALBEDO_FACTOR_DEFAULTED_TO_WHITE;
        }
    }

    move_asset_allocation(asset);
    return true;
}

move_asset_allocation :: (using asset: *Asset_3D) {
    // we want allocations to look like this:
    // 
    // Asset
    // {
    //     meshes[] o--------------------------------------------------.
    //     scenes[] o.                                                 |
    //     ...       |         .---------------------------------------|-----------.
    // }             |         |                                       |           |
    //               v         o                                       v           v
    // Buffer [ ... [scene1:  mesh ... |scene2: ... |scene3: ... ] ... [mesh1: ... |mesh2: ...] ... ] 
    //
    // however, at this point in the process, top level arrays (meshes, scenes, ...) point into 
    // a buffer owned by this module. and, pointer fields within the buffer are storing indices 
    // to top-level arrays. so, this proc needs to: 
    //
    //     {1} make an allocation that can be owned by the result and copy the gltf module buffer 
    //          (above 'Buffer') data into it.
    //     {2} make all of the top level arrays in the asset point into the new buffer
    //         {2a} rebase_pointer handles the rebasing
    //     {3} convert indices (fake pointers) into pointers that also point into the new buffer.
    //         {3a} rebase_pointer also handles this

    // {1} copy from the gltf load buffer into a new allocation owned by the load result
    new_allocation := alloc(context.gltf_buffer.count);
    memcpy(new_allocation, context.gltf_buffer.data, context.gltf_buffer.count);
    asset.cpu_self_allocation.data = new_allocation;
    asset.cpu_self_allocation.count = context.gltf_buffer.count;

    // {2a/3a}
    // this could be two procedures but it's fine
    rebase_pointer :: (asset: *Asset_3D, ptr: *$T, new_allocation: *u8, ptr_is_index: bool) -> *void {
        if ptr_is_index {
            i := cast(s32) ptr;
            if i == -1 {
                return null;
            }
            #if T == {
            case Scene_3D;
                return ifx asset.scenes.data        == null then null else *asset.scenes[i];
            case Mesh;
                return ifx asset.meshes.data        == null then null else *asset.meshes[i];
            case Mesh_Skin;
                return ifx asset.mesh_skins.data    == null then null else *asset.mesh_skins[i];
            case Camera_Info;
                return ifx asset.cameras.data       == null then null else *asset.cameras[i];
            case Texture;
                return ifx asset.textures.data      == null then null else *asset.textures[i];
            case Image;
                return ifx asset.images.data        == null then null else *asset.images[i];
            case Index_Buffer;
                return ifx asset.index_buffers.data == null then null else *asset.index_buffers[i];
            case Material;
                return ifx asset.materials.data     == null then null else *asset.materials[i];
            }
            return null;
        } else {
            based_ptr := cast(int) ptr - cast(int) context.gltf_buffer.data;
            if based_ptr >= 0 && based_ptr < context.gltf_buffer.count {
                return new_allocation + based_ptr;
            } else {
                return ptr;
            }
        }
    }

    // generating code to nullify pointers that are set to -1 and rebase all pointers to the new allocation.
    #insert -> string {
        fix_pointers_in_struct :: (
            fixes: *String_Builder, 
            struct_tinfo: *Type_Info_Struct, 
            struct_name: string, 
            depth: int, 
            depth_spaces_data: *u8, 
            depth_spaces_max: int,
            top_level_pass: bool
        ) {
            depth_str := string.{min(depth * 4, depth_spaces_max), depth_spaces_data};
            for member : struct_tinfo.members {
                if member.type.type == {
                case .ARRAY;
                    full_member_path    := tprint("%.%", struct_name, member.name);
                    member_array_tinfo  := cast(*Type_Info_Array) member.type;
                    array_element_tinfo := member_array_tinfo.element_type;

                    if top_level_pass {
                        print(fixes,
#string HERE
%%.data = rebase_pointer(asset, %.data, new_allocation, false);
HERE,
                            depth_str, full_member_path, full_member_path
                        );
                        continue;
                    }

                    if array_element_tinfo.type == {
                    case .STRUCT;
                        print(fixes, "%for *% {\n", depth_str, full_member_path);
                        fix_pointers_in_struct(fixes, xx array_element_tinfo, "it", depth + 1, depth_spaces_data, depth_spaces_max, false);
                        print(fixes, "%}\n", depth_str);
                    case .POINTER; 
                        print(fixes,
#string HERE
%for *% {
%    it.* = rebase_pointer(asset, it.*, new_allocation, true);
%}
HERE,
                            depth_str, full_member_path, depth_str, depth_str
                        );
                    }
                case .POINTER;
                    full_member_path := tprint("%.%", struct_name, member.name);
                    print(fixes,
#string HERE
%% = rebase_pointer(asset, %, new_allocation, true);
HERE,
                        depth_str, full_member_path, full_member_path
                    );
                case .STRUCT;
                    full_member_path := tprint("%.%", struct_name, member.name);
                    fix_pointers_in_struct(fixes, xx member.type, full_member_path, depth + 1, depth_spaces_data, depth_spaces_max, false);
                }
            }
        }

        depth_spaces_buffer: [128]u8 = ---;
        for *depth_spaces_buffer {
            it.* = #char " ";
        }

        pointer_manipulations: String_Builder;

        // {2} set all the top level array pointers
        fix_pointers_in_struct(*pointer_manipulations, cast(*Type_Info_Struct) Asset_3D, "asset", 1, depth_spaces_buffer.data, depth_spaces_buffer.count, true);

        // {3} fix pointers within the top level arrays
        fix_pointers_in_struct(*pointer_manipulations, cast(*Type_Info_Struct) Asset_3D, "asset", 1, depth_spaces_buffer.data, depth_spaces_buffer.count, false);

        output := builder_to_string(*pointer_manipulations);
        // log(output);
        return output;
    }
}

parse_file_header :: (using parser: *GLTF_Parser) -> valid_header: bool {
    header.magic   = read_string(parser, 4);
    header.version = read_u32(parser);
    header.length  = read_u32(parser);
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

        if chunk.type == {
        case "JSON";
            if chunk_count != 0 {
                add_load_error(.JSON_CHUNK_NOT_AT_INDEX_0, chunk_location, .FATAL);
                return false;
            }
            chunk_count += 1;
        case "BIN";
            if chunk_count != 1 {
                add_load_error(.BIN_CHUNK_NOT_AT_INDEX_1, chunk_location, .FATAL);
                return false;
            }
            chunk_count += 1;
            break;
        case;
            break;
        }
    }
    
    if chunk_count == 0 {
        add_load_error(.JSON_CHUNK_MISSING, parser.pos, .FATAL);
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
    chunk.type    = read_string_up_to(parser, 4); // points into file buffer, no overflow
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
    if element.key != null {
        if element.key.str == {
        case "asset";               process_field("asset",                parser, element);
        case "scenes";              process_field("scenes",               parser, element);
        case "scene";               process_field("scene",                parser, element);
        case "nodes";               process_field("nodes",                parser, element);
        case "meshes";              process_field("meshes",               parser, element);
        case "accessors";           process_field("accessors",            parser, element);
        case "bufferViews";         process_field("buffer_views",         parser, element);
        case "buffers";             process_field("buffers",              parser, element);
        case "materials";           process_field("materials",            parser, element);
        case "textures";            process_field("textures",             parser, element);
        case "images";              process_field("images",               parser, element);
        case "samplers";            process_field("samplers",             parser, element);
        case "animations";          process_field("animations",           parser, element);
        case "skins";               process_field("skins",                parser, element);
        case "cameras";             process_field("cameras",              parser, element);
        case "extensions";          process_field("extensions",           parser, element);
        case "extensionsUsed";      process_field("extensions_used",      parser, element);
        case "extensionsRequired";  process_field("extensions_required",  parser, element);
        case "extras";              process_field("extras",               parser, element);
        }
    }
    keep_iterating := !parser.any_load_failures;
    return keep_iterating, false; // false = only iterate over top level elements
}

// boilerplate handler
// validates the field hasn't been visited, marks the field visited, and calls the respective procedure
// for example, process_field(parser, element, "asset") calls process_asset_field(parser, element);
process_field :: ($name: string, parser: *GLTF_Parser, element: JSON_Element_Container) #expand {
    #insert -> string {
        UPPER_NAME :: #run to_upper(name);
        return tprint(
#string HERE
    if parser.field_visited & .% {
        add_process_load_error(.DUPLICATE_%_FIELD, get_file_position(element.key), .FATAL);
        return;
    }
    parser.field_visited |= .%;   
    process_%_field(parser, element);
HERE,
            UPPER_NAME, UPPER_NAME, UPPER_NAME, name
        );
    }
}

process_asset_field :: (parser: *GLTF_Parser, element: JSON_Element_Container) {
    if json_get(*element.value.object).elements.count == 0 {
        add_process_load_error(.JSON_ASSET_HAS_ZERO_ELEMENTS, get_file_position(element.key), .FATAL);
    } else {
        for subelement : element.value.object.elements {
            key := json_get(*subelement.key.str, .ASSERT).*;

            // according to spec, all minor versions must be backward compatible, so 
            // supporting 2.0 means supporting 2.x to an extent
            if key == "version" {
                version := json_get(*subelement.value.str, .ASSERT).*;
                if begins_with(version, "2.") { 
                    parser.asset_version_validated = true;
                } else {
                    add_process_load_error(.JSON_ASSET_VERSION_NOT_2, get_file_position(element.key), .FATAL);
                    return;
                }
            // also according to the spec, you can just set a minVersion and I guess
            // the above rule is a lie. or, maybe they mean something like:
            // the file has version 2.x but minVersion = 1.x ok?
            } else if key == "minVersion" {
                min_version := json_get(*subelement.value.str, .ASSERT).*;
                if min_version != "2.0" && !begins_with(min_version, "1.") {
                    add_process_load_error(.JSON_ASSET_MIN_VERSION_NOT_2_0, get_file_position(element.key), .FATAL);
                }
            }
        }
        if !parser.asset_version_validated {
            add_process_load_error(.JSON_ASSET_VERSION_INCORRECTLY_FORMATTED, get_file_position(element.key), .FATAL);
        }
    }
}

// scenes = array of scenes, or collections of nodes.
process_scenes_field :: (parser: *GLTF_Parser, element: JSON_Element_Container) {
    // root scenes.
    scenes := json_get(*element.value.array, .ASSERT);
    if scenes.elements.count == 0 {
        add_process_load_error(.NO_SCENES, get_file_position(element.key), .FATAL);
        return;
    }

    scene_roots  := *context.gltf_asset.scene_roots;
    scene_roots.* = gltf_alloc_array(Scene_Root, scenes.elements.count);

    for scene, si : scenes.elements {
        scene_components := json_get(*scene.object, .ASSERT).elements;
        if scene_components.count == 0 {
            // todo: non-fatal error
            continue;
        }
        for scene_component, sci : scene_components {
            if json_get(*scene_component.key.str).* == "name" {
                scene_roots.*[si].name = gltf_copy_string(json_get(*scene_component.value.str).*);
            } else if json_get(*scene_component.key.str).* == "nodes" {
                nodes := json_get(*scene_component.value.array, .ASSERT).elements;
                if nodes.count == 0 {
                    // todo: (non?)fatal error
                    continue;
                }

                scene_roots.*[si].scenes = gltf_alloc_array(*Scene_3D, nodes.count);

                for node, ni : nodes {
                    scene_index := json_get(*node.i64, .ASSERT).*;
                    if scene_index < 0 {
                        add_process_load_error(
                            .JSON_NON_NEGATIVE_INTEGER_EXPECTED, 
                            get_file_position(element.key), 
                            .FATAL
                        );
                        return;
                    }
                    scene_roots.*[si].scenes[ni] = xx sci; // convert to pointers later
                }
            } else {
                // todo: (non?)fatal error (unhandled case)
            }
        }
    }
}

process_scene_field :: (parser: *GLTF_Parser, element: JSON_Element_Container) {
    context.gltf_asset.primary_scene = xx json_get(*element.value.i64).*;
}

process_nodes_field :: (parser: *GLTF_Parser, element: JSON_Element_Container) {
    nodes := json_get(*element.value.array).elements;
    if nodes.count == 0 {
        // todo: fatal error
        return;
    }

    using context.gltf_asset;
    scenes = gltf_alloc_array(Scene_3D, nodes.count);
    scenes_internal := cast,force([]Scene_3D_Internal) scenes;

    for node, ni : nodes {
        // note: matrix and TRS are mutually exclusive. error if both included
        // note: if TRS, any of them are optional
        // note: skin implies a mesh must exist.
        for node_component : json_get(*node.object).elements {
            key := json_get(*node_component.key.str).*;
            if key == {
            case "name";
                scenes_internal[ni].name = gltf_copy_string(json_get(*node_component.value.str).*);
            case "children";
                children := json_get(*node_component.value.array).elements;
                scenes_internal[ni].children = gltf_alloc_array(*Scene_3D, children.count);
                for child, ci : children {
                    scenes_internal[ni].children[ci] = xx json_get(*child.i64).*;
                }
            case "matrix";
                if scenes_internal[ni]._internal_transform_flags != 0 {
                    // todo: error
                    return;
                }
                scenes_internal[ni]._internal_transform_flags |= .MATRIX;
                mat_components := json_get(*node_component.value.array).elements;
                for cmp : mat_components {
                    scenes_internal[ni].transform.floats[it_index] = xx json_get(*cmp.f64).*;
                }
            case "translation";
                if (scenes_internal[ni]._internal_transform_flags & (.MATRIX | .TRANSLATION)) != 0 {
                    // todo: error
                    return;
                }
                scenes_internal[ni]._internal_transform_flags |= .TRANSLATION;
                position_components := json_get(*node_component.value.array).elements;
                for cmp : position_components {
                    scenes_internal[ni]._internal_translation.component[it_index] = xx json_get(*cmp.f64).*;
                }
            case "rotation";
                if (scenes_internal[ni]._internal_transform_flags & (.MATRIX | .ROTATION)) != 0 {
                    // todo: error
                    return;
                }
                scenes_internal[ni]._internal_transform_flags |= .ROTATION;
                quat_components := json_get(*node_component.value.array).elements;
                for cmp : quat_components {
                    scenes_internal[ni]._internal_rotation.component[it_index] = xx json_get(*cmp.f64).*;
                }
            case "scale";
                if (scenes_internal[ni]._internal_transform_flags & (.MATRIX | .SCALE)) != 0 {
                    // todo: error
                    return;
                }
                scenes_internal[ni]._internal_transform_flags |= .SCALE;
                scale_components := json_get(*node_component.value.array).elements;
                for cmp : scale_components {
                    scenes_internal[ni]._internal_scale.component[it_index] = xx json_get(*cmp.f64).*;
                }
            case "mesh";
                scenes_internal[ni].mesh      = xx json_get(*node_component.value.i64).*;
            case "camera";
                scenes_internal[ni].camera    = xx json_get(*node_component.value.i64).*;
            case "skin";
                scenes_internal[ni].mesh_skin = xx json_get(*node_component.value.i64).*;
            case "weights";
                module_log("weights: %",     node_component.value.array.elements);
            case "extensions";
            case "extras";
            }
        }
    }
}

process_meshes_field :: (parser: *GLTF_Parser, element: JSON_Element_Container) {
    meshes := json_get(*element.value.array).elements;
    if meshes.count == 0 {
        // todo: fatal error
        return;
    }

    asset_meshes  := *context.gltf_asset.meshes;
    asset_meshes.* = gltf_alloc_array(Mesh, meshes.count);

    for mesh, mi : meshes {
        for mesh_component : json_get(*mesh.object).elements {
            key := json_get(*mesh_component.key.str).*;
            if key == {
            case "name";
                asset_meshes.*[mi].name = gltf_copy_string(json_get(*mesh_component.value.str).*);
            case "primitives";
                primitives := json_get(*mesh_component.value.array).elements;
                mesh_sections := *asset_meshes.*[mi].sections;
                mesh_sections.* = gltf_alloc_array(Mesh_Section, primitives.count);
                for prim, pi : primitives {
                    mesh_section := *(mesh_sections.*[pi]);
                    prim_fields := json_get(*prim.object).elements;
                    for field, fi : prim_fields {
                        key := json_get(*field.key.str).*;
                        if key == {
                        case "attributes";
                            attributes := json_get(*field.value.object).elements;
                            mesh_section.attributes = gltf_alloc_array(Mesh_Data_Attribute, attributes.count);
                            for attrib, ai : attributes {
                                attrib_key := json_get(*attrib.key.str).*;
                                attrib_value := json_get(*attrib.value.i64).*;
                                mesh_section.attributes[ai].accessor = xx attrib_value;
                                if attrib_key == {
                                case "POSITION";
                                    mesh_section.attributes[ai].type = .POSITION;
                                case "NORMAL";
                                    mesh_section.attributes[ai].type = .NORMAL;
                                case "TANGENT";
                                    mesh_section.attributes[ai].type = .TANGENT;
                                case "TEXCOORD_0";
                                    mesh_section.attributes[ai].type = .TEXCOORD_0;
                                case "TEXCOORD_1";
                                    mesh_section.attributes[ai].type = .TEXCOORD_1;
                                case "COLOR";
                                    mesh_section.attributes[ai].type = .COLOR;
                                case "JOINTS";
                                    mesh_section.attributes[ai].type = .JOINTS;
                                case "WEIGHTS";
                                    mesh_section.attributes[ai].type = .WEIGHTS;
                                }
                            }
                        case "indices";
                            mesh_section.indices  = xx json_get(*field.value.i64).*;
                        case "material";
                            mesh_section.material = xx json_get(*field.value.i64).*;
                        case;
                            // todo: error, unsupported
                        }
                    }
                }
            case;
                // todo: error
                module_log("unprocessed mesh component type: %", key);
            }
        }
    }
}

process_accessors_field :: (parser: *GLTF_Parser, element: JSON_Element_Container) {
    accessor_elems := json_get(*element.value.array).elements;
    if accessor_elems.count == 0 {
        // todo: nonfatal error
        return;
    }

    parser.accessors.data = alloc(size_of(Accessor_Internal) * accessor_elems.count,, temp);
    parser.accessors.count = accessor_elems.count;

    for accessor_elem, ai : accessor_elems {
        accessor_parts := json_get(*accessor_elem.object).elements;
        for part : accessor_parts {
            key := json_get(*part.key.str).*;
            if key == {
            case "name";
                parser.accessors[ai].name = gltf_copy_string(json_get(*part.value.str).*);
            case "bufferView";
                parser.accessors[ai].buffer_view = xx json_get(*part.value.i64).*;
            case "byteOffset";
                parser.accessors[ai].byte_offset = xx json_get(*part.value.i64).*;
            case "count";
                parser.accessors[ai].count = xx json_get(*part.value.i64).*;
            case "componentType";
                gltf_primitive := json_get(*part.value.i64).*;
                if gltf_primitive == {
                case 5120;
                    parser.accessors[ai].component_type = .S8;
                case 5121;
                    parser.accessors[ai].component_type = .U8;
                case 5122;
                    parser.accessors[ai].component_type = .S16;
                case 5123;
                    parser.accessors[ai].component_type = .U16;
                case 5125;
                    parser.accessors[ai].component_type = .U32;
                case 5126;
                    parser.accessors[ai].component_type = .F32;
                case;
                    // todo: fatal error unimplemented
                    return;    
                }
            case "type";
                type := json_get(*part.value.str).*;
                if type == {
                case "SCALAR";
                    parser.accessors[ai].type = .SCALAR;
                case "VEC2";
                    parser.accessors[ai].type = .VEC2;
                case "VEC3";
                    parser.accessors[ai].type = .VEC3;
                case "VEC4";
                    parser.accessors[ai].type = .VEC4;
                case "MAT2";
                    parser.accessors[ai].type = .MAT2;
                case "MAT3";
                    parser.accessors[ai].type = .MAT3;
                case "MAT4";
                    parser.accessors[ai].type = .MAT4;
                case;
                    // todo: fatal error unimplemented
                    return;
                }
            case "normalized";
            case "min";
            case "max";
            case "sparse";
                // todo: fatal error unimplemented
            case;
                // todo: nonfatal error
            }
        }
    }
}

process_buffer_views_field :: (parser: *GLTF_Parser, element: JSON_Element_Container) {
    buffer_view_elems := json_get(*element.value.array).elements;
    if buffer_view_elems.count == 0 {
        // todo: nonfatal error
        return;
    }

    parser.buffer_views.data = alloc(size_of(Buffer_View_Internal) * buffer_view_elems.count,, temp);
    parser.buffer_views.count = buffer_view_elems.count;

    for bv, bi : buffer_view_elems {
        bv_elems := json_get(*bv.object).elements;
        for elem : bv_elems {
            key := json_get(*elem.key.str).*;
            if key == {
            case "buffer";
                parser.buffer_views[bi].buffer = xx json_get(*elem.value.i64).*;
            case "byteOffset";
                parser.buffer_views[bi].byte_offset = xx json_get(*elem.value.i64).*;
            case "byteLength";
                parser.buffer_views[bi].byte_length = xx json_get(*elem.value.i64).*;
            case "byteStride";
                parser.buffer_views[bi].byte_stride = xx json_get(*elem.value.i64).*;
            case "target";
                parser.buffer_views[bi].target = xx json_get(*elem.value.i64).*;
            case;
                // todo: nonfatal error
            }
        }
    }
}

process_buffers_field :: (parser: *GLTF_Parser, element: JSON_Element_Container) {
    // unsupported
    // add_load_error(.BUFFERS_FIELD_UNIMPLEMENTED, get_file_position(element.key));
    // parser.any_load_failures = true;
}

process_materials_field :: (parser: *GLTF_Parser, element: JSON_Element_Container) {
    materials := json_get(*element.value.array).elements;
    
    material_buffer  := *context.gltf_asset.materials;
    material_buffer.* = gltf_alloc_array(Material, materials.count);
    
    for mat, mi : materials {
        material := *(material_buffer.*)[mi];
        for mat_prop, mpi : json_get(*mat.object).elements {
            key := json_get(*mat_prop.key.str).*;
            if key == {
            case "name";
                material.name = gltf_copy_string(json_get(*mat_prop.value.str).*);
            case "pbrMetallicRoughness";
                metallic_roughness := json_get(*mat_prop.value.object).elements;
                for mr_prop : metallic_roughness {
                    mr_prop_key := json_get(*mr_prop.key.str).*;
                    if mr_prop_key == {
                    case "baseColorTexture";
                        mr_prop_items := json_get(*mr_prop.value.object).elements;
                        for item : mr_prop_items {
                            item_key := json_get(*item.key.str).*;
                            if item_key == {
                            case "index";
                                material.albedo_texture = xx json_get(*item.value.i64).*;
                                material.flags |= .ALBEDO_TEXTURE_SET;
                            case;
                                // todo: nonfatal error
                            }
                        }
                    case "metallicRoughnessTexture";
                        mr_prop_items := json_get(*mr_prop.value.object).elements;
                        for item : mr_prop_items {
                            item_key := json_get(*item.key.str).*;
                            if item_key == {
                            case "index";
                                material.metallic_texture = xx json_get(*item.value.i64).*;
                                material.roughness_texture = xx json_get(*item.value.i64).*;
                                material.flags |= .METALLIC_TEXTURE_SET;
                                material.flags |= .ROUGHNESS_TEXTURE_SET;
                            case;
                                // todo: nonfatal error
                            }
                        }
                    case;
                        // todo: nonfatal error
                    }
                }
            case "normalTexture";
                normal_texture := json_get(*mat_prop.value.object).elements;
                for norm_prop : normal_texture {
                    norm_prop_key := json_get(*norm_prop.key.str).*;
                    if norm_prop_key == {
                    case "index";
                        material.normal_texture = xx json_get(*norm_prop.value.i64).*;
                        material.flags |= .NORMAL_TEXTURE_SET;
                    case;
                        // todo: nonfatal error
                    }
                }
            case;
                // todo: nonfatal error
            }
        }
    }
}

process_textures_field :: (parser: *GLTF_Parser, element: JSON_Element_Container) {
    texture_elems := json_get(*element.value.array).elements;
    if texture_elems.count == 0 {
        // todo: nonfatal error
    }

    using context.gltf_asset;
    textures = gltf_alloc_array(Texture, texture_elems.count);

    for texture_elem, ti : texture_elems {
        texture_elem_obj_elems := json_get(*texture_elem.object).elements;
        for elem : texture_elem_obj_elems {
            elem_key := json_get(*elem.key.str).*;
            if elem_key == {
            case "source";
                textures[ti].image = xx json_get(*elem.value.i64).*;
            case "sampler";
                // todo: nonfatal error
            case;
                // todo: nonfatal error
            }
        }
    }
}

process_images_field :: (parser: *GLTF_Parser, element: JSON_Element_Container) {
    image_elems := json_get(*element.value.array).elements;
    if image_elems.count == 0 {
        // todo: nonfatal error
    }

    using context.gltf_asset;
    images = gltf_alloc_array(Image, image_elems.count);

    for image_elem, imgi : image_elems {
        image_elem_obj_elems := json_get(*image_elem.object).elements;
        for elem : image_elem_obj_elems {
            key := json_get(*elem.key.str).*;
            if key == {
            case "mimeType";
                images[imgi].mime_type = json_get(*elem.value.str).*;
            case "bufferView";
                (cast(*Image_Internal) *images[imgi])._internal_buffer_view = xx json_get(*elem.value.i64).*;
            case;
                // todo: nonfatal error
            }
        }
    }
}

process_samplers_field :: (parser: *GLTF_Parser, element: JSON_Element_Container) {
    // unsupported
    // add_load_error(.SAMPLERS_FIELD_UNIMPLEMENTED, get_file_position(element.key));
    // parser.any_load_failures = true;
}

process_animations_field :: (parser: *GLTF_Parser, element: JSON_Element_Container) {
    // unsupported
    // add_load_error(.ANIMATIONS_FIELD_UNIMPLEMENTED, get_file_position(element.key));
    // parser.any_load_failures = true;
}

process_skins_field :: (parser: *GLTF_Parser, element: JSON_Element_Container) {
    // unsupported
    // add_load_error(.SKINS_FIELD_UNIMPLEMENTED, get_file_position(element.key));
    // parser.any_load_failures = true;
}

process_cameras_field :: (parser: *GLTF_Parser, element: JSON_Element_Container) {
    // unsupported
    // add_load_error(.CAMERAS_FIELD_UNIMPLEMENTED, get_file_position(element.key));
    // parser.any_load_failures = true;
}

process_extensions_field :: (parser: *GLTF_Parser, element: JSON_Element_Container) {
    // unsupported
    // add_load_error(.EXTENSIONS_FIELD_UNIMPLEMENTED, get_file_position(element.key));
    // parser.any_load_failures = true;
}

process_extensions_used_field :: (parser: *GLTF_Parser, element: JSON_Element_Container) {
    // unsupported
    // add_load_error(.EXTENSIONS_USED_FIELD_UNIMPLEMENTED, get_file_position(element.key));
    // parser.any_load_failures = true;
}

process_extensions_required_field :: (parser: *GLTF_Parser, element: JSON_Element_Container) {
    // unsupported
    // add_load_error(.EXTENSIONS_REQUIRED_FIELD_UNIMPLEMENTED, get_file_position(element.key));
    // parser.any_load_failures = true;
}

process_extras_field :: (parser: *GLTF_Parser, element: JSON_Element_Container) {
    // unsupported
    // add_load_error(.EXTRAS_FIELD_UNIMPLEMENTED, get_file_position(element.key));
    // parser.any_load_failures = true;
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
    using context;
    auto_release_temp();

    if parse_success && shrink_allocations && gltf_load_result.allocator.proc != temp.proc {

    }

    gltf_load_result.errors = gltf_errors;

    // todo: seems like the file text part o this and the json error reporting could be part of File

    for *err : gltf_errors {
        err.flags &= ~.INTERNAL_UNPROCESSED;

        if log_errors {
            remaining_bytes := max(0, parser.json_chunk.bytes.count - err.file_position);
            display_bytes := min(remaining_bytes, 32);
            json_file_context := string.{display_bytes, parser.json_chunk.bytes.data + err.file_position};

            module_log(
#string HERE


error code : %
flags      : %
file pos   : %
file text  : %
             ^
HERE,
                err.code, 
                err.flags, 
                err.file_position,
                json_file_context
            );
        }
    }
}

// -----------------------------------------------------------------------------------
// ------------------------------------------------------------------------ :buffering

init_buffer :: () {
    using context;
    if gltf_buffer.data == null {
        assert(gltf_buffer_data.data == null);
        BUFFER_SIZE :: 512 * 1024; // 512KB
        gltf_buffer_data.data = alloc(BUFFER_SIZE,,context.default_allocator);
        gltf_buffer_data.count = BUFFER_SIZE;
    }

    gltf_buffer.data = gltf_buffer_data.data;
    gltf_buffer.count = 0;
    gltf_zero_next_buffer_chunk();
}

gltf_zero_next_buffer_chunk :: inline () -> bool {
    using context;
    prev_zero_mark := gltf_buffer_zero_mark;
    gltf_buffer_zero_mark += gltf_buffer_data.count / 16;
    gltf_buffer_zero_mark = min(gltf_buffer_zero_mark, gltf_buffer_data.count);
    zero_byte_count := gltf_buffer_zero_mark - prev_zero_mark;
    if zero_byte_count > 0 {
        memset(gltf_buffer_data.data + prev_zero_mark, 0, zero_byte_count);
        return true;
    } else return false;
}

gltf_alloc :: (size: int, align := 1) -> *u8 {
    using context;
    
    buffer_pos := gltf_buffer.count;
    buffer_pos_plus_align_offset := ceil_to_power_of_two_multiple(buffer_pos, align);
    align_offset := buffer_pos_plus_align_offset - buffer_pos;

    new_buffer_end := gltf_buffer.count + align_offset + size;

    while new_buffer_end > gltf_buffer_zero_mark {
        if !gltf_zero_next_buffer_chunk() {
            return null;
        }
    }
    
    gltf_buffer.count = new_buffer_end;
    return gltf_buffer.data + buffer_pos_plus_align_offset;
}

gltf_alloc_array :: ($T: Type, count: int) -> []T {
    TYPE_ALIGN :: #run align_of(T);

    array: []T = ---;
    array.data = xx gltf_alloc(size_of(T) * count, TYPE_ALIGN);
    array.count = ifx array.data == null then 0 else count;

    ini :: initializer_of(T);

    // initialize only the structs that have nonzero values by default
    // the buffer is zeroed already.
    for *array {
        // if the type has an initializer, initialize, otherwise it already has zeroed memory.
        // confirmed that types without '=' expressions in their definitions don't have initializers
        #if ini {
            it.* = {};
        }

        // insert special initialization for internal versions of structs, such as Material_Internal
        #insert -> string {
            special_instructions: String_Builder;

            internal_type: Type = void;
            for INTERNAL_ASSET_TYPE_REGISTRY {
                if it.asset_type == T {
                    internal_type = it.internal_type;
                    break;
                }
            }

            if internal_type == void {
                internal_type = T;
            }

            tinfo_struct_internal := cast(*Type_Info_Struct) internal_type;
            for member : tinfo_struct_internal.members {
                if member.type.type == .POINTER {
                    // initialize an internal index field to -1
                    print(*special_instructions, 
#string HERE
        {
            internal_index_field := (it.(*u8) + %).(*s32);
            internal_index_field.* = -1;
        }
HERE,
                        member.offset_in_bytes
                    );
                } else for note : member.notes {
                    if note == {
                    case "u8_zero_init";
                        // initialize an internal byte field to 0
                        print(*special_instructions, 
#string HERE
        {
            internal_u8_field := it.(*u8) + %;
            internal_u8_field.* = -1;
        }
HERE,
                            member.offset_in_bytes
                        );
                    }
                }
            }

            return builder_to_string(*special_instructions);
        }
    }

    return array;
}

gltf_alloc_string :: (count: int) -> string {
    str: string = ---;
    str.data = gltf_alloc(count);
    str.count = ifx str.data == null then 0 else count;
    return str;
}

gltf_copy_string :: (in_str: string) -> string {
    str := gltf_alloc_string(in_str.count);
    memcpy(str.data, in_str.data, min(str.count, in_str.count));
    return str;
}

// -----------------------------------------------------------------------------------
// ----------------------------------------------------------------------------- :misc

module_log :: (fmt: string, args: ..Any) #expand {
    trm_log(fmt=fmt, args=..args, header="TeRM/glTF");
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

read_string_up_to :: inline (using parser: *GLTF_Parser, max_read_count: int) -> string {
    str := to_string_safe(file.data + pos, max_read_count);
    // advances by 4 anyway, because this proc is used in a context where the string is <= 4 bytes,
    // but the next item is always 4 bytes away.
    pos += 4;
    return str;
}

read_string :: inline (using parser: *GLTF_Parser, count: int) -> string {
    str := to_string(file.data + pos, count);
    pos += xx count;
    return str;
}

// -----------------------------------------------------------------------------------
// ------------------------------------------------------------------- :internal types

// internal types used for things like internal flags and using integer indexes
// instead of pointers until post-processing.

// nodes like 'index_init' tell the array allocator to put a -1 on the field, indicating no index.
// #overlay doesn't allow initializing values on the struct definition.
// that used to be a thing you could do, but it was understandably taken out.

Internal_Asset_Type_Registry_Item :: struct {
    asset_type: Type;
    internal_type: Type;
}

// this list needs to be kept current with alternative types that do internal things
INTERNAL_ASSET_TYPE_REGISTRY :: Internal_Asset_Type_Registry_Item.[
    {Scene_3D, Scene_3D_Internal},
];

Scene_3D_Internal :: struct {
    using #as scene_3d: Scene_3D;
    #overlay(scene_3d.transform) using trs: struct {
        _internal_translation: Vector3;
        _internal_rotation: Quaternion;
        _internal_scale: Vector3;
        // the file data may have these pos/rot/scale instead of a matrix,
        // for now anyway, this is only for internal processing. always matrix.
        _internal_transform_flags: enum_flags u8 { 
            TRANSLATION; 
            ROTATION;
            SCALE;
            MATRIX;
        }; @u8_zero_init
    };
}

Buffer_View_Internal :: struct {
    buffer: s32;
    byte_length: s32;
    byte_offset: s32;
    byte_stride: s32;
    target: s32;
}

Accessor_Internal :: struct {
    name: string; // DO NOT FORGET to ship this name with something in the asset
    buffer_view: s32;
    byte_offset: s32;
    count: s32;
    component_type: Mesh_Data_Primitive;
    type: Mesh_Data_Shape;// rename -> shape
    normalized: bool;// rename -> normalized_integers
    min: float32;
    max: float32;
    // sparse: ?
}

Image_Internal :: struct {
    using #as image: Image;
    #overlay(image.cpu_allocation.data) _internal_buffer_view: *Buffer_View_Internal;
}

// errors are cleared and added per-load and per-save, for each thread. 
// if the number of errors maxes out, errors are no longer stored.
// adding these to the context so they can be thread-local, allowing for multithreaded processing
#add_context gltf_asset:              *Asset_3D;
#add_context gltf_error_buffer:       [32]GLTF_Error;
#add_context gltf_errors:             [..]GLTF_Error;
#add_context gltf_load_result:        GLTF_Load_Result;
#add_context gltf_parser:             *GLTF_Parser;
#add_context gltf_buffer:             []u8;
#add_context gltf_buffer_data:        []u8;
#add_context gltf_buffer_zero_mark:   int;


#import "Basic";
#import "File";
#import "String";
#import "Math";
#import "Compiler";

#import "TeRM/TeRM_JSON";
#import "TeRM/TeRM_Log";
#import "TeRM/TeRM_String";
#import "TeRM/TeRM_Metaprogram";
#import "TeRM/TeRM_Asset3D";
#import "TeRM/TeRM_Math";
#import "TeRM/TeRM_LogHelpers";
#import "TeRM/TeRM_Color";
#import "TeRM/TeRM_Camera";
