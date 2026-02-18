// --- module params & debug ---
// -----------------------------------------------------------------------------------
#module_parameters()(
    // 0, 1, 2 (0=basic, 1=log, 2=assert). validation requires TeRM_Log module.
    // term logs can be customized program-wide to go to stdout, stdout + callback, or just callback.
    VALIDATION_LEVEL := 0,
    ADD_TEXT_ENCODINGS: []string = string.[], // see 'how to add text encodings' section
    ADD_ENCODE_FAILURES: []string = string.[] // see 'how to add text encodings' section
);

// optionally replace this proc pointer with a procedure that tells this module whether 
// asserts should be allowed to trigger or not. only used when on validation level 2.
term_encode_text_allow_assert := () -> bool { return true; };

// optionally replace this proc pointer with a procedure that tells this module whether 
// logs should be printed or not. only used when on validation level >= 1.
term_encode_text_allow_log := () -> bool { return true; };

// -----------------------------------------------------------------------------------

// -- sections --
// How to Add Text Encodings From Your Program (or here)
// Types and Helpers
// Encode String
// Conversion

// -----------------------------------------------------------------------------------
// -------------------------------------- :How to Add Text Encodings From Your Program

/*

// obviously you could just modify this module and that works fine, but if you don't like doing
// that, this was made to be modified externally, and to have those external parts work
// exactly like the default internal ones.

// if I wanted to add an encoding like IBM CP850, first I insert it into the Text_Encoding
// enum via the module parameters at import time, like so:

#import "TRM/TRM_EncodeText"()(ADD_TEXT_ENCODINGS=string.["CP850"]);

// then, I would need to define conversion procedures for any conversions I want to make, like this:

cp850_to_utf8 :: (in: *u8, out: *u8, in_size: int, out_size: int) -> s8, s8, Text_Encode_Failure { ... }

// then, I can make an encoder:

CP850_TO_UTF8 :: Text_Encoder.{.CP850, .UTF8, cp850_to_utf8, 0};

// and use it:

utf8_str, success := encode_text_string(cp850_str, CP850_to_UTF8);

// you can also then of course name your own encode proc if you use it a lot:

my_encode_text :: #bake_arguments encode_text_string(encoder=CP850_TO_UTF8);

// to then use it like:

utf8_str, success := my_encode_text(cp850_str);

// to make a new encoder procedure, consider this example:

ansi_to_utf8 :: (in: *u8, out: *u8, in_buf_size: int, out_buf_size: int) -> s8, s8, Text_Encode_Failure {
    if is_ascii(in.*) {
        return_if_not_valid_encode(in_buf_size, out_buf_size, 1, 1);
        out.* = in.*;
        return 1, 1, 0;
    } else {
        return_if_not_valid_encode(in_buf_size, out_buf_size, 1, 2);
        out[0] = (0xc0).(u8) | ((in.* & 0xc0) >> 6);
        out[1] = (0x80).(u8) |  (in.* & 0x3f);
        return 1, 2, 0;
    }
}

// your procedure is responsible for reading bytes, translating, writing bytes, validating that
// a read and write are safe (convenience macro provided), validating that the input is not 
// malformed, and returning values as such: bytes read or intended to read if no error, bytes
// written or intended to write if no error, and 0 or error code. 

// null bytes are appended to the end of all strings as per the 'terminating_null_byte_count' 
// field on the encoder. a 0 can be passed in if you don't want a terminating null.

// if you want to use one of the default encodings, and don't want the terminating null, you
// could declare an alternative version of that encoder in your program:

MY_UTF8_TO_UTF16 :: Text_Encoder.{.UTF8,  .UTF16, utf8_to_utf16,  0};

// user-defined error codes can also be added at import, and returned by your function so that 
// they can be logged when something goes wrong.

*/

// -----------------------------------------------------------------------------------
// ---------------------------------------------------------------- :Types and Helpers

text_encoder_procedure :: #type (src: *u8, dst: *u8, src_size: int, dst_size: int) -> read_byte_count: s8, wrote_byte_count: s8, error_code: Text_Encode_Failure;

Text_Encoder :: struct {
    encode_from: Text_Encoding;
    encode_to: Text_Encoding;
    proc: text_encoder_procedure;
    terminating_null_byte_count: int; // how many null bytes to put at the end of the string
}

