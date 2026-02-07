const std = @import("std");
const math = std.math;

const tsfm = @import("transformation.zig");

const EPSILON = @import("core.zig").EPSILON;
const Intersection = @import("intersection.zig").Intersection;
const Intersections = @import("intersection.zig").Intersections;
const Point = @import("tuple.zig").Point;
const Ray = @import("ray.zig").Ray;
const Vector = @import("tuple.zig").Vector;
const Mat4 = @import("matrix.zig").Mat4;

pub const Sphere = struct {
    transformation: Mat4 = Mat4.identity(),

    pub fn intersect(self: *const Sphere, r: Ray) Intersections {
        const inv = self.transformation.inverse() catch @panic("Sphere has non-invertible transform");
        const ray = r.transform(inv);

        // remember: the sphere is centered at the world origin
        const sphere_to_ray = ray.origin.sub(Point.init(0, 0, 0));

        const a = ray.direction.dot(ray.direction);
        const b = 2 * ray.direction.dot(sphere_to_ray);
        const c = sphere_to_ray.dot(sphere_to_ray) - 1;

        const discriminant = b * b - 4 * a * c;
        if (discriminant < 0) return Intersections.init(.{});

        const root: f64 = math.sqrt(discriminant);
        const t1 = (-b - root) / (2 * a);
        const t2 = (-b + root) / (2 * a);

        const i_1 = Intersection{ .t = t1, .object = self };
        const i_2 = Intersection{ .t = t2, .object = self };

        return Intersections.init(.{ i_1, i_2 });
    }

    pub fn setTransform(self: *Sphere, t: Mat4) void {
        self.transformation = t;
    }
};

test "A ray intersects a sphere at two points" {
    // Given
    const r = Ray.init(Point.init(0, 0, -5), Vector.init(0, 0, 1));
    const s = Sphere{};

    // When
    const xs = s.intersect(r);

    // Then
    try std.testing.expectEqual(2, xs.count);
    try std.testing.expectApproxEqAbs(4.0, xs.items[0].t, EPSILON);
    try std.testing.expectApproxEqAbs(6.0, xs.items[1].t, EPSILON);
}

test "A ray intersects a sphere at a tangent" {
    // Given
    const r = Ray.init(Point.init(0, 1, -5), Vector.init(0, 0, 1));
    const s = Sphere{};

    // When
    const xs = s.intersect(r);

    // Then
    try std.testing.expectEqual(2, xs.count);
    try std.testing.expectApproxEqAbs(5.0, xs.items[0].t, EPSILON);
    try std.testing.expectApproxEqAbs(5.0, xs.items[1].t, EPSILON);
}

test "A ray misses a sphere" {
    // Given
    const r = Ray.init(Point.init(0, 2, -5), Vector.init(0, 0, 1));
    const s = Sphere{};

    // When
    const xs = s.intersect(r);

    // Then
    try std.testing.expectEqual(0, xs.count);
}

test "A ray originates inside a sphere" {
    // Given
    const r = Ray.init(Point.init(0, 0, 0), Vector.init(0, 0, 1));
    const s = Sphere{};

    // When
    const xs = s.intersect(r);

    // Then
    try std.testing.expectEqual(2, xs.count);
    try std.testing.expectApproxEqAbs(-1.0, xs.items[0].t, EPSILON);
    try std.testing.expectApproxEqAbs(1.0, xs.items[1].t, EPSILON);
}

test "A sphere is behind a ray" {
    // Given
    const r = Ray.init(Point.init(0, 0, 5), Vector.init(0, 0, 1));
    const s = Sphere{};

    // When
    const xs = s.intersect(r);

    // Then
    try std.testing.expectEqual(2, xs.count);
    try std.testing.expectApproxEqAbs(-6.0, xs.items[0].t, EPSILON);
    try std.testing.expectApproxEqAbs(-4.0, xs.items[1].t, EPSILON);
}

test "Intersect sets the object on the intersection" {
    // Given
    const r = Ray.init(Point.init(0, 0, -5), Vector.init(0, 0, 1));
    const s = &Sphere{};

    // When
    const xs = s.intersect(r);

    // Then
    try std.testing.expectEqual(2, xs.count);
    try std.testing.expectEqual(s, xs.items[0].object);
    try std.testing.expectEqual(s, xs.items[1].object);
}

test "A sphere's default transformation" {
    // Given
    const s = Sphere{};

    // Then
    try std.testing.expect(s.transformation.approxEq(&Mat4.identity()));
}

test "Changing a sphere's transformation" {
    // Given
    var s = Sphere{};
    const t = tsfm.translation(2, 3, 4);

    // When
    s.setTransform(t);

    // Then
    try std.testing.expect(s.transformation.approxEq(&t));
}

test "Intersecting a scaled sphere with a ray" {
    // Given
    const r = Ray.init(Point.init(0, 0, -5), Vector.init(0, 0, 1));
    var s = Sphere{};

    // When
    s.setTransform(tsfm.scaling(2, 2, 2));
    const xs = s.intersect(r);

    // Then
    try std.testing.expectEqual(2, xs.count);
    try std.testing.expectApproxEqAbs(3, xs.items[0].t, EPSILON);
    try std.testing.expectApproxEqAbs(7, xs.items[1].t, EPSILON);
}

test "Intersecting a translated sphere with a ray" {
    // Given
    const r = Ray.init(Point.init(0, 0, -5), Vector.init(0, 0, 1));
    var s = Sphere{};

    // When
    s.setTransform(tsfm.translation(5, 0, 0));
    const xs = s.intersect(r);

    // Then
    try std.testing.expectEqual(0, xs.count);
}
