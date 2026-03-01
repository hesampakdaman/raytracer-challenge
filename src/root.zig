const std = @import("std");
pub const tuple = @import("tuple.zig");
pub const color = @import("color.zig");
pub const canvas = @import("canvas.zig");
pub const projectile = @import("projectile.zig");
pub const matrix = @import("matrix.zig");
pub const transformation = @import("transformation.zig");
pub const ray = @import("ray.zig");
pub const sphere = @import("sphere.zig");
pub const intersection = @import("intersection.zig");
pub const light = @import("light.zig");
pub const material = @import("material.zig");
pub const world = @import("world.zig");

test {
    std.testing.refAllDecls(@This());
}
