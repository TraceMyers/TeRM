// --- sections ---
// Types and Constants
// Init
// Convenience Procs
// Primitives
// Dynamic Arrays
// Arrays
// Strings
// Bytes
// Helpers
// Byte Reversing for Net Serialization
// Internal Helpers

// -----------------------------------------------------------------------------------
// -------------------------------------------------------------- :Types and Constants

SERIALIZER_CHECKSUM_SIZE :: 32;
CHECKSUM_UINT32_COUNT :: SERIALIZER_CHECKSUM_SIZE / 4;
Serializer_Checksum_Type :: [CHECKSUM_UINT32_COUNT]u32;

Rw_Mode :: enum u8 {
    WRITE;
    READ;
}

Serializer :: struct($alloc_mode: Serializer_Alloc_Mode = .STATIC, $align_mode: Serializer_Align_Mode = .BYTE) {
    memory: string;
    allocator: Allocator; // only used if dynamic
    // used only when reading out arrays. if not set, will default to using the above allocator.
    read_array_allocator: Allocator; 
    head: s64;
    parameter_align : u8 = 1; // must be power of 2 if used
    rw_mode: Rw_Mode;
    pad_for_checksum := false;
#overlay(memory) // for debug
    memory_count: s64; 
    memory_data: *u8;
    reverse_byte_order: bool;
}

Serializer_Alloc_Mode :: enum u8 {
    STATIC;
    DYNAMIC;
}

Serializer_Align_Mode :: enum u8 {
    BYTE;
    PRIMITIVE;
    PARAMETER;
}

// -----------------------------------------------------------------------------------
// ----------------------------------------------------------------------------- :Init

initialize :: (using buffer: *Serializer, use_checksum := false, reverse_primitive_byte_order := false) {
    head = 0;
    rw_mode = .WRITE;
    pad_for_checksum = use_checksum;
    reverse_byte_order = reverse_primitive_byte_order;
}

// should be called after pad_for_checksum is set, if it is being set
set_rw_mode :: (using buffer: *Serializer, m: Rw_Mode) {
    rw_mode = m;
    if pad_for_checksum {
        head = SERIALIZER_CHECKSUM_SIZE;
    } else {
        head = 0;
    }
}

reset :: (using buffer: *Serializer, keep_allocation := true) {
    if !keep_allocation {
        if memory.data != null {
            free(memory.data);
            memory.data = null;
        }
        memory.count = 0;
    }
    initialize(buffer, pad_for_checksum, reverse_byte_order);
}

// -----------------------------------------------------------------------------------
// ---------------------------------------------------------------- :Convenience Procs

write               :: #bake_arguments serialize_primitive(mode=.WRITE);
read                :: #bake_arguments serialize_primitive(mode=.READ);
write_array         :: #bake_arguments serialize_array(mode=.WRITE);
read_array          :: #bake_arguments serialize_array(mode=.READ);
write_array_data    :: #bake_arguments serialize_array_data(mode=.WRITE);
read_array_data     :: #bake_arguments serialize_array_data(mode=.READ);
write_string        :: #bake_arguments serialize_string(mode=.WRITE);
read_string         :: #bake_arguments serialize_string(mode=.READ);
write_bytes         :: #bake_arguments serialize_bytes(mode=.WRITE);
read_bytes          :: #bake_arguments serialize_bytes(mode=.READ);

read_out :: inline (using buffer: *Serializer, $T: Type) -> T 
#modify {
    return is_serial_primitive(T);
} {
    item: T = ---;
    read(buffer, *item);
    if reverse_byte_order {
        item_copy := item;
        reverse_bytes((*item).(*u8), (*item_copy).(*u8), size_of(T));
    }
    return item;
}

// -----------------------------------------------------------------------------------
// ----------------------------------------------------------------------- :Primitives

serialize :: (using buffer: *Serializer, item: *$T) 
#modify {
    return is_serial_primitive(T);
} {
    if rw_mode == .WRITE {
        serialize_primitive(buffer, item, .WRITE);
    } else {
        serialize_primitive(buffer, item, .READ);
    }
}

serialize_primitive :: (using buffer: *Serializer, item: *$T, $mode: Rw_Mode) 
#modify {
    return is_serial_primitive(T);
} {
    validate_read_write();
    align_head_up_for_type(buffer, T);
    new_head := head + size_of(T);
    check_new_head(buffer, new_head);
    
    #if mode == .WRITE {
        write_primitive(buffer, item);
    } else {
        read_primitive(buffer, item);
    }

    head = new_head;
}

// -----------------------------------------------------------------------------------
// ------------------------------------------------------------------- :Dynamic Arrays

serialize :: (using buffer: *Serializer, array: *[..]$T) 
#modify {
    return is_serial_primitive(T);
} {
    if rw_mode == .WRITE {
        serialize_dynamic_array(buffer, array, .WRITE);
    } else {
        serialize_dynamic_array(buffer, array, .READ);
    }
}

