// initialize your first (and maybe only) renderer
init_first_renderer :: (first_renderer: *Renderer, render_width: u32, render_height: u32) -> bool {
    render_target_width = render_width;
    render_target_height = render_height;
    success := init_renderer_shared_data(first_renderer);
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
init_renderer_shared_data :: (thread_local_renderer: *Renderer) -> bool {
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
    
    run_init_proc(create_vk_instance);
    run_init_proc(create_surface);
    run_init_proc(select_physical_device);
    run_init_proc(create_logical_device);
    run_init_proc(create_swapchain_and_attachments);
    run_init_proc(create_frame_datas);

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

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