Text_Encoding :: enum u8 {
    UTF8;
    UTF16;
    UTF32;
    ANSI;
    #insert -> string {
        builder: String_Builder;
        for ADD_TEXT_ENCODINGS {
            print(*builder, "%;\n", it);
        }
        return builder_to_string(*builder);
    };
}

Text_Encode_Failure :: enum s32 {
    // 0 = success
    TRUNCATED_BYTES_IN_INPUT :: 1;
    OUTPUT_BUFFER_IMPROPERLY_SIZED_BY_SYSTEM;
    IMPOSSIBLE_TRANSLATION_OR_MALFORMED_INPUT;
    UNSUPPORTED_UTF8_CODE_POINT_SIZE;
    INVALID_UTF8_TRAILING_BYTES;
    MALFORMED_INPUT;
    #insert -> string {
        builder: String_Builder;
        for ADD_ENCODE_FAILURES {
            print(*builder, "%;\n", it);
        }
        return builder_to_string(*builder);
    };
}

is_ansi :: inline (in: u32) -> bool {
    return (in & 0xff) == in;
}

is_ascii :: inline (in: u32) -> bool {
    return (in & 0x7f) == in;
}

ANSI_TO_UTF8   :: Text_Encoder.{.ANSI,  .UTF8,  ansi_to_utf8,   1};
ANSI_TO_UTF16  :: Text_Encoder.{.ANSI,  .UTF16, ansi_to_utf16,  2};
ANSI_TO_UTF32  :: Text_Encoder.{.ANSI,  .UTF32, ansi_to_utf32,  4};
ANSI_TO_ANSI   :: Text_Encoder.{.ANSI,  .ANSI,  null,           1};

UTF8_TO_UTF8   :: Text_Encoder.{.UTF8,  .UTF8,  null,           1};
UTF8_TO_UTF16  :: Text_Encoder.{.UTF8,  .UTF16, utf8_to_utf16,  2};
UTF8_TO_UTF32  :: Text_Encoder.{.UTF8,  .UTF32, utf8_to_utf32,  4};
UTF8_TO_ANSI   :: Text_Encoder.{.UTF8,  .ANSI,  utf8_to_ansi,   1};

UTF16_TO_UTF8  :: Text_Encoder.{.UTF16, .UTF8,  utf16_to_utf8,  1};
UTF16_TO_UTF16 :: Text_Encoder.{.UTF16, .UTF16, null,           2};
UTF16_TO_UTF32 :: Text_Encoder.{.UTF16, .UTF32, utf16_to_utf32, 4};
UTF16_TO_ANSI  :: Text_Encoder.{.UTF16, .ANSI,  utf16_to_ansi,  1};

UTF32_TO_UTF8  :: Text_Encoder.{.UTF32, .UTF8,  utf32_to_utf8,  1};
UTF32_TO_UTF16 :: Text_Encoder.{.UTF32, .UTF16, utf32_to_utf16, 2};
UTF32_TO_UTF32 :: Text_Encoder.{.UTF32, .UTF32, null,           4};
UTF32_TO_ANSI  :: Text_Encoder.{.UTF32, .ANSI,  utf32_to_ansi,  1};

// -----------------------------------------------------------------------------------
// -------------------------------------------------------------------- :Encode String

