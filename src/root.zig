const std = @import("std");
pub const tuple = @import("tuple.zig");

test {
    std.testing.refAllDecls(@This());
}
