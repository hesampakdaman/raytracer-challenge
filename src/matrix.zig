const std = @import("std");
const math = std.math;
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;

const Tuple = @import("tuple.zig").Tuple;
const EPSILON = @import("core.zig").EPSILON;

pub const Mat2 = Matrix(2);
pub const Mat3 = Matrix(3);
pub const Mat4 = Matrix(4);

fn Matrix(comptime N: usize) type {
    return struct {
        const Self = @This();
        data: [N][N]f64,

        pub fn init(data: [N][N]f64) Self {
            return .{ .data = data };
        }

        pub fn zero() Self {
            const data: [N][N]f64 = [_][N]f64{[_]f64{0} ** N} ** N;
            return Self.init(data);
        }

        pub fn identity() Self {
            var I = Self.zero();
            for (0..N) |i| {
                I.set(i, i, 1);
            }
            return I;
        }

        pub fn approxEq(self: Self, other: Self) bool {
            for (0..N) |i| {
                for (0..N) |j| {
                    if (!std.math.approxEqAbs(f64, self.at(i, j), other.at(i, j), EPSILON)) {
                        // std.debug.print("{d} vs {d}\n", .{ self.at(i, j), other.at(i, j) });
                        return false;
                    }
                }
            }
            return true;
        }

        pub fn at(self: Self, row: usize, col: usize) f64 {
            return self.data[row][col];
        }

        pub fn set(self: *Self, row: usize, col: usize, val: f64) void {
            self.data[row][col] = val;
        }

        pub fn mul(self: Self, other: Self) Self {
            var out: Self = undefined;
            for (0..N) |i| {
                for (0..N) |j| {
                    var val: f64 = 0;
                    for (0..N) |k| {
                        val += self.at(i, k) * other.at(k, j);
                    }
                    out.set(i, j, val);
                }
            }
            return out;
        }

        pub fn apply(self: Matrix(4), tuple: Tuple) Tuple {
            var out: [N]f64 = .{ 0, 0, 0, 0 };
            for (0..N) |i| {
                for (0..N) |j| {
                    out[i] += self.data[i][j] * tuple.at(j);
                }
            }
            return Tuple.init(out[0], out[1], out[2], out[3]);
        }

        pub fn transpose(self: Self) Self {
            var out: Self = undefined;
            for (0..N) |i| {
                for (0..N) |j| {
                    out.set(j, i, self.at(i, j));
                }
            }
            return out;
        }

        pub fn determinant(self: Self) f64 {
            if (N == 2) return self.at(0, 0) * self.at(1, 1) -
                self.at(0, 1) * self.at(1, 0);

            var det: f64 = 0;
            for (0..N) |j| {
                det += self.at(0, j) * self.cofactor(0, j);
            }
            return det;
        }

        pub fn submatrix(self: Self, row: usize, col: usize) Matrix(N - 1) {
            comptime if (N <= 1) @compileError("submatrix requires N > 1");
            assert(row < N and col < N);

            var out: Matrix(N - 1) = undefined;

            var k: usize = 0;
            for (0..N) |i| {
                if (i == row) continue;

                var l: usize = 0;
                for (0..N) |j| {
                    if (j == col) continue;
                    out.set(k, l, self.at(i, j));
                    l += 1;
                }
                k += 1;
            }

            return out;
        }

        pub fn minor(self: Self, row: usize, col: usize) f64 {
            return self.submatrix(row, col).determinant();
        }

        pub fn cofactor(self: Self, row: usize, col: usize) f64 {
            const sign: f64 = if ((row + col) % 2 == 0) 1 else -1;
            return sign * self.minor(row, col);
        }

        pub fn invertible(self: Self) bool {
            return !std.math.approxEqAbs(f64, self.determinant(), 0, EPSILON);
        }

        pub fn inverse(self: Self) !Self {
            const det = self.determinant();
            if (std.math.approxEqAbs(f64, det, 0, EPSILON))
                return error.NotInvertible;

            var out: Self = undefined;
            for (0..N) |i| {
                for (0..N) |j| {
                    const cof = self.cofactor(i, j);
                    out.set(j, i, cof / det);
                }
            }

            return out;
        }

        pub fn translate(self: Matrix(4), x: f64, y: f64, z: f64) Self {
            const T = Self{
                .data = .{
                    .{ 1, 0, 0, x },
                    .{ 0, 1, 0, y },
                    .{ 0, 0, 1, z },
                    .{ 0, 0, 0, 1 },
                },
            };

            return T.mul(self);
        }

        pub fn scale(self: Matrix(4), x: f64, y: f64, z: f64) Self {
            const T = Self{
                .data = .{
                    .{ x, 0, 0, 0 },
                    .{ 0, y, 0, 0 },
                    .{ 0, 0, z, 0 },
                    .{ 0, 0, 0, 1 },
                },
            };

            return T.mul(self);
        }

        pub fn rotateX(self: Matrix(4), rad: f64) Matrix(4) {
            const cosr = math.cos(rad);
            const sinr = math.sin(rad);
            const T = Self{
                .data = .{
                    .{ 1.000, 0.00, 0.00, 0.00 },
                    .{ 0.000, cosr, -sinr, 0.00 },
                    .{ 0.000, sinr, cosr, 0.00 },
                    .{ 0.000, 0.00, 0.00, 1.00 },
                },
            };

            return T.mul(self);
        }

        pub fn rotateY(self: Matrix(4), rad: f64) Matrix(4) {
            const cosr = math.cos(rad);
            const sinr = math.sin(rad);
            const T = Self{
                .data = .{
                    .{ cosr, 0.000, sinr, 0.00 },
                    .{ 0.000, 1.00, 0.00, 0.00 },
                    .{ -sinr, 0.00, cosr, 0.00 },
                    .{ 0.000, 0.00, 0.00, 1.00 },
                },
            };

            return T.mul(self);
        }

        pub fn rotateZ(self: Matrix(4), rad: f64) Matrix(4) {
            const cosr = math.cos(rad);
            const sinr = math.sin(rad);
            const T = Self{
                .data = .{
                    .{ cosr, -sinr, 0.00, 0.00 },
                    .{ sinr, cosr, 0.000, 0.00 },
                    .{ 0.00, 0.00, 1.000, 0.00 },
                    .{ 0.00, 0.00, 0.000, 1.00 },
                },
            };

            return T.mul(self);
        }

        pub fn shear(self: Matrix(4), x_y: f64, x_z: f64, y_x: f64, y_z: f64, z_x: f64, z_y: f64) Self {
            const T = Self{
                .data = .{
                    .{ 1.0, x_y, x_z, 0.0 },
                    .{ y_x, 1.0, y_z, 0.0 },
                    .{ z_x, z_y, 1.0, 0.0 },
                    .{ 0.0, 0.0, 0.0, 1.0 },
                },
            };

            return T.mul(self);
        }
    };
}

