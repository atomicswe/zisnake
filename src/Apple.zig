const std = @import("std");
const log = std.log;
const testing = std.testing;

const rl = @import("raylib");
const Vector2 = rl.Vector2;

const Player = @import("Player.zig");

const Apple = @This();
pos: Vector2,
radius: f32 = 8,
color: rl.Color = .white,

pub fn init(x: f32, y: f32) Apple {
    const pos = Vector2.init(x, y);
    return .{ .pos = pos };
}

pub fn drawApple(self: *Apple) void {
    rl.drawCircleV(self.pos, self.radius, self.color);
}

// move to Game.zig
// if player.top == apple.bottom -> collision
// if player.bottom == apple.top -> collision
// if player.left == apple.right -> collision
// if player.right == apple.left -> collision
// pub fn detectCollision(self: *Apple, player: Player) bool {}

test "apple init" {
    const sut = init(0, 0);
    testing.expectEqual(Vector2.init(0, 0), sut.pos);
}
