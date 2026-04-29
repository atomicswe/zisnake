const std = @import("std");
const testing = std.testing;

const rl = @import("raylib");
const Vector2 = rl.Vector2;

const Player = @import("Player.zig");
const vars = @import("vars.zig");

const log = std.log.scoped(.apple);
const Apple = @This();
center: Vector2,
radius: f32 = 8,
color: rl.Color = .white,

pub fn init(x: f32, y: f32) Apple {
    var center = Vector2.init(x, y);

    if (center.x <= 0) {
        center.x = 0 + 8; // + radius
    }

    if (center.x >= vars.ScreenWidth) {
        center.x = vars.ScreenWidth - 8; // - radius
    }

    if (center.y <= 0) {
        center.y = 0 + 8; // + radius
    }

    if (center.y >= vars.ScreenHeight) {
        center.y = vars.ScreenHeight - 8; // - radius
    }

    return .{ .center = center };
}

pub fn drawApple(self: *Apple) void {
    rl.drawCircleV(self.center, self.radius, self.color);
}

test "apple init" {
    const sut = init(0, 0);
    try testing.expectEqual(Vector2.init(0 + sut.radius, 0 + sut.radius), sut.center);
}

test "apple init out-of-bounds" {
    {
        const sut = init(-10, 100);
        try testing.expectEqual(Vector2.init(0 + sut.radius, 100), sut.center);
    }

    {
        const sut = init(vars.ScreenWidth + 100, 100);
        try testing.expectEqual(Vector2.init(vars.ScreenWidth - sut.radius, 100), sut.center);
    }

    {
        const sut = init(100, -10);
        try testing.expectEqual(Vector2.init(100, 0 + sut.radius), sut.center);
    }

    {
        const sut = init(100, vars.ScreenHeight + 100);
        try testing.expectEqual(Vector2.init(100, vars.ScreenHeight - sut.radius), sut.center);
    }

    {
        const sut = init(-10, -10);
        try testing.expectEqual(Vector2.init(0 + sut.radius, 0 + sut.radius), sut.center);
    }

    {
        const sut = init(vars.ScreenWidth + 100, vars.ScreenHeight + 100);
        try testing.expectEqual(Vector2.init(vars.ScreenWidth - sut.radius, vars.ScreenHeight - sut.radius), sut.center);
    }

    {
        const sut = init(-10, vars.ScreenHeight + 100);
        try testing.expectEqual(Vector2.init(0 + sut.radius, vars.ScreenHeight - sut.radius), sut.center);
    }

    {
        const sut = init(vars.ScreenWidth + 100, -10);
        try testing.expectEqual(Vector2.init(vars.ScreenWidth - sut.radius, 0 + sut.radius), sut.center);
    }
}
