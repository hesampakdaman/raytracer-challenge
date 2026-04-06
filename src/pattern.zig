const std = @import("std");
const math = std.math;
const builtin = @import("builtin");

const Color = @import("color.zig").Color;
const expect = @import("expect.zig");
const Mat4 = @import("matrix.zig").Mat4;
const Point = @import("tuple.zig").Point;
const Shape = @import("shape.zig").Shape;
const tsfm = @import("transformation.zig");

pub const Pattern = union(enum) {
    checkers: Checkers,
    gradient: Gradient,
    radial_gradient: RadialGradient,
    ring: Ring,
    solid: Solid,
    stripe: Stripe,
    testPattern: if (builtin.is_test) TestPattern else void,

    pub fn newCheckers(args: struct { a: *const Pattern, b: *const Pattern, transform: Mat4 = Mat4.identity() }) Pattern {
        return .{ .checkers = .{ .a = args.a, .b = args.b, .transform = args.transform } };
    }

    pub fn newGradient(args: struct { a: *const Pattern, b: *const Pattern, transform: Mat4 = Mat4.identity() }) Pattern {
        return .{ .gradient = .{ .a = args.a, .b = args.b, .transform = args.transform } };
    }

    pub fn newRadialGradient(args: struct { a: *const Pattern, b: *const Pattern, transform: Mat4 = Mat4.identity() }) Pattern {
        return .{ .radial_gradient = .{ .a = args.a, .b = args.b, .transform = args.transform } };
    }

    pub fn newRing(args: struct { a: *const Pattern, b: *const Pattern, transform: Mat4 = Mat4.identity() }) Pattern {
        return .{ .ring = .{ .a = args.a, .b = args.b, .transform = args.transform } };
    }

    pub fn newSolid(color: Color) Pattern {
        return .{ .solid = .{ .color = color } };
    }

    pub fn newStripe(args: struct { a: *const Pattern, b: *const Pattern, transform: Mat4 = Mat4.identity() }) Pattern {
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

    fn patternAt(self: *const Pattern, point: Point) Color {
        return switch (self.*) {
            inline else => |*p| p.patternAt(point),
        };
    }
};

const Checkers = struct {
    a: *const Pattern,
    b: *const Pattern,
    transform: Mat4 = Mat4.identity(),

    fn patternAt(self: *const Checkers, p: Point) Color {
        // Like stripes, but alternating in x, y, and z
        const cell = @floor(p.x()) + @floor(p.y()) + @floor(p.z());
        return if (@mod(cell, 2) == 0) self.a.patternAt(p) else self.b.patternAt(p);
    }
};

test "Checkers should repeat in x" {
    // Given
    const white = Pattern.newSolid(Color.white());
    const black = Pattern.newSolid(Color.black());
    const pattern = Checkers{ .a = &white, .b = &black };

    // Then
    try expect.approxEqColor(Color.white(), pattern.patternAt(Point.zero()));
    try expect.approxEqColor(Color.white(), pattern.patternAt(Point.init(0.99, 0, 0)));
    try expect.approxEqColor(Color.black(), pattern.patternAt(Point.init(1.01, 0, 0)));
}

test "Checkers should repeat in y" {
    // Given
    const white = Pattern.newSolid(Color.white());
    const black = Pattern.newSolid(Color.black());
    const pattern = Checkers{ .a = &white, .b = &black };

    // Then
    try expect.approxEqColor(Color.white(), pattern.patternAt(Point.zero()));
    try expect.approxEqColor(Color.white(), pattern.patternAt(Point.init(0, 0.99, 0)));
    try expect.approxEqColor(Color.black(), pattern.patternAt(Point.init(0, 1.01, 0)));
}

test "Checkers should repeat in z" {
    // Given
    const white = Pattern.newSolid(Color.white());
    const black = Pattern.newSolid(Color.black());
    const pattern = Checkers{ .a = &white, .b = &black };

    // Then
    try expect.approxEqColor(Color.white(), pattern.patternAt(Point.zero()));
    try expect.approxEqColor(Color.white(), pattern.patternAt(Point.init(0, 0, 0.99)));
    try expect.approxEqColor(Color.black(), pattern.patternAt(Point.init(0, 0, 1.01)));
}

const Gradient = struct {
    a: *const Pattern,
    b: *const Pattern,
    transform: Mat4 = Mat4.identity(),

    fn patternAt(self: *const Gradient, p: Point) Color {
        // linear combination ca + (cb - ca) * (pₓ - ⌊pₓ⌋)
        const ca, const cb = .{ self.a.patternAt(p), self.b.patternAt(p) };
        const distance = cb.sub(ca);
        const fraction = p.x() - @floor(p.x());
        return ca.add(distance.mul(fraction));
    }
};

test "A gradient linearly interpolates between colors" {
    // Given
    const white = Pattern.newSolid(Color.white());
    const black = Pattern.newSolid(Color.black());
    const pattern = Gradient{ .a = &white, .b = &black };

    // Then
    try expect.approxEqColor(Color.white(), pattern.patternAt(Point.zero()));
    try expect.approxEqColor(Color.init(0.75, 0.75, 0.75), pattern.patternAt(Point.init(0.25, 0, 0)));
    try expect.approxEqColor(Color.init(0.50, 0.50, 0.50), pattern.patternAt(Point.init(0.50, 0, 0)));
    try expect.approxEqColor(Color.init(0.25, 0.25, 0.25), pattern.patternAt(Point.init(0.75, 0, 0)));
}

const Ring = struct {
    a: *const Pattern,
    b: *const Pattern,
    transform: Mat4 = Mat4.identity(),

    fn patternAt(self: *const Ring, p: Point) Color {
        // check where the r := ⌊√(x² + z²)⌋ lie within an
        // alternating band
        const r = math.sqrt(p.x() * p.x() + p.z() * p.z());
        return if (@mod(math.floor(r), 2) == 0) self.a.patternAt(p) else self.b.patternAt(p);
    }
};

test "A ring should extend in both x and z" {
    // Given
    const white = Pattern.newSolid(Color.white());
    const black = Pattern.newSolid(Color.black());
    const pattern = Ring{ .a = &white, .b = &black };

    // Then
    try expect.approxEqColor(Color.white(), pattern.patternAt(Point.zero()));
    try expect.approxEqColor(Color.black(), pattern.patternAt(Point.init(1, 0, 0)));
    try expect.approxEqColor(Color.black(), pattern.patternAt(Point.init(0, 0, 1)));
    try expect.approxEqColor(Color.black(), pattern.patternAt(Point.init(0.708, 0, 0.708)));
}

const RadialGradient = struct {
    a: *const Pattern,
    b: *const Pattern,
    transform: Mat4 = Mat4.identity(),

    fn patternAt(self: *const RadialGradient, p: Point) Color {
        const ca, const cb = .{ self.a.patternAt(p), self.b.patternAt(p) };
        const distance = cb.sub(ca);
        const r = math.sqrt(p.x() * p.x() + p.z() * p.z());
        const fraction = r - @floor(r);
        return ca.add(distance.mul(fraction));
    }
};

test "A radial gradient linearly interpolates in radius" {
    // Given
    const white = Pattern.newSolid(Color.white());
    const black = Pattern.newSolid(Color.black());
    const pattern = RadialGradient{ .a = &white, .b = &black };

    // Then
    try expect.approxEqColor(Color.white(), pattern.patternAt(Point.zero()));
    try expect.approxEqColor(Color.init(0.75, 0.75, 0.75), pattern.patternAt(Point.init(0.25, 0, 0)));
    try expect.approxEqColor(Color.init(0.50, 0.50, 0.50), pattern.patternAt(Point.init(0.50, 0, 0)));
    try expect.approxEqColor(Color.init(0.25, 0.25, 0.25), pattern.patternAt(Point.init(0.75, 0, 0)));
}

const Solid = struct {
    color: Color,
    transform: Mat4 = Mat4.identity(),

    fn patternAt(self: *const Solid, _: Point) Color {
        return self.color;
    }
};

const Stripe = struct {
    a: *const Pattern,
    b: *const Pattern,
    transform: Mat4 = Mat4.identity(),

    fn patternAt(self: *const Stripe, point: Point) Color {
        const x = @floor(point.x());
        return if (@mod(x, 2) == 0) self.a.patternAt(point) else self.b.patternAt(point);
    }
};

test "Creating a stripe pattern" {
    // Given
    const white = Pattern.newSolid(Color.white());
    const black = Pattern.newSolid(Color.black());
    const pattern = Stripe{ .a = &white, .b = &black };

    // Then
    try expect.approxEqColor(Color.white(), pattern.a.patternAt(Point.zero()));
    try expect.approxEqColor(Color.black(), pattern.b.patternAt(Point.zero()));
}

test "A stripe pattern is constant in y" {
    // Given
    const white = Pattern.newSolid(Color.white());
    const black = Pattern.newSolid(Color.black());
    const pattern = Stripe{ .a = &white, .b = &black };

    // Then
    try expect.approxEqColor(Color.white(), pattern.patternAt(Point.zero()));
    try expect.approxEqColor(Color.white(), pattern.patternAt(Point.init(0, 1, 0)));
    try expect.approxEqColor(Color.white(), pattern.patternAt(Point.init(0, 2, 0)));
}

test "A stripe pattern is constant in z" {
    // Given
    const white = Pattern.newSolid(Color.white());
    const black = Pattern.newSolid(Color.black());
    const pattern = Stripe{ .a = &white, .b = &black };

    // Then
    try expect.approxEqColor(Color.white(), pattern.patternAt(Point.zero()));
    try expect.approxEqColor(Color.white(), pattern.patternAt(Point.init(0, 0, 1)));
    try expect.approxEqColor(Color.white(), pattern.patternAt(Point.init(0, 0, 2)));
}

test "A stripe pattern is alternates in x" {
    // Given
    const white = Pattern.newSolid(Color.white());
    const black = Pattern.newSolid(Color.black());
    const pattern = Stripe{ .a = &white, .b = &black };

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
