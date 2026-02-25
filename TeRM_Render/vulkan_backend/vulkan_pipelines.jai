create_device_space_mesh_pipeline :: () -> bool {
    using context.renderer;
    auto_release_temp();

    vert := get_shader("device_space_mesh_vert");
    if !validate(vert != null, "failed to get device space vert shader") then return false;

    frag := get_shader("device_space_mesh_frag");
    if !validate(frag != null, "failed to get device space frag shader") then return false;

    shader_stages := VkPipelineShaderStageCreateInfo.[
     .{
        stage = .VERTEX_BIT,
        module = vert,
        pName = "main"
    }, 
    .{
        stage = .FRAGMENT_BIT,
        module = frag,
        pName = "main"
    }];

    vertex_bindings, vertex_attributes := make_vertex_descriptors(Simple_Vertex,, temp);

    vertex_input_info := VkPipelineVertexInputStateCreateInfo.{
        vertexBindingDescriptionCount = 1,
        pVertexBindingDescriptions = *vertex_bindings,
        vertexAttributeDescriptionCount = xx vertex_attributes.count,
        pVertexAttributeDescriptions = vertex_attributes.data
    };

    input_assembly_info := VkPipelineInputAssemblyStateCreateInfo.{
        topology = .TRIANGLE_LIST,
    };

    viewport := VkViewport.{
        width = xx swapchain.extent.width,
        height = xx swapchain.extent.height,
        minDepth = MIN_DEPTH,
        maxDepth = MAX_DEPTH
    };

    scissor := VkRect2D.{
        extent = swapchain.extent
    };

    viewport_create_info := VkPipelineViewportStateCreateInfo.{
        viewportCount = 1,
        scissorCount = 1
    };

    rasterizer_create_info := VkPipelineRasterizationStateCreateInfo.{
        depthClampEnable = VK_FALSE,
        rasterizerDiscardEnable = VK_FALSE,
        polygonMode = .FILL,
        lineWidth = 1.0,
        // cullMode = .FRONT_BIT,
        // cullMode = .BACK_BIT,
        cullMode = .NONE,
        frontFace = .CLOCKWISE,
        depthBiasEnable = VK_FALSE,
        depthBiasConstantFactor = 0.0,
        depthBiasClamp = 0.0,
        depthBiasSlopeFactor = 0.0
    };

    multisample_create_info := VkPipelineMultisampleStateCreateInfo.{
        sampleShadingEnable = VK_FALSE,
        rasterizationSamples = ._1_BIT,
        minSampleShading = 1.0,
        pSampleMask = null,
        alphaToCoverageEnable = VK_FALSE,
        alphaToOneEnable = VK_FALSE
    };

    color_blend_attachment := VkPipelineColorBlendAttachmentState.{
        colorWriteMask = .R_BIT | .G_BIT | .B_BIT | .A_BIT,
        blendEnable = VK_TRUE,
        srcColorBlendFactor = .SRC_ALPHA,
        dstColorBlendFactor = .ONE_MINUS_SRC_ALPHA,
        colorBlendOp = .ADD,
        srcAlphaBlendFactor = .ONE,
        dstAlphaBlendFactor = .ZERO,
        alphaBlendOp = .ADD
    };

    color_blend_create := VkPipelineColorBlendStateCreateInfo.{
        logicOpEnable = VK_FALSE,
        logicOp = .COPY,
        attachmentCount = 1,
        pAttachments = *color_blend_attachment
    };

    dynamic_states := VkDynamicState.[
        .VIEWPORT,
        .SCISSOR,
        // .LINE_WIDTH,
        // .DEPTH_BIAS,
        // .BLEND_CONSTANTS,
        // .DEPTH_BOUNDS,
        // .STENCIL_COMPARE_MASK             :: 6;
        // .STENCIL_WRITE_MASK               :: 7;
        // .STENCIL_REFERENCE                :: 8;
        // .VIEWPORT_W_SCALING_NV            :: 1000087000;
        // .DISCARD_RECTANGLE_EXT            :: 1000099000;
        // SAMPLE_LOCATIONS_EXT             :: 1000143000;
    ];

    dynamic_state := VkPipelineDynamicStateCreateInfo.{
        dynamicStateCount = xx dynamic_states.count,
        pDynamicStates = dynamic_states.data
    };

    // layouts := VkDescriptorSetLayout.[
    //     mesh_descriptor_set_layout,
    // ];

    // color_pc := VkPushConstantRange.{
    //     stageFlags = .VERTEX_BIT,
    //     offset = 0,
    //     size = size_of(float32) * 16 + size_of(float32) * 4 + size_of(float) * 4
    // };

    pipeline_layout_info := VkPipelineLayoutCreateInfo.{
        // setLayoutCount = xx layouts.count,
        // pSetLayouts = layouts.data,
        // pushConstantRangeCount = 1,
        // pPushConstantRanges = *color_pc
    };

    if !validate(vkCreatePipelineLayout(logical.obj, *pipeline_layout_info, null, *device_space_mesh_pipeline_layout), "failed to create device space mesh pipeline layout") then return false;

    // color_attachment_format := VkFormat.R16G16B16A16_SFLOAT;
    color_attachment_format := VkFormat.R8G8B8A8_UNORM;
    rendering_create_info := VkPipelineRenderingCreateInfo.{
        colorAttachmentCount=1,
        pColorAttachmentFormats = *color_attachment_format,
        depthAttachmentFormat = DEPTH_FORMAT
    };

    depth_stencil_info := VkPipelineDepthStencilStateCreateInfo.{
        depthTestEnable = VK_TRUE,
        depthWriteEnable = VK_TRUE,
        depthCompareOp = .GREATER, // this renderer has 1=near, 0=far
        depthBoundsTestEnable = VK_FALSE,
        stencilTestEnable = VK_FALSE,
        // front:                 VkStencilOpState;
        // back:                  VkStencilOpState;
        // minDepthBounds:        float;
        // maxDepthBounds:        float;
    };

    pipeline_create := VkGraphicsPipelineCreateInfo.{
        pNext = *rendering_create_info,
        stageCount = xx shader_stages.count,
        pStages = shader_stages.data,
        pVertexInputState = *vertex_input_info,
        pInputAssemblyState = *input_assembly_info,
        // pTessellationState:  *VkPipelineTessellationStateCreateInfo;
        pViewportState = *viewport_create_info,
        pRasterizationState = *rasterizer_create_info,
        pMultisampleState = *multisample_create_info,
        pDepthStencilState = *depth_stencil_info,
        pColorBlendState = *color_blend_create,
        pDynamicState = *dynamic_state,
        layout = device_space_mesh_pipeline_layout,
        // renderPass:          VkRenderPass;
        // subpass:             u32;
        // basePipelineHandle:  VkPipeline;
        // basePipelineIndex:   s32;
    };

    if !validate(vkCreateGraphicsPipelines(logical.obj, VK_NULL_HANDLE, 1, *pipeline_create, null, *device_space_mesh_pipeline), "failed to create the device space mesh pipeline") then return false;

    render_log("created the device space mesh pipeline");
    return true;
}

