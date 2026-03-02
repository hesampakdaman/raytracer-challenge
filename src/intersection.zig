const std = @import("std");
const assert = std.debug.assert;

const expect = @import("expect.zig");
const num = @import("num.zig");
const Point = @import("tuple.zig").Point;
const Ray = @import("ray.zig").Ray;
const Sphere = @import("sphere.zig").Sphere;
const Vector = @import("tuple.zig").Vector;

pub const Computations = struct {
    t: f64,
    object: *const Sphere,
    point: Point,
    eyev: Vector,
    normalv: Vector,
};

pub const Intersection = struct {
    t: f64,
    object: *const Sphere,

    pub fn init(t: f64, object: *const Sphere) Intersection {
        return .{ .t = t, .object = object };
    }

    pub fn prepareComputations(self: Intersection, r: Ray) Computations {
        const world_point = r.position(self.t);
        return Computations{
            .t = self.t,
            .object = self.object,
            .point = world_point,
            .eyev = r.direction.negate(),
            .normalv = self.object.normalAt(world_point),
        };
    }

    fn lessThan(context: void, a: Intersection, b: Intersection) bool {
        _ = context;
        return a.t < b.t;
    }
};

pub const Intersections = struct {
    items: [32]Intersection,
    count: usize,

    pub fn init(xs: anytype) Intersections {
        comptime {
            const info = @typeInfo(@TypeOf(xs));
            if (info != .@"struct") @compileError("init expects a tuple");

            const fields = info.@"struct".fields.len;
            if (fields > 32) @compileError("too many intersections, max is 32");
        }

        var out = Intersections{ .items = undefined, .count = 0 };
        inline for (xs) |x| {
            out.items[out.count] = x;
            out.count += 1;
        }

        std.sort.insertion(Intersection, out.items[0..out.count], {}, Intersection.lessThan);
        return out;
    }

    pub fn fromSlice(xs: []Intersection) Intersections {
        assert(xs.len <= 32);

        var out = Intersections{ .items = undefined, .count = 0 };
        for (xs) |x| {
            out.items[out.count] = x;
            out.count += 1;
        }

        std.sort.insertion(Intersection, out.items[0..out.count], {}, Intersection.lessThan);
        return out;
    }

    pub fn hit(self: Intersections) ?Intersection {
        for (self.items) |i| {
            if (i.t >= 0) return i;
        }
        return null;
    }

    fn lessThan(_: void, a: Intersection, b: Intersection) bool {
        return a.t < b.t;
    }
};

test "An intersection encapsulates t and object" {
    // Given
    const s = Sphere{};

    // When
    const i = Intersection{ .t = 3.5, .object = &s };

    // Then
    try std.testing.expectApproxEqAbs(3.5, i.t, num.epsilon);
    try std.testing.expectEqual(&s, i.object);
}

test "Aggregating intersections" {
    // Given
    const s = Sphere{};
    const i_1 = Intersection{ .t = 1, .object = &s };
    const i_2 = Intersection{ .t = 2, .object = &s };

    // When
    const xs = Intersections.init(.{ i_1, i_2 });

    // Then
    try std.testing.expectEqual(2, xs.count);
    try std.testing.expectApproxEqAbs(1, xs.items[0].t, num.epsilon);
    try std.testing.expectApproxEqAbs(2, xs.items[1].t, num.epsilon);
}

test "The hit, when all intersections have positive t" {
    // Given
    const s = &Sphere{};
    const i_1 = Intersection{ .t = 1, .object = s };
    const i_2 = Intersection{ .t = 2, .object = s };
    const xs = Intersections.init(.{ i_2, i_1 });

    // When
    const i = xs.hit().?;

    // Then
    try std.testing.expectEqual(i_1, i);
}

test "The hit, when some intersections have negative t" {
    // Given
    const s = &Sphere{};
    const i_1 = Intersection{ .t = -1, .object = s };
    const i_2 = Intersection{ .t = 1, .object = s };
    const xs = Intersections.init(.{ i_2, i_1 });

    // When
    const i = xs.hit().?;

    // Then
    try std.testing.expectEqual(i_2, i);
}

test "The hit, when all intersections have negative t" {
    // Given
    const s = &Sphere{};
    const i_1 = Intersection{ .t = -2, .object = s };
    const i_2 = Intersection{ .t = -1, .object = s };
    const xs = Intersections.init(.{ i_2, i_1 });

    // When
    const i = xs.hit();

    // Then
    try std.testing.expectEqual(null, i);
}

test "The hit is always the lowest non-negative intersection" {
    // Given
    const s = &Sphere{};
    const i_1 = Intersection{ .t = 5, .object = s };
    const i_2 = Intersection{ .t = 7, .object = s };
    const i_3 = Intersection{ .t = -3, .object = s };
    const i_4 = Intersection{ .t = 2, .object = s };
    const xs = Intersections.init(.{ i_1, i_2, i_3, i_4 });

    // When
    const i = xs.hit().?;

    // Then
    try std.testing.expectEqual(i_4, i);
}

test "Precomputing the state of an intersection" {
    // Given
    const r = Ray.init(Point.init(0, 0, -5), Vector.init(0, 0, 1));
    const shape = Sphere{};
    const i = Intersection.init(4, &shape);

    // When
    const comps = i.prepareComputations(r);

    // Then
    try std.testing.expectEqual(i.object, comps.object);
    try expect.approxEqPoint(Point.init(0, 0, -1), comps.point);
    try expect.approxEqVector(Vector.init(0, 0, -1), comps.eyev);
    try expect.approxEqVector(Vector.init(0, 0, -1), comps.normalv);
}
