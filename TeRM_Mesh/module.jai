
TeRM_Mesh_Header :: "TeRM-Mesh   ";


load_mesh :: (path: string) -> Mesh {

}

Mesh_Static_Vertex :: struct {
    VERSION :: 1;

    position:   Vector3;
    normal:     Vector3;
    tangent:    Vector4;
    uv_0:       Vector2;
    uv_1:       Vector2;
    color:      Color4f;
    extra_data: [4]u32;
};

Mesh_Skinned_Vertex :: struct {
    VERSION :: 1;

    using base: Vertex;
    joints:  [4]u16;
    weights: [4]float32;
}

Mesh_Index_Buffer :: struct {
    VERSION :: 1;

    type:  enum { U16; U32; };
    count: s32;
    using cpu_allocation: struct {
        _u16: []u16;
        _u32: []u32;
    }
};

Mesh_Vertex_Buffer :: struct {
    VERSION :: 1;

    type: enum { STATIC; SKINNED; };
    count: s32;
    using cpu_allocation: struct {
        static:  []Mesh_Static_Vertex;
        skinned: []Mesh_Skinned_Vertex;
    }
}

Mesh :: struct {
    VERSION :: 1;

    name: string;
    sections: []Mesh_Section;

    self_cpu_allocation:    string;
    buffers_cpu_allocation: string;
}

Mesh_Section :: struct {
    VERSION :: 1;

    indices:  Mesh_Index_Buffer;
    vertices: Mesh_Vertex_Buffer;
    material: Material;
}

RGBA8_Pixel :: Color4b;
RG8_Pixel   :: struct { r: u8; g: u8; }
R8_Pixel    :: struct { r: u8; }

Texture :: struct {
    VERSION :: 1;

    name: string;

    in_file_mime_type: string;
    width: s16;
    height: s16;
    type: enum {
        RGBA8_INT;
        RG8_INT;
        R8_INT;
    };

    mag_filter: Texture_Filter;
    min_filter: Texture_Filter;
    horizontal_wrap: Texture_Wrap;
    vertical_wrap: Texture_Wrap;

    using cpu_allocation: struct {
        rgba8: []RGBA8_Pixel; 
        rg8:   []RG8_Pixel;
        r8:    []R8_Pixel;
    };
}

Material_Flags :: enum_flags u16 {
    HAS_ALBEDO_TEXTURE;
    HAS_ALBEDO_FACTOR;
    HAS_METALLIC_TEXTURE;
    HAS_METALLIC_FACTOR;
    HAS_ROUGHNESS_TEXTURE;
    HAS_ROUGHNESS_FACTOR;
    HAS_NORMAL_TEXTURE;
    HAS_OCCLUSION_TEXTURE;
    HAS_EMISSIVE_TEXTURE;
    HAS_EMISSIVE_FACTOR;
    ALBEDO_FACTOR_DEFAULTED_TO_WHITE;
    DOUBLE_SIDED;
}

Material_Alpha_Mode :: enum u8 {
    OPAQUE;
    MASK;
    BLEND;
}

Material :: struct {
    VERSION :: 1;

    name: string;

    flags: Material_Flags;
    alpha_mode: Material_Alpha_Mode;
    discard_alpha_cutoff := 0.5;

    // default values are meant to look obviously unconfigured
    albedo_factor    := COLOR4F_MAGENTA;
    metallic_factor  := 1.0; 
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
}

#import "Math";
#import "TeRM/TeRM_Color";
