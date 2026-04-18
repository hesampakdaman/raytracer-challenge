const std = @import("std");

pub const Camera = @import("Camera.zig");
pub const Canvas = @import("Canvas.zig");
pub const Color = @import("Color.zig");
pub const intersection = @import("intersection.zig");
pub const light = @import("light.zig");
pub const material = @import("material.zig");
pub const matrix = @import("matrix.zig");
pub const pattern = @import("pattern.zig");
pub const plane = @import("plane.zig");
pub const projectile = @import("projectile.zig");
pub const ray = @import("ray.zig");
pub const shape = @import("shape.zig");
pub const Sphere = @import("Sphere.zig");
pub const transformation = @import("transformation.zig");
pub const Tuple = @import("Tuple.zig");
pub const world = @import("world.zig");

test {
    std.testing.refAllDecls(@This());
}