test "Constructing and inspecting a 4x4 matrix" {
    // Given
    const M = Mat4.init(.{
        .{ 1, 2, 3, 4 },
        .{ 5.5, 6.5, 7.5, 8.5 },
        .{ 9, 10, 11, 12 },
        .{ 13.5, 14.5, 15.5, 16.5 },
    });

    // Then
    try std.testing.expectApproxEqAbs(1, M.at(0, 0), EPSILON);
    try std.testing.expectApproxEqAbs(4, M.at(0, 3), EPSILON);
    try std.testing.expectApproxEqAbs(5.5, M.at(1, 0), EPSILON);
    try std.testing.expectApproxEqAbs(7.5, M.at(1, 2), EPSILON);
    try std.testing.expectApproxEqAbs(11, M.at(2, 2), EPSILON);
    try std.testing.expectApproxEqAbs(13.5, M.at(3, 0), EPSILON);
    try std.testing.expectApproxEqAbs(15.5, M.at(3, 2), EPSILON);
}

test "A 2x2 matrix ought to be representable" {
    // Given
    const M = Mat2.init(.{
        .{ -3, 5 },
        .{ 1, -2 },
    });

    // Then
    try std.testing.expectApproxEqAbs(-3, M.at(0, 0), EPSILON);
    try std.testing.expectApproxEqAbs(5, M.at(0, 1), EPSILON);
    try std.testing.expectApproxEqAbs(1, M.at(1, 0), EPSILON);
    try std.testing.expectApproxEqAbs(-2, M.at(1, 1), EPSILON);
}

