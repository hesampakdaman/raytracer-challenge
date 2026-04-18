const std = @import("std");
const assert = std.debug.assert;

const expect = @import("expect.zig");
const Mat4 = @import("matrix.zig").Mat4;
const Material = @import("material.zig").Material;
const num = @import("num.zig");
const Point = @import("Point.zig");
const Ray = @import("ray.zig").Ray;
const Vector = @import("Vector.zig");

pub const Plane = struct {
    transform: Mat4 = Mat4.identity(),
    material: Material = Material{},

    pub fn localIntersect(_: *const Plane, ray: *const Ray, buf: []f64) usize {
        assert(buf.len >= 1);
        if (@abs(ray.direction.y()) < num.epsilon) return 0;
        buf[0] = -ray.origin.y() / ray.direction.y();
        return 1;
    }

    pub fn localNormalAt(_: *const Plane, _: Point) Vector {
        return Vector.init(0, 1, 0);
    }
};

test "The normal of a plane is constant everywhere" {
    // Given
    const p = Plane{};

    // When
    const n1 = p.localNormalAt(Point.zero());
    const n2 = p.localNormalAt(Point.init(10, 0, -10));
    const n3 = p.localNormalAt(Point.init(-5, 0, 150));

    // Then
    try expect.approxEqVector(Vector.init(0, 1, 0), n1);
    try expect.approxEqVector(Vector.init(0, 1, 0), n2);
    try expect.approxEqVector(Vector.init(0, 1, 0), n3);
}

test "Intersect with a ray parallel to the plane" {
    // Given
    const p = Plane{};
    const r = Ray.init(Point.init(0, 10, 0), Vector.init(0, 0, 1));

    // When
    var buf: [32]f64 = undefined;
    const hits = p.localIntersect(&r, &buf);

    // Then
    try std.testing.expectEqual(0, hits);
}

test "Intersect with a coplanar ray" {
    // Given
    const p = Plane{};
    const r = Ray.init(Point.zero(), Vector.init(0, 0, 1));

    // When
    var buf: [32]f64 = undefined;
    const hits = p.localIntersect(&r, &buf);

    // Then
    try std.testing.expectEqual(0, hits);
}
