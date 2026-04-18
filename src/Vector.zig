const std = @import("std");
const math = std.math;

const expect = @import("expect.zig");
const num = @import("num.zig");
const Point = @import("Vector.zig");
const Tuple = @import("Tuple.zig");

tuple: Tuple,

const Vector = @This();

pub fn init(x_val: f64, y_val: f64, z_val: f64) Vector {
    return .{ .tuple = Tuple.init(x_val, y_val, z_val, 0) };
}

pub fn fromTuple(t: Tuple) Vector {
    return Vector.init(t.at(0), t.at(1), t.at(2));
}

pub fn zero() Vector {
    return Vector.init(0, 0, 0);
}

pub fn x(self: Vector) f64 {
    return self.tuple.x();
}

pub fn y(self: Vector) f64 {
    return self.tuple.y();
}

pub fn z(self: Vector) f64 {
    return self.tuple.z();
}

pub fn at(self: Vector, i: usize) f64 {
    return self.tuple.at(i);
}

pub fn approxEq(self: Vector, other: Vector) bool {
    return self.tuple.approxEq(other.tuple);
}

pub fn add(self: Vector, other: Vector) Vector {
    return Vector.fromTuple(self.tuple.add(other.tuple));
}

pub fn sub(self: Vector, other: Vector) Vector {
    return Vector.fromTuple(self.tuple.sub(other.tuple));
}

pub fn mul(self: Vector, m: f64) Vector {
    return Vector.init(
        self.x() * m,
        self.y() * m,
        self.z() * m,
    );
}

pub fn div(self: Vector, d: f64) Vector {
    return Vector.init(
        self.x() / d,
        self.y() / d,
        self.z() / d,
    );
}

pub fn magnitude(self: Vector) f64 {
    return math.sqrt(self.x() * self.x() +
        self.y() * self.y() +
        self.z() * self.z());
}

pub fn normalize(self: Vector) Vector {
    return self.div(self.magnitude());
}

pub fn dot(self: Vector, other: Vector) f64 {
    return self.x() * other.x() +
        self.y() * other.y() +
        self.z() * other.z();
}

pub fn cross(self: Vector, other: Vector) Vector {
    return Vector.init(
        self.y() * other.z() - self.z() * other.y(),
        self.z() * other.x() - self.x() * other.z(),
        self.x() * other.y() - self.y() * other.x(),
    );
}

pub fn reflect(self: Vector, normal: Vector) Vector {
    return self.sub(normal.mul(2 * self.dot(normal)));
}

pub fn negate(self: Vector) Vector {
    return Vector.init(-self.x(), -self.y(), -self.z());
}

test "vector() creates tuples with w=0" {
    // Given
    const v = Vector.init(4, -4, 3);

    // Then
    try std.testing.expect(v.approxEq(Vector.init(4, -4, 3)));
}

test "Subtracting a vector from a point" {
    // Given
    const p = Point.init(3, 2, 1);
    const v = Vector.init(5, 6, 7);

    // Then
    try std.testing.expect(p.sub(v).approxEq(Point.init(-2, -4, -6)));
}

test "Subtracting two vectors" {
    // Given
    const v1 = Vector.init(3, 2, 1);
    const v2 = Vector.init(5, 6, 7);

    // Then
    try std.testing.expect(v1.sub(v2).approxEq(Vector.init(-2, -4, -6)));
}

test "Subtracting a vector from the zero vector" {
    // Given
    const zerov = Vector.init(0, 0, 0);
    const v = Vector.init(1, -2, 3);

    // Then
    try std.testing.expect(zerov.sub(v).approxEq(Vector.init(-1, 2, -3)));
}

test "Computing the magnitude of Vector.init(1, 0, 0)" {
    // Given
    const v = Vector.init(1, 0, 0);

    // Then
    try std.testing.expectApproxEqAbs(1, v.magnitude(), num.epsilon);
}

test "Computing the magnitude of vector(0, 1, 0)" {
    // Given
    const v = Vector.init(0, 1, 0);

    // Then
    try std.testing.expectApproxEqAbs(1, v.magnitude(), num.epsilon);
}

test "Computing the magnitude of vector(0, 0, 1)" {
    // Given
    const v = Vector.init(0, 0, 1);

    // Then
    try std.testing.expectApproxEqAbs(1, v.magnitude(), num.epsilon);
}

test "Computing the magnitude of vector(1, 2, 3)" {
    // Given
    const v = Vector.init(1, 2, 3);

    // Then
    try std.testing.expectApproxEqAbs(math.sqrt(14.0), v.magnitude(), num.epsilon);
}

test "Computing the magnitude of vector(-1, -2, -3)" {
    // Given
    const v = Vector.init(-1, -2, -3);

    // Then
    try std.testing.expectApproxEqAbs(math.sqrt(14.0), v.magnitude(), num.epsilon);
}

test "Normalizing vector(4, 0, 0) gives (1, 0, 0)" {
    // Given
    const v = Vector.init(4, 0, 0);

    // Then
    try std.testing.expect(v.normalize().approxEq(Vector.init(1, 0, 0)));
}

test "Normalizing vector(1, 2, 3)" {
    // Given
    const v = Vector.init(1, 2, 3);

    // Then
    try std.testing.expect(
        v.normalize().approxEq(Vector.init(1.0 / math.sqrt(14.0), 2.0 / math.sqrt(14.0), 3.0 / math.sqrt(14.0))),
    );
}

test "The magnitude of a normalized vector" {
    // Given
    const v = Vector.init(1, 2, 3);

    // When
    const norm = v.normalize();

    // Then
    try std.testing.expectApproxEqAbs(1, norm.magnitude(), num.epsilon);
}

test "The dot product of two vectors" {
    // Given
    const a = Vector.init(1, 2, 3);
    const b = Vector.init(2, 3, 4);

    // Then
    try std.testing.expectApproxEqAbs(20, a.dot(b), num.epsilon);
}

test "The cross product of two vectors" {
    // Given
    const a = Vector.init(1, 2, 3);
    const b = Vector.init(2, 3, 4);

    // Then
    try std.testing.expect(a.cross(b).approxEq(Vector.init(-1, 2, -1)));
    try std.testing.expect(b.cross(a).approxEq(Vector.init(1, -2, 1)));
}

test "Reflecting a vector approaching at 45°" {
    // Given
    const v = Vector.init(1, -1, 0);
    const n = Vector.init(0, 1, 0);

    // When
    const r = v.reflect(n);

    // Then
    try expect.approxEqVector(Vector.init(1, 1, 0), r);
}

test "Reflecting a vector off a slanted surface" {
    // Given
    const v = Vector.init(0, -1, 0);
    const n = Vector.init(num.sqrt2 / 2.0, num.sqrt2 / 2.0, 0);

    // When
    const r = v.reflect(n);

    // Then
    try expect.approxEqVector(Vector.init(1, 0, 0), r);
}
