
dev_gui_process_input_event :: (event: Event) {
    using io := GetIO();

    mouse_button: s32 = -1;
    if event.key_code == {
    case .MOUSE_BUTTON_LEFT;
        mouse_button = 0;
    case .MOUSE_BUTTON_RIGHT;
        mouse_button = 1;
    case .MOUSE_BUTTON_MIDDLE;
        mouse_button = 2;
    }
    if mouse_button != -1 {
        AddMouseButtonEvent(io, 0, event.key_pressed != 0);
        return;
    }

    if event.type == {
    case .KEYBOARD;
        imgui_update_key_modifiers(io, *event);
        imgui_key := input_key_to_imgui_key(io, event.key_code);
        AddKeyEvent(io, imgui_key, event.key_pressed != 0);
    case .TEXT_INPUT;
        AddInputCharacter(io, event.utf32);
    case .MOUSE_WHEEL;
        wheel_val := event.wheel_delta.(float) / event.typical_wheel_delta.(float);
        AddMouseWheelEvent(io, 0, wheel_val);
    }
}

dev_gui_rgba :: (r: u8, g: u8, b: u8, a : u8 = 255) -> ImGui.ImColor {
    return .{r.(float) / 255.0, g.(float) / 255.0, b.(float) / 255.0, a.(float) / 255.0};
}