test "A 3x3 matrix ought to be representable" {
    // Given
    const M = Mat3.init(.{
        .{ -3, 5, 0 },
        .{ 1, -2, -7 },
        .{ 0, 1, 1 },
    });

    // Then
    try std.testing.expectApproxEqAbs(-3, M.at(0, 0), EPSILON);
    try std.testing.expectApproxEqAbs(-2, M.at(1, 1), EPSILON);
    try std.testing.expectApproxEqAbs(1, M.at(2, 2), EPSILON);
}

test "Matrix equality with identical matrices" {
    // Given
    const A = Mat4.init(.{
        .{ 1, 2, 3, 4 },
        .{ 5, 6, 7, 8 },
        .{ 9, 8, 7, 6 },
        .{ 5, 4, 3, 2 },
    });
    const B = Mat4.init(.{
        .{ 1, 2, 3, 4 },
        .{ 5, 6, 7, 8 },
        .{ 9, 8, 7, 6 },
        .{ 5, 4, 3, 2 },
    });

    // Then
    try std.testing.expect(A.approxEq(B));
}

test "Matrix equality with different matrices" {
    // Given
    const A = Mat4.init(.{
        .{ 1, 2, 3, 4 },
        .{ 5, 6, 7, 8 },
        .{ 9, 8, 7, 6 },
        .{ 5, 4, 3, 2 },
    });
    const B = Mat4.init(.{
        .{ 2, 3, 4, 5 },
        .{ 6, 7, 8, 9 },
        .{ 8, 7, 6, 5 },
        .{ 4, 3, 2, 1 },
    });

    // Then
    try std.testing.expect(!A.approxEq(B));
}

test "Multiplying two matrices" {
    // Given
    const A = Mat4.init(.{
        .{ 1, 2, 3, 4 },
        .{ 5, 6, 7, 8 },
        .{ 9, 8, 7, 6 },
        .{ 5, 4, 3, 2 },
    });
    const B = Mat4.init(.{
        .{ -2, 1, 2, 3 },
        .{ 3, 2, 1, -1 },
        .{ 4, 3, 6, 5 },
        .{ 1, 2, 7, 8 },
    });

    // Then
    try std.testing.expect(A.mul(B).approxEq(Mat4.init(.{
        .{ 20, 22, 50, 48 },
        .{ 44, 54, 114, 108 },
        .{ 40, 58, 110, 102 },
        .{ 16, 26, 46, 42 },
    })));
}

test "A matrix multiplied by a tuple" {
    // Given
    const M = Mat4.init(.{
        .{ 1, 2, 3, 4 },
        .{ 2, 4, 4, 2 },
        .{ 8, 6, 4, 1 },
        .{ 0, 0, 0, 1 },
    });
    const b = Tuple.init(1, 2, 3, 1);

    // Then
    try std.testing.expect(M.apply(b).approxEq(Tuple.init(18, 24, 33, 1)));
}

test "Multiplying a matrix by the identity matrix" {
    // Given
    const M = Mat4.init(.{
        .{ 0, 1, 2, 4 },
        .{ 1, 2, 4, 8 },
        .{ 2, 4, 8, 16 },
        .{ 4, 8, 16, 32 },
    });

    // Then
    try std.testing.expect(M.mul(Mat4.identity()).approxEq(M));
}

test "Multiplying the identity matrix by a tuple" {
    // Given
    const a = Tuple.init(1, 2, 3, 4);

    // Then
    try std.testing.expect(Mat4.identity().apply(a).approxEq(a));
}

test "Transposing a matrix" {
    // Given
    const A = Mat4.init(.{
        .{ 0, 9, 3, 0 },
        .{ 9, 8, 0, 8 },
        .{ 1, 8, 5, 3 },
        .{ 0, 0, 5, 8 },
    });

    // Then
    try std.testing.expect(A.transpose().approxEq(Mat4.init(.{
        .{ 0, 9, 1, 0 },
        .{ 9, 8, 8, 0 },
        .{ 3, 0, 5, 5 },
        .{ 0, 8, 3, 8 },
    })));
}

test "Transposing the identity matrix" {
    // Given
    const A = Mat4.identity().transpose();

    // Then
    try std.testing.expect(A.approxEq(Mat4.identity()));
}

