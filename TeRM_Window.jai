is_window_open :: (window: Window_Type) -> bool {
    #if OS == .WINDOWS {
        return xx IsWindow(window);
    }
    return false;
}

is_window_minimized :: (window: Window_Type) -> bool {
    #if OS == .WINDOWS {
        return xx IsIconic(window);
    }
    return false;
}

#scope_file;

#import "Window_Creation";

#if OS == .WINDOWS {
    Win32 :: #import "Windows";
    user32 :: #system_library "user32";
    IsWindow :: (window: Window_Type) -> Win32.BOOL #foreign user32;
    IsIconic :: (window: Window_Type) -> Win32.BOOL #foreign user32;
}
