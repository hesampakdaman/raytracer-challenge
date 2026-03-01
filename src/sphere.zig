const std = @import("std");
const math = std.math;

const expect = @import("expect.zig");
const num = @import("num.zig");
const tsfm = @import("transformation.zig");

const Intersection = @import("intersection.zig").Intersection;
const Intersections = @import("intersection.zig").Intersections;
const Point = @import("tuple.zig").Point;
const PointLight = @import("light.zig").PointLight;
const Ray = @import("ray.zig").Ray;
const Vector = @import("tuple.zig").Vector;
const Material = @import("material.zig").Material;
const Mat4 = @import("matrix.zig").Mat4;

pub const Sphere = struct {
    transform: Mat4 = Mat4.identity(),
    material: Material = Material{},

    pub fn intersect(self: *const Sphere, r: Ray) Intersections {
        const inv = self.transform.inverse();
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
        self.transform = t;
    }

    pub fn normalAt(self: Sphere, world_point: Point) Vector {
        const object_point: Point = self.transform.inverse().apply(world_point);
        const object_normal: Vector = object_point.sub(Point.zero());
        return self.transform
            .inverse()
            .transpose()
            .apply(object_normal)
            .normalize();
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

test "The normal on a sphere at a point on the x axis" {
    // Given
    const s = Sphere{};

    // When
    const n = s.normalAt(Point.init(1, 0, 0));

    // Then
    try expect.approxEqVector(Vector.init(1, 0, 0), n);
}

test "The normal on a sphere at a point on the y axis" {
    // Given
    const s = Sphere{};

    // When
    const n = s.normalAt(Point.init(0, 1, 0));

    // Then
    try std.testing.expect(n.approxEq(Vector.init(0, 1, 0)));
}

test "The normal on a sphere at a point on the z axis" {
    // Given
    const s = Sphere{};

    // When
    const n = s.normalAt(Point.init(0, 0, 1));

    // Then
    try std.testing.expect(n.approxEq(Vector.init(0, 0, 1)));
}

test "The normal on a sphere at a point on a nonaxial point" {
    // Given
    const s = Sphere{};

    // When
    const n = s.normalAt(Point.init(num.sqrt3 / 3.0, num.sqrt3 / 3.0, num.sqrt3 / 3.0));

    // Then
    try expect.approxEqVector(Vector.init(num.sqrt3 / 3.0, num.sqrt3 / 3.0, num.sqrt3 / 3.0), n);
}

test "The normal is a normalized vector" {
    // Given
    const s = Sphere{};

    // When
    const n = s.normalAt(Point.init(num.sqrt3 / 3.0, num.sqrt3 / 3.0, num.sqrt3 / 3.0));

    // Then
    try expect.approxEqVector(n.normalize(), n);
}

test "Computing the normal on a translated sphere" {
    // Given
    var s = Sphere{};
    s.setTransform(tsfm.translation(0, 1, 0));

    // When
    const n = s.normalAt(Point.init(0, 1.70711, -0.70711));

    // Then
    try expect.approxEqVector(Vector.init(0, num.sqrt1_2, -num.sqrt1_2), n);
}

test "Computing the normal on a transformed sphere" {
    // Given
    var s = Sphere{};
    const m = tsfm.scaling(1, 0.5, 1).mul(&tsfm.rotationZ(num.pi / 5.0));
    s.setTransform(m);

    // When
    const n = s.normalAt(Point.init(0, num.sqrt2 / 2.0, -num.sqrt2 / 2.0));

    // Then
    try expect.approxEqVector(Vector.init(0, 0.97014, -0.24254), n);
}

test "Chapter 6: Putting it together" {
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

    const canvas_pixels: usize = 50;
    const pixel_size = wall_size / @as(f64, canvas_pixels);
    const half = wall_size / 2.0;

    var canvas = try Canvas.init(allocator, canvas_pixels, canvas_pixels);
    defer canvas.deinit();

    var sphere = Sphere{};
    sphere.material = Material{};
    sphere.material.color = Color.init(1, 0.2, 1);

    const light_position = Point.init(-10, 10, -10);
    const light_color = Color.init(1, 1, 1);
    const light = PointLight.init(light_position, light_color);

    for (0..canvas_pixels) |y| {
        const world_y = half - pixel_size * @as(f64, @floatFromInt(y));

        for (0..canvas_pixels) |x| {
            const world_x = -half + pixel_size * @as(f64, @floatFromInt(x));
            const position = Point.init(world_x, world_y, wall_z);

            const ray = Ray.init(ray_origin, position.sub(ray_origin).normalize());
            const xs = sphere.intersect(ray);

            if (xs.hit()) |hit| {
                const point = ray.position(hit.t);
                const normal = hit.object.normalAt(point);
                const eye = ray.direction.negate();
                const color = hit.object.material.lighting(light, point, eye, normal);
                canvas.writePixel(x, y, color);
            }
        }
    }

    try canvas.savePpm(ppm_file_path);
}
