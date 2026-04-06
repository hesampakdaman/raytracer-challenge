const std = @import("std");
const builtin = @import("builtin");
const math = std.math;

const Color = @import("color.zig").Color;
const expect = @import("expect.zig");
const Mat4 = @import("matrix.zig").Mat4;
const Point = @import("tuple.zig").Point;
const Shape = @import("shape.zig").Shape;
const tsfm = @import("transformation.zig");

pub const Pattern = union(enum) {
    checkers: Checkers,
    gradient: Gradient,
    ring: Ring,
    stripe: Stripe,
    testPattern: if (builtin.is_test) TestPattern else void,

    pub fn newCheckers(args: struct { a: Color, b: Color, transform: Mat4 = Mat4.identity() }) Pattern {
        return .{ .checkers = .{ .a = args.a, .b = args.b, .transform = args.transform } };
    }

    pub fn newGradient(args: struct { a: Color, b: Color, transform: Mat4 = Mat4.identity() }) Pattern {
        return .{ .gradient = .{ .a = args.a, .b = args.b, .transform = args.transform } };
    }

    pub fn newRing(args: struct { a: Color, b: Color, transform: Mat4 = Mat4.identity() }) Pattern {
        return .{ .ring = .{ .a = args.a, .b = args.b, .transform = args.transform } };
    }

    pub fn newStripe(args: struct { a: Color, b: Color, transform: Mat4 = Mat4.identity() }) Pattern {
        return .{ .stripe = .{ .a = args.a, .b = args.b, .transform = args.transform } };
    }

    pub fn patternAtShape(self: *const Pattern, shape: *const Shape, world_point: Point) Color {
        const object_point = shape.transform().inverse().apply(world_point);
        const pattern_point = self.transform().inverse().apply(object_point);
        return switch (self.*) {
            inline else => |*p| p.patternAt(pattern_point),
        };
    }

    pub fn transform(self: *const Pattern) *const Mat4 {
        return switch (self.*) {
            inline else => |*p| &p.transform,
        };
    }

    pub fn setTransform(self: *Pattern, t: Mat4) void {
        return switch (self.*) {
            inline else => |*p| p.transform = t,
        };
    }
};

const Checkers = struct {
    a: Color,
    b: Color,
    transform: Mat4 = Mat4.identity(),

    fn patternAt(self: *const Checkers, p: Point) Color {
        // Like stripes, but alternating in x, y, and z
        const cell = @floor(p.x()) + @floor(p.y()) + @floor(p.z());
        return if (@mod(cell, 2) == 0) self.a else self.b;
    }
};

test "Checkers should repeat in x" {
    // Given
    const pattern = Checkers{ .a = Color.white(), .b = Color.black() };

    // Then
    try expect.approxEqColor(Color.white(), pattern.patternAt(Point.zero()));
    try expect.approxEqColor(Color.white(), pattern.patternAt(Point.init(0.99, 0, 0)));
    try expect.approxEqColor(Color.black(), pattern.patternAt(Point.init(1.01, 0, 0)));
}

test "Checkers should repeat in y" {
    // Given
    const pattern = Checkers{ .a = Color.white(), .b = Color.black() };

    // Then
    try expect.approxEqColor(Color.white(), pattern.patternAt(Point.zero()));
    try expect.approxEqColor(Color.white(), pattern.patternAt(Point.init(0, 0.99, 0)));
    try expect.approxEqColor(Color.black(), pattern.patternAt(Point.init(0, 1.01, 0)));
}

test "Checkers should repeat in z" {
    // Given
    const pattern = Checkers{ .a = Color.white(), .b = Color.black() };

    // Then
    try expect.approxEqColor(Color.white(), pattern.patternAt(Point.zero()));
    try expect.approxEqColor(Color.white(), pattern.patternAt(Point.init(0, 0, 0.99)));
    try expect.approxEqColor(Color.black(), pattern.patternAt(Point.init(0, 0, 1.01)));
}

const Gradient = struct {
    a: Color,
    b: Color,
    transform: Mat4 = Mat4.identity(),

    fn patternAt(self: *const Gradient, point: Point) Color {
        // linear combination a + (b - a) * (pₓ - ⌊pₓ⌋)
        const distance = self.b.sub(self.a);
        const fraction = point.x() - @floor(point.x());
        return self.a.add(distance.mul(fraction));
    }
};

test "A gradient linearly interpolates between colors" {
    // Given
    const pattern = Gradient{ .a = Color.white(), .b = Color.black() };

    // Then
    try expect.approxEqColor(Color.white(), pattern.patternAt(Point.zero()));
    try expect.approxEqColor(Color.init(0.75, 0.75, 0.75), pattern.patternAt(Point.init(0.25, 0, 0)));
    try expect.approxEqColor(Color.init(0.50, 0.50, 0.50), pattern.patternAt(Point.init(0.50, 0, 0)));
    try expect.approxEqColor(Color.init(0.25, 0.25, 0.25), pattern.patternAt(Point.init(0.75, 0, 0)));
}

