#version 450
#extension GL_EXT_nonuniform_qualifier : require

layout(location=0) in vec3 in_position;
layout(location=1) in vec3 in_normal;
layout(location=2) in vec4 in_tangent;
layout(location=3) in vec2 in_uv_0;
layout(location=4) in vec2 in_uv_1;
layout(location=5) in vec4 in_color;

layout(location=0) out      mat3 out_tbn;
// 1, 2 = mat cols
layout(location=3) out      vec2 out_uv_0;
layout(location=4) out      vec2 out_uv_1;
layout(location=5) out      vec4 out_color;
layout(location=6) out flat int  out_material_id;

layout(set=2, binding=0) uniform Per_Frame_Uniform_Buffer {
    mat4  view;
    mat4  view_projection;
    vec3  camera_position; float _pad0;
    vec3  camera_forward;  float _pad1;
    vec3  camera_up;       float _pad2;
    vec3  camera_right;    float _pad3;
    float time;
    float delta_time;
} frame;

layout(set=3, binding=0, std430) readonly buffer Transform_Data {
    mat4 model[];
} transforms;

struct Mesh_Instance {
    int transform_id;
    int material_id;
};

layout(set=4, binding=0, std430) readonly buffer Instance_Data {
    Mesh_Instance instances[];
} instance_data;

void main() {
    Mesh_Instance inst = instance_data.instances[gl_InstanceIndex];
    mat4 model = transforms.model[inst.transform_id];

    gl_Position = vec4(in_position, 1.0) * model * frame.view_projection;

    // generating the orthonormal axes of this triangle in world space
    vec3 T = normalize(vec3(vec4(in_tangent.xyz, 0.0) * model));
    vec3 N = normalize(vec3(vec4(in_normal.xyz,  0.0) * model));
    vec3 B = cross(N, T) * in_tangent.w; // handedness - which direction does this ortho vector point of the two?

    out_tbn         = mat3(T, B, N);
    out_uv_0        = in_uv_0;
    out_uv_1        = in_uv_1;
    out_color       = in_color;
    out_material_id = inst.material_id;
}
