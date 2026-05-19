Vector4u :: struct {
    x: u32 #align 16; // note allocators may not respect this alignment
    y: u32;
    z: u32;
    w: u32;

    #overlay (x) component: [4]u32;
}

Vector3d :: struct {
    x: float64 #align 16; // note allocators may not respect this alignment
    y: float64;
    z: float64;
    _unused: float64;

    #overlay (x) component: [3]float64;
}

Matrix4d :: struct {
    values: [16]float64;
}

#load "windows.jai";