serialize :: (using buffer: *Serializer, array: *[..]$T, array_count: s64) 
#modify {
    return is_serial_primitive(T);
} {
    if rw_mode == .WRITE {
        serialize_dynamic_array_data(buffer, array, array_count, .WRITE);
    } else {
        serialize_dynamic_array_data(buffer, array, array_count, .READ);
    }
}

serialize_dynamic_array :: (using buffer: *Serializer, array: *[..]$T, $mode: Rw_Mode)
#modify {
    return is_serial_primitive(T);
} {
    array_count: s64 = xx array.count;
    serialize_primitive(buffer, *array_count, mode);
    serialize_dynamic_array_data(buffer, array, array_count, mode);
}

serialize_dynamic_array_data :: (using buffer: *Serializer, array: *[..]$T, array_count: s64, $mode: Rw_Mode)
#modify {
    return is_serial_primitive(T);
} {
    validate_read_write();
    if array_count == 0 {
        return;
    }
    align_head_up_for_type(buffer, T);
    array_size := size_of(T) * array_count;
    new_head := head + array_size;
    check_new_head(buffer, new_head);
    #if mode == .WRITE {
        memcpy(memory.data + head, array.data, array_size);
    } else {
        if array.data == null {
            array_resize(array, array_count, false);
        } else {
            assert(array.count >= array_count);
        }
        memcpy(array.data, memory.data + head, array_size);
    }
    head = new_head;
}

// -----------------------------------------------------------------------------------
// --------------------------------------------------------------------------- :Arrays

serialize :: (using buffer: *Serializer, array: *[]$T) 
#modify {
    return is_serial_primitive(T);
} {
    if rw_mode == .WRITE {
        serialize_array(buffer, array, .WRITE);
    } else {
        serialize_array(buffer, array, .READ);
    }
}

serialize :: (using buffer: *Serializer, array: *[]$T, array_count: s64) 
#modify {
    return is_serial_primitive(T);
} {
    if rw_mode == .WRITE {
        serialize_array_data(buffer, array, array_count, .WRITE);
    } else {
        serialize_array_data(buffer, array, array_count, .READ);
    }
}

serialize_array :: (using buffer: *Serializer, array: *[]$T, $mode: Rw_Mode)
#modify {
    return is_serial_primitive(T);
} {
    array_count: s64 = xx array.count;
    serialize_primitive(buffer, *array_count, mode);
    serialize_array_data(buffer, array, array_count, mode);
}

serialize_array_data :: (using buffer: *Serializer, array: *[]$T, array_count: s64, $mode: Rw_Mode)
#modify {
    return is_serial_primitive(T);
} {
    validate_read_write();
    if array_count == 0 {
        return;
    }
    align_head_up_for_type(buffer, T);
    array_size := size_of(T) * array_count;
    new_head := head + array_size;
    check_new_head(buffer, new_head);
    #if mode == .WRITE {
        #if alloc_mode != .DYNAMIC {
            assert(memory.count >= new_head);
        }
        memcpy(memory.data + head, array.data, array_size);
    } else {
        if array.data == null {
            use_allocator := ifx read_array_allocator.proc != null then read_array_allocator else allocator;
            array.data = xx alloc(size_of(T) * array_count,, use_allocator);
            array.count = array_count;
        }
        assert(array.count >= array_count);
        memcpy(array.data, memory.data + head, array_size);
    }
    head = new_head;
}

// -----------------------------------------------------------------------------------
// -------------------------------------------------------------------------- :Strings

serialize :: (using buffer: *Serializer, str: *string) {
    if rw_mode == .WRITE {
        serialize_string(buffer, str, .WRITE);
    } else {
        serialize_string(buffer, str, .READ);
    }
}

serialize_string :: (using buffer: *Serializer, str: *string, $mode: Rw_Mode) {
    assert(rw_mode == mode);
    array: []u8;
    #if mode == .WRITE {
        array.data = str.data;
        array.count = str.count;
        serialize_array(buffer, *array, .WRITE);
    } else {
        serialize_array(buffer, *array, .READ);
        str.data = array.data;
        str.count = array.count;
    }
}

// -----------------------------------------------------------------------------------
// ---------------------------------------------------------------------------- :Bytes

serialize :: (using buffer: *Serializer, data: *u8, count: s64) {
    if rw_mode == .WRITE {
        serialize_bytes(buffer, data, xx count, .WRITE);
    } else {
        serialize_bytes(buffer, data, xx count, .READ);
    }
}

serialize_bytes :: inline (using buffer: *Serializer, data: *u8, count: s64, $mode: Rw_Mode) {
    array: []u8 = ---;
    array.count = xx count;
    array.data = data;
    serialize_array_data(buffer, *array, count, mode);
}

