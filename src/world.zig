const std = @import("std");
const Allocator = std.mem.Allocator;

const num = @import("num.zig");
const Color = @import("color.zig").Color;
const Intersection = @import("intersection.zig").Intersection;
const Intersections = @import("intersection.zig").Intersections;
const Material = @import("material.zig").Material;
const Point = @import("tuple.zig").Point;
const PointLight = @import("light.zig").PointLight;
const Ray = @import("ray.zig").Ray;
const Sphere = @import("sphere.zig").Sphere;
const tsfm = @import("transformation.zig");
const Vector = @import("tuple.zig").Vector;

pub const World = struct {
    gpa: Allocator,
    light: ?PointLight,
    objects: std.ArrayList(Sphere),

    pub fn init(gpa: Allocator) !World {
        return World{
            .gpa = gpa,
            .light = null,
            .objects = try std.ArrayList(Sphere).initCapacity(gpa, 10),
        };
    }

    pub fn deinit(self: *World) void {
        self.objects.deinit(self.gpa);
    }

    pub fn default(gpa: Allocator) !World {
        const light = PointLight.init(Point.init(-10, 10, -10), Color.init(1, 1, 1));

        var objects = try std.ArrayList(Sphere).initCapacity(gpa, 10);
        try objects.append(gpa, Sphere{ .transform = tsfm.scaling(0.5, 0.5, 0.5) });
        try objects.append(gpa, Sphere{ .material = .{
            .color = Color.init(0.8, 1.0, 0.6),
            .diffuse = 0.7,
            .specular = 0.2,
        } });

        return World{
            .gpa = gpa,
            .light = light,
            .objects = objects,
        };
    }

    pub fn contains(self: *const World, target: *const Sphere) bool {
        for (self.objects.items) |s| {
            if (s.approxEq(target)) return true;
        }
        return false;
    }

    pub fn intersectWorld(self: *const World, r: Ray) Intersections {
        var out: [32]Intersection = undefined;
        var n_objs: usize = 0;
        for (self.objects.items) |obj| {
            const xs = obj.intersect(r);
            for (0..xs.count) |i| {
                out[n_objs] = xs.items[i];
                n_objs += 1;
            }
        }

        return Intersections.fromSlice(out[0..n_objs]);
    }
};

test "Creating a world" {
    // Given
    var w = try World.init(std.testing.allocator);
    defer w.deinit();

    // Then
    try std.testing.expectEqual(null, w.light);
    try std.testing.expectEqual(0, w.objects.items.len);
}

test "The default world" {
    // Given
    const light = PointLight.init(Point.init(-10, 10, -10), Color.init(1, 1, 1));
    const s1 = Sphere{
        .material = Material{
            .color = Color.init(0.8, 1.0, 0.6),
            .diffuse = 0.7,
            .specular = 0.2,
        },
    };
    const s2 = Sphere{ .transform = tsfm.scaling(0.5, 0.5, 0.5) };

    // When
    var w = try World.default(std.testing.allocator);
    defer w.deinit();

    // Then
    try std.testing.expectEqual(light, w.light);
    try std.testing.expect(w.contains(&s1));
    try std.testing.expect(w.contains(&s2));
}

test "Intersect a world with a ray" {
    // Given
    var w = try World.default(std.testing.allocator);
    defer w.deinit();
    const r = Ray.init(Point.init(0, 0, -5), Vector.init(0, 0, 1));

    // When
    const xs = w.intersectWorld(r);

    // Then
    try std.testing.expectEqual(4, xs.count);
    try std.testing.expectApproxEqAbs(4.0, xs.items[0].t, num.epsilon);
    try std.testing.expectApproxEqAbs(4.5, xs.items[1].t, num.epsilon);
    try std.testing.expectApproxEqAbs(5.5, xs.items[2].t, num.epsilon);
    try std.testing.expectApproxEqAbs(6.0, xs.items[3].t, num.epsilon);
}
