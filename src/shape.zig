const std = @import("std");
const Io = std.Io;
const builtin = @import("builtin");

const expect = @import("expect.zig");
const Intersections = @import("intersection.zig").Intersections;
const Mat4 = @import("matrix.zig").Mat4;
const Material = @import("material.zig").Material;
const num = @import("num.zig");
const Plane = @import("plane.zig").Plane;
const Point = @import("tuple.zig").Point;
const Ray = @import("ray.zig").Ray;
const Sphere = @import("sphere.zig").Sphere;
const tsfm = @import("transformation.zig");
const Vector = @import("tuple.zig").Vector;

/// Shape is a tagged union over all renderable primitives.
///
/// Required fields
/// transform: Mat4      // object-to-world transform, default Identity
/// material: Material   // surface properties, default Material
///
/// Required methods
///
/// pub fn localIntersect(self: *const T, ray: *const Ray) Intersections
/// - ray is already transformed into object space
///
/// pub fn localNormalAt(self: *const T, point: Point) Vector
/// - point is in object space
/// - must return the normal in object space (not normalized to world)
///
/// Concrete shapes should only implement local (object-space) logic
/// and must not apply transforms themselves.
pub const Shape = union(enum) {
    sphere: Sphere,
    plane: Plane,
    testShape: if (builtin.is_test) TestShape else void,

    pub fn newSphere(args: struct {
        transform: Mat4 = Mat4.identity(),
        material: Material = .{},
    }) Shape {
        return .{
            .sphere = .{
                .transform = args.transform,
                .material = args.material,
            },
        };
    }

    pub fn newPlane(args: struct { material: Material = .{} }) Shape {
        return .{ .plane = .{
            .material = args.material,
        } };
    }

    pub fn intersect(self: *const Shape, r: *const Ray) Intersections {
        const inv = self.transform().inverse();
        const local_ray = r.transform(inv);
        var buf: [32]f64 = undefined;

        const count: usize = switch (self.*) {
            inline else => |*s| s.localIntersect(&local_ray, &buf),
        };
        if (count == 0) return .{ .count = 0, .items = undefined };
        return Intersections.fromTs(buf[0..count], self);
    }

    pub fn normalAt(self: *const Shape, point: *const Point) Vector {
        const local_point: Point = self.transform().inverse().apply(point.*);
        const local_normal = switch (self.*) {
            inline else => |*s| s.localNormalAt(local_point),
        };

        return self.transform()
            .inverse()
            .transpose()
            .apply(local_normal)
            .normalize();
    }

    pub fn transform(self: *const Shape) *const Mat4 {
        switch (self.*) {
            inline else => |*s| return &s.transform,
        }
    }

    pub fn material(self: *const Shape) Material {
        return switch (self.*) {
            inline else => |s| s.material,
        };
    }

    pub fn setTransform(self: *Shape, t: Mat4) void {
        switch (self.*) {
            inline else => |*s| s.transform = t,
        }
    }

    pub fn setMaterial(self: *Shape, m: Material) void {
        return switch (self.*) {
            inline else => |*s| s.material = m,
        };
    }

    pub fn approxEq(self: *const Shape, other: *const Shape) bool {
        if (std.meta.activeTag(self.*) != std.meta.activeTag(other.*)) return false;
        return self.transform().approxEq(other.transform()) and
            self.material().approxEq(other.material());
    }
};

const Probe = struct {
    saved_ray: ?Ray = null,
};

const TestShape = struct {
    probe: *Probe,
    transform: Mat4 = Mat4.identity(),
    material: Material = Material{},

    pub fn localIntersect(self: *const TestShape, r: *const Ray, _: []f64) usize {
        self.probe.saved_ray = r.*;
        return 0;
    }

    pub fn setMaterial(self: *TestShape, m: Material) void {
        self.material = m;
    }

    pub fn localNormalAt(_: *const TestShape, p: Point) Vector {
        return Vector.init(p.x(), p.y(), p.z());
    }
};

