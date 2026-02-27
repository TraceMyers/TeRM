// do not use this. it's mid-development
// why is it here? because it doesn't hurt anybody

// todo: logging. add another bool that is set true at beginning and defer if true then 
// iterate over errors and log them.

GLB_Error_Code :: enum u16 {
    FAILED_TO_LOAD_FILE;
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
}

GLB_Error_Flags :: enum_flags u16 {
    FATAL;
}

GLB_Error :: struct {
    code: GLB_Error_Code; 
    flags: GLB_Error_Flags;
    file_location: s32;
}

GLB_Load_Result :: struct {
    file_size: s32;
    // if there are any errors, they will be in this list. errors are not necessarily
    // fatal. if fatal, they will be marked. fatal errors mark an unsucessful load.
    // this array points into a buffer owned by the module, and it's valid until 
    // the next load or save.
    errors: []GLB_Error;
    // if any errors caused loading to exit early, this will be true. if so,
    // the final error in the list is guaranteed to be a fatal one, but not necessarily the
    // inciting error. if the error list is truncated, the fatal error replaced a non-fatal one. 
    any_fatal_errors: bool;
    // if adding more errors would have overflowed the internal buffer, this is set
    errors_truncated: bool;
}

// alt name
load_glb :: load_glb_from_file;

load_glb_from_file :: (file_path: string, log_errors := false) -> GLB_Load_Result {
    glb_init_load();

    mark := get_temporary_storage_mark();
    defer if context.allocator.proc != temp.proc then set_temporary_storage_mark(mark);

    file_bytes, success = read_entire_file(request.file_path, log_errors=log_errors,, temp);

    if !success {
        add_load_error(.FAILED_TO_LOAD_FILE, 0, .TERMINAL);
        return context.glb_load_result;
    }

    return load_glb_from_string(request, log_errors);
}

// this data is assumed to be valid for at least the header bytes (12), and overall
// however many bytes are described in the header.
// proc exists in case you want to pack multiple files into one, or multithread the parsing.
load_glb_from_bytes :: (file_data: *u8, log_errors := false) -> GLB_Load_Result {
    glb_init_load();

    header: GLB_Header;
    success := read_glb_file_header(file_data);
    if !success {
        return context.glb_load_result;
    }

    return load_glb_from_string({header.length, file_data}, *header, log_errors);
}

// if already_loaded_header is non-null, file_data is still assumed to point to the top of the file, but
// those bytes are skipped. this is mainly just so _from_bytes can use _from_string.
load_glb_from_string :: (file_data: string, already_loaded_header: *GLB_Header = null, log_errors := false) -> GLB_Load_Result {
    glb_init_load();

    if file_data.count < 12 {
        add_load_error(.FILE_TOO_SMALL_FOR_HEADER, 0, .FATAL);
        return context.glb_load_result;
    }

    header: GLB_Header;
    if already_loaded_header {
        header = already_loaded_header.*;
    } else {
        success := read_glb_file_header(file_data.data, *header);
        if !success then return context.glb_load_result;
    }

    reported_file_size := header.length;
    if reported_file_size != bytes.count {
        add_load_error(.FILE_SIZE_DOES_NOT_MATCH_SIZE_REPORTED_IN_HEADER, 8);
    }

    ser: Serializer(.BYTE, .STATIC);
    initialize(*ser, .READ, bytes);
    ser.head = 12; // skip past header
 
    known_chunk_count := 0;

    while true {
        chunk, end_read := read_chunk;
        if end_read then break;

        chunk_type := as_string(chunk.type);
        chunk_location := ser.head - bytes.count - 8;

        if chunk.type == "JSON" {
            if chunk_index != 0 {
                add_load_error(.JSON_CHUNK_NOT_AT_INDEX_0, chunk_location, .FATAL);
                break;
            }
            known_chunk_count += 1;
        } else if chunk.type = "BIN" {
            if chunk_index != 1 {
                add_load_error(.BIN_CHUNK_NOT_AT_INDEX_1, chunk_location, .FATAL);
                break;
            }
            known_chunk_count += 1;
        } else {
            // the spec says to ignore unkown chunk types
            add_load_error(.UNKNOWN_CHUNK_TYPE_AT_FILE_LOCATION, chunk_location, .FATAL); 
            break;
        }
    }
    
    if known_chunk_count == 0 {
        add_load_error(.JSON_CHUNK_MISSING, 12, .FATAL);
    }

    return context.glb_load_result;   
}