// -----------------------------------------------------------------------------------
// -------------------------------------------------------------------------- :Helpers

// warning: this can't reverse bytes, if that function is needed
write_entire_file :: (name: string, buffer: *Serializer) -> bool {
    str := string.{buffer.head, buffer.memory.data};
    return write_entire_file(name, str);
}

view_bytes_before_head :: (using buffer: *Serializer) -> string {
    return string.{head, memory.data};
}

validate_checksum :: no_inline (using buffer: *Serializer) -> bool {
    assert(pad_for_checksum);
    assert(memory.count > SERIALIZER_CHECKSUM_SIZE);
    calculated: [CHECKSUM_UINT32_COUNT]u32;
    calculate_checksum(buffer, calculated.data);
    have : *[CHECKSUM_UINT32_COUNT]u32 = xx memory.data;
    for 0..CHECKSUM_UINT32_COUNT-1 {
        if have.*[it] != calculated[it] then return false;
    }
    return true;
}

imprint_checksum :: (using buffer: *Serializer) {
    assert(pad_for_checksum);
    assert(memory.count > SERIALIZER_CHECKSUM_SIZE);
    calculate_checksum(buffer, xx memory.data);
}

calculate_checksum :: (using buffer: *Serializer, out: *u32) {

    // --- 

    calc_checksum_impl :: (bufstr: string, out: *u32) {
        str := md5(bufstr);
        array: []u32;
        array.data = xx str.data;
        array.count = str.count / 4;
        assert(array.count == CHECKSUM_UINT32_COUNT);
        memcpy(out, array.data, size_of(u32) * CHECKSUM_UINT32_COUNT);
    }

    // --- 

    assert(pad_for_checksum);
    assert(memory.count > SERIALIZER_CHECKSUM_SIZE);
    assert(head >= SERIALIZER_CHECKSUM_SIZE);
    bufstr := string.{memory.count - SERIALIZER_CHECKSUM_SIZE, memory.data + SERIALIZER_CHECKSUM_SIZE};

    auto_release_temp();
    calc_checksum_impl(bufstr, out,,temp);
}

align_head_up :: (using buffer: *Serializer, align: u8) {
    new_head := ceil_to_pow2_multiple(head, align);
    diff := new_head - head;
    if diff > 0 {
        advance_head(buffer, diff);
    } else assert(diff == 0);
}

check_new_head :: (using buffer: *Serializer, new_head: s64) {
    // ---

    realloc :: (desired_capacity: s64, memory: *string) {
        new_memory := alloc_string(desired_capacity);
        memcpy(new_memory.data, memory.data, memory.count);
        free(memory.data);
        memory.* = new_memory;
    }

    // ---

    assert(new_head >= 0);
    #if alloc_mode == .STATIC {
        assert(new_head <= memory.count, "old head: %, new head: %, memory.count: %", head, new_head, memory.count);
    } else { // DYNAMIC
        desired_capacity := max(ceil_to_pow2_multiple(new_head, 2), 256);
        if memory.count < desired_capacity {
            if allocator.proc == null {
                allocator = context.default_allocator;
            }
            realloc(desired_capacity, *memory,, allocator);
        }
    }
}

advance_head :: inline (using buffer: *Serializer, by_count: s64) {
    new_head := head + by_count;
    assert(by_count > 0);
    assert(head >= 0 && head <= memory.count);
    assert(new_head <= memory.count);
    head = new_head;
}

align_head_up_for_type :: (using buffer: *Serializer, $T: Type) {
    align_head_up(buffer, serial_primitive_alignment(buffer, T));
}

align_head_up_for_array :: (using buffer: *Serializer, $T: Type) {
    #if #complete align_mode == {
    case .PRIMITIVE;
        align_head_up(buffer, 4);
    case .PARAMETER;
        align_head_up(buffer, parameter_align);
    case .BYTE;
    }
}

// -----------------------------------------------------------------------------------
// --------------------------------------------- :Byte Reversing for Net Serialization

// iterate over struct members and reverse bytes of each member. NOT recursive. todo: maybe should be recursive
reverse_bytes :: (in: *$T) 
#modify {
    tinfo := T.(*Type_Info);
    return tinfo.type == .STRUCT;
} {
    byte_buffer: [size_of(T)]u8 = ---;
    memcpy(byte_buffer.data, in, size_of(T));

    for info : T.(*Type_Info_Struct).members {
        in\_field_ptr := byte_buffer.data + info.offset_in_bytes;
        out_field_ptr := in.(*u8) + info.offset_in_bytes;
        for 0..info.type.runtime_size-1 {
            out_field_ptr[it] = in_field_ptr[(info.type.runtime_size-1) - it];
        }
    }
}

