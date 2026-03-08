INALID_ASSET3D_INDEX_S16 : s16 : -1;

free_cpu_side_buffers :: (using asset: *Asset_3D) {
    free(cpu_buffers_allocation.data);
    cpu_buffers_allocation = {};
    for mesh_buffers {
        it.cpu_allocation = {};
    }
}

// todo: if assets refer to other assets, this could punch a hole where other stuff points.
// best approach to have assets refer to assets is to divide an asset into parts, one of which 
// includes the data you want to be referenced by other assets. either have this special split-off 
// asset be managed specially with references to its referencers, or just make it permantently allocated.
free :: (using asset: *Asset_3D) {
    free(cpu_keep_allocation.data);
    free(cpu_buffers_allocation.data);
    asset.* = {};
}


Asset_3D :: struct {
    file_path      : string;
    scene_roots    : []Scene_Root;
    scenes         : []Scene_3D;
    meshes         : []Mesh;
    mesh_buffers   : []Mesh_Buffer;
    images         : []Image;
    textures       : []Texture;
    cameras        : []Camera_Info;
    indices        : []s32;
    materials      : []Material;
    skins          : []Mesh_Skin;
    primary_scene  : int;

    // all allocations *except* buffer data.
    cpu_self_allocation: string;
    // any fields called 'cpu_allocation' are loaded here. if this is empty, the
    // cpu-side buffers have been freed.
    // todo: prob should be a staging buffer if it's used that way...
    cpu_buffers_allocation: string;
}

Scene_Root :: struct {
    name: string;
    scenes: []*Scene_3D;
}

Scene_3D :: struct {
    name: string;
    children: []*Scene_3D;

    mesh: *Mesh;
    skin: *Mesh_Skin;
    camera: *Camera_Info;

    morph_weights: []float32;
    joint_transforms: []Matrix4;
    inverse_joint_transforms: []Matrix4;

    // the file data may have these pos/rot/scale instead of a matrix,
    // for now anyway, this is only for internal processing. always matrix.
    transform_mode: enum {NONE; TRS; MATRIX;};

    using tform_data: union {
        transform: Matrix4;
        using trs: struct {
            _internal_position: Vector3    = ---;
            _internal_rotation: Quaternion = ---;
            _internal_scale: Vector3       = ---;
        };
    }
}

Mesh :: struct {
    name: string;
    sections: []*Mesh_Section;
}

Mesh_Buffer_Attribute :: struct {
    type: Mesh_Buffer_Attribute_Type;
    primitive: Mesh_Buffer_Attribute_Primitive;
    offset: s16;
}

Texture :: struct {
    name: string;
    image: *Image;
    mag_filter: Texture_Filter;
    min_filter: Texture_Filter;
    horizontal_wrap: Texture_Wrap;
    vertical_wrap: Texture_Wrap;
}

Mesh_Buffer :: struct {
    using #as graphics_buffer: Graphics_Buffer;
    attributes: []Mesh_Buffer_Attribute;
    count: s32;
    normalized: bool;
    // if there is a position attribute, this is the min of the position bbox
    position_min: Vector3; 
    // if there is a position attribute, this is the max of the position bbox
    position_max: Vector3; 
    rewrites: []Sparse_Graphics_Buffer_Rewrite;
}

Image :: struct {
    using #as graphics_buffer: Graphics_Buffer;
    mime_type: string;
}

Graphics_Buffer :: struct {
    name: string;
    uri: string;
    cpu_allocation: string;
}

Sparse_Graphics_Buffer_Rewrite :: struct {
    attribute_index: int;
    indices: []u32;
    values: string;
}

Mesh_Section :: struct {
    indices: *Mesh_Buffer;
    vertices: *Mesh_Buffer;
    material: *Material;
    data_type: Mesh_Data_Type;
    morph_targets: []Mesh_Morph_Target;
}

Mesh_Morph_Target :: struct {
    // todo: morphin' time
}

Mesh_Skin :: struct {
    name: string;
    joint_names: []string;
    joint_parents: []s16;
    inverse_bind_transforms: []Matrix4;
}

