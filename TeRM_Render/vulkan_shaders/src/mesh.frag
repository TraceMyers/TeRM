#version 450
#extension GL_EXT_nonuniform_qualifier : require
#extension GL_EXT_scalar_block_layout : require

layout(location=0) in mat3 in_tbn;
// 1,2 = mat cols
layout(location=3) in      vec2 in_uv_0;
layout(location=4) in      vec2 in_uv_1;
layout(location=5) in      vec4 in_color;
layout(location=6) in flat int  in_material_id;

layout(location=0) out vec4 color;

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
    Material mat = material_block.materials[in_material_id]; 
    vec2 uvs[2] = vec2[2](in_uv_0, in_uv_1);

    color = texture(textures[nonuniformEXT(mat.albedo_tex)], uvs[mat.albedo_uv]) * mat.albedo_factor * in_color;
}
