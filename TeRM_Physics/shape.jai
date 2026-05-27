Physics_Shape :: enum u8 {
    PLANE;
    CIRCLE;
    RECTANGLE;
    CYLINDER;
    BOX;
    PILLBOX;
    SPHERE;
    CAPSULE;
    CONVEX;
}

Shape_Plane :: struct {}

Shape_Circle :: struct {
    radius: float32;
}

Shape_Rectangle :: struct {
    half_height: float32;
    half_width: float32;
}

Shape_Cylinder :: struct {
    half_height: float32;
    radius: float32;
}

Shape_Box :: struct {
    half_height: float32;
    half_length: float32;
    half_width: float32;
}

Shape_Pillbox :: struct {
    half_height: float32;
    half_box_length: float32;
    radius: float32;
}

Shape_Sphere :: struct {
    radius: float32;
}

Shape_Capsule :: struct {
    half_height: float32;
    radius: float32;
}

Shape_Convex :: struct {
    half_height: float32;
    data_index: s32;
}

Shape_Convex_Data :: struct {
    center: Vector3;
    points:  []Vector3;
    triangles: []uint16;
}

