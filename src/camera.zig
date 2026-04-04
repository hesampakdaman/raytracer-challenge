const std = @import("std");
const math = std.math;
const Allocator = std.mem.Allocator;

const Canvas = @import("canvas.zig").Canvas;
const Color = @import("color.zig").Color;
const expect = @import("expect.zig");
const Mat4 = @import("matrix.zig").Mat4;
const num = @import("num.zig");
const Point = @import("tuple.zig").Point;
const Ray = @import("ray.zig").Ray;
const Sphere = @import("sphere.zig").Sphere;
const tsfm = @import("transformation.zig");
const Vector = @import("tuple.zig").Vector;
const World = @import("world.zig").World;

const Camera = struct {
    hsize: usize,
    vsize: usize,
    field_of_view: f64,
    transform: Mat4,
    half_width: f64,
    half_height: f64,
    pixel_size: f64,

    pub fn init(hsize: usize, vsize: usize, fov: f64) Camera {
        const half_view = math.tan(fov / 2.0);
        const aspect =
            @as(f64, @floatFromInt(hsize)) /
            @as(f64, @floatFromInt(vsize));

        const half_width, const half_height = if (aspect >= 1)
            .{ half_view, half_view / aspect }
        else
            .{ half_view * aspect, half_view };

        const pixel_size =
            (half_width * 2.0) /
            @as(f64, @floatFromInt(hsize));

        return .{
            .hsize = hsize,
            .vsize = vsize,
            .field_of_view = fov,
            .transform = Mat4.identity(),
            .half_width = half_width,
            .half_height = half_height,
            .pixel_size = pixel_size,
        };
    }

    pub fn rayForPixel(self: *const Camera, px: f64, py: f64) Ray {
        // the offset from the edge of the canvas to the pixel's center
        // e.g. px is in [0, 1, ..., vsize] and py is in [0, 1, ..., hsize]
        // so that the center of the pixel is at (px+0.5, py+0.5).
        const xoffset = (px + 0.5) * self.pixel_size;
        const yoffset = (py + 0.5) * self.pixel_size;

        // the untransformed coordinates of the pixel in the world space.
        // (remember that the camera looks toward -z, so +x is to the *left*.)
        const world_x = self.half_width - xoffset;
        const world_y = self.half_height - yoffset;

        // using the camera matrix, transform the canvas point and the origin,
        // and then compute the ray's direction vector.
        // (remember that the canvas is at z=-1)
        const inv = self.transform.inverse();
        const pixel = inv.apply(Point.init(world_x, world_y, -1));
        const origin = inv.apply(Point.zero());
        const direction = pixel.sub(origin).normalize();

        return Ray.init(origin, direction);
    }

    pub fn render(self: *const Camera, gpa: Allocator, world: *const World) !Canvas {
        var image = try Canvas.init(gpa, self.hsize, self.vsize);

        for (0..self.vsize) |y| {
            for (0..self.hsize) |x| {
                const ray = self.rayForPixel(@floatFromInt(x), @floatFromInt(y));
                const color = world.colorAt(&ray);
                image.writePixel(x, y, color);
            }
        }

        return image;
    }
};

test "Constructing a camera" {
    // Given
    const hsize: usize = 160;
    const vsize: usize = 120;
    const field_of_view = num.pi / 2.0;

    // When
    const c = Camera.init(hsize, vsize, field_of_view);

    // Then
    try std.testing.expectEqual(160, c.hsize);
    try std.testing.expectEqual(120, c.vsize);
    try std.testing.expectApproxEqAbs(num.pi / 2.0, c.field_of_view, num.epsilon);
    try expect.approxEqMatrix(4, &Mat4.identity(), &c.transform);
}

test "The pixel size for a horizontal canvas" {
    // Given
    const c = Camera.init(200, 125, num.pi / 2.0);

    // Then
    try std.testing.expectApproxEqAbs(0.01, c.pixel_size, num.epsilon);
}

test "The pixel size for a vertical canvas" {
    // Given
    const c = Camera.init(125, 200, num.pi / 2.0);

    // Then
    try std.testing.expectApproxEqAbs(0.01, c.pixel_size, num.pi / 2.0);
}

test "Constructing a ray through the center of the canvas" {
    // Given
    const c = Camera.init(201, 101, num.pi / 2.0);

    // When
    const r = c.rayForPixel(100, 50);

    // Then
    try expect.approxEqPoint(Point.zero(), r.origin);
    try expect.approxEqVector(Vector.init(0, 0, -1), r.direction);
}