Material_Flags :: enum_flags u16 {
    ALBEDO_SET;
    METALLIC_SET;
    ROUGHNESS_SET;
    NORMAL_SET;
    OCCLUSION_SET;
    EMISSIVE_SET;
    DOUBLE_SIDED;
}

Texture_Alpha_Mode :: enum u8 {
    OPAQUE;
    MASK;
    BLEND;
}

Material :: struct {
    name: string;

    // default values are meant to look obviously unconfigured
    albedo_factor := Color4f.{1, 0, 1, 1};
    metallic_factor := 1.0; 
    roughness_factor := 1.0;
    emissive_factor: Color3f;

    albedo_texture:    *Texture;
    metallic_texture:  *Texture;
    roughness_texture: *Texture;
    normal_texture:    *Texture;
    occlusion_texture: *Texture;
    emissive_texture:  *Texture;
     
    albedo_uv:    s8;
    metallic_uv:  s8;
    roughness_uv: s8;
    normal_uv:    s8;
    occlusion_uv: s8;
    emissive_uv:  s8;

    flags: Material_Flags;
    alpha_mode: Texture_Alpha_Mode;
    discard_alpha_cutoff := 0.5;
}

Vertex_Attribute_Type :: enum u8 {
    POSITION;       // Vec3
    NORMAL;         // Vec3
    TANGENT;        // Vec4
    UV_UPPER_LEFT;  // Vec2
    UV_LOWER_RIGHT; // Vec2
    COLOR;          // Vec4
    JOINTS;         // Vec4
    WEIGHTS;        // Vec4
}

Mesh_Buffer_Attribute_Type :: enum u8 {
    // vertex attributes
    POSITION :: 1;
    NORMAL;
    TANGENT;
    TEXCOORD;
    COLOR;
    JOINTS;
    WEIGHTS;
    // morph target deltas
    MORPH_POSITION;
    MORPH_NORMAL;
    MORPH_TANGENT;
    // index buffer
    INDICES;
    // animation
    ANIMATION_INPUT;  // keyframe timestamps
    ANIMATION_OUTPUT; // keyframe values (translation, rotation, scale, or morph weights)
    // skinning
    INVERSE_BIND_MATRICES;
}

Mesh_Buffer_Attribute_Primitive :: enum u8 {
    S8 :: 1;
    U8;
    S16;
    U16;
    U32;
    F32;
}

Texture_Filter :: enum u8 {
    LINEAR;
    NEAREST;
    NEAREST_MIPMAP_NEAREST;
    LINEAR_MIPMAP_NEAREST;
    NEAREST_MIPMAP_LINEAR;
    LINEAR_MIPMAP_LINEAR;
}

Texture_Wrap :: enum u8 {
    CLAMP_TO_EDGE;
    MIRRORED_REPEAT;
    REPEAT;
}

Mesh_Data_Type :: enum u8 {
    POINTS;
    LINES;
    LINE_LOOP;
    LINE_STRIP;
    TRIANGLES;
    TRIANGLE_STRIP;
    TRIANGLE_FAN;
}


// GLTF_Animation :: struct {
//     name:     string;
//     channels: []GLTF_Animation_Channel; // required
//     samplers: []GLTF_Animation_Sampler; // required
// }

// GLTF_Animation_Channel :: struct {
//     sampler: s32; // required, index into the animation's own samplers array
//     target:  GLTF_Animation_Channel_Target; // required
// }

// GLTF_Animation_Channel_Target :: struct {
//     node: s32 = -1; // optional (spec allows omission for extensions)
//     path: GLTF_Animation_Path; // required
// }

// GLTF_Animation_Path :: enum u8 {
//     TRANSLATION;
//     ROTATION;
//     SCALE;
//     WEIGHTS;
// }

// GLTF_Animation_Sampler :: struct {
//     input:         s32; // required, accessor index (keyframe timestamps)
//     output:        s32; // required, accessor index (keyframe values)
//     interpolation: GLTF_Interpolation = .LINEAR;
// }

// GLTF_Interpolation :: enum u8 {
//     LINEAR;
//     STEP;
//     CUBICSPLINE;
// }

#scope_file

#import "TeRM/TeRM_Camera";
#import "TeRM/TeRM_Color";
#import "TeRM/TeRM_Metaprogram";
#import "Math";
