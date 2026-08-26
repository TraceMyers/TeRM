// todo: errors for other systems
// todo: code for other systems
// todo: more system info

System_Information :: struct {
    cpu_frequency: s64;
}

recommended_system_init :: () -> bool {
    #if OS == .WINDOWS {
        Win32.SetProcessDPIAware();
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

get_console_window :: () -> Window_Type {
    #if OS == .WINDOWS {
        return GetConsoleWindow();
    } else return null;
}

set_console_cursor_position :: (window: Window_Type, x: s16, y: s16) {
    if OS == .WINDOWS {
        SetConsoleCursorPosition(window, {x, y});
    }
}

clear_console :: () {
    if OS == .WINDOWS {
        print("\e[1;1H\e[2J");
    }
}

MIN_CPU_PAUSE_CYCLES : u64 : 400;

// try to pause the cpu at least some number of tsc cycles.
// if < min, just calls pause() once, because that resolution
// is too small for the procedure to handle.
cpu_pause :: inline (wait_cycles: u64 = MIN_CPU_PAUSE_CYCLES-1) {
    if wait_cycles <= MIN_CPU_PAUSE_CYCLES-1 {
        pause();
        return;
    }

    core_ids: [2]u32 = ---;
    cycles:   [2]u64 = ---;

    cycles[0], core_ids[0] = rdtscp();
    cycles[1], core_ids[1] = cycles[0], core_ids[0];
    cycle_sum: u64 = 60; // how many cycles have passed up to this point, estimate.

    while cycle_sum < wait_cycles {
        remain          := max(wait_cycles - cycle_sum, 0);
        pauses_per_loop := max(remain >> 8, 1);

        if pauses_per_loop >= 4 {
            pause();
            pause();
            pause();
            pause();
        } else if pauses_per_loop >= 2 {
            pause();
            pause();
        } else {
            pause();
        }
        
        cycles[1], core_ids[1] = rdtscp();

        if core_ids[1] != core_ids[0] {
            // if the core running the procedure changes mid-pause, it assumes 200
            // cycles were waited to avoid overshooting the target excessively.
            cycle_sum  += 200;
            cycles[0]   = cycles[1] - cycle_sum;
            core_ids[0] = core_ids[1];
        } else {
            cycle_sum = cycles[1] - cycles[0];
        }
    }
}

// progressive backoff starting with OS-level timer then cpu pauses.
// wait_error is an attempt to account for a measured single digit microsecond-level 
// error in getting system time, exiting loop, and getting out of the procedure.
// could be better.
wait :: (wait_ms: float64, wait_error: float64 = 0.001) -> time_spent_ms: float64, end_time: float64 {
    start_time := seconds_since_init();
    end_time   := start_time;

    wait_ms = wait_ms - wait_error;
    if wait_ms <= 0 {
        return 0, start_time;
    }

    spent_ms: float64;

    roomy_wait_time_ms := wait_ms - 1.5;
    while spent_ms < roomy_wait_time_ms {
        _, end_time = wait_inaccurate(0.25);
        spent_ms = (end_time - start_time) * 1000.0;
    }

    time_remain_ms := wait_ms - spent_ms;
    while time_remain_ms > 0.004 {
        cpu_pause(2048);
        end_time = seconds_since_init();
        spent_ms = (end_time - start_time) * 1000.0;
        time_remain_ms = wait_ms - spent_ms;
    }

    while spent_ms < wait_ms {
        cpu_pause();
        end_time = seconds_since_init();
        spent_ms = (end_time - start_time) * 1000.0;
    }

    return spent_ms, end_time;
}

wait_inaccurate :: inline (wait_ms: float64) -> time_spent_ms: float64, end_time: float64 {
    // #add_context system_timer: Win32.HANDLE;
    #if OS == .WINDOWS {
        start_time := seconds_since_init();
        end_time   := start_time;

        if context.system_timer == null {
            security_params: SyncObjectSecurityParams = .TIMER_MODIFY_STATE | .SYNCHRONIZE;
            flags : s32 = CREATE_WAITABLE_TIMER_MANUAL_RESET | CREATE_WAITABLE_TIMER_HIGH_RESOLUTION;
            context.system_timer = CreateWaitableTimerExW(null, null, flags, xx security_params);
            assert(context.system_timer != null);
        }

        spent_ms: float64;

        while spent_ms < wait_ms {
            MILLI_TO_100_NANO : s64 : 10_000;

            remaining_time_in_hundreds_of_ns: Win32.LARGE_INTEGER;
            remaining_time_in_hundreds_of_ns.QuadPart = max(cast(s64) (wait_ms - spent_ms) * MILLI_TO_100_NANO, 0);
            // negative time value indicates it's a duration, rather than a time point.
            remaining_time_in_hundreds_of_ns.QuadPart *= -1; 

            set_success := Win32.SetWaitableTimer(context.system_timer, *remaining_time_in_hundreds_of_ns, 0, null, null, Win32.BOOL.FALSE);
            if set_success == .FALSE {
                assert(false, "win32 SetWaitableTimer error: %", Win32.GetLastError());
            }
            wait_success := Win32.WaitForSingleObject(context.system_timer, 20);
            if wait_success != Win32.WAIT_OBJECT_0 {
                assert(false, "win32 WaitForSingleObject error: %", Win32.GetLastError());
            }

            end_time = seconds_since_init();
            spent_ms = (end_time - start_time) * 1000.0;
        }

        return spent_ms, end_time;
    } else {
        sleep_milliseconds(max(cast(s32) wait_ms, 1));
    }
}

