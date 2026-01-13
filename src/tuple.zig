const std = @import("std");
const EPSILON = @import("core.zig").EPSILON;

const Tuple = struct {
    x: f64,
    y: f64,
    z: f64,
    w: f64,

    pub fn isPoint(self: Tuple) bool {
        return std.math.approxEqAbs(f64, self.w, 1.0, EPSILON);
    }

    pub fn isVector(self: Tuple) bool {
        return std.math.approxEqAbs(f64, self.w, 0.0, EPSILON);
    }

    pub fn approxEq(self: Tuple, other: Tuple) bool {
        const x_ok = std.math.approxEqAbs(f64, self.x, other.x, EPSILON);
        const y_ok = std.math.approxEqAbs(f64, self.y, other.y, EPSILON);
        const z_ok = std.math.approxEqAbs(f64, self.z, other.z, EPSILON);
        const w_ok = std.math.approxEqAbs(f64, self.w, other.w, EPSILON);

        return x_ok and y_ok and z_ok and w_ok;
    }
};

pub fn tuple(x: f64, y: f64, z: f64, w: f64) Tuple {
    return Tuple{ .x = x, .y = y, .z = z, .w = w };
}

pub fn point(x: f64, y: f64, z: f64) Tuple {
    return Tuple{ .x = x, .y = y, .z = z, .w = 1 };
}

pub fn vector(x: f64, y: f64, z: f64) Tuple {
    return Tuple{ .x = x, .y = y, .z = z, .w = 0 };
}

test "Scenario: A tuple with w=1.0 is a point" {
    // Given
    const a = tuple(4.3, -4.2, 3.1, 1.0);

    // Then
    try std.testing.expectApproxEqAbs(4.3, a.x, EPSILON);
    try std.testing.expectApproxEqAbs(-4.2, a.y, EPSILON);
    try std.testing.expectApproxEqAbs(3.1, a.z, EPSILON);
    try std.testing.expectApproxEqAbs(1.0, a.w, EPSILON);
    try std.testing.expect(a.isPoint());
    try std.testing.expect(!a.isVector());
}

test "Scenario: A tuple with w=0 is a vector" {
    // Given
    const a = tuple(4.3, -4.2, 3.1, 0.0);

    // Then
    try std.testing.expectApproxEqAbs(4.3, a.x, EPSILON);
    try std.testing.expectApproxEqAbs(-4.2, a.y, EPSILON);
    try std.testing.expectApproxEqAbs(3.1, a.z, EPSILON);
    try std.testing.expectApproxEqAbs(0.0, a.w, EPSILON);
    try std.testing.expect(!a.isPoint());
    try std.testing.expect(a.isVector());
}

test "Scenario: point() creates tuples with w=1" {
    // Given
    const p = point(4, -4, 3);

    // Then
    try std.testing.expect(p.approxEq(tuple(4, -4, 3, 1)));
}

test "Scenario: vector() creates tuples with w=0" {
    // Given
    const v = vector(4, -4, 3);

    // Then
    try std.testing.expect(v.approxEq(tuple(4, -4, 3, 0)));
}
