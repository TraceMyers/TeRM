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

#scope_file

#import "Basic";
#import "String";