fn testShape(p: *Probe) Shape {
    return Shape{ .testShape = TestShape{ .probe = p } };
}

test "The default transformation" {
    // Given
    var probe = Probe{};
    var s = testShape(&probe);

    // Then
    try expect.approxEqMatrix(4, &Mat4.identity(), s.transform());
}

test "Assigning a transformation" {
    // Given
    var probe = Probe{};
    var s = testShape(&probe);

    // When
    s.setTransform(tsfm.translation(2, 3, 4));

    // Then
    const t = tsfm.translation(2, 3, 4);
    try expect.approxEqMatrix(4, &t, s.transform());
}

test "The default material" {
    // Given
    var probe = Probe{};
    var s = testShape(&probe);

    // When
    const m = s.material();

    // Then
    try expect.approxEqMaterial(Material{}, m);
}

test "Assigning a material" {
    // Given
    var probe = Probe{};
    var s = testShape(&probe);
    var m = Material{};
    m.ambient = 1;

    // When
    s.setMaterial(m);

    // Then
    try expect.approxEqMaterial(m, s.material());
}

test "Intersecting a scaled shape with a ray" {
    // Given
    var probe = Probe{};
    const r = Ray.init(Point.init(0, 0, -5), Vector.init(0, 0, 1));
    var s = testShape(&probe);

    // When
    s.setTransform(tsfm.scaling(2, 2, 2));
    _ = s.intersect(&r);

    // Then
    try expect.approxEqPoint(Point.init(0, 0, -2.5), probe.saved_ray.?.origin);
    try expect.approxEqVector(Vector.init(0, 0, 0.5), probe.saved_ray.?.direction);
}

test "Intersecting a translated sphere with a ray" {
    // Given
    const r = Ray.init(Point.init(0, 0, -5), Vector.init(0, 0, 1));
    var probe = Probe{};
    var s = testShape(&probe);

    // When
    s.setTransform(tsfm.translation(5, 0, 0));
    _ = s.intersect(&r);

    // Then
    try expect.approxEqPoint(Point.init(-5, 0, -5), probe.saved_ray.?.origin);
    try expect.approxEqVector(Vector.init(0, 0, 1), probe.saved_ray.?.direction);
}

test "Computing the normal on a translated shape" {
    // Given
    var probe = Probe{};
    var s = testShape(&probe);
    s.setTransform(tsfm.translation(0, 1, 0));

    // When
    const n = s.normalAt(&Point.init(0, 1.70711, -0.70711));

    // Then
    try expect.approxEqVector(Vector.init(0, num.sqrt1_2, -num.sqrt1_2), n);
}

test "Computing the normal on a transformed sphere" {
    // Given
    var probe = Probe{};
    var s = testShape(&probe);
    const m = tsfm.scaling(1, 0.5, 1).mul(&tsfm.rotationZ(num.pi / 5.0));

    // When
    s.setTransform(m);
    const n = s.normalAt(&Point.init(0, num.sqrt2 / 2.0, -num.sqrt2 / 2.0));

    // Then
    try expect.approxEqVector(Vector.init(0, 0.97014, -0.24254), n);
}

test "Intersect sets the object on the intersection" {
    // Given
    const r = Ray.init(Point.init(0, 0, -5), Vector.init(0, 0, 1));
    const s = Shape.newSphere(.{});

    // When
    const xs = s.intersect(&r);

    // Then
    try std.testing.expectEqual(2, xs.count);
    try std.testing.expectEqual(&s, xs.items[0].object);
    try std.testing.expectEqual(&s, xs.items[1].object);
}

test "A Sphere is a Shape" {
    comptime {
        var found = false;
        for (std.meta.fields(Shape)) |f| {
            if (f.type == Sphere) found = true;
        }
        if (!found) @compileError("Sphere not in Shape");
    }
}

