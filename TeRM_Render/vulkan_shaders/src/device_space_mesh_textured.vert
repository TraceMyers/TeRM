#version 450

layout(location=0) in vec3 in_position;
layout(location=1) in vec3 in_tint;
layout(location=2) in vec2 in_uv;

layout(location=0) out vec3 out_tint;
layout(location=1) out vec2 out_uv;

void main() {
    gl_Position = vec4(in_position, 1);
    out_tint = in_tint;
    out_uv = in_uv;
}