create_device_space_mesh_textured_pipeline :: () -> bool {
    using context.renderer;
    auto_release_temp();

    vert := get_shader("device_space_mesh_textured_vert");
    if !validate(vert != null, "failed to get device space textured vert shader") then return false;

    frag := get_shader("device_space_mesh_textured_frag");
    if !validate(frag != null, "failed to get device space textured frag shader") then return false;

    shader_stages := VkPipelineShaderStageCreateInfo.[
    {
        stage = .VERTEX_BIT,
        module = vert,
        pName = "main"
    }, 
    {
        stage = .FRAGMENT_BIT,
        module = frag,
        pName = "main"
    }];

    vertex_bindings, vertex_attributes := make_vertex_descriptors(Simple_Vertex,, temp);

    vertex_input_info := VkPipelineVertexInputStateCreateInfo.{
        vertexBindingDescriptionCount = 1,
        pVertexBindingDescriptions = *vertex_bindings,
        vertexAttributeDescriptionCount = xx vertex_attributes.count,
        pVertexAttributeDescriptions = vertex_attributes.data
    };

    input_assembly_info := VkPipelineInputAssemblyStateCreateInfo.{
        topology = .TRIANGLE_LIST,
    };

    viewport := VkViewport.{
        width = xx swapchain.extent.width,
        height = xx swapchain.extent.height,
        minDepth = MIN_DEPTH,
        maxDepth = MAX_DEPTH
    };

    scissor := VkRect2D.{
        extent = swapchain.extent
    };

    viewport_create_info := VkPipelineViewportStateCreateInfo.{
        viewportCount = 1,
        scissorCount = 1
    };

    rasterizer_create_info := VkPipelineRasterizationStateCreateInfo.{
        depthClampEnable = VK_FALSE,
        rasterizerDiscardEnable = VK_FALSE,
        polygonMode = .FILL,
        lineWidth = 1.0,
        // cullMode = .FRONT_BIT,
        // cullMode = .BACK_BIT,
        cullMode = .NONE,
        frontFace = .CLOCKWISE,
        depthBiasEnable = VK_FALSE,
        depthBiasConstantFactor = 0.0,
        depthBiasClamp = 0.0,
        depthBiasSlopeFactor = 0.0
    };

    multisample_create_info := VkPipelineMultisampleStateCreateInfo.{
        sampleShadingEnable = VK_FALSE,
        rasterizationSamples = ._1_BIT,
        minSampleShading = 1.0,
        pSampleMask = null,
        alphaToCoverageEnable = VK_FALSE,
        alphaToOneEnable = VK_FALSE
    };

    color_blend_attachment := VkPipelineColorBlendAttachmentState.{
        colorWriteMask = .R_BIT | .G_BIT | .B_BIT | .A_BIT,
        blendEnable = VK_TRUE,
        srcColorBlendFactor = .SRC_ALPHA,
        dstColorBlendFactor = .ONE_MINUS_SRC_ALPHA,
        colorBlendOp = .ADD,
        srcAlphaBlendFactor = .ONE,
        dstAlphaBlendFactor = .ZERO,
        alphaBlendOp = .ADD
    };

    color_blend_create := VkPipelineColorBlendStateCreateInfo.{
        logicOpEnable = VK_FALSE,
        logicOp = .COPY,
        attachmentCount = 1,
        pAttachments = *color_blend_attachment
    };

    dynamic_states := VkDynamicState.[
        .VIEWPORT,
        .SCISSOR,
        // .LINE_WIDTH,
        // .DEPTH_BIAS,
        // .BLEND_CONSTANTS,
        // .DEPTH_BOUNDS,
        // .STENCIL_COMPARE_MASK             :: 6;
        // .STENCIL_WRITE_MASK               :: 7;
        // .STENCIL_REFERENCE                :: 8;
        // .VIEWPORT_W_SCALING_NV            :: 1000087000;
        // .DISCARD_RECTANGLE_EXT            :: 1000099000;
        // SAMPLE_LOCATIONS_EXT             :: 1000143000;
    ];

    dynamic_state := VkPipelineDynamicStateCreateInfo.{
        dynamicStateCount = xx dynamic_states.count,
        pDynamicStates = dynamic_states.data
    };

    layouts := VkDescriptorSetLayout.[
        scratch_texture_sampler_descriptor_set_layout,
    ];

    // color_pc := VkPushConstantRange.{
    //     stageFlags = .VERTEX_BIT,
    //     offset = 0,
    //     size = size_of(float32) * 16 + size_of(float32) * 4 + size_of(float) * 4
    // };

    pipeline_layout_info := VkPipelineLayoutCreateInfo.{
        setLayoutCount = xx layouts.count,
        pSetLayouts = layouts.data,
        // pushConstantRangeCount = 1,
        // pPushConstantRanges = *color_pc
    };

    if !validate(vkCreatePipelineLayout(logical.obj, *pipeline_layout_info, null, *device_space_mesh_textured_pipeline_layout), "failed to create device space mesh textured pipeline layout") then return false;

    // color_attachment_format := VkFormat.R16G16B16A16_SFLOAT;
    color_attachment_format := VkFormat.R8G8B8A8_UNORM;
    rendering_create_info := VkPipelineRenderingCreateInfo.{
        colorAttachmentCount=1,
        pColorAttachmentFormats = *color_attachment_format,
        depthAttachmentFormat = DEPTH_FORMAT
    };

    depth_stencil_info := VkPipelineDepthStencilStateCreateInfo.{
        depthTestEnable = VK_TRUE,
        depthWriteEnable = VK_TRUE,
        depthCompareOp = .GREATER, // 1=near, 0=far
        depthBoundsTestEnable = VK_FALSE,
        stencilTestEnable = VK_FALSE,
        // front:                 VkStencilOpState;
        // back:                  VkStencilOpState;
        // minDepthBounds:        float;
        // maxDepthBounds:        float;
    };

    pipeline_create := VkGraphicsPipelineCreateInfo.{
        pNext = *rendering_create_info,
        stageCount = xx shader_stages.count,
        pStages = shader_stages.data,
        pVertexInputState = *vertex_input_info,
        pInputAssemblyState = *input_assembly_info,
        // pTessellationState:  *VkPipelineTessellationStateCreateInfo;
        pViewportState = *viewport_create_info,
        pRasterizationState = *rasterizer_create_info,
        pMultisampleState = *multisample_create_info,
        pDepthStencilState = *depth_stencil_info,
        pColorBlendState = *color_blend_create,
        pDynamicState = *dynamic_state,
        layout = device_space_mesh_textured_pipeline_layout,
        // renderPass:          VkRenderPass;
        // subpass:             u32;
        // basePipelineHandle:  VkPipeline;
        // basePipelineIndex:   s32;
    };

    if !validate(vkCreateGraphicsPipelines(logical.obj, VK_NULL_HANDLE, 1, *pipeline_create, null, *device_space_mesh_textured_pipeline), "failed to create the device space mesh textured pipeline") then return false;

    render_log("created the device space mesh pipeline");
    return true;
}
