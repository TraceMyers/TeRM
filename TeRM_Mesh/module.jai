#module_parameters(
    user_types : $I/interface Type_Provider_Default = Type_Provider_Default
) {
    Type_Provider_Default :: struct {
        vertex_buffer_type: int;
        index_buffer_type: int;
        texture_type: int;
    }
};

// load .trm mesh from file
load_mesh :: (path: string) -> Mesh, bool {
    // doesn't seem like the option to temp allocate on-struct data is valuable
    assert(context.allocator.proc != temp.proc);
    auto_release_temp();

    file := read_entire_file(path,, temp);
    pos: int;
    header := read_string(file, *pos, 16);
    if header != TeRM_Mesh_Header {
        return {}, false;
    }

    version := read_s32(file, *pos);
    assert(version == 1);

    array_reset(*context.term_mesh_buffer_table);
    array_reserve(*context.term_mesh_buffer_table, 256,, temp);
    array_reset(*context.term_mesh_texture_buffer_table);
    array_reserve(*context.term_mesh_texture_buffer_table, 128,, temp);
    array_reset(*context.term_mesh_self_allocation);
    array_reserve(*context.term_mesh_self_allocation, 16 * 1024 * 1024,, temp);

    mesh_sections_header := read_block_header(file, *pos);
    animations_header    := read_block_header(file, *pos);
    joints_header        := read_block_header(file, *pos);

    mesh: Mesh;
    mesh.allocator = context.allocator;

    if mesh_sections_header.item_count > 0 {
        mesh.sections = allocate_self_array(Mesh_Section, mesh_sections_header.item_count);
        pos = mesh_sections_header.offset_to_block;

        for *section : mesh.sections {
            ibuf_pos := read_s32(file, *pos);
            index_buffer, index_buffer_type := alloc_or_look_up_buffer(file, ibuf_pos);

            section.indices.count = xx index_buffer.count;
            // union'd with u32 index array
            section.indices._u16.data  = xx index_buffer.data;
            section.indices._u16.count = index_buffer.count;

            if index_buffer_type == {
            case .U16;
                section.indices.type = .U16;
            case .U32;
                section.indices.type = .U32;
            case;
                assert(false, "invalid index buffer type %", index_buffer_type);
            }
            
            vbuf_pos := read_s32(file, *pos);
            vertex_buffer, vertex_buffer_type := alloc_or_look_up_buffer(file, vbuf_pos);

            section.vertices.count = xx vertex_buffer.count;
            // union'd with skinned vertex array
            section.vertices.static.data  = xx vertex_buffer.data;
            section.vertices.static.count = vertex_buffer.count;

            if vertex_buffer_type == {
            case .STATIC_VERTEX;
                section.vertices.type = .STATIC;
            case .SKINNED_VERTEX;
                section.vertices.type = .SKINNED;
            case;
                assert(false, "invalid vertex buffer type %", vertex_buffer_type);
            }

            matbuf_name_pos := read_s32(file, *pos);
            matbuf_name, matbuf_name_type := alloc_or_look_up_buffer(file, matbuf_name_pos, true);
            assert(matbuf_name_type == .BYTE);

            using section.material;
            name = string.{matbuf_name.count, matbuf_name.data};
            alpha_mode    = cast(Material_Alpha_Mode) read_s32(file, *pos);
            albedo_uv     = cast(s8) read_s32(file, *pos);
            metallic_uv   = cast(s8) read_s32(file, *pos);
            roughness_uv  = cast(s8) read_s32(file, *pos);
            normal_uv     = cast(s8) read_s32(file, *pos);
            occlusion_uv  = cast(s8) read_s32(file, *pos);
            emissive_uv   = cast(s8) read_s32(file, *pos);

            discard_alpha_cutoff_if_masked_alpha = read_float(file, *pos);

            albedo_factor    = read_color4f(file, *pos);
            metallic_factor  = read_float(file, *pos);
            roughness_factor = read_float(file, *pos);
            emissive_factor  = read_color4f(file, *pos);

            read_texture(*albedo_texture, file, *pos);
            read_texture(*normal_texture, file, *pos);
            read_texture(*emissive_texture, file, *pos);
            read_texture(*orm_texture, file, *pos);
        }
    }

    if joints_header.item_count > 0 {
        mesh.skeleton.joints = allocate_self_array(Joint, joints_header.item_count);
        pos = joints_header.offset_to_block;

        for *joint : mesh.skeleton.joints {
            read_joint(joint, file, *pos);
        }
    }

    if animations_header.item_count > 0 {
        mesh.skeleton.animations = allocate_self_array(Skeletal_Animation, animations_header.item_count);
        pos = animations_header.offset_to_block;

        for *animation : mesh.skeleton.animations {
            name_pos := read_s32(file, *pos);
            anim_name, anim_name_type := alloc_or_look_up_buffer(file, name_pos, true);
            assert(anim_name_type == .BYTE);

            animation.name = string.{anim_name.count, anim_name.data};
            animation.interpolate = cast(bool) read_s32(file, *pos);
            
            timestamps_pos := read_s32(file, *pos);
            timestamps, timestamps_type := alloc_or_look_up_buffer(file, timestamps_pos, true);
            assert(timestamps_type == .FLOAT);
            animation.timestamps = cast,force([]float) timestamps;

            transforms_pos := read_s32(file, *pos);
            transforms, transforms_type := alloc_or_look_up_buffer(file, transforms_pos, true);
            assert(transforms_type == .JOINT_TRANSFORM);
            animation.transforms = cast,force([]Joint_Transform) transforms;

            assert(animation.transforms.count == animation.timestamps.count * mesh.skeleton.joints.count);
        }
    }

    if context.term_mesh_texture_buffer_table.count > 0 {
        mesh.texture_buffers = allocate_self_array(Texture_Buffer, context.term_mesh_texture_buffer_table.count);
        for temp_item : context.term_mesh_texture_buffer_table {
            temp_buf := *temp_item.texture_buffer;
            out_buf := *mesh.texture_buffers[it_index];
            out_buf.* = temp_buf.*;
        }
    }

    // little awkward, but allocating on-struct arrays into a temp buffer then copying stuff over
    // and fixing the pointers avoids making a bunch of spaced-out allocations.
    mesh.self_cpu_allocation = alloc_string(context.term_mesh_self_allocation.count);

    old_allocation := context.term_mesh_self_allocation.data;
    new_allocation := mesh.self_cpu_allocation.data;
    memcpy(new_allocation, old_allocation, mesh.self_cpu_allocation.count);

    // pointer fixing needs to be done in layers...

    // layer 1
    move_pointer(xx *mesh.sections.data, old_allocation, new_allocation);
    move_pointer(xx *mesh.texture_buffers.data, old_allocation, new_allocation);
    move_pointer(xx *mesh.skeleton.joints.data, old_allocation, new_allocation);
    move_pointer(xx *mesh.skeleton.animations.data, old_allocation, new_allocation);

    // layer 2
    for *section : mesh.sections {
        move_pointer(xx *section.material.name.data, old_allocation, new_allocation);
    }
    for *joint : mesh.skeleton.joints {
        move_pointer(xx *joint.name.data, old_allocation, new_allocation);
    }
    for *animation : mesh.skeleton.animations {
        move_pointer(xx *animation.name.data, old_allocation, new_allocation);
        move_pointer(xx *animation.timestamps.data, old_allocation, new_allocation);
        move_pointer(xx *animation.transforms.data, old_allocation, new_allocation);
    }

    return mesh, true;
}

