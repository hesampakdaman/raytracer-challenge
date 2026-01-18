const std = @import("std");
pub const tuple = @import("tuple.zig");
pub const color = @import("color.zig");
pub const canvas = @import("canvas.zig");

test {
    std.testing.refAllDecls(@This());
}
