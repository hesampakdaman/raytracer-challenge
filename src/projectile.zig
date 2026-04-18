const std = @import("std");
const Io = std.Io;

const Canvas = @import("canvas.zig").Canvas;
const Color = @import("Color.zig");
const Point = @import("Point.zig");
const Vector = @import("Vector.zig");

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

    var threaded = Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    const file = try tmp.dir.createFile(io, "projectile_demo.ppm", .{});
    defer file.close(io);

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

    try c.savePpm(io, file);
}
