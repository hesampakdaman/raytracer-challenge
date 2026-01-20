const std = @import("std");

const canvas = @import("canvas.zig");
const color = @import("color.zig");
const tuple = @import("tuple.zig");

const Canvas = canvas.Canvas;
const Color = color.Color;
const Tuple = tuple.Tuple;
const point = tuple.point;
const vector = tuple.vector;

const Projectile = struct {
    position: Tuple,
    velocity: Tuple,
};

const Environment = struct {
    gravity: Tuple,
    wind: Tuple,
};

fn tick(env: Environment, proj: Projectile) Projectile {
    const position = proj.position.add(proj.velocity);
    const velocity = proj.velocity.add(env.gravity.add(env.wind));
    return Projectile{ .position = position, .velocity = velocity };
}

test "Chapter 2: Putting it togheter" {
    var p = Projectile{
        .position = point(0, 1, 0),
        .velocity = vector(1, 1, 0).normalize(),
    };
    const e = Environment{
        .gravity = vector(0, -0.1, 0),
        .wind = vector(-0.01, 0, 0),
    };

    var i: usize = 0;
    while (p.position.y() >= 0) {
        p = tick(e, p);
        i += 1;
    }

    try std.testing.expect(p.position.approxEq(point(10.66082, -0.57919, 0)));
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
        .position = point(0, 1, 0),
        .velocity = vector(1, 1.8, 0).normalize().mul(11.25),
    };
    const e = Environment{
        .gravity = vector(0, -0.1, 0),
        .wind = vector(-0.01, 0, 0),
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
