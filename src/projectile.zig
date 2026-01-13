const std = @import("std");

const tuple = @import("tuple.zig");
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

test "projectile playground" {
    var p = Projectile{
        .position = point(0, 1, 0),
        .velocity = vector(1, 1, 0).normalize(),
    };
    const e = Environment{
        .gravity = vector(0, -0.1, 0),
        .wind = vector(-0.01, 0, 0),
    };

    var i: usize = 0;
    while (p.position.y >= 0) {
        p = tick(e, p);
        std.debug.print("tick({d}): projectile at position({d:.2}, {d:.2}, {d:.2})\n", .{ i, p.position.x, p.position.y, p.position.z });
        i += 1;
    }
}