Static_Mesh_Vertex :: struct {
    position:   Vector3;
    normal:     Vector3;
    tangent:    Vector4;
    uv_0:       Vector2;
    uv_1:       Vector2;
    color:      Color4f;
}

Skinned_Mesh_Vertex :: struct {
    using #as base: Static_Mesh_Vertex;
    joints:  [4]u16;
    weights: [4]float32;
}

Mesh_Index_Buffer :: struct {
    type:  enum { U16; U32; };
    count: s32;
    gpu_allocation: user_types.index_buffer_type;
    using cpu_allocation: union {
        _u16: []u16;
        _u32: []u32;
    }
}

Mesh_Vertex_Buffer :: struct {
    type: enum { STATIC; SKINNED; };
    count: s32;
    gpu_allocation: user_types.vertex_buffer_type;
    using cpu_allocation: union {
        static:  []Static_Mesh_Vertex;
        skinned: []Skinned_Mesh_Vertex;
    }
}

Texture_Buffer :: struct {
    width: s32;
    height: s32;
    gpu_allocation: user_types.texture_type;
    // may not be allocated on cpu
    cpu_allocation: []Color4b;
}

Mesh :: struct {
    name: string; // not using rn

    sections:        []Mesh_Section;
    texture_buffers: []Texture_Buffer;
    skeleton:        Skeleton;

    self_cpu_allocation: string;
    // texture buffers are allocated with stbi. others use this one. (strings are 'self')
    allocator: Allocator;
}

