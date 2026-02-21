#module_parameters()(
    VALIDATION_LEVEL := 0,
    API := "VULKAN"
);

TERM_RENDER_VERSION_MAJOR : u32 : 0;
TERM_RENDER_VERSION_MINOR : u32 : 1;

#if API == {
case "VULKAN";
    #load "vulkan_frontend/vulkan_frontend.jai";
case "DIRECT3D";
    #load "direct3d_frontend.jai";
}

#scope_module

render_target_width: u32;
render_target_height: u32;
should_recreate_swapchain: bool;

#add_context renderer: *Renderer;

scope_set_renderer :: (in_renderer: *Renderer) #expand {
    context.renderer = in_renderer;
    `defer context.renderer = null;
}

#if OS == .WINDOWS {
    Win32 :: #import "Windows";
}

NANOSECONDS_PER_MILLISECOND :: 1_000_000;
NANOSECONDS_PER_SECOND :: 1_000_000_000;
VALIDATION_LEVEL_NONE   :: 0;
VALIDATION_LEVEL_MEDIUM :: 1;
VALIDATION_LEVEL_HIGH   :: 2;
VALIDATION_ON :: #run VALIDATION_LEVEL >= VALIDATION_LEVEL_MEDIUM;

render_log :: (fmt: string, args: ..Any, add_newline := true, caller_loc := #caller_location) #expand {
    #if VALIDATION_ON {
        trm_log(fmt=fmt, args=..args, header="TeRM/Render", add_newline=add_newline, caller_loc=caller_loc);
    }
}

run_init_proc :: (proc: () -> bool, caller_loc := #caller_location) {
    if !context.renderer.init_success {
        return;
    }
    context.renderer.init_success = proc();
    if !context.renderer.init_success {
        render_log("init failure. exiting.", caller_loc=caller_loc);
    }
}

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