test "Chapter 5: Putting it together" {
    const Canvas = @import("canvas.zig").Canvas;
    const Color = @import("color.zig").Color;

    const allocator = std.testing.allocator;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    var threaded = Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    const file = try tmp.dir.createFile(io, "sphere_demo.ppm", .{});
    defer file.close(io);

    const ray_origin = Point.init(0, 0, -5);
    const wall_z: f64 = 10;
    const wall_size: f64 = 7;

    const canvas_pixels: usize = 100;
    const pixel_size = wall_size / @as(f64, canvas_pixels);
    const half = wall_size / 2.0;

    var canvas = try Canvas.init(allocator, canvas_pixels, canvas_pixels);
    defer canvas.deinit();

    const color = Color.init(1, 0, 0);
    var shape = Shape{ .sphere = Sphere{} };

    for (0..canvas_pixels) |y| {
        const world_y = half - pixel_size * @as(f64, @floatFromInt(y));

        for (0..canvas_pixels) |x| {
            const world_x = -half + pixel_size * @as(f64, @floatFromInt(x));
            const position = Point.init(world_x, world_y, wall_z);

            const r = Ray.init(ray_origin, position.sub(ray_origin).normalize());
            const xs = shape.intersect(&r);

            if (xs.hit()) |_| canvas.writePixel(x, y, color);
        }
    }

    try canvas.savePpm(io, file);
}

test "Chapter 6: Putting it together" {
    const PointLight = @import("light.zig").PointLight;
    const Canvas = @import("canvas.zig").Canvas;
    const Color = @import("color.zig").Color;

    const allocator = std.testing.allocator;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    var threaded = Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    const file = try tmp.dir.createFile(io, "sphere_demo_2.ppm", .{});
    defer file.close(io);

    const ray_origin = Point.init(0, 0, -5);
    const wall_z: f64 = 10;
    const wall_size: f64 = 7;

    const canvas_pixels: usize = 50;
    const pixel_size = wall_size / @as(f64, canvas_pixels);
    const half = wall_size / 2.0;

    var canvas = try Canvas.init(allocator, canvas_pixels, canvas_pixels);
    defer canvas.deinit();

    var sphere = Shape{ .sphere = Sphere{} };
    sphere.setMaterial(Material{ .color = Color.init(1, 0.2, 1) });

    const light_position = Point.init(-10, 10, -10);
    const light_color = Color.init(1, 1, 1);
    const light = PointLight.init(light_position, light_color);

    for (0..canvas_pixels) |y| {
        const world_y = half - pixel_size * @as(f64, @floatFromInt(y));

        for (0..canvas_pixels) |x| {
            const world_x = -half + pixel_size * @as(f64, @floatFromInt(x));
            const position = Point.init(world_x, world_y, wall_z);

            const ray = Ray.init(ray_origin, position.sub(ray_origin).normalize());
            const xs = sphere.intersect(&ray);

            if (xs.hit()) |hit| {
                const point = ray.position(hit.t);
                const normal = hit.object.normalAt(&point);
                const eye = ray.direction.negate();
                const color = hit.object.material().lighting(light, point, eye, normal, false);
                canvas.writePixel(x, y, color);
            }
        }
    }

    try canvas.savePpm(io, file);
}

test "A ray intersecting a plane from above" {
    // Given
    const s = Shape.newPlane(.{});
    const r = Ray.init(Point.init(0, 1, 0), Vector.init(0, -1, 0));

    // When
    const xs = s.intersect(&r);

    // Then
    try std.testing.expectEqual(1, xs.count);
    try std.testing.expectEqual(&s, xs.items[0].object);
}

test "A ray intersecting a plane from below" {
    // Given
    const s = Shape.newPlane(.{});
    const r = Ray.init(Point.init(0, -1, 0), Vector.init(0, 1, 0));

    // When
    const xs = s.intersect(&r);

    // Then
    try std.testing.expectEqual(1, xs.count);
    try std.testing.expectEqual(&s, xs.items[0].object);
}
