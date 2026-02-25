
load_glb_from_file :: (file_path: string) -> bool {
    file_bytes := read_entire_file(file_path);
    return load_glb_from_bytes(file_bytes);
}

load_glb_from_bytes :: (bytes: string) -> bool {
    // ---


    // ---

    if bytes.count < 12 {
        return false;
    }

    ser: Serializer(.BYTE, .STATIC);
    initialize(*ser, .READ, bytes);

    header: GLB_Header = ---;
    read(*ser, *header);
    
    if as_string(header.magic) != "glTF" {
        return false;
    }
    if header.version != 2 {
        return false;
    }

    // maybe warning instead
    reported_file_size := header.length;
    if reported_file_size != bytes.count {
        return false;
    }

    while true {
        chunk, valid, eof := read_chunk;
        if eof then break;


    }
}

#scope_file

read_chunk :: (ser: *Serializer) -> chunk: GLB_Chunk, valid: bool, eof: bool {
    // all chunks are 4-byte aligned.
    align_head_up(ser, 4);

    // if, after alignment, we moved up to the end of the file, return that information
    if ser.head >= ser.memory.count {
        return {}, false, true;
    }

    chunk: GLB_Chunk;
    chunk_length: u32;

    read(ser, *chunk_length);

    if chunk_length == 0 {
        return chunk, false, false;
    }

    read_bytes(ser, chunk.type_bytes.data, 4);
    chunk_type_str := as_string(chunk.type);

    if chunk_type_str == 
    case "BIN";
        chunk.type = .BIN;
    case "JSON";
        chunk.type = .JSON;
    case;
        return chunk, false, false;
    }

    chunk.bytes.data = ser.memory.data + ser.head;
    chunk.bytes.count = chunk_length;

    advance_head_success := advance_head(ser, chunk_length);

    return chunk, advance_head_success, false;
}

GLB_Header :: struct {
    magic: [4]u8;
    version: u32;
    length: u32;
}

GLB_Chunk :: struct {
    bytes: []u8;
    type: enum u32 {JSON; BIN;};
    type_bytes: [4]u8;
}

as_string :: inline (bytes: []u8) -> string {
    return string.{count=bytes.count, data=bytes.data};
]

#import "File"
#import "TeRM/TeRM_Serialize";
#import "TeRM/TeRM_Log";
