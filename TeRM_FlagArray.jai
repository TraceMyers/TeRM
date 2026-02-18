// convenient for making one big flag set that might expand beyond 64 flags.
// uses an enum as an indexer to the bits in an array.

Flag_Array_Indexer :: struct {
    index: s16;
    bit: s16;
}

Flag_Array :: struct($Enum_Type: Type) {
    FLAG_COUNT :: #run enum_highest_value(Enum_Type) + 1;
    flag_sets: [#run div_ceil(FLAG_COUNT, 8)]u8;
}

convert_to_lfa_indexer :: inline (int_val: s32) -> Flag_Array_Indexer {
    return .{xx ((int_val & ~0x07) >> 3), xx (int_val & 0x07)};
}

is_set :: inline (arr: *Flag_Array($T), enum_val: T) -> bool {
    indexer := convert_to_lfa_indexer(xx enum_val);
    return (arr.flag_sets[indexer.index] & ((1).(u8) << indexer.bit)) != 0;
}

set :: inline (arr: *Flag_Array($T), enum_val: T) {
    indexer := convert_to_lfa_indexer(xx enum_val);
    arr.flag_sets[indexer.index] |= ((1).(u8) << indexer.bit);
}

unset :: inline (arr: *Flag_Array($T), enum_val: T) {
    indexer := convert_to_lfa_indexer(xx enum_val);
    arr.flag_sets[indexer.index] &= ~((1).(u8) << indexer.bit);
}

set :: inline (arr: *Flag_Array($T), enum_vals: []T) {
    for enum_vals {
        set(arr, it);
    }
}

unset :: inline (arr: *Flag_Array($T), enum_vals: []T) {
    for enum_vals {
        unset(arr, it);
    }
}

are_all_set :: inline (array: *Flag_Array($T), enum_vals: []T) -> bool {
    for enum_vals {
        if !is_set(array, it) {
            return false;
        }
    }
    return true;
}

are_any_set :: inline (array: *Flag_Array($T), enum_vals: []T) -> bool {
    any_set := false;
    for enum_vals {
        any_set |= is_set(array, it);
    }
    return any_set;
}

unset_all :: inline (arr: *Flag_Array($T)) {
    memset(arr.flag_sets.data, 0x00, arr.flag_sets.count);
}

set_all :: inline (arr: *Flag_Array($T)) {
    memset(arr.flag_sets.data, 0xff, arr.flag_sets.count);
}

#scope_file

div_ceil :: inline (a: $Int_Type, b: Int_Type) -> Int_Type 
#modify {
    return Int_Type.(*Type_Info).type == .INTEGER;
} {
    assert(a >= 0 && b > 0);
    return ((a - 1) / b) + 1;
}

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