Mesh_Section :: struct {
    indices:  Mesh_Index_Buffer;
    vertices: Mesh_Vertex_Buffer;
    material: Material;
}

Texture :: struct {
    mag_filter: Texture_Filter;
    min_filter: Texture_Filter;
    horizontal_wrap: Texture_Wrap;
    vertical_wrap:   Texture_Wrap;
    buffer: s32;
}

Material :: struct {
    name: string;

    alpha_mode: Material_Alpha_Mode;    

    albedo_uv:    s8;
    metallic_uv:  s8;
    roughness_uv: s8;
    normal_uv:    s8;
    occlusion_uv: s8;
    emissive_uv:  s8;

    discard_alpha_cutoff_if_masked_alpha := 0.5;

    // default values are meant to look obviously unconfigured
    albedo_factor    := COLOR4F_MAGENTA;
    emissive_factor  := COLOR4F_WHITE;
    metallic_factor  := 1.0; 
    roughness_factor := 1.0;

    albedo_texture:    Texture;
    normal_texture:    Texture;
    emissive_texture:  Texture;
    // occlusion, roughness, metallic
    orm_texture: Texture;
}

Joint :: struct {
    name:               string;
    parent:             s16;  // -1 = root
    inverse_bind_pose:  Matrix4;
    local_rest_pose:    Joint_Transform;
}

Joint_Transform :: struct {
    translation: Vector3;
    rotation:    Quaternion;
    scale:       Vector3;
}

Skeleton :: struct {
    joints:     []Joint;
    animations: []Skeletal_Animation;
}

Skeletal_Animation :: struct {
    name:          string;
    interpolate:   bool;  // if true, translation and scale = lerp, rotation = slerp; otherwise, teleport
    timestamps:    []float32;
    transforms:    []Joint_Transform; // joint_count * timestamps.count
}

Skeleton_Pose :: struct {
    skeleton:        *Skeleton;
    local_joints:    []Joint_Transform;
    world_joints:    []Matrix4;    // local accumulated up the hierarchy
    skinning_joints: []Matrix4;    // world * inverse_bind_pose, uploaded to gpu
}

Material_Alpha_Mode :: enum u8 {
    OPAQUE;
    MASK;
    BLEND;
}

Texture_Filter :: enum u8 {
    LINEAR;
    NEAREST;
}

Texture_Wrap :: enum u8 {
    CLAMP_TO_EDGE;
    MIRRORED_REPEAT;
    REPEAT;
}

#scope_file

TeRM_Mesh_Header :: "TeRM-Mesh\0\0\0\0\0\0\0";
#add_context term_mesh_self_allocation: [..]u8;
#add_context term_mesh_buffer_table: [..]Buffer_Table_Item;
#add_context term_mesh_texture_buffer_table: [..]Texture_Buffer_Table_Item;

Block_Header :: struct {
    item_count: s32;
    size_of_one_item: s32;
    offset_to_block: s32;
}

Buffer_Table_Item :: struct {
    file_position: s32;
    bytes: []u8;
    type: Buffer_Type;
    // if the table item is a texture buffer, this will be set.
    texture_buffer: Texture_Buffer;
    is_texture_buffer: bool;
}

Texture_Buffer_Table_Item :: struct {
    file_position: s32;
    texture_buffer: Texture_Buffer;
}

Buffer_Type :: enum s32 {
    BYTE;
    U16;
    U32;
    FLOAT;
    STATIC_VERTEX;
    SKINNED_VERTEX;
    JOINT_TRANSFORM;
    NONE :: S32_MAX;
}