#scope_file

read_glb_file_header :: (bytes: *u8, header: *GLB_Header) -> valid_header: bool {
    header.magic.data   = bytes;
    header.magic.count  = 4;
    header.version      = (cast(u32*) (bytes + 4)).*;
    header.length       = (cast(u32*) (bytes + 8)).*;
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

read_chunk :: (ser: *Serializer) -> chunk: GLB_Chunk, end_read: bool {
    // ---

    try_advance_head_or_return :: (ser: *Serializer, by_amt: s64) #expand {
        advance_head_success = advance_head(ser, by_amt);
        if !advance_head_success {
            add_load_error(.READING_CHUNK_OVERFLOWS_FILE, ser.head, .FATAL);
            `return chunk, true;
        }
    }

    // ---

    // all chunks are 4-byte aligned.
    align_head_up(ser, 4);

    chunk: GLB_Chunk;
    chunk_length: u32;

    if ser.head >= ser.memory.count {
        // after alignment, at or past end of file, indicating read end
        return chunk, true;
    }

    read(ser, *chunk_length);

    if chunk_length == 0 {
        add_load_error(.READ_CHUNK_LENGTH_0, ser.head-4);
        return chunk, false;
    }

    chunk.type.data = ser.memory.data + ser.head;
    chunk.type.count = c_style_strlen(chunk.type.data);
    try_advance_head_or_return(ser, 4);

    chunk.bytes.data = ser.memory.data + ser.head;
    chunk.bytes.count = chunk_length;
    try_advance_head_or_return(ser, chunk_length);

    return chunk, false;
}

as_string :: inline (bytes: []u8) -> string {
    return string.{count=bytes.count, data=bytes.data};
}

GLB_Header :: struct {
    magic: string;
    version: u32;
    length: u32;
}

GLB_Chunk :: struct {
    type: string;
    bytes: []u8;
}

add_load_error :: (code: GLB_Error_Code, file_location: s64, flags: GLB_Error_Flags = 0) {
    using context;
    if error.flags & .FATAL {
        glb_load_result.any_fatal_errors = true;
    }
    if glb_errors.count == glb_error_buffer.count {
        if glb_load_result.any_fatal_errors {
            // make sure at least the final fatal error is recorded, even if the errors are truncated.
            glb_error_buffer[glb_error_buffer.count-1] = error;
        }
        glb_load_result.errors_truncated = true;
        return;
    }
    array_add(*glb_errors, {code, flags, xx file_location});
}

glb_init_load :: () #expand {
    using context;

    `defer context.glb_load_initialized = false;
    `defer context.glb_load_result.errors = context.glb_errors;

    // making sure errors don't get reset when non-fatal errors occur during 
    // initial wrapper procedures
    if !glb_load_initialized { 
        glb_load_result = {};
        glb_errors.data = glb_error_buffer.data;
        glb_errors.count = 0;
        glb_errors.allocated = glb_error_buffer.count;
        glb_errors.allocator = {proc=glb_error_dummy_allocator_proc};
        glb_load_initialized = true;
    }
}

// errors are cleared and added per-load and per-save, for each thread. 
// if the number of errors maxes out, errors are no longer stored.
// adding these to the context so they can be thread-local, allowing for multithreaded processing
#add_context glb_error_buffer:       [32]GLB_Error;
#add_context glb_errors:             [..]GLB_Error;
#add_context glb_load_result:        GLB_Load_Result;
#add_context glb_load_initialized:   bool;

glb_error_dummy_allocator_proc :: (mode: Allocator_Mode, size: s64, old_size: s64, old_memory: *void, allocator_data: *void) -> *void { return null; }

#import "File";
#import "String";

#import "TeRM/TeRM_Serialize";
