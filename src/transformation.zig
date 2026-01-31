const std = @import("std");
const math = std.math;

const Mat4 = @import("matrix.zig").Mat4;
const point = @import("tuple.zig").point;
const vector = @import("tuple.zig").vector;

pub fn translation(x: f64, y: f64, z: f64) Mat4 {
    return Mat4.identity().translate(x, y, z);
}

pub fn scaling(x: f64, y: f64, z: f64) Mat4 {
    return Mat4.identity().scale(x, y, z);
}

pub fn rotationX(rad: f64) Mat4 {
    return Mat4.identity().rotateX(rad);
}

pub fn rotationY(rad: f64) Mat4 {
    return Mat4.identity().rotateY(rad);
}

pub fn rotationZ(rad: f64) Mat4 {
    return Mat4.identity().rotateZ(rad);
}

pub fn shearing(x_y: f64, x_z: f64, y_x: f64, y_z: f64, z_x: f64, z_y: f64) Mat4 {
    return Mat4.identity().shear(x_y, x_z, y_x, y_z, z_x, z_y);
}

test "Multiplying by a translation matrix" {
    // Given
    const transform = translation(5, -3, 2);
    const p = point(-3, 4, 5);

    // Then
    try std.testing.expect(transform.apply(p).approxEq(point(2, 1, 7)));
}

test "Multiplying by the inverse of a translation matrix" {
    // Given
    const transform = translation(5, -3, 2);
    const inv = try transform.inverse();
    const p = point(-3, 4, 5);

    // Then
    try std.testing.expect(inv.apply(p).approxEq(point(-8, 7, 3)));
}

test "Translation does not affect vectors" {
    // Given
    const transform = translation(5, -3, 2);
    const v = vector(-3, 4, 5);

    // Then
    try std.testing.expect(transform.apply(v).approxEq(v));
}

test "A scaling matrix applied to a a vector" {
    // Given
    const transform = scaling(2, 3, 4);
    const p = point(-4, 6, 8);

    // Then
    try std.testing.expect(transform.apply(p).approxEq(point(-8, 18, 32)));
}

test "A scaling matrix applied to a vector" {
    // Given
    const transform = scaling(2, 3, 4);
    const p = vector(-4, 6, 8);

    // Then
    try std.testing.expect(transform.apply(p).approxEq(vector(-8, 18, 32)));
}

test "Multiplying by the inverse of a scaling matrix" {
    // Given
    const transform = scaling(2, 3, 4);
    const inv = try transform.inverse();
    const v = vector(-4, 6, 8);

    // Then
    try std.testing.expect(inv.apply(v).approxEq(vector(-2, 2, 2)));
}

test "Reflection is scaling by a negative value" {
    // Given
    const transform = scaling(-1, 1, 1);
    const p = point(2, 3, 4);

    // Then
    try std.testing.expect(transform.apply(p).approxEq(point(-2, 3, 4)));
}

test "Rotating a point around the x axis" {
    // Given
    const p = point(0, 1, 0);
    const half_quarter = rotationX(@as(f64, math.pi) / 4);
    const full_quarter = rotationX(@as(f64, math.pi) / 2);

    // Then
    try std.testing.expect(half_quarter.apply(p).approxEq(point(0, math.sqrt(2.0) / 2.0, math.sqrt(2.0) / 2.0)));
    try std.testing.expect(full_quarter.apply(p).approxEq(point(0, 0, 1)));
}

test "The inverse of an x-rotation rotates in the opposite direction" {
    // Given
    const p = point(0, 1, 0);
    const half_quarter = rotationX(@as(f64, math.pi) / 4);
    const inv = try half_quarter.inverse();

    // Then
    try std.testing.expect(inv.apply(p).approxEq(point(0, math.sqrt(2.0) / 2.0, -math.sqrt(2.0) / 2.0)));
}

