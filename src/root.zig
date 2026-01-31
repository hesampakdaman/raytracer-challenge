const std = @import("std");
pub const tuple = @import("tuple.zig");
pub const color = @import("color.zig");
pub const canvas = @import("canvas.zig");
pub const projectile = @import("projectile.zig");
pub const matrix = @import("matrix.zig");
pub const transformation = @import("transformation.zig");

test {
    std.testing.refAllDecls(@This());
}
