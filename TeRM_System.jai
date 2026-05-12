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

// ---------------------------- shennanigans

Console_Text_Image :: struct {
    // row first, so [y][x]
    text: []u8;
    text_width: s32;
    text_height: s32;
    upper_left_x: float; 
    upper_left_y: float;
    scale: float;
    scale_by: enum { WIDTH; HEIGHT;};
}

get_console_render_target_dimensions :: () -> width: s32, height: s32 {
    csbi: Console_Screen_Buffer_Info;

    stdout := Win32.GetStdHandle(Win32.STD_OUTPUT_HANDLE);

    if !GetConsoleScreenBufferInfo(stdout, *csbi) {
        return 0, 0;
    }

    return csbi.dwSize.x, csbi.dwSize.y;
}

get_width_scale :: (image: Console_Text_Image, render_target_width: s32, render_target_height: s32) -> float {

    if image.scale_by == .WIDTH {
        return image.scale;
    } else {
        render_height := render_target_height * image.scale;
        text_scalar   := render_height / image.text_height;
        return (image.text_width * text_scalar) / render_target_width;
    }
}

get_height_scale :: (image: Console_Text_Image, render_target_width: s32, render_target_height: s32) -> float {
    if image.scale_by == .WIDTH {
        render_width := render_target_width * image.scale;
        text_scalar  := render_width / image.text_width;
        return (image.text_height * text_scalar) / render_target_height;
    } else {
        return image.scale;
    }
}

set_console_text_image_character :: (image: *Console_Text_Image, char: u8) {
    for *image.text {
        if it.* != #char " " {
            it.* = char;
        }
    }
}

make_console_text_image :: (str: string, upper_left_x: float, upper_left_y: float, scale: float, scale_by_width := true, ignore_zero_length_lines := true, consume_whitespace_on_right := true) -> Console_Text_Image {
    max_line_length := 0;

    line_count: int;

    for :per_line str {
        line_count = it_index + 1;

        line_length: int;
        if consume_whitespace_on_right {
            for < c : it {
                if c != #char " " {
                    line_length = it_index + 1;
                    break;
                }
            }
        } else {
            line_length = it.count;
        }

        if line_length == 0 && ignore_zero_length_lines {
            continue;
        }

        max_line_length = max(max_line_length, xx line_length);
    }

    if max_line_length == 0 {
        return {};
    }

    image := Console_Text_Image.{
        text         = make_static_array(u8, max_line_length * line_count),
        text_width   = xx max_line_length,
        text_height  = xx line_count,
        upper_left_x = upper_left_x,
        upper_left_y = upper_left_y,
        scale        = scale,
        scale_by     = ifx scale_by_width then .WIDTH else .HEIGHT
    };

    for :per_line line, li : str {
        y := li;
        for x : 0..image.text_width-1 {
            if x >= line.count {
                image.text[y * image.text_width + x] = #char " ";
            } else {
                image.text[y * image.text_width + x] = line[x];
            }
        }
    }

    return image;
}

Console_Text_Color :: enum_flags s16 {
    FOREGROUND_BLUE;
    FOREGROUND_GREEN;
    FOREGROUND_RED;
    FOREGROUND_INTENSITY;
    BACKGROUND_BLUE;
    BACKGROUND_GREEN;
    BACKGROUND_RED;
    BACKGROUND_INTENSITY;
}

// shennanigans
render_text_images_to_console :: (images: []Console_Text_Image, color: Console_Text_Color = .FOREGROUND_BLUE | .FOREGROUND_GREEN | .FOREGROUND_RED) {
    auto_release_temp();
    if OS == .WINDOWS {
        csbi: Console_Screen_Buffer_Info;
        scroll_rect: Win32.SMALL_RECT;
        scroll_target: Win32.COORD;

        stdout := Win32.GetStdHandle(Win32.STD_OUTPUT_HANDLE);

        if !GetConsoleScreenBufferInfo(stdout, *csbi) {
            return;
        }

        SetConsoleTextAttribute(stdout, xx color);

        render_target_width  := csbi.dwSize.x;
        render_target_height := csbi.dwSize.y;
        render_target_size   := render_target_width * render_target_height;
        render_target        := make_static_array(u8, render_target_size,, temp);

        render_images_to_console_render_target(render_target, render_target_width, render_target_height, images);

        for y : 0..render_target_height-1 {
            pixel := render_target[y * render_target_width];
            pixel_start_x := 0;
            pixel_end_x   := 0;

            for x : 1..render_target_width {

                do_flush_draw: bool;
                next_pixel: u8;
                if x == render_target_width {
                    do_flush_draw = true;
                } else {
                    next_pixel = render_target[y * render_target_width + x];
                    if pixel != next_pixel {
                        do_flush_draw = true;
                    }
                }

                if do_flush_draw {
                    render_character_rect(stdout, xx pixel, csbi.wAttributes, render_target_height, {left=xx pixel_start_x, top= xx y, right=xx pixel_end_x, bottom=xx y});
                    pixel = next_pixel;
                    pixel_start_x = x;
                    pixel_end_x   = x;
                } else {
                    pixel_end_x   = x;
                }
            }
        }
    }
}

