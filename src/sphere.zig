const std = @import("std");
const math = std.math;

const expect = @import("expect.zig");
const num = @import("num.zig");
const tsfm = @import("transformation.zig");

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
    try std.testing.expectApproxEqAbs(4.0, xs.items[0].t, num.epsilon);
    try std.testing.expectApproxEqAbs(6.0, xs.items[1].t, num.epsilon);
}

test "A ray intersects a sphere at a tangent" {
    // Given
    const r = Ray.init(Point.init(0, 1, -5), Vector.init(0, 0, 1));
    const s = Sphere{};

    // When
    const xs = s.intersect(r);

    // Then
    try std.testing.expectEqual(2, xs.count);
    try std.testing.expectApproxEqAbs(5.0, xs.items[0].t, num.epsilon);
    try std.testing.expectApproxEqAbs(5.0, xs.items[1].t, num.epsilon);
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
    try std.testing.expectApproxEqAbs(-1.0, xs.items[0].t, num.epsilon);
    try std.testing.expectApproxEqAbs(1.0, xs.items[1].t, num.epsilon);
}

test "A sphere is behind a ray" {
    // Given
    const r = Ray.init(Point.init(0, 0, 5), Vector.init(0, 0, 1));
    const s = Sphere{};

    // When
    const xs = s.intersect(r);

    // Then
    try std.testing.expectEqual(2, xs.count);
    try std.testing.expectApproxEqAbs(-6.0, xs.items[0].t, num.epsilon);
    try std.testing.expectApproxEqAbs(-4.0, xs.items[1].t, num.epsilon);
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
    try expect.approxEqMatrix(4, &Mat4.identity(), &s.transform);
}

test "Changing a sphere's transformation" {
    // Given
    var s = Sphere{};
    const t = tsfm.translation(2, 3, 4);

    // When
    s.setTransform(t);

    // Then
    try expect.approxEqMatrix(4, &t, &s.transform);
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
    try std.testing.expectApproxEqAbs(3, xs.items[0].t, num.epsilon);
    try std.testing.expectApproxEqAbs(7, xs.items[1].t, num.epsilon);
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

test "Chapter 5: Putting it together" {
    const Canvas = @import("canvas.zig").Canvas;
    const Color = @import("color.zig").Color;

    const allocator = std.testing.allocator;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    const parent = try tmp.dir.realpathAlloc(allocator, ".");
    defer allocator.free(parent);

    const ppm_file_path = try std.fs.path.join(std.testing.allocator, &[_][]const u8{ parent, "test.ppm" });
    defer allocator.free(ppm_file_path);

    const ray_origin = Point.init(0, 0, -5);
    const wall_z: f64 = 10;
    const wall_size: f64 = 7;

    const canvas_pixels: usize = 100;
    const pixel_size = wall_size / @as(f64, canvas_pixels);
    const half = wall_size / 2.0;

    var canvas = try Canvas.init(allocator, canvas_pixels, canvas_pixels);
    defer canvas.deinit();

    const color = Color.init(1, 0, 0);
    var shape = Sphere{};

    for (0..canvas_pixels) |y| {
        const world_y = half - pixel_size * @as(f64, @floatFromInt(y));

        for (0..canvas_pixels) |x| {
            const world_x = -half + pixel_size * @as(f64, @floatFromInt(x));
            const position = Point.init(world_x, world_y, wall_z);

            const r = Ray.init(ray_origin, position.sub(ray_origin).normalize());
            const xs = shape.intersect(r);

            if (xs.hit()) |_| canvas.writePixel(x, y, color);
        }
    }

    try canvas.savePpm(ppm_file_path);
}