read_u16     :: #bake_arguments read_primitive(T=u16);
read_s32     :: #bake_arguments read_primitive(T=s32);
read_float   :: #bake_arguments read_primitive(T=float32);
read_vector2 :: #bake_arguments read_primitive(T=Vector2);
read_vector3 :: #bake_arguments read_primitive(T=Vector3);
read_vector4 :: #bake_arguments read_primitive(T=Vector4);
read_color4f :: #bake_arguments read_primitive(T=Color4f);
read_matrix4 :: #bake_arguments read_primitive(T=Matrix4);
read_mesh_static_vertex :: #bake_arguments read_primitive(T=Static_Mesh_Vertex);

read_block_header :: (file: string, location: *int) -> Block_Header{
    header: Block_Header;
    header.item_count       = read_s32(file, location);
    header.size_of_one_item = read_s32(file, location);
    header.offset_to_block  = read_s32(file, location);
    return header;
}

read_string :: inline (file: string, location: *int, length: int) -> string {
    assert(location.* + length <= file.count);
    str := string.{length, file.data + location.*};
    location.* += length;
    return str;
}

read_primitive :: inline (file: string, location: *int, $T: Type) -> T {
    assert(location.* + size_of(T) <= file.count);
    val := (cast(*T) (file.data + location.*)).*;
    location.* += size_of(T);
    return val;
}

read_array :: inline (array: []$T, file: string, location: *int, count: int) {
    for 0..count-1 {
        array[it] = read_primitive(file, location, T);
    }
}

read_mesh_skinned_vertex :: inline (vert: *Skinned_Mesh_Vertex, file: string, location: *int) {
    vert.base = read_mesh_static_vertex(file, location);
    read_array(vert.joints, file, location, 4);
    read_array(vert.weights, file, location, 4);
}

read_joint :: inline (joint: *Joint, file: string, location: *int) {
    offset_to_name := read_s32(file, location);
    joint_name_bytes := alloc_buffer(file, offset_to_name, true);
    joint.name              = {joint_name_bytes.count, joint_name_bytes.data};
    joint.parent            = xx read_s32(file, location);
    joint.inverse_bind_pose = read_matrix4(file, location);
    read_joint_transform(*joint.local_rest_pose, file, location);
}

read_joint_transform :: inline (tform: *Joint_Transform, file: string, location: *int) {
    tform.translation = read_vector3(file, location);
    tform.rotation    = xx,force read_vector4(file, location);
    tform.scale       = read_vector3(file, location);
}

read_texture :: (tex: *Texture, file: string, pos: *int) {
    offset_to_buffer := read_s32(file, pos);
    if offset_to_buffer == -1 {
        tex.buffer = -1;
    } else {
        tex.buffer = alloc_or_look_up_texture_buffer(file, offset_to_buffer);
    }
    tex.mag_filter      = cast(Texture_Filter) read_s32(file, pos);
    tex.min_filter      = cast(Texture_Filter) read_s32(file, pos);
    tex.horizontal_wrap = cast(Texture_Wrap) read_s32(file, pos);
    tex.vertical_wrap   = cast(Texture_Wrap) read_s32(file, pos);
}

allocate_self_array :: ($T: Type, count: int) -> []T {
    buf_pos := align_up(context.term_mesh_self_allocation.count, align_of(T));
    buf_end := buf_pos + size_of(T) * count;
    assert(context.term_mesh_self_allocation.allocated >= buf_end);
    array_resize(*context.term_mesh_self_allocation, buf_end);
    array: []T = ---;
    array.data = xx (context.term_mesh_self_allocation.data + buf_pos);
    array.count = count;
    return array;
}

align_up :: inline (value: int, align: int) -> int {
    return (value + align - 1) & ~(align - 1);
}

move_pointer :: inline (ptr: **u8, old_allocation: *u8, new_allocation: *u8) {
    offset := cast(s64) ptr.* - cast(s64) old_allocation;
    ptr.* = new_allocation + offset;
}

clear_mesh_loading_arrays :: () {
    array_reset(*context.term_mesh_self_allocation); 
    array_reset(*context.term_mesh_buffers_allocation);
}

