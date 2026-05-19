Physics_Shape :: enum u8 {
    PLANE;
    CIRCLE;
    RECTANGLE;
    CYLINDER;
    BOX;
    PILLBOX;
    SPHERE;
    CAPSULE;
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