// translate a string from one encoding to another
encode_text_string :: (src: string, encoder: Text_Encoder, caller_loc := #caller_location) -> string, bool {
    temp_storage_mark := get_temporary_storage_mark();
    defer if context.allocator.proc != temp.proc then set_temporary_storage_mark(temp_storage_mark);

    assert(encoder.terminating_null_byte_count >= 0);

    if src.count == 0 then return "", true;

    out_buffer_inline: [4096]u8;
    out_buffer: *u8 = out_buffer_inline.data;
    out_buffer_size := out_buffer_inline.count;
    
    src_index: int;
    out_index: int;

    if encoder.encode_from != encoder.encode_to {
        MAX_WRITE_SIZE :: 4;
        while src_index < src.count {
            out_remain := out_buffer_size - out_index;
            if out_remain - MAX_WRITE_SIZE <= 0 {
                // no need to free on resize. all previous allocations are either stack-local or temp
                new_size := max(out_buffer_size * 2, src.count + MAX_WRITE_SIZE);
                new_buffer := alloc(new_size,,temp);
                memcpy(new_buffer, out_buffer, out_index);
                out_buffer = new_buffer;
                out_buffer_size = new_size;
                out_remain = out_buffer_size - out_index;
            }
            src_remain := src.count - src_index;

            read_count, write_count, encode_failure := encoder.proc(src.data + src_index, out_buffer + out_index, src_remain, out_remain);

            if encode_failure != 0 {
                src_truncated := string.{min(100, src.count), src.data};
                report_module_error("failed to encode string '%' from % to %. error: %. callsite: %.", src_truncated, encoder.encode_from, encoder.encode_to, encode_failure, caller_loc);
                // making sure this happens regardless of what context.allocator is (see defer at top)
                set_temporary_storage_mark(temp_storage_mark);
                return "", false;
            }

            src_index += read_count;
            out_index += write_count;
        }
    } else {
        // an encode with the same src and dst encoding is just a string copy.
        // this feeds into the logic below.
        out_buffer = src.data;
        out_index = src.count;
        out_buffer_size = src.count;
    }

    // check whether a new allocation needs to be made or if the current one can just be returned as-is
    // null bytes always written to the end for compatibility with other stuff. it's just easier this way.
    if out_buffer == src.data 
    || out_buffer == out_buffer_inline.data 
    || context.allocator.proc != temp.proc 
    || out_index + encoder.terminating_null_byte_count > out_buffer_size {
        // again, no need to free here, just as above
        new_buffer_size := out_index + encoder.terminating_null_byte_count;
        new_buffer := alloc(new_buffer_size);
        memcpy(new_buffer, out_buffer, out_index);
        out_buffer = new_buffer;
        out_buffer_size = new_buffer_size;
    }
    
    if encoder.terminating_null_byte_count > 0 {
        memset(out_buffer + out_index, 0, encoder.terminating_null_byte_count);
    }
    return string.{out_index, out_buffer}, true;
}

// -----------------------------------------------------------------------------------
// ----------------------------------------------------------------------- :Conversion
// for all encode procs: 
// - if the Text_Encode_Failure value is 0, the first two values are how many bytes were read, and how many were written.
// - if the Text_Encode_Failure value is nonzero, the first two values are how many bytes the encode proc wanted to read and write, but  failed to.

// ansi -> ...

ansi_to_utf8 :: (in: *u8, out: *u8, in_buf_size: int, out_buf_size: int) -> s8, s8, Text_Encode_Failure {
    if is_ascii(in.*) {
        return_if_not_valid_encode(in_buf_size, out_buf_size, 1, 1);
        out.* = in.*;
        return 1, 1, 0;
    } else {
        return_if_not_valid_encode(in_buf_size, out_buf_size, 1, 2);
        out[0] = (0xc0).(u8) | ((in.* & 0xc0) >> 6);
        out[1] = (0x80).(u8) |  (in.* & 0x3f);
        return 1, 2, 0;
    }
}

ansi_to_utf16 :: (in: *u8, out: *u8, in_buf_size: int, out_buf_size: int) -> s8, s8, Text_Encode_Failure {
    return_if_not_valid_encode(in_buf_size, out_buf_size, 1, 2);
    out_utf16 := out.(*u16,force);
    out_utf16.* = in.*;
    return 1, 2, 0;
}

ansi_to_utf32 :: (in: *u8, out: *u8, in_buf_size: int, out_buf_size: int) -> s8, s8, Text_Encode_Failure {
    return_if_not_valid_encode(in_buf_size, out_buf_size, 1, 4);
    out_utf32 := out.(*u32,force);
    out_utf32.* = in.*;
    return 1, 4, 0;
}

// utf8 -> ...

