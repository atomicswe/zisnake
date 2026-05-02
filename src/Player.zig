const std = @import("std");
const testing = std.testing;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const rl = @import("raylib");
const Vector2 = rl.Vector2;
const Color = rl.Color;

const vars = @import("vars.zig");

const log = std.log.scoped(.player);
const Player = @This();

pub const Direction = enum {
    up,
    down,
    right,
    left,
};

pub const Part = struct {
    pos: Vector2,
    isHead: bool = false,
    velocity: Vector2 = Vector2.init(0, 0),
    oldVelocity: ?Vector2 = null,
    turnPoint: ?Vector2 = null,
};

const PlayerSize: f32 = 32;

body: ArrayList(Part),
size: Vector2 = Vector2.init(PlayerSize, PlayerSize),
color: Color,
safeAreaSize: Vector2 = Vector2.init(150, 100), // area where enemies (apples) can not spawn in around the player
allocator: Allocator,

pub fn init(allocator: Allocator) !Player {
    var body: ArrayList(Part) = .empty;

    const pos = Vector2.init((vars.ScreenWidth / 2 - PlayerSize / 2), (vars.ScreenHeight / 2) - (PlayerSize / 2));
    const head = Part{ .pos = pos, .isHead = true };
    try body.append(allocator, head);

    return .{ .body = body, .color = .maroon, .allocator = allocator };
}

pub fn deinit(self: *Player) void {
    self.body.deinit(self.allocator);
}

pub fn drawPlayer(self: *Player) void {
    for (self.body.items) |*part| {
        if (part.turnPoint != null and part.pos.equals(part.turnPoint.?)) {
            part.turnPoint = null;
            part.oldVelocity = null;
        }

        if (part.turnPoint == null) {
            part.pos = Vector2.add(part.pos, part.velocity);
        } else {
            if (part.oldVelocity == null) @panic("oldVelocity is not set");
            part.pos = Vector2.add(part.pos, part.oldVelocity.?);
        }

        if (part.pos.x > vars.ScreenWidth and part.velocity.equals(Vector2.init(1, 0))) {
            part.pos.x = 0;
        } else if (part.pos.x < 0 - self.size.x and part.velocity.equals(Vector2.init(-1, 0))) {
            part.pos.x = vars.ScreenWidth;
        }

        if (part.pos.y > vars.ScreenHeight and part.velocity.equals(Vector2.init(0, 1))) {
            part.pos.y = 0;
        } else if (part.pos.y < 0 - self.size.y and part.velocity.equals(Vector2.init(0, -1))) {
            part.pos.y = vars.ScreenHeight;
        }

        rl.drawRectangleV(part.pos, self.size, self.color);
        if (part.isHead) self.drawSafeArea();
    }
}

fn drawSafeArea(self: *Player) void {
    const safeArea = self.getSafeAreaLimits()[0];
    rl.drawRectangleLines(@intFromFloat(safeArea.x), @intFromFloat(safeArea.y), @intFromFloat(self.safeAreaSize.x), @intFromFloat(self.safeAreaSize.y), .green);
}

pub fn switchDirection(self: *Player, direction: Direction) void {
    log.info("switch direction to: {s}", .{@tagName(direction)});
    var newV: Vector2 = undefined;
    switch (direction) {
        .up => {
            newV = Vector2.init(0, -1);
        },
        .down => {
            newV = Vector2.init(0, 1);
        },
        .left => {
            newV = Vector2.init(-1, 0);
        },
        .right => {
            newV = Vector2.init(1, 0);
        },
    }

    for (self.body.items) |*part| {
        if (!part.isHead) {
            part.oldVelocity = part.velocity;
            part.turnPoint = part.pos;
        }

        part.velocity = newV;
    }
}

