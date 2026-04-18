const std = @import("std");
const math = std.math;

const expect = @import("expect.zig");
const num = @import("num.zig");
const Point = @import("Point.zig");

pub const Tuple = @This();

data: [4]f64,

pub fn init(x_val: f64, y_val: f64, z_val: f64, w_val: f64) Tuple {
    return .{ .data = .{ x_val, y_val, z_val, w_val } };
}

pub fn zeros() Tuple {
    return Tuple.init(0, 0, 0, 0);
}

pub fn ones() Tuple {
    return Tuple.init(1, 1, 1, 1);
}

pub fn at(self: Tuple, i: usize) f64 {
    return self.data[i];
}

pub fn x(self: Tuple) f64 {
    return self.data[0];
}

pub fn y(self: Tuple) f64 {
    return self.data[1];
}

pub fn z(self: Tuple) f64 {
    return self.data[2];
}

pub fn w(self: Tuple) f64 {
    return self.data[3];
}

pub fn isPoint(self: Tuple) bool {
    return math.approxEqAbs(f64, self.w(), 1.0, num.epsilon);
}

pub fn isVector(self: Tuple) bool {
    return math.approxEqAbs(f64, self.w(), 0.0, num.epsilon);
}

pub fn approxEq(self: Tuple, other: Tuple) bool {
    return math.approxEqAbs(f64, self.x(), other.x(), num.epsilon) and
        math.approxEqAbs(f64, self.y(), other.y(), num.epsilon) and
        math.approxEqAbs(f64, self.z(), other.z(), num.epsilon) and
        math.approxEqAbs(f64, self.w(), other.w(), num.epsilon);
}

pub fn add(self: Tuple, other: Tuple) Tuple {
    return Tuple.init(
        self.x() + other.x(),
        self.y() + other.y(),
        self.z() + other.z(),
        self.w() + other.w(),
    );
}

pub fn sub(self: Tuple, other: Tuple) Tuple {
    return Tuple.init(
        self.x() - other.x(),
        self.y() - other.y(),
        self.z() - other.z(),
        self.w() - other.w(),
    );
}

pub fn negate(self: Tuple) Tuple {
    return Tuple.init(-self.x(), -self.y(), -self.z(), -self.w());
}

pub fn mul(self: Tuple, m: f64) Tuple {
    return Tuple.init(
        m * self.x(),
        m * self.y(),
        m * self.z(),
        m * self.w(),
    );
}

pub fn div(self: Tuple, d: f64) Tuple {
    return self.mul(1.0 / d);
}

test "A tuple with w=1.0 is a point" {
    // Given
    const a = Tuple.init(4.3, -4.2, 3.1, 1.0);

    // Then
    try std.testing.expectApproxEqAbs(4.3, a.x(), num.epsilon);
    try std.testing.expectApproxEqAbs(-4.2, a.y(), num.epsilon);
    try std.testing.expectApproxEqAbs(3.1, a.z(), num.epsilon);
    try std.testing.expectApproxEqAbs(1.0, a.w(), num.epsilon);
    try std.testing.expect(a.isPoint());
    try std.testing.expect(!a.isVector());
}

test "A tuple with w=0 is a vector" {
    // Given
    const a = Tuple.init(4.3, -4.2, 3.1, 0.0);

    // Then
    try std.testing.expectApproxEqAbs(4.3, a.x(), num.epsilon);
    try std.testing.expectApproxEqAbs(-4.2, a.y(), num.epsilon);
    try std.testing.expectApproxEqAbs(3.1, a.z(), num.epsilon);
    try std.testing.expectApproxEqAbs(0.0, a.w(), num.epsilon);
    try std.testing.expect(!a.isPoint());
    try std.testing.expect(a.isVector());
}

test "Adding two tuples" {
    // Given
    const a1 = Tuple.init(3, -2, 5, 1);
    const a2 = Tuple.init(-2, 3, 1, 0);

    // Then
    try std.testing.expect(a1.add(a2).approxEq(Tuple.init(1, 1, 6, 1)));
}

test "Negating a tuple" {
    // Given
    const a = Tuple.init(1, -2, 3, -4);

    // Then
    try std.testing.expect(a.negate().approxEq(Tuple.init(-1, 2, -3, 4)));
}

test "Multiplying a tuple by a scalar" {
    // Given
    const a = Tuple.init(1, -2, 3, -4);

    // Then
    try std.testing.expect(a.mul(3.5).approxEq(Tuple.init(3.5, -7, 10.5, -14)));
}

test "Multiplying a tuple by a fraction" {
    // Given
    const a = Tuple.init(1, -2, 3, -4);

    // Then
    try std.testing.expect(a.mul(0.5).approxEq(Tuple.init(0.5, -1, 1.5, -2)));
}

test "Dividing a tuple by a scalar" {
    // Given
    const a = Tuple.init(1, -2, 3, -4);

    // Then
    try std.testing.expect(a.div(2).approxEq(Tuple.init(0.5, -1, 1.5, -2)));
}