test "Constructing a ray through a corner of the canvas" {
    // Given
    const c = Camera.init(201, 101, num.pi / 2.0);

    // When
    const r = c.rayForPixel(0, 0);

    // Then
    try expect.approxEqPoint(Point.zero(), r.origin);
    try expect.approxEqVector(Vector.init(0.66519, 0.33259, -0.66851), r.direction);
}

test "Constructing a ray when the camera is transformed" {
    // Given
    var c = Camera.init(201, 101, num.pi / 2.0);

    // When
    c.transform = tsfm.rotationY(num.pi / 4.0).mul(&tsfm.translation(0, -2, 5));
    const r = c.rayForPixel(100, 50);

    // Then
    try expect.approxEqPoint(Point.init(0, 2, -5), r.origin);
    try expect.approxEqVector(Vector.init(num.sqrt2 / 2.0, 0, -num.sqrt2 / 2.0), r.direction);
}

test "Rendering a world with a camera" {
    // Given
    const gpa = std.testing.allocator;
    var w = try World.default(gpa);
    defer w.deinit();

    var c = Camera.init(11, 11, num.pi / 2.0);
    const from = Point.init(0, 0, -5);
    const to = Point.zero();
    const up = Vector.init(0, 1, 0);
    c.transform = tsfm.viewTransform(from, to, up);

    // When
    const image = try c.render(gpa, &w);
    defer image.deinit();

    // Then
    try expect.approxEqColor(Color.init(0.38066, 0.47583, 0.2855), image.pixelAt(5, 5));
}

test "Chapter 7: Putting it together" {
    const Io = std.Io;
    const Material = @import("material.zig").Material;
    const PointLight = @import("light.zig").PointLight;

    const gpa = std.testing.allocator;

    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    var threaded = Io.Threaded.init(gpa, .{});
    defer threaded.deinit();
    const io = threaded.io();

    const file = try tmp.dir.createFile(io, "camera.ppm", .{});
    defer file.close(io);

    const floor = Sphere{
        .transform = tsfm.scaling(10, 0.01, 10),
        .material = Material{
            .color = Color.init(1, 0.9, 0.9),
            .specular = 0,
        },
    };

    const left_wall = Sphere{
        .transform = tsfm.translation(0, 0, 5)
            .mul(&tsfm.rotationY(-num.pi / 4.0)
            .mul(&tsfm.rotationX(num.pi / 2.0))
            .mul(&tsfm.scaling(10, 0.01, 10))),
        .material = floor.material,
    };

    const right_wall = Sphere{
        .transform = tsfm.translation(0, 0, 5)
            .mul(&tsfm.rotationY(num.pi / 4.0))
            .mul(&tsfm.rotationX(num.pi / 2.0))
            .mul(&tsfm.scaling(10, 0.01, 10)),
        .material = floor.material,
    };

    const middle = Sphere{
        .transform = tsfm.translation(-0.5, 1, 0.5),
        .material = Material{
            .color = Color.init(0.1, 1, 0.5),
            .diffuse = 0.7,
            .specular = 0.3,
        },
    };

    const right = Sphere{
        .transform = tsfm.translation(1.5, 0.5, -0.5)
            .mul(&tsfm.scaling(0.5, 0.5, 0.5)),
        .material = Material{
            .color = Color.init(0.5, 1, 0.1),
            .diffuse = 0.7,
            .specular = 0.3,
        },
    };

    const left = Sphere{
        .transform = tsfm.translation(-1.5, 0.33, -0.75)
            .mul(&tsfm.scaling(0.33, 0.33, 0.33)),
        .material = Material{
            .color = Color.init(1, 0.8, 0.1),
            .diffuse = 0.7,
            .specular = 0.3,
        },
    };

    var world = try World.init(gpa);
    defer world.deinit();
    world.light = PointLight.init(Point.init(-10, 10, -10), Color.White());

    try world.objects.append(gpa, floor);
    try world.objects.append(gpa, left_wall);
    try world.objects.append(gpa, right_wall);
    try world.objects.append(gpa, middle);
    try world.objects.append(gpa, right);
    try world.objects.append(gpa, left);

    var camera = Camera.init(10, 5, num.pi / 3.0);
    camera.transform = tsfm.viewTransform(
        Point.init(0, 1.5, -5),
        Point.init(0, 1, 0),
        Vector.init(0, 1, 0),
    );

    var canvas = try camera.render(gpa, &world);
    defer canvas.deinit();
    try canvas.savePpm(io, file);
}
