#version 450

layout(location=0) in vec2 in_position;
layout(location=1) in vec2 in_uv;

layout(location=0) out      vec2 out_uv;
layout(location=1) out      vec4 out_tint;
layout(location=2) out flat uint out_texture_index;

struct Billboard_Instance {
    vec3 position;      float _pad0;
    vec4 tint;
    vec2 scale;
    vec2 uv_offset;
    vec2 uv_scale;  
    uint texture_index; float _pad1;
};

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

// std430 makes it so arrays of data are packed correctly rather
// than having each element aligned to the struct's alignment.
// does nothing here probably a good idea to always use it.
layout(set=3, binding=0, std430) readonly buffer Instance_Data {
    Billboard_Instance instances[];
} instance_data;

void main() {
    Billboard_Instance inst = instance_data.instances[gl_InstanceIndex];

    float right_distance = in_position.x * inst.scale.x;
    float up_distance    = in_position.y * inst.scale.y;

    vec3 world_offset = frame.camera_up * up_distance + frame.camera_right * right_distance;
    vec3 world_pos    = inst.position.xyz + world_offset;

    gl_Position = vec4(world_pos, 1.0) * frame.view_projection;

    out_tint          = inst.tint;
    out_uv            = inst.uv_offset + in_uv * inst.uv_scale;
    out_texture_index = inst.texture_index;
}
