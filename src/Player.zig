const std = @import("std");
const testing = std.testing;

const rl = @import("raylib");
const Vector2 = rl.Vector2;
const Color = rl.Color;

const vars = @import("vars.zig");

const log = std.log.scoped(.player);
const Player = @This();

const PlayerSize: f32 = 32;

pos: Vector2,
size: Vector2 = Vector2.init(PlayerSize, PlayerSize),
color: Color,
velocity: Vector2 = Vector2.init(0, 0),
safeAreaSize: Vector2 = Vector2.init(150, 100), // area where enemies (apples) can not spawn in around the player

pub const Direction = enum {
    up,
    down,
    right,
    left,
};

pub fn init() Player {
    const pos = Vector2.init((vars.ScreenWidth / 2 - PlayerSize / 2), (vars.ScreenHeight / 2) - (PlayerSize / 2));
    return .{ .pos = pos, .color = .maroon };
}

pub fn drawPlayer(self: *Player) void {
    self.pos = Vector2.add(self.pos, self.velocity);

    if (self.pos.x > vars.ScreenWidth and self.velocity.equals(Vector2.init(1, 0))) {
        self.pos.x = 0;
    } else if (self.pos.x < 0 - self.size.x and self.velocity.equals(Vector2.init(-1, 0))) {
        self.pos.x = vars.ScreenWidth;
    }

    if (self.pos.y > vars.ScreenHeight and self.velocity.equals(Vector2.init(0, 1))) {
        self.pos.y = 0;
    } else if (self.pos.y < 0 - self.size.y and self.velocity.equals(Vector2.init(0, -1))) {
        self.pos.y = vars.ScreenHeight;
    }

    rl.drawRectangleV(self.pos, self.size, self.color);
    self.drawSafeArea();
}

fn drawSafeArea(self: *Player) void {
    const safeArea = self.getSafeAreaLimits()[0];
    rl.drawRectangleLines(@intFromFloat(safeArea.x), @intFromFloat(safeArea.y), @intFromFloat(self.safeAreaSize.x), @intFromFloat(self.safeAreaSize.y), .green);
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

// TODO: add tests
pub fn getSafeAreaLimits(self: *Player) [2]Vector2 {
    const x1: f32 = @max(0, (self.pos.x + self.size.x / 2) - (self.safeAreaSize.x / 2));
    const y1: f32 = @max(0, (self.pos.y + self.size.y / 2) - (self.safeAreaSize.y / 2));

    const x2: f32 = @min(vars.ScreenWidth, (self.pos.x + self.size.x / 2) + (self.safeAreaSize.x / 2));
    const y2: f32 = @min(vars.ScreenHeight, (self.pos.y + self.size.y / 2) + (self.safeAreaSize.y / 2));

    return [2]Vector2{
        .init(x1, y1),
        .init(x2, y2),
    };
}

test "player init" {
    _ = init();
}

test "switch direction success" {
    var sut = init();

    try testing.expectEqual(Vector2.init(0, 0), sut.velocity);

    sut.switchDirection(.up);
    try testing.expectEqual(Vector2.init(0, -1), sut.velocity);

    sut.switchDirection(.left);
    try testing.expectEqual(Vector2.init(-1, 0), sut.velocity);
}
