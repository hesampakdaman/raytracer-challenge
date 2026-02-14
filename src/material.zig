const std = @import("std");
const math = std.math;

const expect = @import("expect.zig");
const num = @import("num.zig");
const tup = @import("tuple.zig");

const Color = @import("color.zig").Color;
const Point = tup.Point;
const PointLight = @import("light.zig").PointLight;
const Sphere = @import("sphere.zig").Sphere;
const Vector = tup.Vector;

pub const Material = struct {
    color: Color = Color.init(1, 1, 1),
    ambient: f32 = 0.1,
    diffuse: f32 = 0.9,
    specular: f32 = 0.9,
    shininess: f32 = 200.0,

    pub fn lighting(self: Material, light: PointLight, point: Point, eyev: Vector, normalv: Vector) Color {
        const effective_color = self.color.hadamard_product(light.intensity);
        const lightv = light.position.sub(point).normalize();
        const ambient = effective_color.mul(self.ambient);
        const light_dot_normal = lightv.dot(normalv);

        // if light is on other side of surface both diffuse and
        // specular contribute nothing
        if (light_dot_normal < 0) return ambient;

        const diffuse = effective_color.mul(self.diffuse).mul(light_dot_normal);
        const reflectv = lightv.negate().reflect(normalv);
        const reflect_dot_eye = reflectv.dot(eyev);

        // if the eye doesn't catch rays from the reflection vector
        // then specular doesn't contribute
        if (reflect_dot_eye <= 0) return ambient.add(diffuse);

        const factor = math.pow(f64, reflect_dot_eye, self.shininess);
        const specular = light.intensity.mul(self.specular).mul(factor);
        return ambient.add(diffuse).add(specular);
    }

    pub fn approxEq(self: Material, other: Material) bool {
        if (!self.color.approxEq(other.color)) return false;
        return math.approxEqAbs(f64, self.ambient, other.ambient, num.epsilon) and
            math.approxEqAbs(f64, self.diffuse, other.diffuse, num.epsilon) and
            math.approxEqAbs(f64, self.specular, other.specular, num.epsilon) and
            math.approxEqAbs(f64, self.shininess, other.shininess, num.epsilon);
    }
};

test "The default material" {
    // Given
    const m = Material{};

    // Then
    try expect.approxEqColor(Color.init(1, 1, 1), m.color);
    try std.testing.expectApproxEqAbs(0.1, m.ambient, num.epsilon);
    try std.testing.expectApproxEqAbs(0.9, m.diffuse, num.epsilon);
    try std.testing.expectApproxEqAbs(0.9, m.specular, num.epsilon);
    try std.testing.expectApproxEqAbs(200.0, m.shininess, num.epsilon);
}

test "A sphere has a default material" {
    // Given
    const s = Sphere{};

    // When
    const m = s.material;

    // Then
    try expect.approxEqMaterial(Material{}, m);
}

test "A sphere may be assigned a material" {
    // Given
    var s = Sphere{};
    var m = Material{};
    m.ambient = 1;

    // When
    s.material = m;

    // Then
    try expect.approxEqMaterial(m, s.material);
}

const TestContext = struct {
    m: Material = Material{},
    position: Point = Point.zero(),
};

test "Lighting with the eye between the light and the surface" {
    // Given
    const ctx = TestContext{};
    const eyev = Vector.init(0, 0, -1);
    const normalv = Vector.init(0, 0, -1);
    const light = PointLight.init(Point.init(0, 0, -10), Color.init(1, 1, 1));

    // When
    const result = ctx.m.lighting(light, ctx.position, eyev, normalv);

    // Then
    try expect.approxEqColor(Color.init(1.9, 1.9, 1.9), result);
}

test "Lighting with the eye between the light and the surface, eye offset 45°" {
    // Given
    const ctx = TestContext{};
    const eyev = Vector.init(0, num.sqrt2 / 2.0, -num.sqrt2 / 2.0);
    const normalv = Vector.init(0, 0, -1);
    const light = PointLight.init(Point.init(0, 0, -10), Color.init(1, 1, 1));

    // When
    const result = ctx.m.lighting(light, ctx.position, eyev, normalv);

    // Then
    try expect.approxEqColor(Color.init(1.0, 1.0, 1.0), result);
}

test "Lighting with eye opposite surface, light offset 45°" {
    // Given
    const ctx = TestContext{};
    const eyev = Vector.init(0, 0, -1);
    const normalv = Vector.init(0, 0, -1);
    const light = PointLight.init(Point.init(0, 10, -10), Color.init(1, 1, 1));

    // When
    const result = ctx.m.lighting(light, ctx.position, eyev, normalv);

    // Then
    try expect.approxEqColor(Color.init(0.7364, 0.7364, 0.7364), result);
}

test "Lighting with eye in the path of the reflection vector" {
    // Given
    const ctx = TestContext{};
    const eyev = Vector.init(0, -num.sqrt2 / 2.0, -num.sqrt2 / 2.0);
    const normalv = Vector.init(0, 0, -1);
    const light = PointLight.init(Point.init(0, 10, -10), Color.init(1, 1, 1));

    // When
    const result = ctx.m.lighting(light, ctx.position, eyev, normalv);

    // Then
    try expect.approxEqColor(Color.init(1.6364, 1.6364, 1.6364), result);
}

test "Lighting with the light behind the surface" {
    // Given
    const ctx = TestContext{};
    const eyev = Vector.init(0, 0, -1);
    const normalv = Vector.init(0, 0, -1);
    const light = PointLight.init(Point.init(0, 0, 10), Color.init(1, 1, 1));

    // When
    const result = ctx.m.lighting(light, ctx.position, eyev, normalv);

    // Then
    try expect.approxEqColor(Color.init(0.1, 0.1, 0.1), result);
}
