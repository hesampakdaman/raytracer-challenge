const std = @import("std");
pub const tuple = @import("tuple.zig");
pub const color = @import("color.zig");

test {
    std.testing.refAllDecls(@This());
}
