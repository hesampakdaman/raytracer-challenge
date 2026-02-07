const std = @import("std");

const Canvas = @import("canvas.zig").Canvas;
const Color = @import("color.zig").Color;
const Point = @import("tuple.zig").Point;
const Vector = @import("tuple.zig").Vector;

const Projectile = struct {
    position: Point,
    velocity: Vector,
};

const Environment = struct {
    gravity: Vector,
    wind: Vector,
};

fn tick(env: Environment, proj: Projectile) Projectile {
    const position = proj.position.add(proj.velocity);
    const velocity = proj.velocity.add(env.gravity.add(env.wind));
    return Projectile{ .position = position, .velocity = velocity };
}

test "Chapter 2: Putting it together" {
    var p = Projectile{
        .position = Point.init(0, 1, 0),
        .velocity = Vector.init(1, 1, 0).normalize(),
    };
    const e = Environment{
        .gravity = Vector.init(0, -0.1, 0),
        .wind = Vector.init(-0.01, 0, 0),
    };

    var i: usize = 0;
    while (p.position.y() >= 0) {
        p = tick(e, p);
        i += 1;
    }

    try std.testing.expect(p.position.approxEq(Point.init(10.66082, -0.57919, 0)));
}

test "Chapter 3: Putting it together" {
    const allocator = std.testing.allocator;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    const parent = try tmp.dir.realpathAlloc(allocator, ".");
    defer allocator.free(parent);

    const ppm_file_path = try std.fs.path.join(std.testing.allocator, &[_][]const u8{ parent, "test.ppm" });
    defer allocator.free(ppm_file_path);

    var p = Projectile{
        .position = Point.init(0, 1, 0),
        .velocity = Vector.init(1, 1.8, 0).normalize().mul(11.25),
    };
    const e = Environment{
        .gravity = Vector.init(0, -0.1, 0),
        .wind = Vector.init(-0.01, 0, 0),
    };
    var c = try Canvas.init(std.testing.allocator, 900, 550);
    defer c.deinit();

    while (p.position.y() > 0) {
        const x: usize = @intFromFloat(std.math.round(p.position.x()));
        const y: usize = @intFromFloat(std.math.round(p.position.y()));
        c.writePixel(x, c.height - y, Color.init(1, 0.25, 0.25));
        p = tick(e, p);
    }

    try c.savePpm(ppm_file_path);
}
