const std = @import("std");
const testing = std.testing;
const ArrayList = std.ArrayList;
const Deque = std.Deque;
const Allocator = std.mem.Allocator;
const Part = @import("Part.zig");

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

const PlayerSize: f32 = 32;

body: ArrayList(Part),
size: Vector2 = Vector2.init(PlayerSize, PlayerSize),
color: Color,
safeAreaSize: Vector2 = Vector2.init(150, 100), // area where enemies (apples) can not spawn in around the player
allocator: Allocator,

pub fn init(allocator: Allocator) !Player {
    var body: ArrayList(Part) = .empty;

    const pos = Vector2.init((vars.ScreenWidth / 2 - PlayerSize / 2), (vars.ScreenHeight / 2) - (PlayerSize / 2));
    const head = Part{ .pos = pos, .isHead = true, .memories = .empty };
    try body.append(allocator, head);

    return .{ .body = body, .color = .maroon, .allocator = allocator };
}

pub fn deinit(self: *Player) void {
    for (self.body.items) |*part| {
        part.deinit(self.allocator);
    }
    self.body.deinit(self.allocator);
}

pub fn drawPlayer(self: *Player) void {
    for (self.body.items) |*part| {
        part.movePart(self.*.size);

        rl.drawRectangleV(part.pos, self.size, self.color);
        if (part.isHead) self.drawSafeArea();
    }
}

fn drawSafeArea(self: *Player) void {
    const safeArea = self.getSafeAreaLimits()[0];
    rl.drawRectangleLines(@intFromFloat(safeArea.x), @intFromFloat(safeArea.y), @intFromFloat(self.safeAreaSize.x), @intFromFloat(self.safeAreaSize.y), .green);
}

pub fn addPartToBody(self: *Player) !void {
    if (self.body.items.len < 1) @panic("body has less than one part");
    const last = self.body.getLast();

    const invV = last.velocity.scale(-1);
    const v = invV.multiply(self.size);
    const newPos = last.pos.add(v);

    var clonedMemories = try copyMemories(self.allocator, &last.memories);
    errdefer clonedMemories.deinit(self.allocator);

    const newPart = Part{ .pos = newPos, .velocity = last.velocity, .memories = clonedMemories };
    try self.body.append(self.allocator, newPart);
}

fn copyMemories(allocator: Allocator, memories: *const Deque(Part.Memory)) !Deque(Part.Memory) {
    var clone: Deque(Part.Memory) = .empty;

    var it = memories.iterator();
    while (it.next()) |memory| {
        try clone.pushBack(allocator, memory);
    }

    return clone;
}

pub fn switchDirection(self: *Player, direction: Direction) !void {
    var newV: Vector2 = undefined;
    switch (direction) {
        .up => newV = .init(0, -1),
        .down => newV = .init(0, 1),
        .left => newV = .init(-1, 0),
        .right => newV = .init(1, 0),
    }

    const head = &self.body.items[0];
    if (self.body.items.len > 1 and head.velocity.x == -newV.x and head.velocity.y == -newV.y) {
        return;
    }
    log.info("switch direction to: {s}", .{@tagName(direction)});

    const turnPoint = head.pos;
    const oldV = head.velocity;

    head.velocity = newV;
    for (self.body.items[1..]) |*part| {
        try part.memories.pushBack(self.allocator, .{
            .turnPoint = turnPoint,
            .oldVelocity = oldV,
            .newVelocity = newV,
        });
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

test "switch direction" {
    const allocator = std.testing.allocator;
    var sut = try init(allocator);
    defer sut.deinit();

    try testing.expectEqual(Vector2.init(0, 0), sut.body.items[0].velocity);

    try sut.body.append(allocator, Part.init(.init(0, 0), .init(0, 0), .empty));

    try sut.switchDirection(.up);
    try testing.expectEqual(Vector2.init(0, -1), sut.body.items[0].velocity);
    try testing.expect(sut.body.items[0].memories.len == 0);
    try testing.expectEqual(Vector2.init(0, 0), sut.body.items[1].memories.front().?.oldVelocity);
    try testing.expectEqual(Vector2.init(0, -1), sut.body.items[1].memories.front().?.newVelocity);

    // temporary, to emulate a move
    _ = sut.body.items[1].memories.popFront();

    try sut.switchDirection(.left);
    try testing.expectEqual(Vector2.init(-1, 0), sut.body.items[0].velocity);
    try testing.expect(sut.body.items[0].memories.len == 0);
    try testing.expectEqual(Vector2.init(0, -1), sut.body.items[1].memories.front().?.oldVelocity);
    try testing.expectEqual(Vector2.init(-1, 0), sut.body.items[1].memories.front().?.newVelocity);
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

test "add part to body" {
    const allocator = std.testing.allocator;
    var sut = try init(allocator);
    defer sut.deinit();

    try testing.expect(sut.body.items.len == 1);
    try testing.expect(sut.body.items[0].isHead == true);

    {
        sut.body.items[0].pos = .init(0, 0);
        sut.body.items[0].velocity = .init(-1, 0);

        try sut.addPartToBody();
        try testing.expect(sut.body.items.len == 2);
        try testing.expect(sut.body.items[1].isHead == false);
        try testing.expectEqual(Vector2.init(32, 0), sut.body.items[1].pos);
    }
}