test "Calculating the determinant of a 2x2 matrix" {
    // Given
    const A = Mat2.init(.{
        .{ 1, 5 },
        .{ -3, 2 },
    });

    // Then
    try std.testing.expectApproxEqAbs(17, A.determinant(), EPSILON);
}

test "A submatrix of a 3x3 matrix is a 2x2 matrix" {
    // Given
    const A = Mat3.init(.{
        .{ 1, 5, 0 },
        .{ -3, 2, 7 },
        .{ 0, 6, -3 },
    });

    // Then
    try std.testing.expect(A.submatrix(0, 2).approxEq(Mat2.init(.{
        .{ -3, 2 },
        .{ 0, 6 },
    })));
}

test "A submatrix of a 4x4 matrix is a 3x3 matrix" {
    // Given
    const A = Mat4.init(.{
        .{ -6, 1, 1, 6 },
        .{ -8, 5, 8, 6 },
        .{ -1, 0, 8, 2 },
        .{ -7, 1, -1, 1 },
    });

    // Then
    try std.testing.expect(A.submatrix(2, 1).approxEq(Mat3.init(.{
        .{ -6, 1, 6 },
        .{ -8, 8, 6 },
        .{ -7, -1, 1 },
    })));
}

test "Calculating a minor of a 3x3 matrix" {
    // Given
    const A = Mat3.init(.{
        .{ 3, 5, 0 },
        .{ 2, -1, -7 },
        .{ 6, -1, 5 },
    });
    const B = A.submatrix(1, 0);

    // Then
    try std.testing.expectApproxEqAbs(25, B.determinant(), EPSILON);
    try std.testing.expectApproxEqAbs(25, A.minor(1, 0), EPSILON);
}

test "Calculating a cofactor of a 3x3 matrix" {
    // Given
    const A = Mat3.init(.{
        .{ 3, 5, 0 },
        .{ 2, -1, -7 },
        .{ 6, -1, 5 },
    });

    // Then
    try std.testing.expectApproxEqAbs(-12, A.minor(0, 0), EPSILON);
    try std.testing.expectApproxEqAbs(-12, A.cofactor(0, 0), EPSILON);
    try std.testing.expectApproxEqAbs(25, A.minor(1, 0), EPSILON);
    try std.testing.expectApproxEqAbs(-25, A.cofactor(1, 0), EPSILON);
}

test "Calculating the determinant of a 3x3 matrix" {
    // Given
    const A = Mat3.init(.{
        .{ 1, 2, 6 },
        .{ -5, 8, -4 },
        .{ 2, 6, 4 },
    });

    // Then
    try std.testing.expectApproxEqAbs(56, A.cofactor(0, 0), EPSILON);
    try std.testing.expectApproxEqAbs(12, A.cofactor(0, 1), EPSILON);
    try std.testing.expectApproxEqAbs(-46, A.cofactor(0, 2), EPSILON);
    try std.testing.expectApproxEqAbs(-196, A.determinant(), EPSILON);
}

test "Calculating the determinant of a 4x4 matrix" {
    // Given
    const A = Mat4.init(.{
        .{ -2, -8, 3, 5 },
        .{ -3, 1, 7, 3 },
        .{ 1, 2, -9, 6 },
        .{ -6, 7, 7, -9 },
    });

    // Then
    try std.testing.expectApproxEqAbs(690, A.cofactor(0, 0), EPSILON);
    try std.testing.expectApproxEqAbs(447, A.cofactor(0, 1), EPSILON);
    try std.testing.expectApproxEqAbs(210, A.cofactor(0, 2), EPSILON);
    try std.testing.expectApproxEqAbs(51, A.cofactor(0, 3), EPSILON);
    try std.testing.expectApproxEqAbs(-4071, A.determinant(), EPSILON);
}

test "Testing an invertible matrix for invertibility" {
    // Given
    const A = Mat4.init(.{
        .{ 6, 4, 4, 4 },
        .{ 5, 5, 7, 6 },
        .{ 4, -9, 3, -7 },
        .{ 9, 1, 7, -6 },
    });

    // Then
    try std.testing.expectApproxEqAbs(-2120, A.determinant(), EPSILON);
    try std.testing.expect(A.invertible());
}

