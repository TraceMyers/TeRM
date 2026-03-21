#version 450
#extension GL_EXT_nonuniform_qualifier : require

layout(location=0) in      vec2 in_uv;
layout(location=1) in      vec3 in_tint;
layout(location=2) in flat uint in_texture_index;

layout(location=0) out vec4 out_color;

layout(set=1, binding=0, std430) readonly buffer Instance_Data {
    Billboard_Instance instances[];
} instance_data;

layout(set=2, binding=0) uniform sampler2D textures[];

void main() {
    out_color = texture(textures[nonuniformEXT(in_texture_index)], in_uv) * vec4(in_tint, 1); 
}
