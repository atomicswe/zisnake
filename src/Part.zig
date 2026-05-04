const std = @import("std");
const Deque = std.Deque;
const Allocator = std.mem.Allocator;
const testing = std.testing;

const rl = @import("raylib");
const Vector2 = rl.Vector2;

const Player = @import("Player.zig");
const vars = @import("vars.zig");

const Part = @This();
pub const Memory = struct {
    turnPoint: Vector2,
    oldVelocity: Vector2,
    newVelocity: Vector2,
};

pos: Vector2,
isHead: bool = false,
velocity: Vector2 = Vector2.init(0, 0),
memories: Deque(Memory),

pub fn init(pos: Vector2, velocity: Vector2, memories: Deque(Memory)) Part {
    return .{ .pos = pos, .velocity = velocity, .memories = memories };
}

pub fn deinit(self: *Part, allocator: Allocator) void {
    self.memories.deinit(allocator);
}

pub fn movePart(self: *Part, playerSize: Vector2) void {
    if (self.memories.front()) |memory| {
        const oldV = memory.oldVelocity;

        const hor = oldV.equals(.init(1, 0)) or oldV.equals(.init(-1, 0));
        const ver = oldV.equals(.init(0, 1)) or oldV.equals(.init(0, -1));

        const reachedTurnPoint =
            (hor and self.pos.x == memory.turnPoint.x) or
            (ver and self.pos.y == memory.turnPoint.y);

        if (reachedTurnPoint) {
            self.pos = memory.turnPoint;
            self.velocity = memory.newVelocity;
            _ = self.memories.popFront();
        } else {
            self.pos = self.pos.add(oldV);
            return;
        }
    }

    self.pos = self.pos.add(self.velocity);

    if (self.pos.x > vars.ScreenWidth and self.velocity.equals(.init(1, 0))) {
        self.pos.x = 0;
    } else if (self.pos.x < 0 - playerSize.x and self.velocity.equals(.init(-1, 0))) {
        self.pos.x = vars.ScreenWidth;
    }

    if (self.pos.y > vars.ScreenHeight and self.velocity.equals(.init(0, 1))) {
        self.pos.y = 0;
    } else if (self.pos.y < 0 - playerSize.y and self.velocity.equals(.init(0, -1))) {
        self.pos.y = vars.ScreenHeight;
    }
}

pub fn getVertices(self: *Part, size: Vector2) [4]Vector2 {
    return [4]Vector2{
        self.pos,
        .init(self.pos.x + size.x, self.pos.y),
        .init(self.pos.x, self.pos.y + size.y),
        .init(self.pos.x + size.x, self.pos.y + size.y),
    };
}

test "move part" {
    const allocator = std.testing.allocator;

    var sut = Part.init(.init(0, 0), .init(1, 0), .empty);
    defer sut.deinit(allocator);

    {
        sut.movePart(.init(32, 32));
        try testing.expectEqual(Vector2.init(1, 0), sut.pos);
    }

    {
        try sut.memories.pushBack(allocator, Memory{ .newVelocity = .init(-1, 0), .oldVelocity = .init(1, 0), .turnPoint = .init(2, 0) });
        sut.movePart(.init(32, 32));
        try testing.expectEqual(Vector2.init(2, 0), sut.pos);

        sut.movePart(.init(32, 32));
        try testing.expectEqual(Vector2.init(1, 0), sut.pos);
        try testing.expect(sut.memories.len == 0);
    }
}

test "get vertices" {
    var sut = Part{ .pos = .init(100, 100), .memories = .empty };
    try testing.expectEqual(Vector2.init(100, 100), sut.pos);

    const vertices = sut.getVertices(.init(32, 32));
    try testing.expect(vertices.len == 4);

    try testing.expectEqual(Vector2.init(100, 100), vertices[0]);
    try testing.expectEqual(Vector2.init(132, 100), vertices[1]);
    try testing.expectEqual(Vector2.init(100, 132), vertices[2]);
    try testing.expectEqual(Vector2.init(132, 132), vertices[3]);
}
