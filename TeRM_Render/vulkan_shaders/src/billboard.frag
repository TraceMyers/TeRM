#version 450
#extension GL_EXT_nonuniform_qualifier : require
#extension GL_EXT_scalar_block_layout  : require

layout(location=0) in      vec2 in_uv;
layout(location=1) in      vec4 in_tint;
layout(location=2) in flat uint in_texture_index;

layout(location=0) out vec4 out_color;

layout(set=0, binding=0) uniform sampler2D textures[];

struct Material {
    vec4 albedo_factor;
    vec4 emissive_factor;
    float metallic_factor;
    float roughness_factor;

    float alpha_cutoff;

    int albedo_uv;
    int metallic_uv;
    int roughness_uv;
    int normal_uv;
    int occlusion_uv;
    int emissive_uv;

    int albedo_tex;
    int normal_tex;
    int emissive_tex;
    int orm_tex;             
};

#define MAX_MATERIALS 1024

layout(set=1, binding=0, scalar) readonly buffer Material_Block {
    Material materials[];
} material_block;

void main() {
    out_color = texture(textures[nonuniformEXT(in_texture_index)], in_uv) * in_tint; 
}
