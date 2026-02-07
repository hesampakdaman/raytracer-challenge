const std = @import("std");
const math = std.math;

const tsfm = @import("transformation.zig");

const EPSILON = @import("core.zig").EPSILON;
const Point = @import("tuple.zig").Point;
const Vector = @import("tuple.zig").Vector;
const Mat4 = @import("matrix.zig").Mat4;

pub const Ray = struct {
    origin: Point,
    direction: Vector,

    pub fn init(origin: Point, direction: Vector) Ray {
        return Ray{ .origin = origin, .direction = direction };
    }

    pub fn position(self: *const Ray, t: f64) Point {
        return self.origin.add(self.direction.mul(t));
    }

    pub fn transform(self: *const Ray, m: Mat4) Ray {
        return Ray.init(m.apply(self.origin), m.apply(self.direction));
    }
};

test "Creating and querying a ray" {
    // Given
    const origin = Point.init(1, 2, 3);
    const direction = Vector.init(4, 5, 6);

    // When
    const r = Ray.init(origin, direction);

    // Then
    try std.testing.expect(r.origin.approxEq(origin));
    try std.testing.expect(r.direction.approxEq(direction));
}

test "Computing a point from a distance" {
    // Given
    const r = Ray.init(Point.init(2, 3, 4), Vector.init(1, 0, 0));

    // Then
    try std.testing.expect(r.position(0).approxEq(Point.init(2, 3, 4)));
    try std.testing.expect(r.position(1).approxEq(Point.init(3, 3, 4)));
    try std.testing.expect(r.position(-1).approxEq(Point.init(1, 3, 4)));
    try std.testing.expect(r.position(2.5).approxEq(Point.init(4.5, 3, 4)));
}

test "Translating a ray" {
    // Given
    const r = Ray.init(Point.init(1, 2, 3), Vector.init(0, 1, 0));
    const m = tsfm.translation(3, 4, 5);

    // When
    const r2 = r.transform(m);

    // Then
    try std.testing.expect(r2.origin.approxEq(Point.init(4, 6, 8)));
    try std.testing.expect(r2.direction.approxEq(Vector.init(0, 1, 0)));
}

test "Scaling a ray" {
    // Given
    const r = Ray.init(Point.init(1, 2, 3), Vector.init(0, 1, 0));
    const m = tsfm.scaling(2, 3, 4);

    // When
    const r2 = r.transform(m);

    // Then
    try std.testing.expect(r2.origin.approxEq(Point.init(2, 6, 12)));
    try std.testing.expect(r2.direction.approxEq(Vector.init(0, 3, 0)));
}
