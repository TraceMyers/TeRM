move_path_back_one_directory :: (path: string) -> path: string, success: bool {
    if path.count == 0 {
        return "", false;
    }

    index_of_last_slash, slash_character := get_index_of_last_slash_and_slash_character(path);
    if index_of_last_slash == -1 {
        return path, false;
    }

    out_path := path;

    success: bool;
    if index_of_last_slash == out_path.count - 1 {
        out_path.count -= 1;
        if out_path.count == 0 {
            return path, false;
        }
        success=, out_path=, chopped := split_from_right(out_path, slash_character);
    } else {
        out_path.count = index_of_last_slash;
        success = true;
    }

    if success {
        return out_path, true;
    } else {
        return path, false;
    }
}

move_path_forward_one_directory :: (path: string, directory: string) -> string {
    index_of_last_slash, slash_character := get_index_of_last_slash_and_slash_character(path);
    if index_of_last_slash == path.count - 1 {
        return tprint("%%", path, directory);    
    } else {
        return tprint("%%%", path, string.{1, *slash_character}, directory);    
    }
}

get_index_of_last_slash_and_slash_character :: (path: string) -> index: s64, slash_character: u8 {
    slash_character : u8 = #char "/";
    index_of_last_slash := find_index_from_right(path, slash_character);
    if index_of_last_slash == -1 {
        slash_character = #char "\\";
        index_of_last_slash = find_index_from_right(path, slash_character);
        if index_of_last_slash == -1 {
            slash_character = #char "/";
        }
    }
    return index_of_last_slash, slash_character;
}

// resolve '..' and symlinks 
get_final_path :: (path: string) -> string {
    #if OS == .WINDOWS {
        handle := CreateFileA(temp_c_string(path), 0, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, null, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, null);
        path_buffer: [4096]u8;
        out_path_len := GetFinalPathNameByHandleA(handle, path_buffer.data, xx path_buffer.count);
        if out_path_len == 0 {
            log("get_path_after_resolving_symlinks win32 error: %", GetLastError());
            return {};
        }

        out_path: string;
        path_as_given := string.{out_path_len, path_buffer.data};
        index_of_drive_colon := find_index_from_left(path_as_given, #char ":");
        assert(index_of_drive_colon > 0);

        // windows adds \\?\ before the drive letter sometimes/all the time (?) to indicate
        // that the path is final.
        index_of_drive_letter := index_of_drive_colon - 1;
        out_path = alloc_string(out_path_len - index_of_drive_letter);
        memcpy(out_path.data, path_buffer.data + index_of_drive_letter, out_path_len - index_of_drive_letter);

        return out_path;
    } else {
        return path;
    }
}


#scope_file


#import "Basic";
#import "String";

#if OS == .WINDOWS {
    #import "Windows";

    GetFinalPathNameByHandleA :: (handle: HANDLE, out_path_buffer: *u8, out_path_buffer_size_including_null: s32, flags: s32 = 0) -> out_path_length: s32 #foreign kernel32;

    kernel32 :: #library,system "kernel32";
}
