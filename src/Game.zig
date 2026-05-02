const std = @import("std");
const testing = std.testing;
const Random = std.Random;
const math = std.math;

const rl = @import("raylib");

const Apple = @import("Apple.zig");
const Player = @import("Player.zig");
const vars = @import("vars.zig");

const log = std.log.scoped(.game);
const Game = @This();

player: Player,
apple: ?Apple = null,
points: i32 = 0,
rand: Random,

pub fn init(rand: Random, allocator: std.mem.Allocator) !Game {
    const p = try Player.init(allocator);

    return .{ .player = p, .rand = rand };
}

pub fn setup(_: *Game) void {
    rl.initWindow(vars.ScreenWidth, vars.ScreenHeight, "zisnake");
    rl.setTargetFPS(60);
}

pub fn deinit(self: *Game) void {
    self.player.deinit();
    rl.closeWindow();
}

pub fn gameLoop(self: *Game) !void {
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        if (self.apple == null) {
            log.info("creating new apple", .{});
            self.apple = self.spawnApple();
        }

        if (self.detectCollision()) {
            self.points += 1;
            self.apple = null;
            log.info("player received +1 points. Current points: {d}", .{self.points});
            try self.player.addPartToBody();
        }

        try self.handleKeyPressed();
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.black);

        self.player.drawPlayer();
        if (self.apple != null) {
            self.apple.?.drawApple();
        }
        //----------------------------------------------------------------------------------
    }
}

fn handleKeyPressed(self: *Game) !void {
    switch (rl.getKeyPressed()) {
        .up => try self.player.switchDirection(.up),
        .down => try self.player.switchDirection(.down),
        .left => try self.player.switchDirection(.left),
        .right => try self.player.switchDirection(.right),
        else => return,
    }
}

fn distance(p1: rl.Vector2, p2: rl.Vector2) f32 {
    const hor = p2.x - p1.x;
    const ver = p2.y - p1.y;
    const squareSum = math.exp2(hor) + math.exp2(ver);
    return math.sqrt(squareSum);
}

/// Spawns an apple randomly on the screen, outside the player's safe area.
/// If the player is centered, on both horizontal and vertical, or in just one,
/// we randomly choose between one of the options in each axis.
///
/// I.e.: If the player is centered horizontally, we randomly choose whether to put
/// the apple on the right or on the left side of the screen.
fn spawnApple(self: *Game) Apple {
    const safeAreaLimits = self.player.getSafeAreaLimits();

    var xMin: i32 = 0;
    var xMax: i32 = vars.ScreenWidth;
    var yMin: i32 = 0;
    var yMax: i32 = vars.ScreenHeight;

    const left = distance(rl.Vector2.init(0, safeAreaLimits[0].y), safeAreaLimits[0]);
    const right = distance(safeAreaLimits[1], rl.Vector2.init(vars.ScreenWidth, safeAreaLimits[1].y));
    if (left == right) {
        const p = self.rand.float(f32);
        xMin = if (p >= 0.5) @intFromFloat(safeAreaLimits[1].x) else xMin;
        xMax = if (p < 0.5) @intFromFloat(safeAreaLimits[0].x) else xMax;
    } else if (left > right) {
        xMax = @intFromFloat(safeAreaLimits[0].x);
    } else {
        xMin = @intFromFloat(safeAreaLimits[1].x);
    }

    const top = distance(rl.Vector2.init(safeAreaLimits[0].x, 0), safeAreaLimits[0]);
    const bottom = distance(safeAreaLimits[1], rl.Vector2.init(safeAreaLimits[1].x, vars.ScreenHeight));
    if (top == bottom) {
        const p = self.rand.float(f32);
        yMin = if (p >= 0.5) @intFromFloat(safeAreaLimits[1].y) else yMin;
        yMax = if (p < 0.5) @intFromFloat(safeAreaLimits[0].y) else yMax;
    } else if (top > bottom) {
        yMax = @intFromFloat(safeAreaLimits[0].y);
    } else {
        yMin = @intFromFloat(safeAreaLimits[1].y);
    }

    const x: f32 = @floatFromInt(self.rand.intRangeAtMost(i32, xMin, xMax));
    const y: f32 = @floatFromInt(self.rand.intRangeAtMost(i32, yMin, yMax));

    log.info("spawning apple at x: {d:.2}, y: {d:.2}", .{ x, y });
    return Apple.init(x, y);
}

