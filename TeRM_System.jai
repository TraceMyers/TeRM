// todo: errors for other systems
// todo: code for other systems
// todo: more system info

System_Information :: struct {
    cpu_frequency: s64;
}

recommended_system_init :: () -> bool {
    #if OS == .WINDOWS {
        Win32.SetProcessDPIAware();
        // Windows is very bad at thread-switching by default unless you do this. buh-buh-buh-buh-bad. buh-buh-buh-buh-bad
        Win32.timeBeginPeriod(1); // bad to the bone
        return true;
    } else {
        return false;
    }
}

query_system_information :: (info: *System_Information) {
    if OS == .WINDOWS {
        Win32.QueryPerformanceFrequency(*info.cpu_frequency);
    }
}

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

make_window_take_focus :: (window: Window_Type) {
    if OS == .WINDOWS {
        SetForegroundWindow(window);
        Win32.SetCapture(window);
    }
}

get_mouse_cursor_position :: () -> x: s32, y: s32 {
    #if OS == .WINDOWS {
        pos: Win32.POINT;
        Win32.GetCursorPos(*pos);
        return pos.x, pos.y;
    }
    return 0,0;
}

set_mouse_cursor_position :: (x: s32, y: s32) {
    #if OS == .WINDOWS {
        SetCursorPos(x, y);
    }
}

set_mouse_cursor_visibility :: (window: Window_Type, visible: bool) {
    #if OS == .WINDOWS {
        if visible {
            ShowCursor(true);
        } else {
            // windows uses a voting system for ShowCursor that expects all applications to agree that the cursor
            // should be hidden or shown, which... I don't know maybe there's a way to make it work.
            // this stuffs the ballot box.
            safety_counter := 100;
            while ShowCursor(false) >= 0 && safety_counter > 0 { 
                safety_counter -= 1; 
            }
        }
    }
}

#scope_file;

#import "Basic";
#import "Window_Creation";

#if OS == .WINDOWS {
    Win32 :: #import "Windows";
    user32 :: #system_library "user32";

    IsWindow :: (window: Win32.HWND) -> Win32.BOOL #foreign user32;
    IsIconic :: (window: Win32.HWND) -> Win32.BOOL #foreign user32;
    SetCursorPos :: (x: s32, y: s32) -> Win32.BOOL #foreign user32;
    SetForegroundWindow :: (window: Win32.HWND) -> Win32. BOOL #foreign user32;
    SetFocus :: (window: Win32.HWND) -> Win32.BOOL #foreign user32;
    ShowCursor :: (show: bool) -> s32 #foreign user32;

    // SetClassLongPtrA :: (window: Win32.HWND, nIndex: s32, dwNewLong: s64) -> u64 #foreign user32;
    // GCLP_HCURSOR : s32 : -12;
}
