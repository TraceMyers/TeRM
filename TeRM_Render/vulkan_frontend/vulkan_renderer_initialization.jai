// initialize your first (and maybe only) renderer
init_first_renderer :: (first_renderer: *Renderer, options: Render_Init_Options, render_width: u32, render_height: u32) -> bool {
    render_target_width = render_width;
    render_target_height = render_height;
    success := init_renderer_shared_data(first_renderer, options);
    if !success then return false;
    return init_renderer_unique_data(first_renderer);
}

// if you are doing the multithreading + one renderer per thread style,
// pass subsequent renderers in here to initialize them.
// as in:
// init_first_renderer(renderer_0);
// init_subsequent_renderer(renderer_1, renderer_0);
// init_subsequent_renderer(renderer_2, renderer_0);
// ...
init_subsequent_renderer :: (subsequent_renderer: *Renderer, first_renderer: *Renderer) -> bool {
    subsequent_renderer.shared_data = first_renderer.shared_data;
    return init_renderer_unique_data(subsequent_renderer);
}

// helper proc for initialization, use it instead if you like.
// initializes the section of data in a renderer that is shared among renderers, if 
// you are doing the multithreading + one renderer per thread style
init_renderer_shared_data :: (thread_local_renderer: *Renderer, options: Render_Init_Options) -> bool {
    // context values are thread-local. this functions as a way to have a global
    // value that is also safe to reassign on any given thread, as no thread can remove or
    // swap out any other thread's renderer. so, using one renderer per thread (but still sharing 
    // vk instance and etc.) might be a good design to reduce the mental overhead of multithreading.
    scope_set_renderer(thread_local_renderer);
    using context.renderer;
    auto_release_temp();

    init_success = true;

    render_log(
#string HERE
initializing renderer for application...

    %, version %
    made with %, version %
    using % graphics, version %
HERE,
        application_name, 
        renderer_version_string(application_version),
        ifx engine_name == "" then "?" else engine_name, 
        renderer_version_string(engine_version),
        API,
        renderer_version_string(API_VERSION)
    );

    if options.populate_shader_data_in_working_directory {
        if !populate_shader_data() then return false;
    }
    
    run_init_proc(create_vk_instance);
    run_init_proc(create_surface);
    run_init_proc(select_physical_device);
    run_init_proc(create_logical_device);
    run_init_proc(create_swapchain_and_attachments);
    run_init_proc(create_frame_datas);
    run_init_proc(create_default_descriptors);
    run_init_proc(create_scratch_data);
    run_init_proc(create_descriptors);
    run_init_proc(create_default_pipelines);

    return init_success;
}

// helper proc for initialization, use it instead if you like.
// initializes the section of data in a renderer that is unique to each renderer, if 
// you are doing the multithreading + one renderer per thread style
init_renderer_unique_data :: (thread_local_renderer: *Renderer) -> bool {
    scope_set_renderer(thread_local_renderer);
    using context.renderer;
    auto_release_temp();

    return true;
}

#scope_file

// copies the shader source code and compile.bat file from this module into the user's project
// directory, creates a folder for compiled spirv, and runs a compile script so the shader
// data is ready for loading later. this really only needs to run once assuming no more shaders
// are added to the module, but behavior is on by default because it populates important data 
// without the user having to think about it. once finished, tells the user how to 
// turn the option off.
//
// the reason shader source and etc are copied into the project directory: because having
// your shaders all in one place is probably what most people want. 
//
// todo: you should be able to decide where in your project the shader directory goes. you
// can technically do that right now by setting your working directory before renderer init.
//
// todo: packaging = this needs to turn off 100%
populate_shader_data :: () -> bool {
    project_working_directory := get_working_directory();
    defer set_working_directory(project_working_directory);

    path_of_this_file := #filepath;
    term_render_path  := move_path_back_one_directory(path_of_this_file);
    term_shaders_path := tprint("%/vulkan_shaders", term_render_path);

    fully_exists, _:= how_much_of_path_exists_on_the_local_filesystem(parse_path(term_shaders_path));

    spiel := "render init options have 'populate_shader_data_in_working_directory' set to true";

    if !fully_exists {
        render_log("%, but the TeRM/Render structure is unable to find path to copy shaders from. expected path is one TeRM_Render/vulkan_shaders.", spiel);
        return false;
    }

    source_path  := term_shaders_path;
    dest_path    := move_path_forward_one_directory(project_working_directory, "shaders");
    copy_success := copy_directory(source_path, dest_path);

    if !copy_success {
        render_log("%, but the copy failed for an unknown reason. this can either be investigated at the system level or it might just be easier to copy by hand from the % to %.", spiel, source_path, dest_path);
        return false;
    } 

    spirv_directory := move_path_forward_one_directory(dest_path, "spirv");
    make_directory_if_it_does_not_exist(spirv_directory);
    fully_exists, _ = how_much_of_path_exists_on_the_local_filesystem(parse_path(spirv_directory));

    if !fully_exists {
        render_log("tried to create directory for shader compilation spirv output at %, but failed", spirv_directory);
        return false;
    }

    set_working_directory(dest_path);
    result := run_command(".\\compile.bat");
    if result.exit_code != 0 {
        render_log("tried to compile shaders in % using the compile.bat in there, but failed with exit code %", dest_path, result.exit_code);
        return false;
    }

    render_log("%, so the default shader datas were copied from % to % and the shaders were compiled. this is on by default for ease of use, but it can be turned off now.", spiel, source_path, dest_path);
    return true;
}

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
