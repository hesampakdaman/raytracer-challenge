const std = @import("std");
const math = std.math;

const num = @import("num.zig");
const Tuple = @import("Tuple.zig");

pub const Color = @This();

t: Tuple,

pub fn init(rval: f64, gval: f64, bval: f64) Color {
    return .{ .t = Tuple.init(rval, gval, bval, 0) };
}

pub fn black() Color {
    return .{ .t = Tuple.zeros() };
}

pub fn white() Color {
    return .{ .t = Tuple.init(1, 1, 1, 0) };
}

pub fn r(self: Color) f64 {
    return self.t.x();
}

pub fn g(self: Color) f64 {
    return self.t.y();
}

pub fn b(self: Color) f64 {
    return self.t.z();
}

pub fn add(self: Color, other: Color) Color {
    const res = self.t.add(other.t);
    return Color.init(res.x(), res.y(), res.z());
}

pub fn sub(self: Color, other: Color) Color {
    const res = self.t.sub(other.t);
    return Color.init(res.x(), res.y(), res.z());
}

pub fn mul(self: Color, m: f64) Color {
    const res = self.t.mul(m);
    return Color.init(res.x(), res.y(), res.z());
}

pub fn hadamard_product(self: Color, other: Color) Color {
    return Color.init(
        self.r() * other.r(),
        self.g() * other.g(),
        self.b() * other.b(),
    );
}

pub fn approxEq(self: Color, other: Color) bool {
    return math.approxEqAbs(f64, self.r(), other.r(), num.epsilon) and
        math.approxEqAbs(f64, self.g(), other.g(), num.epsilon) and
        math.approxEqAbs(f64, self.b(), other.b(), num.epsilon);
}

test "Colors are (red, green, blue) tuples" {
    // Given
    const c = Color.init(-0.5, 0.4, 1.7);

    // Then
    try std.testing.expectApproxEqAbs(-0.5, c.r(), num.epsilon);
    try std.testing.expectApproxEqAbs(0.4, c.g(), num.epsilon);
    try std.testing.expectApproxEqAbs(1.7, c.b(), num.epsilon);
}

test "Adding colors" {
    // Given
    const c1 = Color.init(0.9, 0.6, 0.75);
    const c2 = Color.init(0.7, 0.1, 0.25);

    // Then
    try std.testing.expect(c1.add(c2).approxEq(Color.init(1.6, 0.7, 1.0)));
}

test "Subtracting colors" {
    // Given
    const c1 = Color.init(0.9, 0.6, 0.75);
    const c2 = Color.init(0.7, 0.1, 0.25);

    // Then
    try std.testing.expect(c1.sub(c2).approxEq(Color.init(0.2, 0.5, 0.5)));
}

test "Multiplying a color by a scalar" {
    // Given
    const c = Color.init(0.2, 0.3, 0.4);

    // Then
    try std.testing.expect(c.mul(2).approxEq(Color.init(0.4, 0.6, 0.8)));
}

test "Multiplying colors" {
    // Given
    const c1 = Color.init(1, 0.2, 0.4);
    const c2 = Color.init(0.9, 1, 0.1);

    // Then
    try std.testing.expect(c1.hadamard_product(c2).approxEq(Color.init(0.9, 0.2, 0.04)));
}