utf8_to_ansi :: (in: *u8, out: *u8, in_buf_size: int, out_buf_size: int) -> s8, s8, Text_Encode_Failure {
    if (in[0] & 0x80) == 0 {
        // 1 byte utf8 code point
        return_if_not_valid_encode(in_buf_size, out_buf_size, 1, 1);
        out.* = in.*;
        return 1, 1, 0;
    } else if (in[0] & 0xfc) == 0x80 {
        // 2 byte utf8 code point
        // the only valid 2 byte utf8 -> ansi bits look like this:
        // [0]: 1100-00xx, [1]: 10xx-xxxx, where the ansi bits are the x's
        return_if_not_valid_encode(in_buf_size, out_buf_size, 2, 1);
        return_if_invalid_utf8_trailing_byte(in[1], 2, 1);
        out.* =  ((in[0] & 0x03) << 6) | (in[1] & 0x3f);
        return 2, 1, 0;
    } else {
        // utf8 encoding is saying it has more than 8 bits to deliver, which is ansi's limit
        return 0, 0, .IMPOSSIBLE_TRANSLATION_OR_MALFORMED_INPUT;
    }
}

utf8_to_utf16 :: (in: *u8, out: *u8, in_buf_size: int, out_buf_size: int) -> s8, s8, Text_Encode_Failure {
    // utf8 and utf16 are both types that require actual decoding. so, encoding while decoding
    // is sort of possible but practically you always need to decode first. so, we decode
    // to utf32 the encode to utf16.
    dummy_utf32: u32 = ---;
    read_utf8_bytes, _, fail_code_1 := utf8_to_utf32(in, xx *dummy_utf32, in_buf_size, 4);
    if fail_code_1 != 0 {
        return read_utf8_bytes, 0, fail_code_1;
    }
    _, write_utf16_bytes, fail_code_2 := utf32_to_utf16(xx *dummy_utf32, out, 4, out_buf_size);
    return read_utf8_bytes, write_utf16_bytes, fail_code_2;
}

utf8_to_utf32 :: (in: *u8, out: *u8, in_buf_size: int, out_buf_size: int) -> s8, s8, Text_Encode_Failure {
    out_utf32 := out.(*u32,force);
    if (in[0] & 0x80) == 0 {
        return_if_not_valid_encode(in_buf_size, out_buf_size, 1, 4);
        out_utf32.* = in.*;
        return 1, 4, 0;
    } else if (in[0] & 0xe0) == 0xc0 {
        return_if_not_valid_encode(in_buf_size, out_buf_size, 2, 4);
        return_if_invalid_utf8_trailing_byte(in[1], 2, 4);
        out_utf32.* = ((in[0] & 0x1f).(u32) << 6) | (in[1] & 0x3f).(u32);
        return 2, 4, 0;
    } else if (in[0] & 0xf0) == 0xe0 {
        return_if_not_valid_encode(in_buf_size, out_buf_size, 3, 4);
        return_if_invalid_utf8_trailing_byte(in[1], 3, 4);
        return_if_invalid_utf8_trailing_byte(in[2], 3, 4);
        out_utf32.* = ((in[0] & 0x0f).(u32) << 12) | ((in[1] & 0x3f).(u32) << 6) | (in[2] & 0x3f).(u32);
        return 3, 4, 0;
    } else if (in[0] & 0xf8) == 0xf0 {
        return_if_not_valid_encode(in_buf_size, out_buf_size, 4, 4);
        return_if_invalid_utf8_trailing_byte(in[1], 4, 4);
        return_if_invalid_utf8_trailing_byte(in[2], 4, 4);
        return_if_invalid_utf8_trailing_byte(in[3], 4, 4);
        out_utf32.* = ((in[0] & 0x07) << 18).(u32) | ((in[1] & 0x3f).(u32) << 12) | ((in[2] & 0x3f).(u32) << 6) | (in[3] & 0x3f).(u32);
        return 4, 4, 0;
    } else {
        // either the utf8 is malformed, or it's reporting a number of bytes (> 4), which is unsupported by this encoder
        return 0, 0, .UNSUPPORTED_UTF8_CODE_POINT_SIZE;
    }
}

// utf16 -> ...

utf16_to_ansi :: (in: *u8, out: *u8, in_buf_size: int, out_buf_size: int) -> s8, s8, Text_Encode_Failure {
    return_if_not_valid_encode(in_buf_size, out_buf_size, 2, 1);
    in_utf16 := in.(*u16,force);
    if in_utf16.* > 255 {
        return 0, 0, .IMPOSSIBLE_TRANSLATION_OR_MALFORMED_INPUT;
    }
    out.* = in.*;
    return 2, 1, 0;
}

