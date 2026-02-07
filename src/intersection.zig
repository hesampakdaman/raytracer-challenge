const std = @import("std");

const EPSILON = @import("core.zig").EPSILON;
const Sphere = @import("sphere.zig").Sphere;

pub const Intersection = struct {
    t: f64,
    object: *const Sphere,

    pub fn init(t: f64, object: *const Sphere) Intersection {
        return .{ .t = t, .object = object };
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
    try std.testing.expectApproxEqAbs(3.5, i.t, EPSILON);
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
    try std.testing.expectApproxEqAbs(1, xs.items[0].t, EPSILON);
    try std.testing.expectApproxEqAbs(2, xs.items[1].t, EPSILON);
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
