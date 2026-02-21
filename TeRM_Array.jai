// an extension of array procedures in Basic module
#import "Basic";

copy_items :: inline (dest: *$T, src: *T, count: s64) {
    memcpy(dest, src, count * size_of(T));
}

make_dynamic_array :: inline ($T: Type, reserve_count := 0) -> [..]T {
    array: [..]T;
    array.allocator = context.allocator;
    array_reserve(*array, reserve_count);
    return array;
}

make_static_array :: inline ($T: Type, count := 0) -> []T {
    array: []T;
    array_resize(*array, count);
    return array;
}

array_element_index :: inline (array: []T, item: *$T) -> s64 {
    index := item - array.data;
    assert(index >= 0 && index < array.count);
    return index;
}

arrays_equal :: inline (a: []$T, b: []T) -> bool {
    if a.count != b.count return false;
    return memcmp(a.data, b.data, a.count) == 0;
}

array_append :: (a: *[..]$T, b: []T) {
    if b.count == 0 then return;
    prev_count := a.count;
    array_resize(a, a.count + b.count);
    copy_items(a.data + prev_count, b.data, b.count);
}

array_concatenate :: (a: []$T, b: []T) -> []T {
    arr := make_static_array(T, a.count + b.count);
    copy_items(arr.data, a.data, a.count);
    copy_items(arr.data + a.count, b.data, b.count);
    return arr;
}

array_copy :: inline (dest: *[]$T, src: []T) {
    assert(dest.count >= src.count);
    copy_items(dest.data, src.data, dest.count);
}

array_duplicate :: (array: []$T) -> []T {
    duplicate := make_static_array(T, array.count);
    array_copy(*duplicate, array);
    return duplicate;
}

array_init :: inline (array: *[]$T) {
    init_range(array.data, 0, array.count);
}

copy_range_inside_array :: (array: *[]$T, dst: s64, src: s64, count: s64) {
    assert(count > 0 && dst != src);
    diff := dst - src;
    abs_diff := abs(diff);
    if abs_diff < count {
        if diff < 0 then for 0..count-1 {
            array[dst+it] = array[src+it];
        } else for < 0..count-1 {
            array[dst+it] = array[src+it];
        }
    } else {
        copy_items(array.data + dst, array.data + src, count);
    }
}

array_shrink :: (array: *[..]$T) {
    if array.allocated > array.count {
        new_allocation: *T;
        if array.count > 0 {
            new_allocation = alloc(array.count * size_of(T),, array.allocator);
            memcpy(new_allocation, array.data, array.count * size_of(T));
            array_free(array.*,,array.allocator);
        }
        array.data = new_allocation;
        array.allocated = array.count;
    }
}

array_shrink_if_small_enough :: (array: *[..]$T, realloc_if_using_leq_proportion := 0.75, minimum_count := 8) {
    if array.count < minimum_count && array.count != 0 {
        return;
    }
    if array.allocated == 0 {
        assert(array.data == null);
        assert(array.count == 0);
        return;
    }
    if array.count.(float) / array.allocated.(float) <= realloc_if_using_leq_proportion {
        array_shrink(array);
    }
}

#scope_file

// copied from module Basic in /Array
init_range :: (ptr: *$T, begin: s64, end: s64) {
    ini :: initializer_of(T);
    #if ini {
        for begin..end-1  inline ini(ptr + it);  // Really this can be one ini followed by a bunch of memcpy. For long arrays we could power-of-two double the copy out, etc.
    } else {
        count := end - begin;
        if count <= 0  return;

        // Fast path for init to zero.
        // In the case that we are shrinking an array, count will be negative.
        memset(ptr + begin, 0, count * size_of(T));
    }
}

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