reverse_bytes :: inline (in: $T) -> T
#modify {
    tinfo := T.(*Type_Info);
    if tinfo.type == {
    case .INTEGER; 
        #through;
    case .FLOAT; 
        #through;
    case .BOOL; 
        #through;
    case .ENUM;
        return true;
    }
    return false;
} {
    out: T = ---;
    TYPE_SIZE :: #run T.(*Type_Info).runtime_size;
    #if TYPE_SIZE == {
    case 1;
        return in;
    case;
        reverse_bytes((*out).(*u8), (*in).(*u8), TYPE_SIZE);
    }
    return out;
}

reverse_bytes :: (bytes_out: *u8, bytes_in: *u8, size: s64) {
    assert(size > 0);
    if size == {
    case 1;
        bytes_out.* = bytes_in.*;
    case 2;
        bytes_out[0], 
        bytes_out[1]  = 
                        bytes_in[1], 
                        bytes_in[0];
    case 4;
        bytes_out[0],
        bytes_out[1],
        bytes_out[2],
        bytes_out[3]  =
                        bytes_in[3],
                        bytes_in[2],
                        bytes_in[1],
                        bytes_in[0];
    case 8;
        bytes_out[0],
        bytes_out[1],
        bytes_out[2],
        bytes_out[3],
        bytes_out[4],
        bytes_out[5],
        bytes_out[6],
        bytes_out[7]  =
                        bytes_in[7],
                        bytes_in[6],
                        bytes_in[5],
                        bytes_in[4],
                        bytes_in[3],
                        bytes_in[2],
                        bytes_in[1],
                        bytes_in[0];
    case;
        assert(bytes_out != bytes_in, "can't do byte swaps in a for loop (not sure why), so pointers should not alias");
        for 0..size-1 {
            bytes_out[it] = bytes_in[(size-1)-it];
        }
    }
}

// -----------------------------------------------------------------------------------
// ----------------------------------------------------------------- :Internal Helpers

#scope_file 

write_primitive :: inline (using buffer: *Serializer, primitive: *$T) {
    if reverse_byte_order {
        #if #run T.(*Type_Info).type == .STRUCT {
            copy := primitive.*;
            reverse_bytes(*copy);
            memcpy(memory.data + head, *copy, size_of(T));
        } else {
            reverse_bytes(memory.data + head, primitive.(*u8), size_of(T));
        }
    } else {
        #if #complete align_mode == {
        case .PRIMITIVE;
            (memory.data + head).(*T).* = primitive.*;
        case .PARAMETER; 
            memcpy(memory.data + head, primitive, size_of(T));
        case .BYTE;
            memcpy(memory.data + head, primitive, size_of(T));
        }
    }
}

read_primitive :: inline (using buffer: *Serializer, primitive: *$T) {
    if reverse_byte_order {
        #if #run T.(*Type_Info).type == .STRUCT {
            memcpy(primitive, memory.data + head, size_of(T));
            reverse_bytes(primitive); 
        } else {
            reverse_bytes(primitive.(*u8), memory.data + head, size_of(T));
        }
    } else {
        #if #complete align_mode == {
        case .PRIMITIVE;
             primitive.* = (memory.data + head).(*T).*;
        case .PARAMETER;
            memcpy(primitive, memory.data + head, size_of(T));
        case .BYTE;
            memcpy(primitive, memory.data + head, size_of(T));
        }
    }
}

serial_primitive_alignment :: inline (using buffer: *Serializer, $T: Type) -> u8 {
    T_ALIGNMENT : u8 : #run align_of(T);
    #if #complete align_mode == {
    case .PRIMITIVE;
        return T_ALIGNMENT;
    case .PARAMETER;
        return parameter_align;
    case .BYTE;
        return 1;
    }
    return 1;
}

is_serial_primitive :: (T: Type) -> bool {
    info := cast(*Type_Info)T;
    if info.type == .INTEGER return true;
    if info.type == .FLOAT   return true;
    if info.type == .BOOL    return true;
    if info.type == .ENUM    return true;
    if info.type == .STRUCT  return true;
    return false;
}

validate_read_write :: () #expand {
    assert(`rw_mode == `mode, "expected mode %, have mode %", `mode, `rw_mode);
    if `pad_for_checksum {
        assert(`head >= SERIALIZER_CHECKSUM_SIZE);
    }
}

// -----------------------------------------------------------------------------------

#scope_file

// module independence boilerplate

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

is_power_of_two :: inline (val: $T) -> bool {
    return val > 0 && (val & (val - 1)) == 0;
}

ceil_to_pow2_multiple :: inline (n: $T, power_of_two_size: T) -> T {
    assert(is_power_of_two(power_of_two_size));
    return (n + power_of_two_size-1) & ~(power_of_two_size-1);
}

// -------

#import "md5";
#import "Basic";
#import "File";