#if OS == .WINDOWS {
    Win32 :: #import "Windows";

    user32   :: #system_library "user32";
    kernel32 :: #system_library "kernel32";

    IsWindow :: (window: Win32.HWND) -> Win32.BOOL #foreign user32;
    IsIconic :: (window: Win32.HWND) -> Win32.BOOL #foreign user32;
    SetCursorPos :: (x: s32, y: s32) -> Win32.BOOL #foreign user32;
    SetForegroundWindow :: (window: Win32.HWND) -> Win32. BOOL #foreign user32;
    SetFocus :: (window: Win32.HWND) -> Win32.BOOL #foreign user32;
    ShowCursor :: (show: bool) -> s32 #foreign user32;
    
    GetConsoleTitleW :: (lpConsoleTitle: *s8, nSize: s32) -> s32 #foreign kernel32;
    SetConsoleTitleW :: (lpConsoleTitle: *s8) -> Win32.BOOL #foreign kernel32;
    GetConsoleWindow :: () -> Win32.HWND #foreign kernel32;
    SetConsoleCursorPosition :: (hConsoleOutput: Win32.HANDLE, dwCursorPosition: Win32.COORD) -> Win32.BOOL #foreign kernel32;
    SetConsoleTextAttribute :: (hConsoleOutput: Win32.HANDLE, wAttributes: s16) -> Win32.BOOL #foreign kernel32; 

    FindWindowW :: (lpClassName: *s8, lpWindowName: *s8) -> Win32.HWND #foreign user32;
    GetTickCount :: () -> s32 #foreign kernel32;
    
    GetConsoleScreenBufferInfo :: (hConsoleOutput: Win32.HANDLE, lpConsoleScreenBufferInfo: *Console_Screen_Buffer_Info) -> Win32.BOOL #foreign kernel32;

    ScrollConsoleScreenBufferW :: (hConsoleOutput: Win32.HANDLE, lpScrollRectangle: *Win32.SMALL_RECT, lpClipRectangle: *Win32.SMALL_RECT, dwDestinationOrigin: Win32.COORD, lpFill: *Char_Info) -> Win32.BOOL #foreign kernel32;

    Console_Screen_Buffer_Info :: struct {
        dwSize: Win32.COORD;
        dwCursorPosition: Win32.COORD;
        wAttributes: s16;
        srWindow: Win32.SMALL_RECT;
        dwMaximumWindowSize: Win32.COORD;

    }

    Char_Info :: struct {
        using Char : union {
            UnicodeChar: s16;
            AsciiChar:   s8;
        }
        Attributes: s16;
    }

    CreateWaitableTimerExW :: (lpTimerAttributes: *Win32.SECURITY_ATTRIBUTES, lpName: *u16, dwFlags: s32, dwDesiredAccess: s32) -> Win32.HANDLE #foreign kernel32;

    CREATE_WAITABLE_TIMER_MANUAL_RESET : s32 : 0x1; 
    CREATE_WAITABLE_TIMER_HIGH_RESOLUTION : s32 : 0x2;
    TIMER_MODIFY_STATE : s32 : 0x02;

    SyncObjectSecurityParams :: enum s32 {
        SYNCHRONIZE         :: 0x00100000;
        TIMER_MODIFY_STATE  :: 0x00000002;
        TIMER_ALL_ACCESS    :: 0x001f0003;
    }

    #add_context system_timer: Win32.HANDLE;
}


#import "Basic";
#import "Window_Creation";
#import "Math";
#import "Machine_X64";

#import "TeRM/TeRM_EncodeText";
#import "TeRM/TeRM_Math";
#import "TeRM/TeRM_String";
#import "TeRM/TeRM_Array";
#import "TeRM/TeRM_Metaprogram";
