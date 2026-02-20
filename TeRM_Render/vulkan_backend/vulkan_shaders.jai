get_shader :: (filename: string) -> VkShaderModule {
    using context.renderer;
    auto_release_temp();

    existing_shader := table_get(*shader_table, filename);
    render_log("existing shader: %", existing_shader);
    if existing_shader != null then return existing_shader.*;

    new_shader := create_shader_module_from_file(filename);
    table_set(*shader_table, filename, new_shader);

    return new_shader;
}

create_shader_module_from_file :: (filename: string) -> VkShaderModule {
    using context.renderer;
    auto_release_temp();

    file_path := tprint("../shaders/spirv/%.spv", filename);
    spirv, success := read_entire_file(file_path, true,, temp);
    if !validate(success, "failed to load shader binary for %", file_path) then return null;

    create_info := VkShaderModuleCreateInfo.{
        codeSize = xx spirv.count,
        pCode = xx spirv.data
    };

    module: VkShaderModule = ---;
    if !validate(vkCreateShaderModule(logical.obj, *create_info, null, *module), "failed to create a shader module with file at path %", file_path) then return null;

    return module;
}

