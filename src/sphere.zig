const std = @import("std");
const assert = std.debug.assert;
const math = std.math;

const expect = @import("expect.zig");
const Mat4 = @import("matrix.zig").Mat4;
const Material = @import("material.zig").Material;
const num = @import("num.zig");
const Point = @import("Point.zig");
const PointLight = @import("light.zig").PointLight;
const Ray = @import("ray.zig").Ray;
const tsfm = @import("transformation.zig");
const Vector = @import("Vector.zig");

pub const Sphere = struct {
    transform: Mat4 = Mat4.identity(),
    material: Material = Material{},

    pub fn init(t: Mat4, m: Material) Sphere {
        return Sphere{
            .transform = t,
            .material = m,
        };
    }

    pub fn default() Sphere {
        return Sphere{};
    }

    pub fn localIntersect(_: *const Sphere, ray: *const Ray, buf: []f64) usize {
        assert(buf.len >= 2);
        // remember: the sphere is centered at the world origin
        const sphere_to_ray = ray.origin.sub(Point.init(0, 0, 0));

        const a = ray.direction.dot(ray.direction);
        const b = 2 * ray.direction.dot(sphere_to_ray);
        const c = sphere_to_ray.dot(sphere_to_ray) - 1;

        const discriminant = b * b - 4 * a * c;
        if (discriminant < 0) return 0;

        const root: f64 = math.sqrt(discriminant);
        buf[0] = (-b - root) / (2 * a);
        buf[1] = (-b + root) / (2 * a);

        return 2;
    }

    pub fn localNormalAt(_: *const Sphere, object_point: Point) Vector {
        return object_point.sub(Point.zero());
    }

    pub fn approxEq(self: *const Sphere, other: *const Sphere) bool {
        return self.transform.approxEq(&other.transform) and
            self.material.approxEq(other.material);
    }
};

test "A ray intersects a sphere at two points" {
    // Given
    const r = Ray.init(Point.init(0, 0, -5), Vector.init(0, 0, 1));
    const s = Sphere{};

    // When
    var xs: [2]f64 = undefined;
    const hits = s.localIntersect(&r, &xs);

    // Then
    try std.testing.expectEqual(2, hits);
    try std.testing.expectApproxEqAbs(4.0, xs[0], num.epsilon);
    try std.testing.expectApproxEqAbs(6.0, xs[1], num.epsilon);
}

test "A ray intersects a sphere at a tangent" {
    // Given
    const r = Ray.init(Point.init(0, 1, -5), Vector.init(0, 0, 1));
    const s = Sphere{};

    // When
    var xs: [2]f64 = undefined;
    const hits = s.localIntersect(&r, &xs);

    // Then
    try std.testing.expectEqual(2, hits);
    try std.testing.expectApproxEqAbs(5.0, xs[0], num.epsilon);
    try std.testing.expectApproxEqAbs(5.0, xs[1], num.epsilon);
}

test "A ray misses a sphere" {
    // Given
    const r = Ray.init(Point.init(0, 2, -5), Vector.init(0, 0, 1));
    const s = Sphere{};

    // When
    var xs: [2]f64 = undefined;
    const hits = s.localIntersect(&r, &xs);

    // Then
    try std.testing.expectEqual(0, hits);
}

test "A ray originates inside a sphere" {
    // Given
    const r = Ray.init(Point.init(0, 0, 0), Vector.init(0, 0, 1));
    const s = Sphere{};

    // When
    var xs: [2]f64 = undefined;
    const hits = s.localIntersect(&r, &xs);

    // Then
    try std.testing.expectEqual(2, hits);
    try std.testing.expectApproxEqAbs(-1.0, xs[0], num.epsilon);
    try std.testing.expectApproxEqAbs(1.0, xs[1], num.epsilon);
}

test "A sphere is behind a ray" {
    // Given
    const r = Ray.init(Point.init(0, 0, 5), Vector.init(0, 0, 1));
    const s = Sphere{};

    // When
    var xs: [2]f64 = undefined;
    const hits = s.localIntersect(&r, &xs);

    // Then
    try std.testing.expectEqual(2, hits);
    try std.testing.expectApproxEqAbs(-6.0, xs[0], num.epsilon);
    try std.testing.expectApproxEqAbs(-4.0, xs[1], num.epsilon);
}

test "The normal on a sphere at a point on the x axis" {
    // Given
    const s = Sphere{};

    // When
    const n = s.localNormalAt(Point.init(1, 0, 0));

    // Then
    try expect.approxEqVector(Vector.init(1, 0, 0), n);
}

test "The normal on a sphere at a point on the y axis" {
    // Given
    const s = Sphere{};

    // When
    const n = s.localNormalAt(Point.init(0, 1, 0));

    // Then
    try std.testing.expect(n.approxEq(Vector.init(0, 1, 0)));
}

test "The normal on a sphere at a point on the z axis" {
    // Given
    const s = Sphere{};

    // When
    const n = s.localNormalAt(Point.init(0, 0, 1));

    // Then
    try std.testing.expect(n.approxEq(Vector.init(0, 0, 1)));
}

test "The normal on a sphere at a point on a nonaxial point" {
    // Given
    const s = Sphere{};

    // When
    const n = s.localNormalAt(Point.init(num.sqrt3 / 3.0, num.sqrt3 / 3.0, num.sqrt3 / 3.0));

    // Then
    try expect.approxEqVector(Vector.init(num.sqrt3 / 3.0, num.sqrt3 / 3.0, num.sqrt3 / 3.0), n);
}

test "The normal is a normalized vector" {
    // Given
    const s = Sphere{};

    // When
    const n = s.localNormalAt(Point.init(num.sqrt3 / 3.0, num.sqrt3 / 3.0, num.sqrt3 / 3.0));

    // Then
    try expect.approxEqVector(n.normalize(), n);
}