dev_gui_set_theme_paper_and_ink :: () {
    scope_set_working_directory(module_path());

    s := ImGui.GetStyle();

    ROUNDING :: 4.0;
    s.WindowRounding    = ROUNDING;
    s.ChildRounding     = ROUNDING;
    s.PopupRounding     = ROUNDING;
    s.FrameRounding     = ROUNDING;
    s.ScrollbarRounding = ROUNDING;
    s.GrabRounding      = ROUNDING;
    s.TabRounding       = ROUNDING;
    s.TreeLinesRounding = ROUNDING;

    main_bg_color       := dev_gui_rgba(243,237,226);
    main_bg_color.xyz *= 0.85;
    secondary_bg_color  := dev_gui_rgba(239,232,219);
    secondary_bg_color.xyz *= 0.85;

    s.Colors[ImGui.Col.Text]                  = dev_gui_rgba(43,43,43);
    s.Colors[ImGui.Col.TextDisabled]          = dev_gui_rgba(111,106,96);
    s.Colors[ImGui.Col.WindowBg]              = main_bg_color;
    s.Colors[ImGui.Col.ChildBg]               = secondary_bg_color;
    s.Colors[ImGui.Col.PopupBg]               = secondary_bg_color;
    s.Colors[ImGui.Col.Border]                = dev_gui_rgba(0,0,0,35);
    s.Colors[ImGui.Col.FrameBg]               = dev_gui_rgba(255,255,255,180);
    s.Colors[ImGui.Col.FrameBgHovered]        = dev_gui_rgba(42,127,98,60);
    s.Colors[ImGui.Col.FrameBgActive]         = dev_gui_rgba(178,76,99,70);
    s.Colors[ImGui.Col.TitleBg]               = dev_gui_rgba(243,237,226);
    s.Colors[ImGui.Col.TitleBgActive]         = dev_gui_rgba(243,237,226);
    s.Colors[ImGui.Col.MenuBarBg]             = dev_gui_rgba(239,232,219);
    s.Colors[ImGui.Col.ScrollbarBg]           = dev_gui_rgba(239,232,219);
    s.Colors[ImGui.Col.ScrollbarGrab]         = dev_gui_rgba(42,127,98,120);
    s.Colors[ImGui.Col.ScrollbarGrabHovered]  = dev_gui_rgba(42,127,98,180);
    s.Colors[ImGui.Col.ScrollbarGrabActive]   = dev_gui_rgba(178,76,99,200);
    s.Colors[ImGui.Col.CheckMark]             = dev_gui_rgba(42,127,98);
    s.Colors[ImGui.Col.SliderGrab]            = dev_gui_rgba(42,127,98,220);
    s.Colors[ImGui.Col.SliderGrabActive]      = dev_gui_rgba(178,76,99,230);
    s.Colors[ImGui.Col.Button]                = dev_gui_rgba(42,127,98,230);
    s.Colors[ImGui.Col.ButtonHovered]         = dev_gui_rgba(42,127,98,255);
    s.Colors[ImGui.Col.ButtonActive]          = dev_gui_rgba(178,76,99,240);
    s.Colors[ImGui.Col.Header]                = dev_gui_rgba(42,127,98,80);
    s.Colors[ImGui.Col.HeaderHovered]         = dev_gui_rgba(178,76,99,120);
    s.Colors[ImGui.Col.HeaderActive]          = dev_gui_rgba(42,127,98,160);
    s.Colors[ImGui.Col.Separator]             = dev_gui_rgba(0,0,0,50);
    s.Colors[ImGui.Col.ResizeGrip]            = dev_gui_rgba(0,0,0,40);
    s.Colors[ImGui.Col.ResizeGripHovered]     = dev_gui_rgba(0,0,0,80);
    s.Colors[ImGui.Col.ResizeGripActive]      = dev_gui_rgba(0,0,0,120);
    s.Colors[ImGui.Col.Tab]                   = dev_gui_rgba(255,255,255,200);
    s.Colors[ImGui.Col.TabHovered]            = dev_gui_rgba(178,76,99,160);
    s.Colors[ImGui.Col.TabActive]             = dev_gui_rgba(42,127,98,160);
    s.Colors[ImGui.Col.TableHeaderBg]         = dev_gui_rgba(255,255,255,180);
    s.Colors[ImGui.Col.TableBorderStrong]     = dev_gui_rgba(0,0,0,40);
    s.Colors[ImGui.Col.TableBorderLight]      = dev_gui_rgba(0,0,0,20);

    font_config: ImGui.ImFontConfig;
    font_config.OversampleH = 3;
    font_config.OversampleV = 3;
    font_config.PixelSnapH = false;

    io := ImGui.GetIO();
    // io.Fonts.AddFontFromFileTTF(io.Fonts, "fonts/PkgTTC-IosevkaAile-33.2.9/IosevkaAile-Regular.ttc", 14.0, null, io.Fonts.GetGlyphRangesDefault(io.Fonts));
    io.Fonts.AddFontFromFileTTF(io.Fonts, "fonts/RobotoMono-SemiBold.ttf", 16.0, null, io.Fonts.GetGlyphRangesDefault(io.Fonts));

    io.Fonts.Build(io.Fonts);
}

draw_dev_gui :: (cmd: VkCommandBuffer) {
    ImplVulkan_NewFrame();
    ImplWin32_NewFrame();
    NewFrame();

    if context.renderer.user_imgui_callback != null {
        context.renderer.user_imgui_callback();
    }

    Render();
    ImGui.ImplVulkan_RenderDrawData(ImGui.GetDrawData(), cmd);
}

#scope_module


imgui_update_key_modifiers :: (using io: *IO, event: *Event) {
    AddKeyEvent(io, .Mod_Ctrl,  event.ctrl_pressed);
    AddKeyEvent(io, .Mod_Shift, event.shift_pressed);
    AddKeyEvent(io, .Mod_Alt,   event.alt_pressed);
    AddKeyEvent(io, .Mod_Super, event.cmd_meta_pressed);
}

