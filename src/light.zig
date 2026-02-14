const std = @import("std");

const expect = @import("expect.zig");
const num = @import("num.zig");
const tup = @import("tuple.zig");

const Color = @import("color.zig").Color;
const Point = tup.Point;

pub const PointLight = struct {
    intensity: Color,
    position: Point,

    pub fn init(p: Point, i: Color) PointLight {
        return .{ .position = p, .intensity = i };
    }
};

test "A point light has a position and intensity" {
    // Given
    const intensity = Color.init(1, 1, 1);
    const position = Point.zero();

    // When
    const light = PointLight.init(position, intensity);

    // Then
    try expect.approxEqPoint(position, light.position);
    try expect.approxEqTuple(intensity.t, light.intensity.t);
}
