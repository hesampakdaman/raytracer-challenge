const std = @import("std");

const Tuple = @import("Tuple.zig");
const Vector = @import("Vector.zig");

tuple: Tuple,

const Point = @This();

pub fn init(x_val: f64, y_val: f64, z_val: f64) Point {
    return .{ .tuple = Tuple.init(x_val, y_val, z_val, 1) };
}

fn fromTuple(t: Tuple) Point {
    return Point.init(t.at(0), t.at(1), t.at(2));
}

pub fn zero() Point {
    return Point.init(0, 0, 0);
}

pub fn at(self: Point, i: usize) f64 {
    return self.tuple.at(i);
}

pub fn x(self: Point) f64 {
    return self.tuple.x();
}

pub fn y(self: Point) f64 {
    return self.tuple.y();
}

pub fn z(self: Point) f64 {
    return self.tuple.z();
}

pub fn approxEq(self: Point, other: Point) bool {
    return self.tuple.approxEq(other.tuple);
}

pub fn add(self: Point, vec: Vector) Point {
    return Point.fromTuple(self.tuple.add(vec.tuple));
}

pub fn sub(self: Point, other: anytype) switch (@TypeOf(other)) {
    Point => Vector,
    Vector => Point,
    else => @compileError("Point can only subtract Point or Vector"),
} {
    return switch (@TypeOf(other)) {
        Point => Vector.fromTuple(self.tuple.sub(other.tuple)),
        Vector => Point.fromTuple(self.tuple.sub(other.tuple)),
        else => unreachable,
    };
}

test "point() creates tuples with w=1" {
    // Given
    const p = Point.init(4, -4, 3);

    // Then
    try std.testing.expect(p.approxEq(Point.init(4, -4, 3)));
}

test "Subtracting two points" {
    // Given
    const p1 = Point.init(3, 2, 1);
    const p2 = Point.init(5, 6, 7);

    // Then
    try std.testing.expect(p1.sub(p2).approxEq(Vector.init(-2, -4, -6)));
}
