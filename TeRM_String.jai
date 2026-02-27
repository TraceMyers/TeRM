// an extension of string helper procedures in String module
#import "String";

TO_LOWER_LETTER_DIFFERENCE :: #char "a" - #char "A";

string_reset :: inline (s: *string) {
    if s.data != null {
        free(s.data);
        s.data = null;
    }
    s.count = 0;
}

as_array :: inline (str: string, $T: Type) -> []T {
    t_array: []T = ---;
    t_array.count = str.count / size_of(T);
    t_array.data = xx str.data;
    // requiring that the number of bytes is a multiple of the item size; no bytes left out
    assert(t_array.count * size_of(T) == str.count); 
    return t_array;
}

to_string_safe :: inline (str: *u8, max_read_count: s64) -> string {
    for 0..max_read_count-1 {
        if str[it] == 0 {
            return string.{it, str};
        }
    }
    return string.{max_read_count, str};
}

as_string :: inline (array: []$T) -> string {
    return string.{array.count * size_of(T), xx array.data};
}

as_string :: inline (item: $T) -> string 
#modify {
    info := cast(*Type_Info)T;
    if info.type == .ARRAY {
        return false;
    }
    return true;
} {
    return string.{size_of(T), xx *item};
}

concatenate :: (strings: ..string) -> string {
    out_count := 0;
    for strings {
        out_count += it.count;
    }

    out_str := alloc_string(out_count);
    copy_loc := 0;
    for strings {
        memcpy(out_str.data + copy_loc, it.data, it.count);
        copy_loc += it.count;
    }
    assert(copy_loc == out_str.count);

    return out_str;
}

string_reverse :: (str: string) {
    b: s64;
    half_count := str.count >> 1;
    while b <= half_count {
        e := str.count - 1 - b;
        str[b], str[e] = str[e], str[b];
        b += 1;
    }
}

string_copy :: (s: string) -> string {
    if s.count == 0 return "";
    copy := alloc_string(s.count);
    memcpy(copy.data, s.data, s.count);
    return copy;
}

is_alpha_upper :: inline (code_point: u32) -> bool {
    return code_point <= #char "Z" && code_point >= #char "A";
}

is_alpha_lower :: inline (code_point: u32) -> bool {
    return code_point <= #char "z" && code_point >= #char "a";
}

is_slash :: inline (code_point: u32) -> bool {
    return code_point == #char "/" || code_point == #char "\\";
}

to_lower_in_place :: inline (str: *string) {
    for *str {
        it.* = to_lower(it.*);
    }
}

to_lower :: inline (str: string) -> string {
    out_str := alloc_string(str.count);
    to_lower_inline(*out_str);
    return out_str;
}

to_upper_in_place :: inline (str: *string) {
    for *str {
        it.* = to_upper(it.*);
    }
}

to_upper :: inline (str: string) -> string {
    out_str := alloc_string(str.count);
    to_upper_inline(*out_str);
    return out_str;
}

// for expansion. process a string per line. usage = 'for :per_line your_string { .. }'
per_line :: (str: *string, body: Code, flags: For_Flags) #expand {
    // todo: could implement going over lines from last to first line
    // getting a pointer to a local string instantiation doesn't do anything helpful.
    // you can modify the data and the count regardless
    #assert(flags == 0);

    line_count: s64;
    left, right: string;
    right = str.*;
    success: bool;
    end_loop: bool;

    while !end_loop {
        prev_right := right;
        success, left, right = split_from_left(right, #char "\n");

        line: string = ---;

        if success {
            if left.count > 0 && left[left.count-1] == #char "\r" {
                left.count -= 1;
            }
            line = left;
        } else {
            if prev_right.count > 0 {
                line = prev_right;
                end_loop = true;
            } else {
                break;
            }
        }

        `it := line;
        `it_index := line_count;
        line_count += 1;

        #insert body;
    }
}

c_strings_equal :: (a: *u8, b: *u8, max_read_count: s64) -> bool {
    if max_read_count <= 0 {
        return false;
    }
    for i : 0..max_read_count-1 {
        if a[i] == 0 {
            if b[i] == 0 {
                return true;
            } else {
                return false;
            }
        } else if b[i] == 0 {
            return false;
        }
        if a[i] != b[i] {
            return false;
        }
    }
    return true;
}

// String_Exchange + for_expansion = progressive string consumption with arbitrary break condition
// usage example:
//
// my_string := "hello/there";
// my_exchange := String_Exchange.{src=my_string}; // can also have src be a pointer
// for my_exchange { 
//      if it == #char "/" {
//          // trims the end '/' from dst
//          my_exchange.trim_bytes = 1;
//          break;
//      }
// }
//  
// after this, my_exchange will be {src="there", dst="hello"};
String_Exchange :: struct($type := enum { NORMAL; PTR; }.NORMAL) {
    source_type :: #insert #run tprint("%string;", ifx type == .NORMAL then "" else "*");
    src: source_type;
    dst: string;
    trim_bytes: s32;
    reset_trim_bytes := true;
    broke_out_of_loop: bool;
}

for_expansion :: (exchange: *String_Exchange, body: Code, flags: For_Flags) #expand {
    #assert(flags == 0);

    // letting the user know a break happened, so they can differentiate between
    // their own inserted break statement and just reaching the end of the source string
    do_break :: () #expand {
        exchange.broke_out_of_loop = true;
        break;
    }

    i := 0;
    if exchange.reset_trim_bytes {
        exchange.trim_bytes = 0;
    }
    exchange.broke_out_of_loop = false;

    while i < exchange.src.count {
        `it := exchange.src.data[i];
        `it_index := i;
        i += 1;

        #insert (break=do_break()) body;
    }

    exchange.dst = {max(i - exchange.trim_bytes, 0), exchange.src.data};
    exchange.src.data  += i;
    exchange.src.count -= i;
    if exchange.src.count <= 0 {
        exchange.src.data = null;
        exchange.src.count = 0;
    }
}

#scope_file

#import "Basic";

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