test "Rotating a point around the y axis" {
    // Given
    const p = point(0, 0, 1);
    const half_quarter = rotationY(@as(f64, math.pi) / 4);
    const full_quarter = rotationY(@as(f64, math.pi) / 2);

    // Then
    try std.testing.expect(half_quarter.apply(p).approxEq(point(math.sqrt(2.0) / 2.0, 0, math.sqrt(2.0) / 2.0)));
    try std.testing.expect(full_quarter.apply(p).approxEq(point(1, 0, 0)));
}

test "Rotating a point around the z axis" {
    // Given
    const p = point(0, 1, 0);
    const half_quarter = rotationZ(@as(f64, math.pi) / 4);
    const full_quarter = rotationZ(@as(f64, math.pi) / 2);

    // Then
    try std.testing.expect(half_quarter.apply(p).approxEq(point(-math.sqrt(2.0) / 2.0, math.sqrt(2.0) / 2.0, 0)));
    try std.testing.expect(full_quarter.apply(p).approxEq(point(-1, 0, 0)));
}

test "A shearing transformation moves x in proportion to y" {
    // Given
    const transform = shearing(1, 0, 0, 0, 0, 0);
    const p = point(2, 3, 4);

    // Then
    try std.testing.expect(transform.apply(p).approxEq(point(5, 3, 4)));
}

test "A shearing transformation moves x in proportion to z" {
    // Given
    const transform = shearing(0, 1, 0, 0, 0, 0);
    const p = point(2, 3, 4);

    // Then
    try std.testing.expect(transform.apply(p).approxEq(point(6, 3, 4)));
}

test "A shearing transformation moves y in proportion to x" {
    // Given
    const transform = shearing(0, 0, 1, 0, 0, 0);
    const p = point(2, 3, 4);

    // Then
    try std.testing.expect(transform.apply(p).approxEq(point(2, 5, 4)));
}

test "A shearing transformation moves y in proportion to z" {
    // Given
    const transform = shearing(0, 0, 0, 1, 0, 0);
    const p = point(2, 3, 4);

    // Then
    try std.testing.expect(transform.apply(p).approxEq(point(2, 7, 4)));
}

test "A shearing transformation moves z in proportion to x" {
    // Given
    const transform = shearing(0, 0, 0, 0, 1, 0);
    const p = point(2, 3, 4);

    // Then
    try std.testing.expect(transform.apply(p).approxEq(point(2, 3, 6)));
}

test "A shearing transformation moves z in proportion to y" {
    // Given
    const transform = shearing(0, 0, 0, 0, 0, 1);
    const p = point(2, 3, 4);

    // Then
    try std.testing.expect(transform.apply(p).approxEq(point(2, 3, 7)));
}

test "Individual transformations are applied in sequence" {
    // Given
    const p = point(1, 0, 1);
    const A = rotationX(@as(f64, math.pi) / 2.0);
    const B = scaling(5, 5, 3);
    const C = translation(10, 5, 7);

    // When
    const p2 = A.apply(p);
    // Then
    try std.testing.expect(p2.approxEq(point(1, -1, 0)));

    // When
    const p3 = B.apply(p2);
    // Then
    try std.testing.expect(p3.approxEq(point(5, -5, 0)));

    // When
    const p4 = C.apply(p3);
    // Then
    try std.testing.expect(p4.approxEq(point(15, 0, 7)));
}

test "Chained transformations must be applied in reverse order" {
    // Given
    const p = point(1, 0, 1);
    const A = rotationX(@as(f64, math.pi) / 2.0);
    const B = scaling(5, 5, 3);
    const C = translation(10, 5, 7);

    // When
    const T = C.mul(B).mul(A);

    // Then
    try std.testing.expect(T.apply(p).approxEq(point(15, 0, 7)));
}

test "Chained transformations using a fluent API" {
    // Given
    const p = point(1, 0, 1);
    const T = Mat4
        .identity()
        .rotateX(@as(f64, math.pi) / 2.0)
        .scale(5, 5, 5)
        .translate(10, 5, 7);

    // Then
    try std.testing.expect(T.apply(p).approxEq(point(15, 0, 7)));
}