const Ring = struct {
    a: Color,
    b: Color,
    transform: Mat4 = Mat4.identity(),

    fn patternAt(self: *const Ring, point: Point) Color {
        // check where the r := ⌊√(x² + z²)⌋ lie within an
        // alternating band
        const r = math.sqrt(point.x() * point.x() + point.z() * point.z());
        return if (@mod(math.floor(r), 2) == 0) self.a else self.b;
    }
};

test "A ring should extend in both x and z" {
    // Given
    const pattern = Ring{ .a = Color.white(), .b = Color.black() };

    // Then
    try expect.approxEqColor(Color.white(), pattern.patternAt(Point.zero()));
    try expect.approxEqColor(Color.black(), pattern.patternAt(Point.init(1, 0, 0)));
    try expect.approxEqColor(Color.black(), pattern.patternAt(Point.init(0, 0, 1)));
    try expect.approxEqColor(Color.black(), pattern.patternAt(Point.init(0.708, 0, 0.708)));
}

const Stripe = struct {
    a: Color,
    b: Color,
    transform: Mat4 = Mat4.identity(),

    fn patternAt(self: *const Stripe, point: Point) Color {
        const x = @floor(point.x());
        return if (@mod(x, 2) == 0) self.a else self.b;
    }
};

test "Creating a stripe pattern" {
    // Given
    const pattern = Stripe{ .a = Color.white(), .b = Color.black() };

    // Then
    try expect.approxEqColor(Color.white(), pattern.a);
    try expect.approxEqColor(Color.black(), pattern.b);
}

test "A stripe pattern is constant in y" {
    // Given
    const pattern = Stripe{ .a = Color.white(), .b = Color.black() };

    // Then
    try expect.approxEqColor(Color.white(), pattern.patternAt(Point.zero()));
    try expect.approxEqColor(Color.white(), pattern.patternAt(Point.init(0, 1, 0)));
    try expect.approxEqColor(Color.white(), pattern.patternAt(Point.init(0, 2, 0)));
}

test "A stripe pattern is constant in z" {
    // Given
    const pattern = Stripe{ .a = Color.white(), .b = Color.black() };

    // Then
    try expect.approxEqColor(Color.white(), pattern.patternAt(Point.zero()));
    try expect.approxEqColor(Color.white(), pattern.patternAt(Point.init(0, 0, 1)));
    try expect.approxEqColor(Color.white(), pattern.patternAt(Point.init(0, 0, 2)));
}

test "A stripe pattern is alternates in x" {
    // Given
    const pattern = Stripe{ .a = Color.white(), .b = Color.black() };

    // Then
    try expect.approxEqColor(Color.white(), pattern.patternAt(Point.zero()));
    try expect.approxEqColor(Color.white(), pattern.patternAt(Point.init(0.9, 0, 0)));
    try expect.approxEqColor(Color.black(), pattern.patternAt(Point.init(1, 0, 0)));
    try expect.approxEqColor(Color.black(), pattern.patternAt(Point.init(-0.1, 0, 0)));
    try expect.approxEqColor(Color.black(), pattern.patternAt(Point.init(-1, 0, 0)));
    try expect.approxEqColor(Color.white(), pattern.patternAt(Point.init(-1.1, 0, 0)));
}

const TestPattern = if (builtin.is_test) struct {
    transform: Mat4 = Mat4.identity(),

    fn patternAt(_: *const TestPattern, point: Point) Color {
        return Color.init(point.x(), point.y(), point.z());
    }
} else struct {};

fn testPattern() Pattern {
    if (!builtin.is_test) @compileError("testPattern is test-only");
    return .{ .testPattern = .{} };
}

test "The default pattern transformation" {
    // Given
    var pattern = testPattern();

    // Then
    try expect.approxEqMatrix(4, &Mat4.identity(), pattern.transform());
}

test "Assigning a transformation" {
    // Given
    var pattern = testPattern();

    // When
    pattern.setTransform(tsfm.translation(1, 2, 3));

    // Then
    try expect.approxEqMatrix(4, &tsfm.translation(1, 2, 3), pattern.transform());
}

test "A pattern with an object transformation" {
    // Given
    const shape = Shape.newSphere(.{ .transform = tsfm.scaling(2, 2, 2) });
    var pattern = testPattern();

    // When
    const c = pattern.patternAtShape(&shape, Point.init(2, 3, 4));

    // Then
    try expect.approxEqColor(Color.init(1, 1.5, 2), c);
}

test "A pattern with a pattern transformation" {
    // Given
    const shape = Shape.newSphere(.{});
    var pattern = testPattern();
    pattern.setTransform(tsfm.scaling(2, 2, 2));

    // When
    const c = pattern.patternAtShape(&shape, Point.init(2, 3, 4));

    // Then
    try expect.approxEqColor(Color.init(1, 1.5, 2), c);
}

test "A pattern with both an object and a pattern transformation" {
    // Given
    const shape = Shape.newSphere(.{ .transform = tsfm.scaling(2, 2, 2) });
    var pattern = testPattern();
    pattern.setTransform(tsfm.translation(0.5, 1, 1.5));

    // When
    const c = pattern.patternAtShape(&shape, Point.init(2.5, 3, 3.5));

    // Then
    try expect.approxEqColor(Color.init(0.75, 0.5, 0.25), c);
}
