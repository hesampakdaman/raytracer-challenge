const std = @import("std");
const math = std.math;

const core = @import("core.zig");
const EPSILON = core.EPSILON;

pub const Tuple = struct {
    data: [4]f64,

    pub fn init(x_val: f64, y_val: f64, z_val: f64, w_val: f64) Tuple {
        return .{ .data = .{ x_val, y_val, z_val, w_val } };
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
        return math.approxEqAbs(f64, self.w(), 1.0, EPSILON);
    }

    pub fn isVector(self: Tuple) bool {
        return math.approxEqAbs(f64, self.w(), 0.0, EPSILON);
    }

    pub fn approxEq(self: Tuple, other: Tuple) bool {
        const x_ok = math.approxEqAbs(f64, self.x(), other.x(), EPSILON);
        const y_ok = math.approxEqAbs(f64, self.y(), other.y(), EPSILON);
        const z_ok = math.approxEqAbs(f64, self.z(), other.z(), EPSILON);
        const w_ok = math.approxEqAbs(f64, self.w(), other.w(), EPSILON);

        return x_ok and y_ok and z_ok and w_ok;
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
        return self.mul(1 / d);
    }

    pub fn magnitude(self: Tuple) f64 {
        return math.sqrt(self.x() * self.x() +
            self.y() * self.y() +
            self.z() * self.z() +
            self.w() * self.w());
    }

    pub fn normalize(self: Tuple) Tuple {
        return self.div(self.magnitude());
    }

    pub fn dot(self: Tuple, other: Tuple) f64 {
        return self.x() * other.x() +
            self.y() * other.y() +
            self.z() * other.z() +
            self.w() * other.w();
    }

    pub fn cross(self: Tuple, other: Tuple) Tuple {
        return vector(
            self.y() * other.z() - self.z() * other.y(),
            self.z() * other.x() - self.x() * other.z(),
            self.x() * other.y() - self.y() * other.x(),
        );
    }
};

pub fn point(x: f64, y: f64, z: f64) Tuple {
    return Tuple.init(x, y, z, 1);
}

pub fn vector(x: f64, y: f64, z: f64) Tuple {
    return Tuple.init(x, y, z, 0);
}

test "A tuple with w=1.0 is a point" {
    // Given
    const a = Tuple.init(4.3, -4.2, 3.1, 1.0);

    // Then
    try std.testing.expectApproxEqAbs(4.3, a.x(), EPSILON);
    try std.testing.expectApproxEqAbs(-4.2, a.y(), EPSILON);
    try std.testing.expectApproxEqAbs(3.1, a.z(), EPSILON);
    try std.testing.expectApproxEqAbs(1.0, a.w(), EPSILON);
    try std.testing.expect(a.isPoint());
    try std.testing.expect(!a.isVector());
}

test "A tuple with w=0 is a vector" {
    // Given
    const a = Tuple.init(4.3, -4.2, 3.1, 0.0);

    // Then
    try std.testing.expectApproxEqAbs(4.3, a.x(), EPSILON);
    try std.testing.expectApproxEqAbs(-4.2, a.y(), EPSILON);
    try std.testing.expectApproxEqAbs(3.1, a.z(), EPSILON);
    try std.testing.expectApproxEqAbs(0.0, a.w(), EPSILON);
    try std.testing.expect(!a.isPoint());
    try std.testing.expect(a.isVector());
}

test "point() creates tuples with w=1" {
    // Given
    const p = point(4, -4, 3);

    // Then
    try std.testing.expect(p.approxEq(Tuple.init(4, -4, 3, 1)));
}

test "vector() creates tuples with w=0" {
    // Given
    const v = vector(4, -4, 3);

    // Then
    try std.testing.expect(v.approxEq(Tuple.init(4, -4, 3, 0)));
}

test "Adding two tuples" {
    // Given
    const a1 = Tuple.init(3, -2, 5, 1);
    const a2 = Tuple.init(-2, 3, 1, 0);

    // Then
    try std.testing.expect(a1.add(a2).approxEq(Tuple.init(1, 1, 6, 1)));
}

test "Subtracting two points" {
    // Given
    const p1 = point(3, 2, 1);
    const p2 = point(5, 6, 7);

    // Then
    try std.testing.expect(p1.sub(p2).approxEq(vector(-2, -4, -6)));
}

test "Subtracting a vector from a point" {
    // Given
    const p = point(3, 2, 1);
    const v = vector(5, 6, 7);

    // Then
    try std.testing.expect(p.sub(v).approxEq(point(-2, -4, -6)));
}

test "Subtracting two vectors" {
    // Given
    const v1 = vector(3, 2, 1);
    const v2 = vector(5, 6, 7);

    // Then
    try std.testing.expect(v1.sub(v2).approxEq(vector(-2, -4, -6)));
}

test "Subtracting a vector from the zero vector" {
    // Given
    const zero = vector(0, 0, 0);
    const v = vector(1, -2, 3);

    // Then
    try std.testing.expect(zero.sub(v).approxEq(vector(-1, 2, -3)));
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

test "Computing the magnitude of vector(1, 0, 0)" {
    // Given
    const v = vector(1, 0, 0);

    // Then
    try std.testing.expectApproxEqAbs(1, v.magnitude(), EPSILON);
}

test "Computing the magnitude of vector(0, 1, 0)" {
    // Given
    const v = vector(0, 1, 0);

    // Then
    try std.testing.expectApproxEqAbs(1, v.magnitude(), EPSILON);
}

test "Computing the magnitude of vector(0, 0, 1)" {
    // Given
    const v = vector(0, 0, 1);

    // Then
    try std.testing.expectApproxEqAbs(1, v.magnitude(), EPSILON);
}

test "Computing the magnitude of vector(1, 2, 3)" {
    // Given
    const v = vector(1, 2, 3);

    // Then
    try std.testing.expectApproxEqAbs(math.sqrt(14.0), v.magnitude(), EPSILON);
}

test "Computing the magnitude of vector(-1, -2, -3)" {
    // Given
    const v = vector(-1, -2, -3);

    // Then
    try std.testing.expectApproxEqAbs(math.sqrt(14.0), v.magnitude(), EPSILON);
}

test "Normalizing vector(4, 0, 0) gives (1, 0, 0)" {
    // Given
    const v = vector(4, 0, 0);

    // Then
    try std.testing.expect(v.normalize().approxEq(vector(1, 0, 0)));
}

test "Normalizing vector(1, 2, 3)" {
    // Given
    const v = vector(1, 2, 3);

    // Then
    try std.testing.expect(
        v.normalize().approxEq(vector(1.0 / math.sqrt(14.0), 2.0 / math.sqrt(14.0), 3.0 / math.sqrt(14.0))),
    );
}

test "The magnitude of a normalized vector" {
    // Given
    const v = vector(1, 2, 3);

    // When
    const norm = v.normalize();

    // Then
    try std.testing.expectApproxEqAbs(1, norm.magnitude(), EPSILON);
}

test "The dot product of two tuples" {
    // Given
    const a = vector(1, 2, 3);
    const b = vector(2, 3, 4);

    // Then
    try std.testing.expectApproxEqAbs(20, a.dot(b), EPSILON);
}

test "The cross product of two vectors" {
    // Given
    const a = vector(1, 2, 3);
    const b = vector(2, 3, 4);

    // Then
    try std.testing.expect(a.cross(b).approxEq(vector(-1, 2, -1)));
    try std.testing.expect(b.cross(a).approxEq(vector(1, -2, 1)));
}
