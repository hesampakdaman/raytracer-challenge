const std = @import("std");

const tuple = @import("tuple.zig");

const EPSILON = @import("core.zig").EPSILON;
const Point = tuple.Point;
const Tuple = tuple.Tuple;
const Vector = tuple.Vector;
const Matrix = @import("matrix.zig").Matrix;

pub fn approxEqTuple(expected: Tuple, actual: Tuple) !void {
    if (!expected.approxEq(actual)) {
        std.debug.print(
            \\ Mismatch
            \\  got:    ({d}, {d}, {d}, {d})
            \\  expect: ({d}, {d}, {d}, {d})
            \\  diff:   ({d}, {d}, {d}, {d})
            \\
        , .{
            expected.x(),              expected.y(),              expected.z(),              expected.w(),
            actual.x(),                actual.y(),                actual.z(),                actual.w(),
            expected.x() - actual.x(), expected.y() - actual.y(), expected.z() - actual.z(), expected.w() - actual.w(),
        });
        return error.TestExpectedApproxEq;
    }
}

pub fn approxEqPoint(expected: Point, actual: Point) !void {
    return approxEqTuple(expected.tuple, actual.tuple);
}

pub fn approxEqVector(expected: Vector, actual: Vector) !void {
    return approxEqTuple(expected.tuple, actual.tuple);
}

pub fn approxEqMatrix(comptime N: usize, expected: *const Matrix(N), actual: *const Matrix(N)) !void {
    if (!expected.approxEq(actual)) {
        for (0..N) |i| {
            for (0..N) |j| {
                const av = expected.at(i, j);
                const bv = actual.at(i, j);
                if (!std.math.approxEqAbs(f64, av, bv, EPSILON)) {
                    std.debug.print(
                        \\Matrix mismatch at ({d}, {d})
                        \\  got:    {d}
                        \\  expect: {d}
                        \\  diff:   {d}
                        \\
                    , .{ i, j, av, bv, av - bv });
                    break;
                }
            }
        }
        return error.TestExpectedApproxEq;
    }
}