alloc_or_look_up_texture_buffer :: (file: string, start_pos: int) -> s32 {
    for item : context.term_mesh_texture_buffer_table {
        if item.file_position == start_pos {
            return xx it_index;
        }
    }

    new_item := array_add(*context.term_mesh_texture_buffer_table);
    new_item.file_position = xx start_pos;

    pos := start_pos;

    type             := cast(Buffer_Type) read_s32(file, *pos);
    count            := read_s32(file, *pos);
    size_of_one_item := read_s32(file, *pos);
    
    channels: s32;
    buf := *new_item.texture_buffer;
    buf.cpu_allocation.data = xx stbi_load_from_memory(file.data + pos, count, *buf.width, *buf.height, *channels, 4);
    assert(channels == 4);
    buf.cpu_allocation.count = count / 4;

    return xx (context.term_mesh_texture_buffer_table.count-1);
}

alloc_or_look_up_buffer :: (file: string, start_pos: int, self_allocation := false) -> []u8, Buffer_Type {
    for item : context.term_mesh_buffer_table {
        if item.file_position == start_pos {
            return item.bytes, item.type;
        }
    }
    new_item := array_add(*context.term_mesh_buffer_table);
    new_item.file_position = xx start_pos;
    new_item.bytes, new_item.type = alloc_buffer(file, start_pos, self_allocation);
    return new_item.bytes, new_item.type;
}

alloc_buffer :: (file: string, start_pos: int, self_allocation: bool) -> []u8, Buffer_Type {
    pos := start_pos;

    type             := cast(Buffer_Type) read_s32(file, *pos);
    count            := read_s32(file, *pos);
    size_of_one_item := read_s32(file, *pos);

    bytes: []u8;
    
    if type == {
    case .BYTE;
        assert(size_of_one_item == 1);
        bytes = ifx self_allocation 
            then allocate_self_array(u8, count) 
            else make_static_array(u8, count);
        read_array(bytes, file, *pos, count);
    case .U16;
        assert(size_of_one_item == 2);
        bytes = cast,force([]u8) ifx self_allocation 
            then allocate_self_array(u16, count) 
            else make_static_array(u16, count);
        read_array(cast,force([]u16) bytes, file, *pos, count);
    case .U32;
        assert(size_of_one_item == 4);
        bytes = cast,force([]u8) ifx self_allocation 
            then allocate_self_array(u32, count) 
            else make_static_array(u32, count);
        read_array(cast,force([]u32) bytes, file, *pos, count);
    case .FLOAT;
        assert(size_of_one_item == 4);
        bytes = cast,force([]u8) ifx self_allocation 
            then allocate_self_array(float, count)
            else make_static_array(float, count);
        read_array(cast,force([]float32) bytes, file, *pos, count);
    case .STATIC_VERTEX;
        assert(size_of_one_item == size_of(Static_Mesh_Vertex));
        bytes = xx,force make_static_array(Static_Mesh_Vertex, count);
        vertices := cast,force([]Static_Mesh_Vertex) bytes;
        for *v : vertices {
            v.* = read_mesh_static_vertex(file, *pos);
        }
    case .SKINNED_VERTEX;
        assert(size_of_one_item == size_of(Skinned_Mesh_Vertex));
        bytes = xx,force make_static_array(Skinned_Mesh_Vertex, count);
        vertices := cast,force([]Skinned_Mesh_Vertex) bytes;
        for *v : vertices {
            read_mesh_skinned_vertex(v, file, *pos);
        }
    case .JOINT_TRANSFORM;
        bytes = xx,force make_static_array(Joint_Transform, count);
        transforms := cast,force([]Joint_Transform) bytes;
        for *t : transforms {
            read_joint_transform(t, file, *pos);
        }
    case;
        assert(false, "invalid buffer type % read from term mesh file", type);
    }

    return bytes, type;
}

#import "Basic";
#import "File";
#import "Math";
#import "stb_image";
#import "TeRM/TeRM_Color";
#import "TeRM/TeRM_Allocation";
#import "TeRM/TeRM_Scope";
#import "TeRM/TeRM_Metaprogram";
#import "TeRM/TeRM_Array";
