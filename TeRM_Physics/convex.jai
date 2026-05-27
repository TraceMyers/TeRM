find_farthest_point_along_axis :: (points: []Vector3, axis: Vector3) -> Vector3 {
    // todo: SIMD. have 2 sets of 3 float vectors (xyz) and two int vectors (index)
    // load them into first set of vectors like so

    // x0 x1 x2 x3
    // y0 y1 y2 y3
    // z0 z1 z2 z3
    // i0 i1 i2 i3

    // splat axis into its own set

    // xa xa xa xa
    // ya ya ya ya
    // za za za za

    // get first dot product, still parallel with indices

    // p0 p1 p2 p3
    // i0 i1 i2 i3

    // get second dot product

    // p4 p5 p6 p7
    // i4 i5 i6 i7

    // compare geq or ge across, and use that mask to create the winner
    // product and index vectors.
    // repeat with the rest
    // at the end, store into an array and just compare four values to get the final winner.

    max_distance_along_axis := -FLOAT32_MAX;
    winner: int;
    for point : points {
        distance_along_axis := dot(point, axis);
        if distance_along_axis > max_distance_along_axis {
            winner = it_index;
            max_distance_along_axis = distance_along_axis;
        }
    }
    return points[winner];
}

calculate_support :: inline (points_a: []Vector3, points_b: []Vector3, axis: Vector3) -> Vector3 {
    return find_farthest_point(points_a, axis) - find_farthest_point(points_b, -axis);
}

// convex shapes must be pre-processed into world space
// (triangles array and half_height not necessary.)
gjk :: (a: Shape_Convex, b: Shape_Convex) -> bool {
    axis := a.center - b.center;
    axis_len_sq := length_squared(axis);
    if axis_len_sq < VERY_SMALL_NUMBER {
        return true;
    } else {
        axis /= sqrt(axis_len_sq);
    }

    support := calculate_support(a.points, b.points, axis);

    simplex: Simplex;
    add_point(*simplex, support);

    axis = -support;

    sanity_counter := 0;
    SANITY_COUNTER_MAX :: 10_000;

    while sanity_counter < SANITY_COUNTER_MAX {
        defer sanity_counter += 1;

        support = calculate_support(a.points, b.points, axis);

        // volumes that don't overlap along any given axis can't overlap at all
        // |<-->| air gap
        // in other words, if we start from a support and point toward the origin, the next
        // support will be on the other side of the origin if an overlap is possible,
        // because the support volume must contain the origin if there is an overlap.
        if dot(support, axis) <= 0 {
            return false;
        }

        add_point(*simplex, support);

        if narrow_search_space(*simplex, *axis) {
            return true;
        }
    }
}

#scope_file

Simplex :: struct {
    points: [4]Vector3;
    point_count: s32;
    #overlay(points) line:        struct { b, a: Vector3; };
    #overlay(points) triangle:    struct { c, b, a: Vector3; };
    #overlay(points) tetrahedron: struct { d, c, b, a: Vector3; };
}

add_point :: inline (simplex: *Simplex, point: Vector3) {
    simplex.points[simplex.point_count] = point;
    simplex.point_count += 1;
}

// returns true if the tetrahedron simplex contains the origin
narrow_search_space :: (simplex: *Simplex, axis: *Vector3) -> bool {
    if simplex.point_count == {
    case 2;
        evaluate_line(simplex, axis);
    case 3;
        evaluate_triangle(simplex, axis);
    case 4;
        return evaluate_tetrahedron(simplex, axis);
    }
    return false;
}

evaluate_line :: inline (using simplex: *Simplex, axis: *Vector3) {
    ab :=  line.b - line.a;
    ao := -line.a;
    axis.* = cross(cross(ab, ao), ab); // search toward origin
}

evaluate_triangle :: inline (using simplex: *Simplex, axis: *Vector3) {
    ab :=  triangle.b - triangle.a;
    ac :=  triangle.c - triangle.a;
    ao := -triangle.a;

    // get plane normals pointing away from the triangle
    ab_outside_normal := cross(ab, cross(ab, ac));
    ac_outside_normal := cross(ac, cross(ac, ab));

    if dot(ao, ab_outside_normal) > 0 {
        // triangle does not contain point
        axis.* = ab_outside_normal;
        triangle.c = triangle.a;
        simplex.point_count = 2;
    } else if dot(ao, ac_outside_normal) > 0 {
        // triangle does not contain point
        axis.* = ac_outside_normal;
        triangle.b = triangle.a;
        simplex.point_count = 2;
    } else {
        // triangle contains point. search in direction of triangle normal
        axis.* = cross(ab, ac);
        if dot(axis.*, ao) < 0 {
            axis.* *= -1;
        }
    }
}

evaluate_tetrahedron :: inline (using simplex: *Simplex, axis: *Vector3) -> bool {
    ab :=  tetrahedron.b - tetrahedron.a;
    ac :=  tetrahedron.c - tetrahedron.a;
    ad :=  tetrahedron.d - tetrahedron.a;
    ao := -tetrahedron.a;


}

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