utf16_to_utf8 :: (in: *u8, out: *u8, in_buf_size: int, out_buf_size: int) -> s8, s8, Text_Encode_Failure {
    // utf8 and utf16 are both types that require actual decoding. so, encoding while decoding
    // is sort of possible but practically you always need to decode first. so, we decode
    // to utf32 the encode to utf8.
    dummy_utf32: u32 = ---;
    read_utf16_bytes, _, fail_code_1 := utf16_to_utf32(in, xx *dummy_utf32, in_buf_size, 4);
    if fail_code_1 != 0 {
        return read_utf16_bytes, 0, fail_code_1;
    }
    _, write_utf8_bytes, fail_code_2 := utf32_to_utf8(xx *dummy_utf32, out, 4, out_buf_size);
    return read_utf16_bytes, write_utf8_bytes, fail_code_2;
}

utf16_to_utf32 :: (in: *u8, out: *u8, in_buf_size: int, out_buf_size: int) -> s8, s8, Text_Encode_Failure {
    return_if_not_valid_encode(in_buf_size, out_buf_size, 2, 4);
    in_utf16 := in.(*u16,force);
    out_utf32 := out.(*u32,force);
    high_surrogate := in_utf16.*;
    if high_surrogate < UTF16_HIGH_SURROGATE_MIN || high_surrogate > UTF16_HIGH_SURROGATE_MAX {
        out_utf32.* = in_utf16.*;
        return 2, 4, 0;
    } else {
        return_if_not_valid_encode(in_buf_size, out_buf_size, 4, 4);
        low_surrogate := (in + 2).(*u16,force).*;
        if low_surrogate < UTF16_LOW_SURROGATE_MIN || low_surrogate > UTF16_LOW_SURROGATE_MAX {
            return 4, 4, .MALFORMED_INPUT;
        }
        _20_bit_high := (high_surrogate.(u32) - UTF16_HIGH_SURROGATE_MIN) << 10;
        _20_bit_low := low_surrogate.(u32) - UTF16_LOW_SURROGATE_MIN;
        out_utf32.* = (_20_bit_high | _20_bit_low) + 0x1_00_00;
        return 4, 4, 0;
    }
}

// utf32 -> ...

utf32_to_ansi :: (in: *u8, out: *u8, in_buf_size: int, out_buf_size: int) -> s8, s8, Text_Encode_Failure {
    return_if_not_valid_encode(in_buf_size, out_buf_size, 4, 1);
    in_utf32 := in.(*u32,force);
    if in_utf32.* > 255 {
        return 0, 0, .IMPOSSIBLE_TRANSLATION_OR_MALFORMED_INPUT;
    }
    out.* = in.*;
    return 4, 1, 0;
}

utf32_to_utf8 :: (in: *u8, out: *u8, in_buf_size: int, out_buf_size: int) -> s8, s8, Text_Encode_Failure {
    return_if_not_valid_encode(in_buf_size, out_buf_size, 4, 1);
    c := in.(*u32,force).*;
    if (c & 0x7f) == c {
        out.* = in.*;
        return 4, 1, 0;
    } else if (c & 0x07_ff) == c {
        return_if_not_valid_encode(in_buf_size, out_buf_size, 4, 2);
        out[0] = (0xc0).(u8) | ((c & 0x07_c0) >> 6 ).(u8);
        out[1] = (0x80).(u8) | ( c & 0x00_3f       ).(u8);
        return 4, 2, 0;
    } else if (c & 0xff_ff) == c {
        return_if_not_valid_encode(in_buf_size, out_buf_size, 4, 3);
        out[0] = (0xe0).(u8) | ((c & 0xf0_00) >> 12).(u8);
        out[1] = (0x80).(u8) | ((c & 0x0f_c0) >>  6).(u8);
        out[2] = (0x80).(u8) | ( c & 0x00_3f       ).(u8);
        return 4, 3, 0;
    } else {
        if (c & 0xff_e0_00_00) != 0 {
            // only support code points representable with 4 bytes in utf8
            return 0, 0, .UNSUPPORTED_UTF8_CODE_POINT_SIZE;
        }
        return_if_not_valid_encode(in_buf_size, out_buf_size, 4, 4);
        out[0] = (0xf0).(u8) | ((c & 0x1c_00_00) >> 18).(u8);
        out[1] = (0x80).(u8) | ((c & 0x03_f0_00) >> 12).(u8);
        out[2] = (0x80).(u8) | ((c & 0x00_0f_c0) >>  6).(u8);
        out[3] = (0x80).(u8) | ( c & 0x00_00_3f       ).(u8);
        return 4, 4, 0;
    }
}

