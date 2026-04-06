const std = @import("std");
const math = std.math;

const expect = @import("expect.zig");
const num = @import("num.zig");
const tup = @import("tuple.zig");
const Color = @import("color.zig").Color;
const Point = tup.Point;
const PointLight = @import("light.zig").PointLight;
const Shape = @import("shape.zig").Shape;
const Vector = tup.Vector;
const Pattern = @import("pattern.zig").Pattern;

pub const Material = struct {
    color: Color = Color.init(1, 1, 1),
    ambient: f32 = 0.1,
    diffuse: f32 = 0.9,
    specular: f32 = 0.9,
    shininess: f32 = 200.0,
    pattern: ?Pattern = null,

    pub fn lighting(self: *const Material, shape: *const Shape, light: PointLight, point: Point, eyev: Vector, normalv: Vector, in_shadow: bool) Color {
        const color = if (self.pattern) |p| p.patternAtShape(shape, point) else self.color;
        // ambient light is uniformly applied
        const effective_color = color.hadamard_product(light.intensity);
        const ambient = effective_color.mul(self.ambient);
        if (in_shadow) return ambient;

        // diffusion only depends on the normal of the material and
        // the light direction
        const lightv = light.position.sub(point).normalize();
        const light_dot_normal = lightv.dot(normalv);
        // if light is on other side of surface both diffuse and
        // specular contribute nothing
        if (light_dot_normal < 0) return ambient;
        const diffuse = effective_color.mul(self.diffuse).mul(light_dot_normal);

        // specular only depends on the reflection of the light source
        // and the eye
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
    const result = ctx.m.lighting(&Shape.newSphere(.{}), light, ctx.position, eyev, normalv, false);

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
    const result = ctx.m.lighting(&Shape.newSphere(.{}), light, ctx.position, eyev, normalv, false);

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
    const result = ctx.m.lighting(&Shape.newSphere(.{}), light, ctx.position, eyev, normalv, false);

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
    const result = ctx.m.lighting(&Shape.newSphere(.{}), light, ctx.position, eyev, normalv, false);

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
    const result = ctx.m.lighting(&Shape.newSphere(.{}), light, ctx.position, eyev, normalv, false);

    // Then
    try expect.approxEqColor(Color.init(0.1, 0.1, 0.1), result);
}

test "Lightning with the surface in shadow" {
    // Given
    const ctx = TestContext{};
    const eyev = Vector.init(0, 0, -1);
    const normalv = Vector.init(0, 0, -1);
    const light = PointLight.init(Point.init(0, 0, -10), Color.white());
    const in_shadow = true;

    // When
    const result = ctx.m.lighting(&Shape.newSphere(.{}), light, ctx.position, eyev, normalv, in_shadow);

    // Then
    try expect.approxEqColor(Color.init(0.1, 0.1, 0.1), result);
}

test "Lighting with a pattern applied" {
    // Given
    var ctx = TestContext{};
    const white = Pattern.newSolid(Color.white());
    const black = Pattern.newSolid(Color.black());
    ctx.m.pattern = Pattern.newStripe(.{ .a = &white, .b = &black });
    ctx.m.ambient = 1;
    ctx.m.diffuse = 0;
    ctx.m.specular = 0;
    const eyev = Vector.init(0, 0, -1);
    const normalv = Vector.init(0, 0, -1);
    const light = PointLight.init(Point.init(0, 0, -10), Color.white());

    // When
    const c1 = ctx.m.lighting(&Shape.newSphere(.{}), light, Point.init(0.9, 0, 0), eyev, normalv, false);
    const c2 = ctx.m.lighting(&Shape.newSphere(.{}), light, Point.init(1.1, 0, 0), eyev, normalv, false);

    // Then
    try expect.approxEqColor(c1, Color.white());
    try expect.approxEqColor(c2, Color.black());
}