fn detectCollision(self: *Game) bool {
    const player: Player = self.player;
    const apple: Apple = self.apple orelse return false;

    {
        // if player.top == apple.bottom -> collision
        const appleBottom = apple.center.add(.init(0, apple.radius));
        if (appleBottom.y == player.body.items[0].pos.y and (appleBottom.x >= player.body.items[0].pos.x and appleBottom.x <= player.body.items[0].pos.x + player.size.x)) {
            log.info("collision (player.top == apple.bottom) detected at x: {d}, y: {d}", .{ appleBottom.x, player.body.items[0].pos.y });
            return true;
        }
    }

    {
        // if player.bottom == apple.top -> collision
        const appleTop = apple.center.add(.init(0, -apple.radius));
        if (appleTop.y == (player.body.items[0].pos.y + player.size.y) and (appleTop.x >= player.body.items[0].pos.x and appleTop.x <= player.body.items[0].pos.x + player.size.x)) {
            log.info("collision (player.bottom == apple.top) detected at x: {d}, y: {d}", .{ appleTop.x, player.body.items[0].pos.y });
            return true;
        }
    }

    {
        // if player.left == apple.right -> collision
        const appleRight = apple.center.add(.init(apple.radius, 0));
        if (appleRight.x == player.body.items[0].pos.x and (appleRight.y >= player.body.items[0].pos.y and appleRight.y <= player.body.items[0].pos.y + player.size.y)) {
            log.info("collision (player.left == apple.right) detected at x: {d}, y: {d}", .{ player.body.items[0].pos.x, appleRight.y });
            return true;
        }
    }

    {
        // if player.right == apple.left -> collision
        const appleLeft = apple.center.add(.init(-apple.radius, 0));
        if (appleLeft.x == (player.body.items[0].pos.x + player.size.x) and (appleLeft.y >= player.body.items[0].pos.y and appleLeft.y <= player.body.items[0].pos.y + player.size.y)) {
            log.info("collision (player.right == apple.left) detected at x: {d}, y: {d}", .{ player.body.items[0].pos.x, appleLeft.y });
            return true;
        }
    }

    return false;
}

test "collisions" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    const rng_impl: std.Random.IoSource = .{ .io = io };

    var sut = try Game.init(rng_impl.interface(), allocator);
    defer sut.player.deinit();

    try testing.expectEqual(0, sut.points);
    try testing.expectEqual(384, sut.player.body.items[0].pos.x);
    try testing.expectEqual(184, sut.player.body.items[0].pos.y);

    sut.apple = Apple.init(0, 0);

    {
        // if player.top == apple.bottom -> collision
        // player -> 384, 184, player.top -> y=184
        // apple -> 384, 176, apple.bottom -> y=184
        sut.apple = Apple.init(384, 184 - sut.apple.?.radius);
        try testing.expectEqual(true, sut.detectCollision());

        // player -> 384, 184, player.top -> y=184
        // apple -> 416, 176, apple.bottom -> y=184
        sut.apple = Apple.init(384 + sut.player.size.x, 184 - sut.apple.?.radius);
        try testing.expectEqual(true, sut.detectCollision());

        // player -> 384, 184, player.top -> y=184
        // apple -> 400, 176, apple.bottom -> y=184
        sut.apple = Apple.init(384 + (sut.player.size.x / 2), 184 - sut.apple.?.radius);
        try testing.expectEqual(true, sut.detectCollision());
    }

    {
        // if player.bottom == apple.top -> collision
        // player -> 384, 184, player.bottom -> y=216
        // apple -> 384, 224, apple.top -> y=216
        sut.apple = Apple.init(384, 184 + (sut.player.size.y + sut.apple.?.radius));
        try testing.expectEqual(true, sut.detectCollision());

        // player -> 384, 184, player.bottom -> y=216
        // apple -> 416, 224, apple.top -> y=216
        sut.apple = Apple.init(384 + sut.player.size.x, 184 + (sut.player.size.y + sut.apple.?.radius));
        try testing.expectEqual(true, sut.detectCollision());

        // player -> 384, 184, player.bottom -> y=216
        // apple -> 400, 224, apple.top -> y=216
        sut.apple = Apple.init(384 + (sut.player.size.x / 2), 184 + (sut.player.size.y + sut.apple.?.radius));
        try testing.expectEqual(true, sut.detectCollision());
    }

    {
        // if player.left == apple.right -> collision
        // player -> 384, 184, player.left -> x=384
        // apple -> 376, 184, apple.right -> x=384
        sut.apple = Apple.init(384 - sut.apple.?.radius, 184);
        try testing.expectEqual(true, sut.detectCollision());

        // player -> 384, 184, player.left -> x=384
        // apple -> 376, 216, apple.right -> x=384
        sut.apple = Apple.init(384 - sut.apple.?.radius, 184 + sut.player.size.y);
        try testing.expectEqual(true, sut.detectCollision());

        // player -> 384, 184, player.left -> x=384
        // apple -> 376, 200, apple.right -> x=384
        sut.apple = Apple.init(384 - sut.apple.?.radius, 184 + (sut.player.size.y / 2));
        try testing.expectEqual(true, sut.detectCollision());
    }

    {
        // if player.right == apple.left -> collision
        // player -> 384, 184, player.right -> x=416
        // apple -> 424, 184, apple.left -> x=416
        sut.apple = Apple.init(384 + (sut.player.size.x + sut.apple.?.radius), 184);
        try testing.expectEqual(true, sut.detectCollision());

        // player -> 384, 184, player.right -> x=416
        // apple -> 424, 216, apple.left -> x=416
        sut.apple = Apple.init(384 + (sut.player.size.x + sut.apple.?.radius), 184 + sut.player.size.y);
        try testing.expectEqual(true, sut.detectCollision());

        // player -> 384, 184, player.right -> x=216
        // apple -> 424, 200, apple.left -> x=216
        sut.apple = Apple.init(384 + (sut.player.size.x + sut.apple.?.radius), 184 + (sut.player.size.y / 2));
        try testing.expectEqual(true, sut.detectCollision());
    }
}