input_key_to_imgui_key :: (using io: *IO, key_code: Key_Code) -> Key {
    if key_code >= #char "A" && key_code <= #char "Z" {
        letter_diff := key_code.(s32) - #char "A";
        return xx (Key.A.(s32) + letter_diff);
    }
    if key_code >= #char "0" && key_code <= #char "9" {
        number_diff := key_code.(s32) - #char "0";
        return xx (Key._0.(s32) + number_diff);
    }
    if key_code >= .F1 && key_code <= .F24 {
        fkey_diff := key_code.(s32) - Key_Code.F1.(s32);
        return xx (Key.F1.(s32) + fkey_diff);
    }
    if key_code == {
    case .UNKNOWN; 
        return .None;
    case .BACKSPACE;
        return .Backspace;
    case .TAB;
        return .Tab;
    case .LINEFEED;
        return .None;
    case .ENTER;
        return .Enter;
    case .ESCAPE;
        return .Escape;
    case .SPACEBAR;
        return .Space;
    // The letters A-Z live in here as well and may be returned
    // by keyboard events.
    case .DELETE;
        return .Delete;
    case .ARROW_UP;
        return .UpArrow;
    case .ARROW_DOWN;
        return .DownArrow;
    case .ARROW_LEFT;
        return .LeftArrow;
    case .ARROW_RIGHT;
        return .RightArrow;
    case .PAGE_UP;
        return .PageUp;
    case .PAGE_DOWN;
        return .PageDown;
    case .HOME;
        return .Home;
    case .END;
        return .End;
    case .INSERT;
        return .Insert;
    case .PAUSE;
        return .Pause;
    case .SCROLL_LOCK;
        return .ScrollLock;
    case .ALT;
        return .LeftAlt; 
    case .CTRL;
        return .LeftCtrl;
    case .SHIFT;
        return .LeftShift;
    case .CMD; // case .META;
        return .LeftSuper;
    case .PRINT_SCREEN;
        return .PrintScreen;
    case .MOUSE_BUTTON_LEFT;
        return .MouseLeft;
    case .MOUSE_BUTTON_MIDDLE;
        return .MouseMiddle;
    case .MOUSE_BUTTON_RIGHT;
        return .MouseRight;
    // case .MOUSE_WHEEL_UP;
    //     return .MouseWheelY;
    // case .MOUSE_WHEEL_DOWN;
    //     return .MouseWheelX;
    }
    // TODO:
    // from:
    // case .GAMEPAD_0_BEGIN;
    // case .GAMEPAD_0_END :: GAMEPAD_0_BEGIN + xx GAMEPAD_BUTTON_COUNT;
    // case .GAMEPAD_1_BEGIN;
    // case .GAMEPAD_1_END :: GAMEPAD_1_BEGIN + xx GAMEPAD_BUTTON_COUNT;
    // case .GAMEPAD_2_BEGIN;
    // case .GAMEPAD_2_END :: GAMEPAD_2_BEGIN + xx GAMEPAD_BUTTON_COUNT;
    // case .GAMEPAD_3_BEGIN;
    // case .GAMEPAD_3_END :: GAMEPAD_3_BEGIN + xx GAMEPAD_BUTTON_COUNT;
    // to:
    // GamepadStart        :: 632;
    // GamepadBack         :: 633;
    // GamepadFaceLeft     :: 634;
    // GamepadFaceRight    :: 635;
    // GamepadFaceUp       :: 636;
    // GamepadFaceDown     :: 637;
    // GamepadDpadLeft     :: 638;
    // GamepadDpadRight    :: 639;
    // GamepadDpadUp       :: 640;
    // GamepadDpadDown     :: 641;
    // GamepadL1           :: 642;
    // GamepadR1           :: 643;
    // GamepadL2           :: 644;
    // GamepadR2           :: 645;
    // GamepadL3           :: 646;
    // GamepadR3           :: 647;
    // GamepadLStickLeft   :: 648;
    // GamepadLStickRight  :: 649;
    // GamepadLStickUp     :: 650;
    // GamepadLStickDown   :: 651;
    // GamepadRStickLeft   :: 652;
    // GamepadRStickRight  :: 653;
    // GamepadRStickUp     :: 654;
    // GamepadRStickDown   :: 655;
    return .None;
}

#scope_file

using ImGui;
