const std = @import("std");
const math = std.math;

const expect = @import("expect.zig");
const num = @import("num.zig");
const Mat4 = @import("matrix.zig").Mat4;

const Camera = struct {
    hsize: usize,
    vsize: usize,
    field_of_view: f64,
    transform: Mat4,
    half_width: f64,
    half_height: f64,
    pixel_size: f64,

    pub fn init(hsize: usize, vsize: usize, fov: f64) Camera {
        const half_view = math.tan(fov / 2.0);
        const aspect =
            @as(f64, @floatFromInt(hsize)) /
            @as(f64, @floatFromInt(vsize));

        const half_width, const half_height = if (aspect >= 1)
            .{ half_view, half_view / aspect }
        else
            .{ half_view * aspect, half_view };

        const pixel_size =
            (half_width * 2.0) /
            @as(f64, @floatFromInt(hsize));

        return .{
            .hsize = hsize,
            .vsize = vsize,
            .field_of_view = fov,
            .transform = Mat4.identity(),
            .half_width = half_width,
            .half_height = half_height,
            .pixel_size = pixel_size,
        };
    }
};

test "Constructing a camera" {
    // Given
    const hsize: usize = 160;
    const vsize: usize = 120;
    const field_of_view = num.pi / 2.0;

    // When
    const c = Camera.init(hsize, vsize, field_of_view);

    // Then
    try std.testing.expectEqual(160, c.hsize);
    try std.testing.expectEqual(120, c.vsize);
    try std.testing.expectApproxEqAbs(num.pi / 2.0, c.field_of_view, num.epsilon);
    try expect.approxEqMatrix(4, &Mat4.identity(), &c.transform);
}

test "The pixel size for a horizontal canvas" {
    // Given
    const c = Camera.init(200, 125, num.pi / 2.0);

    // Then
    try std.testing.expectApproxEqAbs(0.01, c.pixel_size, num.epsilon);
}

test "The pixel size for a vertical canvas" {
    // Given
    const c = Camera.init(125, 200, num.pi / 2.0);

    // Then
    try std.testing.expectApproxEqAbs(0.01, c.pixel_size, num.pi / 2.0);
}
