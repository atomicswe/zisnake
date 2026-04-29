const std = @import("std");
const log = std.log.scoped(.player);
const testing = std.testing;

const rl = @import("raylib");
const Vector2 = rl.Vector2;
const Color = rl.Color;

const Player = @This();

pos: Vector2, // top left corner
size: Vector2 = Vector2.init(32, 32),
color: Color,
velocity: Vector2 = Vector2.init(1, 0),
screenWidth: f32,
screenHeight: f32,

pub const Direction = enum {
    up,
    down,
    right,
    left,
};

pub fn init(screenWidth: f32, screenHeight: f32) Player {
    const pos = Vector2.init(screenWidth / 2, screenHeight / 2);
    return .{ .pos = pos, .color = .maroon, .screenWidth = screenWidth, .screenHeight = screenHeight };
}

pub fn drawPlayer(self: *Player) void {
    self.pos = Vector2.add(self.pos, self.velocity);

    if (self.pos.x > self.screenWidth and self.velocity.equals(Vector2.init(1, 0))) {
        self.pos.x = 0;
    } else if (self.pos.x < 0 - self.size.x and self.velocity.equals(Vector2.init(-1, 0))) {
        self.pos.x = self.screenWidth;
    }

    if (self.pos.y > self.screenHeight and self.velocity.equals(Vector2.init(0, 1))) {
        self.pos.y = 0;
    } else if (self.pos.y < 0 - self.size.y and self.velocity.equals(Vector2.init(0, -1))) {
        self.pos.y = self.screenHeight;
    }

    rl.drawRectangleV(self.pos, self.size, self.color);
}

pub fn switchDirection(self: *Player, direction: Direction) void {
    log.info("switch direction to: {s}", .{@tagName(direction)});
    switch (direction) {
        .up => {
            self.velocity.x = 0;
            self.velocity.y = -1;
        },
        .down => {
            self.velocity.x = 0;
            self.velocity.y = 1;
        },
        .left => {
            self.velocity.x = -1;
            self.velocity.y = 0;
        },
        .right => {
            self.velocity.x = 1;
            self.velocity.y = 0;
        },
    }
}

test "player init" {
    const sut = init(100, 100);

    try testing.expectEqual(Vector2.init(50, 50), sut.pos);
}

test "switch direction success" {
    var sut = init(100, 100);

    try testing.expectEqual(Vector2.init(50, 50), sut.pos);
    try testing.expectEqual(Vector2.init(1, 0), sut.velocity);

    sut.switchDirection(.up);
    try testing.expectEqual(Vector2.init(0, -1), sut.velocity);

    sut.switchDirection(.left);
    try testing.expectEqual(Vector2.init(-1, 0), sut.velocity);
}
