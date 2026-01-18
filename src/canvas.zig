const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;

const color = @import("color.zig");
const Color = color.Color;

const Canvas = struct {
    allocator: Allocator,
    width: usize,
    height: usize,
    pixels: []Color,
    max_color_value: usize,
    max_ppm_width: usize,

    pub fn init(allocator: Allocator, w: usize, h: usize) !Canvas {
        const pixels = try allocator.alloc(Color, w * h);
        @memset(pixels, Color.init(0, 0, 0));
        return Canvas{
            .allocator = allocator,
            .width = w,
            .height = h,
            .pixels = pixels,
            .max_color_value = 255,
            .max_ppm_width = 70,
        };
    }

    pub fn deinit(self: Canvas) void {
        self.allocator.free(self.pixels);
    }

    pub fn writePixel(self: *Canvas, x: usize, y: usize, c: Color) void {
        assert(x < self.width);
        assert(y < self.height);
        self.pixels[y * self.width + x] = c;
    }

    pub fn pixelAt(self: Canvas, x: usize, y: usize) Color {
        assert(x < self.width);
        assert(y < self.height);
        return self.pixels[y * self.width + x];
    }

    pub fn ppm(self: Canvas, allocator: Allocator) ![]const u8 {
        const num_colors: usize = 3;
        const num_headers: usize = 3;
        var list = try std.ArrayList(u8).initCapacity(
            allocator,
            (num_colors + 1) * self.pixels.len + num_headers,
        );
        errdefer list.deinit(allocator);

        // header
        try list.print(
            allocator,
            "P3\n{d} {d}\n{d}\n",
            .{ self.width, self.height, self.max_color_value },
        );

        // data
        for (0..self.height) |y| {
            var line_len: usize = 0;
            for (0..self.width) |x| {
                const pixel = self.pixelAt(x, y);
                for ([_]f64{ pixel.red(), pixel.green(), pixel.blue() }) |ch| {
                    const ch_digit = self.normalizeColor(ch);
                    const num_digits: usize = if (ch_digit >= 100) 3 else if (ch_digit >= 10) 2 else 1;
                    if (self.needsWrap(line_len, num_digits)) {
                        try list.print(allocator, "\n", .{});
                        line_len = 0;
                    } else if (line_len > 0) {
                        try list.print(allocator, " ", .{});
                        line_len += 1;
                    }

                    try list.print(allocator, "{d}", .{ch_digit});
                    line_len += num_digits;
                }
            }
            try list.print(allocator, "\n", .{});
        }
        return list.toOwnedSlice(allocator);
    }

    pub fn savePpm(self: Canvas, allocator: Allocator, path: []const u8) !void {
        const data = try self.ppm(allocator);
        defer allocator.free(data);

        try std.fs.cwd().writeFile(.{
            .sub_path = path,
            .data = data,
        });
    }

    fn normalizeColor(self: Canvas, val: f64) usize {
        const upper: f64 = @floatFromInt(self.max_color_value);
        const scaled = std.math.round(val * upper);
        return @intFromFloat(std.math.clamp(scaled, 0, upper));
    }

    fn needsWrap(self: Canvas, line_len: usize, num_digits: usize) bool {
        const sep: usize = if (line_len > 0) 1 else 0;
        return line_len + sep + num_digits > self.max_ppm_width;
    }
};

test "Creating a canvas" {
    // Given
    var c = try Canvas.init(std.testing.allocator, 10, 20);
    defer c.deinit();
    const red = Color.init(1, 0, 0);

    // When
    c.writePixel(2, 3, red);

    // Then
    try std.testing.expect(c.pixelAt(2, 3).approxEq(red));
}

test "Constructing the PPM header" {
    // Given
    const allocator = std.testing.allocator;
    var c = try Canvas.init(allocator, 5, 3);
    defer c.deinit();

    // When
    const ppm = try c.ppm(allocator);
    defer allocator.free(ppm);

    // Then
    try std.testing.expectEqualStrings(
        \\P3
        \\5 3
        \\255
    , TestHelper.getLines(ppm, 1, 3));
}

test "Constructing the PPM pixel data" {
    // Given
    const allocator = std.testing.allocator;
    var c = try Canvas.init(allocator, 5, 3);
    defer c.deinit();
    const c1 = Color.init(1.5, 0, 0);
    const c2 = Color.init(0, 0.5, 0);
    const c3 = Color.init(-0.5, 0, 1);

    // When
    c.writePixel(0, 0, c1);
    c.writePixel(2, 1, c2);
    c.writePixel(4, 2, c3);
    const ppm = try c.ppm(allocator);
    defer allocator.free(ppm);

    // Then
    try std.testing.expectEqualStrings(
        \\255 0 0 0 0 0 0 0 0 0 0 0 0 0 0
        \\0 0 0 0 0 0 0 128 0 0 0 0 0 0 0
        \\0 0 0 0 0 0 0 0 0 0 0 0 0 0 255
    , TestHelper.getLines(ppm, 4, 6));
}

test "Splitting long lines in PPM files" {
    // Given
    const allocator = std.testing.allocator;
    var c = try Canvas.init(allocator, 10, 2);
    defer c.deinit();

    // When
    for (0..c.width) |i| {
        for (0..c.height) |j| {
            c.writePixel(i, j, Color.init(1, 0.8, 0.6));
        }
    }
    const ppm = try c.ppm(allocator);
    defer allocator.free(ppm);

    // Then
    try std.testing.expectEqualStrings(
        \\255 204 153 255 204 153 255 204 153 255 204 153 255 204 153 255 204
        \\153 255 204 153 255 204 153 255 204 153 255 204 153
        \\255 204 153 255 204 153 255 204 153 255 204 153 255 204 153 255 204
        \\153 255 204 153 255 204 153 255 204 153 255 204 153
    , TestHelper.getLines(ppm, 4, 7));
}

test "PPM files are terminated by a newline character" {
    // Given
    const allocator = std.testing.allocator;
    var c = try Canvas.init(allocator, 5, 3);
    defer c.deinit();

    // When
    const ppm = try c.ppm(allocator);
    defer allocator.free(ppm);

    // Then
    try std.testing.expectEqual('\n', ppm[ppm.len - 1]);
}

const TestHelper = struct {
    pub fn getLines(str: []const u8, from: usize, to: usize) []const u8 {
        assert(to > from);

        var start_index: ?usize = null;
        var line: usize = 1;

        var i: usize = 0;
        while (i < str.len and line <= to) : (i += 1) {
            if (line == from and start_index == null) start_index = i;
            if (line == to and str[i] == '\n') return str[start_index.?..i];
            if (str[i] == '\n') line += 1;
        }

        std.debug.panic(
            "Test Error: Requested lines {d}-{d}, but string only has {d} lines.\n",
            .{ from, to, line - 1 },
        );
    }
};
