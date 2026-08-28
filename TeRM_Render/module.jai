// don't use this module. it's in development and doesn't do anything useful.

#module_parameters()(
    VALIDATION_LEVEL := 0,
    API := "VULKAN"
);

TERM_RENDER_VERSION_MAJOR : u32 : 0;
TERM_RENDER_VERSION_MINOR : u32 : 1;

#if API == {
case "VULKAN";
    #load "vulkan_frontend/vulkan_frontend.jai";
// case "DIRECT3D";
//     #load "direct3d_frontend.jai";
}

#scope_module

module_path :: () -> string {
    return get_final_path(#filepath,, temp);
}

render_target_width: u32;
render_target_height: u32;
should_recreate_swapchain: bool;

#add_context renderer: *Renderer;

scope_set_renderer :: (in_renderer: *Renderer) #expand {
    context.renderer = in_renderer;
    `prev_renderer := context.renderer;
    `defer context.renderer = prev_renderer;
}

#if OS == .WINDOWS {
    Win32 :: #import "Windows";
}

#import "Window_Creation";
#import "Basic";
#import "Math";
#import "File";
#import "File_Utilities";
#import "Process";
#import "Sort";
#import "stb_image";
#import "Input";
#import "Hash_Table";

#import "TeRM/TeRM_Allocation";
#import "TeRM/TeRM_Scope";
#import "TeRM/TeRM_Log";
#import "TeRM/TeRM_Array";
#import "TeRM/TeRM_String";
#import "TeRM/TeRM_Storage";
#import "TeRM/TeRM_Color";
#import "TeRM/TeRM_File";
#import "TeRM/TeRM_System";
#import "TeRM/TeRM_Math";
#import "TeRM/TeRM_Render/vulkan-jai";
ImGui :: #import "TeRM/TeRM_Render/ImGui_VulkanWin32";
#import "TeRM/TeRM_Camera";
#import "TeRM/TeRM_Metaprogram";
#import "TeRM/TeRM_Mesh"(user_types = Mesh_Import_Types);
#import "TeRM/TeRM_Physics";

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

run_init_proc :: (proc: Code, caller_loc := #caller_location) #expand {
    proc_name :: #run code_string(proc);
    render_log("calling %", proc_name);
    if !context.renderer.init_success {
        return;
    }
    #insert #run tprint("context.renderer.init_success = `%();", proc_name);
    if !context.renderer.init_success {
        render_log("init failure. exiting.", caller_loc=caller_loc);
    }
}

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
