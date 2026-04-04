const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

const Color = @import("color.zig").Color;
const expect = @import("expect.zig");
const inter = @import("intersection.zig");
const Intersection = inter.Intersection;
const Intersections = inter.Intersections;
const Computations = inter.Computations;
const Material = @import("material.zig").Material;
const num = @import("num.zig");
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
        const light = PointLight.init(
            Point.init(-10, 10, -10),
            Color.init(1, 1, 1),
        );

        var objects = try std.ArrayList(Sphere).initCapacity(gpa, 10);
        try objects.append(gpa, Sphere{ .material = .{
            .color = Color.init(0.8, 1.0, 0.6),
            .diffuse = 0.7,
            .specular = 0.2,
        } });
        try objects.append(gpa, Sphere{ .transform = tsfm.scaling(0.5, 0.5, 0.5) });

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

    pub fn intersectWorld(self: *const World, r: *const Ray) Intersections {
        var out: [32]Intersection = undefined;
        var n_objs: usize = 0;
        for (self.objects.items) |*obj| {
            const xs = obj.intersect(r.*);
            for (0..xs.count) |i| {
                out[n_objs] = xs.items[i];
                n_objs += 1;
            }
        }

        return Intersections.fromSlice(out[0..n_objs]);
    }

    pub fn shadeHit(self: *const World, comps: *const Computations) Color {
        assert(self.light != null);
        const shadowed = self.isShadowed(comps.over_point);
        return comps.object.material.lighting(
            self.light.?,
            comps.point,
            comps.eyev,
            comps.normalv,
            shadowed,
        );
    }

    pub fn colorAt(self: *const World, r: *const Ray) Color {
        const xs = self.intersectWorld(r);
        if (xs.hit()) |x| {
            const comps = x.prepareComputations(r.*);
            return self.shadeHit(&comps);
        }
        return Color.Black();
    }

    pub fn isShadowed(self: *const World, point: Point) bool {
        assert(self.light != null);
        const v = self.light.?.position.sub(point);
        const distance = v.magnitude();
        const direction = v.normalize();

        const r = Ray.init(point, direction);
        const intersections = self.intersectWorld(&r);

        if (intersections.hit()) |h| {
            return h.t < distance;
        }
        return false;
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
    const xs = w.intersectWorld(&r);

    // Then
    try std.testing.expectEqual(4, xs.count);
    try std.testing.expectApproxEqAbs(4.0, xs.items[0].t, num.epsilon);
    try std.testing.expectApproxEqAbs(4.5, xs.items[1].t, num.epsilon);
    try std.testing.expectApproxEqAbs(5.5, xs.items[2].t, num.epsilon);
    try std.testing.expectApproxEqAbs(6.0, xs.items[3].t, num.epsilon);
}

test "Shading an intersection" {
    // Given
    var w = try World.default(std.testing.allocator);
    defer w.deinit();
    const r = Ray.init(Point.init(0, 0, -5), Vector.init(0, 0, 1));
    const shape = &w.objects.items[0];
    const i = Intersection.init(4, shape);

    // When
    const comps = i.prepareComputations(r);
    const c = w.shadeHit(&comps);

    // Then
    try expect.approxEqColor(Color.init(0.38066, 0.47583, 0.2855), c);
}

test "Shading an intersection from the inside" {
    // Given
    var w = try World.default(std.testing.allocator);
    defer w.deinit();
    w.light = PointLight.init(Point.init(0, 0.25, 0), Color.White());
    const r = Ray.init(Point.zero(), Vector.init(0, 0, 1));
    const shape = &w.objects.items[1];
    const i = Intersection.init(0.5, shape);

    // When
    const comps = i.prepareComputations(r);
    const c = w.shadeHit(&comps);

    // Then
    try expect.approxEqColor(Color.init(0.90498, 0.90498, 0.90498), c);
}

test "The color when a ray misses" {
    // Given
    var w = try World.default(std.testing.allocator);
    defer w.deinit();
    const r = Ray.init(Point.init(0, 0, -5), Vector.init(0, 1, 0));

    // When
    const c = w.colorAt(&r);

    // Then
    try expect.approxEqColor(Color.Black(), c);
}

test "The color when a ray hits" {
    // Given
    var w = try World.default(std.testing.allocator);
    defer w.deinit();
    const r = Ray.init(Point.init(0, 0, -5), Vector.init(0, 0, 1));

    // When
    const c = w.colorAt(&r);

    // Then
    try expect.approxEqColor(Color.init(0.38066, 0.47583, 0.2855), c);
}

test "The color with an intersection behind the ray" {
    // Given
    var w = try World.default(std.testing.allocator);
    defer w.deinit();
    var outer = &w.objects.items[0];
    outer.material.ambient = 1;
    var inner = &w.objects.items[1];
    inner.material.ambient = 1;
    const r = Ray.init(Point.init(0, 0, 0.75), Vector.init(0, 0, -1));

    // When
    const c = w.colorAt(&r);

    // Then
    try expect.approxEqColor(inner.material.color, c);
}

test "There is no shadow when nothing is collinear with point and light" {
    // Given
    const gpa = std.testing.allocator;
    var w = try World.default(gpa);
    defer w.deinit();
    const p = Point.init(0, 10, 0);

    // Then
    try std.testing.expectEqual(false, w.isShadowed(p));
}

test "The shadow when an object is between the point and the light" {
    // Given
    const gpa = std.testing.allocator;
    var w = try World.default(gpa);
    defer w.deinit();
    const p = Point.init(10, -10, 10);

    // Then
    try std.testing.expectEqual(true, w.isShadowed(p));
}

test "There is no shadow when an object is behind light" {
    // Given
    const gpa = std.testing.allocator;
    var w = try World.default(gpa);
    defer w.deinit();

    // When
    const p = Point.init(-20, 20, -20);

    // Then
    try std.testing.expectEqual(false, w.isShadowed(p));
}

test "There is no shadow when an object is behind the point" {
    // Given
    const gpa = std.testing.allocator;
    var w = try World.default(gpa);
    defer w.deinit();

    // When
    const p = Point.init(-2, 2, -2);

    // Then
    try std.testing.expectEqual(false, w.isShadowed(p));
}

test "shadeHit() is given an intersection in shadow" {
    // Given
    const gpa = std.testing.allocator;
    var w = try World.default(gpa);
    defer w.deinit();

    w.light = PointLight.init(Point.init(0, 0, -10), Color.White());

    const s1 = Sphere.default();
    const s2 = Sphere{ .transform = tsfm.translation(0, 0, 10) };
    try w.objects.append(gpa, s1);
    try w.objects.append(gpa, s2);

    const r = Ray.init(Point.init(0, 0, 5), Vector.init(0, 0, 1));
    const i = Intersection.init(4, &s2);

    // When
    const comps = i.prepareComputations(r);
    const c = w.shadeHit(&comps);

    // Then
    try expect.approxEqColor(Color.init(0.1, 0.1, 0.1), c);
}