test "Testing a noninvertible matrix for invertibility" {
    // Given
    const A = Mat4.init(.{
        .{ -4, 2, -2, -3 },
        .{ 9, 6, 2, 6 },
        .{ 0, -5, 1, -5 },
        .{ 0, 0, 0, 0 },
    });

    // Then
    try std.testing.expectApproxEqAbs(0, A.determinant(), EPSILON);
    try std.testing.expect(!A.invertible());
}

test "Calculating the inverse of a matrix" {
    // Given
    const A = Mat4.init(.{
        .{ -5, 2, 6, -8 },
        .{ 1, -5, 1, 8 },
        .{ 7, 7, -6, -7 },
        .{ 1, -3, 7, 4 },
    });
    const B = try A.inverse();

    // Then
    try std.testing.expectApproxEqAbs(532, A.determinant(), EPSILON);
    try std.testing.expectApproxEqAbs(-160, A.cofactor(2, 3), EPSILON);
    try std.testing.expectApproxEqAbs(-160.0 / 532.0, B.at(3, 2), EPSILON);
    try std.testing.expectApproxEqAbs(105, A.cofactor(3, 2), EPSILON);
    try std.testing.expectApproxEqAbs(105.0 / 532.0, B.at(2, 3), EPSILON);

    try std.testing.expect(B.approxEq(Mat4.init(.{
        .{ 0.21805, 0.45113, 0.24060, -0.04511 },
        .{ -0.80827, -1.45677, -0.44361, 0.52068 },
        .{ -0.07895, -0.22368, -0.05263, 0.19737 },
        .{ -0.52256, -0.81391, -0.30075, 0.30639 },
    })));
}

test "Calculating the inverse of another matrix" {
    // Given
    const A = Mat4.init(.{
        .{ 8, -5, 9, 2 },
        .{ 7, 5, 6, 1 },
        .{ -6, 0, 9, 6 },
        .{ -3, 0, -9, -4 },
    });

    // Then
    try std.testing.expect((try A.inverse()).approxEq(Mat4.init(.{
        .{ -0.15385, -0.15385, -0.28205, -0.53846 },
        .{ -0.07692, 0.12308, 0.02564, 0.03077 },
        .{ 0.35897, 0.35897, 0.43590, 0.92308 },
        .{ -0.69231, -0.69231, -0.76923, -1.92308 },
    })));
}

test "Multiplying a product by its inverse" {
    // Given
    const A = Mat4.init(.{
        .{ 3, -9, 7, 3 },
        .{ 3, -8, 2, -9 },
        .{ -4, 4, 4, 1 },
        .{ -6, 5, -1, 1 },
    });
    const B = Mat4.init(.{
        .{ 8, 2, 2, 2 },
        .{ 3, -1, 7, 0 },
        .{ 7, 0, 5, 4 },
        .{ 6, -2, 0, 5 },
    });
    const C = A.mul(B);

    // Then
    try std.testing.expect(C.mul(try B.inverse()).approxEq(A));
}

test "Invert the identity matrix" {
    // Given
    const A = Mat4.identity();

    // Then
    try std.testing.expect(A.mul(try A.inverse()).approxEq(A));
}

test "Multiply a matrix by its inverse" {
    // Given
    const A = Mat4.init(.{
        .{ 3, -9, 7, 3 },
        .{ 3, -8, 2, -9 },
        .{ -4, 4, 4, 1 },
        .{ -6, 5, -1, 1 },
    });

    // Then
    try std.testing.expect(A.mul(try A.inverse()).approxEq(Mat4.identity()));
}

test "Inverse of the transpose of a matrix are interchangeable" {
    // Given
    const A = Mat4.init(.{
        .{ 3, -9, 7, 3 },
        .{ 3, -8, 2, -9 },
        .{ -4, 4, 4, 1 },
        .{ -6, 5, -1, 1 },
    });

    // Then
    try std.testing.expect((try A.transpose().inverse())
        .approxEq((try A.inverse()).transpose()));
}

test "Changing one element of identity matrix affects tuple multiplication" {
    var I = Mat4.identity();
    const a = Tuple.init(1, 2, 3, 4);

    I.set(0, 1, 2);
    I.set(2, 3, 10);

    try std.testing.expect(I.apply(a).approxEq(Tuple.init(1 + 2 * 2, 2, 3 + 4 * 10, 4)));
}