pub fn getSafeAreaLimits(self: *Player) [2]Vector2 {
    const head = self.body.items[0];
    if (!head.isHead) @panic("player head is not present or in the wrong place");

    const x1: f32 = @max(0, (head.pos.x + self.size.x / 2) - (self.safeAreaSize.x / 2));
    const y1: f32 = @max(0, (head.pos.y + self.size.y / 2) - (self.safeAreaSize.y / 2));

    const x2: f32 = @min(vars.ScreenWidth, (head.pos.x + self.size.x / 2) + (self.safeAreaSize.x / 2));
    const y2: f32 = @min(vars.ScreenHeight, (head.pos.y + self.size.y / 2) + (self.safeAreaSize.y / 2));

    return [2]Vector2{
        .init(x1, y1),
        .init(x2, y2),
    };
}

test "player init" {
    const allocator = std.testing.allocator;
    var sut = try init(allocator);
    defer sut.deinit();

    try testing.expect(sut.body.items.len == 1);
    try testing.expect(sut.body.items[0].isHead == true);
}

test "switch direction success" {
    const allocator = std.testing.allocator;
    var sut = try init(allocator);
    defer sut.deinit();

    try testing.expectEqual(Vector2.init(0, 0), sut.body.items[0].velocity);

    try sut.body.append(allocator, Part{ .pos = .init(0, 0) });

    sut.switchDirection(.up);
    try testing.expectEqual(Vector2.init(0, -1), sut.body.items[0].velocity);
    try testing.expectEqual(null, sut.body.items[0].oldVelocity);
    try testing.expectEqual(Vector2.init(0, -1), sut.body.items[1].velocity);
    try testing.expectEqual(Vector2.init(0, 0), sut.body.items[1].oldVelocity);

    sut.switchDirection(.left);
    try testing.expectEqual(Vector2.init(-1, 0), sut.body.items[0].velocity);
    try testing.expectEqual(null, sut.body.items[0].oldVelocity);
    try testing.expectEqual(Vector2.init(-1, 0), sut.body.items[1].velocity);
    try testing.expectEqual(Vector2.init(0, -1), sut.body.items[1].oldVelocity);
}

test "get safe area limits" {
    const allocator = std.testing.allocator;
    var sut = try init(allocator);
    defer sut.deinit();

    try testing.expect(sut.body.items.len == 1);
    try testing.expect(sut.body.items[0].isHead == true);

    var head = sut.body.items[0];
    try testing.expectEqual(Vector2.init(384, 184), head.pos);
    try testing.expectEqual(Vector2.init(150, 100), sut.safeAreaSize);

    {
        const safeArea = sut.getSafeAreaLimits();
        try testing.expect(safeArea.len == 2);

        try testing.expectEqual(Vector2.init(325, 150), safeArea[0]);
        try testing.expectEqual(Vector2.init(475, 250), safeArea[1]);
    }

    {
        sut.body.items[0].pos = .init(0, 0);
        head = sut.body.items[0];

        const safeArea = sut.getSafeAreaLimits();
        try testing.expect(safeArea.len == 2);

        try testing.expectEqual(Vector2.init(0, 0), safeArea[0]);
        try testing.expectEqual(Vector2.init(91, 66), safeArea[1]);
    }

    {
        sut.body.items[0].pos = .init(vars.ScreenWidth, vars.ScreenHeight);
        head = sut.body.items[0];

        const safeArea = sut.getSafeAreaLimits();
        try testing.expect(safeArea.len == 2);

        try testing.expectEqual(Vector2.init(741, 366), safeArea[0]);
        try testing.expectEqual(Vector2.init(vars.ScreenWidth, vars.ScreenHeight), safeArea[1]);
    }

    {
        sut.body.items[0].pos = .init(37, 276);
        head = sut.body.items[0];

        const safeArea = sut.getSafeAreaLimits();
        try testing.expect(safeArea.len == 2);

        try testing.expectEqual(Vector2.init(0, 242), safeArea[0]);
        try testing.expectEqual(Vector2.init(128, 342), safeArea[1]);
    }
}