#if OS == .WINDOWS {
    vblank :: (handle: Win32.HANDLE, character_attributes: s16, rect: Win32.SMALL_RECT) {
        render_character_rect(handle, #char " ", character_attributes, rect.bottom, rect);
    }

    render_character_rect :: (handle: Win32.HANDLE, character: s8, character_attributes: s16, render_height: s32, scroll_rect: Win32.SMALL_RECT) {
        fill: Char_Info;
        scroll_target: Win32.COORD;

        // Scroll it upwards off the top of the buffer with a magnitude of the entire height.
        scroll_target.x = 0;
        scroll_target.y = xx (0 - render_height);

        fill.Char.UnicodeChar = character;
        fill.Attributes = character_attributes;

        // Do the scroll
        ScrollConsoleScreenBufferW(handle, *scroll_rect, null, scroll_target, *fill);
    }
}

#scope_file;

clear_console_render_target :: (render_target: []u8) {
    memset(render_target.data, #char " ", render_target.count);
}

render_images_to_console_render_target :: (render_target: []u8, width: s32, height: s32, images: []Console_Text_Image) {
    clear_console_render_target(render_target);

    for image : images {
        if image.text.count == 0 {
            continue;
        }

        assert(image.text_width * image.text_height == image.text.count);

        render_width, render_height: s32;

        // max'd because I don't want div by zero and/or rejection of images if too small
        if image.scale_by == .WIDTH {
            width_float  := image.scale * width;
            render_width  = max(round(width_float), 1);
            render_height = max(round(width_float * (cast(float) image.text_height / image.text_width)), 1);
        } else { // .HEIGHT
            height_float  := image.scale * height;
            render_height  = max(round(height_float), 1);
            render_width   = max(round(height_float * (cast(float) image.text_width / image.text_height)), 1);
        }

        Render_Rect :: struct {
            ul_x, ul_y, lr_x, lr_y: s32;
            inv_width:  float;
            inv_height: float;
        };
        render_rect: Render_Rect;

        render_rect.ul_x       = round(image.upper_left_x * width);
        render_rect.ul_y       = round(image.upper_left_y * height);
        render_rect.lr_x       = max(render_rect.ul_x + render_width  - 1, render_rect.ul_x);
        render_rect.lr_y       = max(render_rect.ul_y + render_height - 1, render_rect.ul_y);

        render_rect.inv_width  = 1.0 / cast(float) (render_rect.lr_x - render_rect.ul_x);
        render_rect.inv_height = 1.0 / cast(float) (render_rect.lr_y - render_rect.ul_y);

        render_target_to_image :: inline (x: s32, y: s32, render_rect: Render_Rect, image_width: s32, image_height: s32) -> s32, s32 {
            norm_pos_x := cast(float) (x - render_rect.ul_x) * render_rect.inv_width;
            norm_pos_y := cast(float) (y - render_rect.ul_y) * render_rect.inv_height;
            return round((image_width - 1) * norm_pos_x), round((image_height - 1) * norm_pos_y);
        }

        for y : render_rect.ul_y..render_rect.lr_y {
            for x : render_rect.ul_x..render_rect.lr_x {
                if x < 0 || y < 0 || x >= width || y >= height {
                    continue;
                }
                render_target_index := y * width + x;
                if render_target[render_target_index] == #char " " {
                    image_x, image_y := render_target_to_image(x, y, render_rect, image.text_width, image.text_height);
                    render_target[render_target_index] = image.text[image_y * image.text_width + image_x];
                }
            }
        }
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
}

#import "Basic";
#import "Window_Creation";
#import "Math";

#import "TeRM/TeRM_EncodeText";
#import "TeRM/TeRM_Math";
#import "TeRM/TeRM_String";
#import "TeRM/TeRM_Array";