utf32_to_utf16 :: (in: *u8, out: *u8, in_buf_size: int, out_buf_size: int) -> s8, s8, Text_Encode_Failure {
    in_utf32 := in.(*u32,force);
    out_utf16 := out.(*u16,force);
    return_if_not_valid_encode(in_buf_size, out_buf_size, 4, 2);
    if in_utf32.* > U16_MAX {
        if in_utf32.* > 0x10ffff {
            return 4, 4, .IMPOSSIBLE_TRANSLATION_OR_MALFORMED_INPUT;
        }
        return_if_not_valid_encode(in_buf_size, out_buf_size, 4, 4);
        utf32_20_bit := in_utf32.* - 0x1_00_00;
        out_utf16[0] = (((utf32_20_bit & UTF16_HIGH_MASK) >> 10) + UTF16_HIGH_SURROGATE_MIN).(u16); // high surrogate
        out_utf16[1] = ((utf32_20_bit & UTF16_LOW_MASK) + UTF16_LOW_SURROGATE_MIN).(u16); // low surrogate
        return 4, 4, 0;
    } else {
        // this range is reserved for utf16 encoding. invalid range for a code point.
        if in_utf32.* >= UTF16_HIGH_SURROGATE_MIN && in_utf32.* <= UTF16_LOW_SURROGATE_MAX {
            return 4, 2, .MALFORMED_INPUT;
        }
        out_utf16.* = xx in_utf32.*;
        return 4, 2, 0;
    }
}

// -----------------------------------------------------------------------------------

return_if_not_valid_encode :: (in_buf_size: int, out_buf_size: int, read_size: int, write_size: int) #expand {
    if in_buf_size < read_size {
        `return read_size, write_size, Text_Encode_Failure.TRUNCATED_BYTES_IN_INPUT;
    }
    if out_buf_size < write_size {
        `return read_size, write_size, Text_Encode_Failure.OUTPUT_BUFFER_IMPROPERLY_SIZED_BY_SYSTEM;
    }
}

return_if_invalid_utf8_trailing_byte :: (b: u8, read_size: int, write_size: int) #expand {
    if (b & 0xc0) != 0x80 {
        `return read_size, write_size, Text_Encode_Failure.INVALID_UTF8_TRAILING_BYTES;
    }
}

// -----------------------------------------------------------------------------------
#scope_file

UTF16_HIGH_SURROGATE_MIN : u32 : 0xd800;
UTF16_HIGH_SURROGATE_MAX : u32 : 0xdbff;
UTF16_LOW_SURROGATE_MIN : u32 : 0xdc00;
UTF16_LOW_SURROGATE_MAX : u32 : 0xdfff;
UTF16_HIGH_MASK : u32 : #run (0x3ff << 10).(u32);
UTF16_LOW_MASK : u32 : #run (0x3ff).(u32);

U16_MAX : u16 : 0xffff;

Utf16_Word :: enum u8 {
    BASIC_MULTILINGUAL_PLANE;
    HIGH_SURROGATE;
    LOW_SURROGATE;
}

#import "Basic";

VALIDATION_LEVEL_NONE   :: 0;
VALIDATION_LEVEL_MEDIUM :: 1;
VALIDATION_LEVEL_HIGH   :: 2;

report_module_error :: (fmt: string, args: ..Any) #expand {
    #if VALIDATION_LEVEL >= VALIDATION_LEVEL_MEDIUM {
        #import "TeRM/TeRM_Log";
        if term_encode_text_allow_log() {
            trm_log(fmt=fmt, args=..args, header="TeRM/EncodeText");
        }
    } else #if VALIDATION_LEVEL == VALIDATION_LEVEL_HIGH {
        if term_encode_text_allow_assert() {
            assert(false, fmt, ..args);
        }
    }
}
