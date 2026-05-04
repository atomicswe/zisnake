const std = @import("std");
const testing = std.testing;
const Random = std.Random;
const math = std.math;

const rl = @import("raylib");
const Vector2 = rl.Vector2;

const Apple = @import("Apple.zig");
const Part = @import("Part.zig");
const Player = @import("Player.zig");
const Sound = @import("Sound.zig");
const vars = @import("vars.zig");

const log = std.log.scoped(.game);
const Game = @This();

player: Player,
apple: ?Apple = null,
points: i32 = 0,
gameOver: bool = false,
sound: Sound,
rand: Random,

pub fn init(rand: Random, allocator: std.mem.Allocator) !Game {
    const p = try Player.init(allocator);
    const sound = Sound.init(allocator);

    return .{ .player = p, .sound = sound, .rand = rand };
}

pub fn setup(self: *Game) !void {
    rl.initWindow(vars.ScreenWidth, vars.ScreenHeight, "zisnake");
    rl.setTargetFPS(60);
    rl.initAudioDevice();

    try self.sound.loadSound("assets/pickup.wav", "pickup");
    try self.sound.loadSound("assets/gameover.wav", "gameover");
}

pub fn deinit(self: *Game) void {
    self.player.deinit();
    self.sound.deinit();
    rl.closeAudioDevice();
    rl.closeWindow();
}

fn restartGame(self: *Game) !void {
    const allocator = self.player.allocator;
    self.player.deinit();
    self.player = try Player.init(allocator);
    self.apple = null;
    self.points = 0;
    self.gameOver = false;
}

pub fn gameLoop(self: *Game) !void {
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        if (self.gameOver) {
            if (rl.isKeyPressed(.r)) {
                log.info("restarting game...", .{});
                try self.restartGame();
                continue;
            }

            rl.beginDrawing();
            defer rl.endDrawing();

            try self.drawGameOver();
            continue;
        }

        if (self.player.detectHeadCollision()) {
            log.info("collision detected between head and body part", .{});
            log.info("GAME OVER", .{});
            self.gameOver = true;
            self.sound.playSound("gameover");
            continue;
        }

        if (self.apple == null) {
            log.info("creating new apple", .{});
            self.apple = self.spawnApple();
        }

        if (self.detectCollision()) {
            self.points += 1;
            self.apple = null;
            self.sound.playSound("pickup");
            log.info("player received +1 points. Current points: {d}", .{self.points});
            try self.player.addPartToBody();
        }

        try self.handleKeyPressed();

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.black);

        self.player.drawPlayer();
        if (self.apple != null) {
            self.apple.?.drawApple();
        }

        try self.drawUI();
    }
}

fn drawUI(self: *Game) !void {
    var pointsTextBuf: [256]u8 = undefined;
    const pointsText = try std.fmt.bufPrintSentinel(&pointsTextBuf, "Points: {d}", .{self.points}, 0);
    rl.drawText(pointsText, 12, 12, 32, .white);
}

fn drawGameOver(self: *Game) !void {
    rl.clearBackground(.black);
    const fontSize: i32 = 64;
    const gameOverText: [:0]const u8 = "GAME OVER!";
    const textWidth = rl.measureText(gameOverText, fontSize);
    const size = Vector2.init(@floatFromInt(textWidth), fontSize);

    const textX: i32 = @trunc((vars.ScreenWidth - size.x) / 2);
    const textY: i32 = @trunc((vars.ScreenHeight - size.y) / 2 - (size.y));
    rl.drawText(gameOverText, textX, textY, fontSize, .red);

    const pointsTextFontSize: i32 = fontSize / 2;
    var pointsTextBuf: [256]u8 = undefined;
    const pointsText = try std.fmt.bufPrintSentinel(&pointsTextBuf, "You made {d} points!", .{self.points}, 0);
    const pointsTextWidth = rl.measureText(pointsText, pointsTextFontSize);
    const pointsTextSize = Vector2.init(@floatFromInt(pointsTextWidth), pointsTextFontSize);

    const pointsTextX: i32 = @trunc((vars.ScreenWidth - pointsTextSize.x) / 2);
    const pointsTextY: i32 = @trunc((vars.ScreenHeight - pointsTextSize.y) / 2);
    rl.drawText(pointsText, pointsTextX, pointsTextY, pointsTextFontSize, .green);

    const restartFontSize: i32 = fontSize / 2;
    const restartGameText: [:0]const u8 = "Press R to restart the game";
    const restartTextWidth = rl.measureText(restartGameText, restartFontSize);
    const restartSize = Vector2.init(@floatFromInt(restartTextWidth), restartFontSize);

    const restartTextX: i32 = @trunc((vars.ScreenWidth - restartSize.x) / 2);
    const restartTextY: i32 = @trunc((vars.ScreenHeight - restartSize.y) / 2 + (size.y));
    rl.drawText(restartGameText, restartTextX, restartTextY, restartFontSize, .white);
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

fn distance(p1: Vector2, p2: Vector2) f32 {
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

    const left = distance(Vector2.init(0, safeAreaLimits[0].y), safeAreaLimits[0]);
    const right = distance(safeAreaLimits[1], Vector2.init(vars.ScreenWidth, safeAreaLimits[1].y));
    if (left == right) {
        const p = self.rand.float(f32);
        xMin = if (p >= 0.5) @trunc(safeAreaLimits[1].x) else xMin;
        xMax = if (p < 0.5) @trunc(safeAreaLimits[0].x) else xMax;
    } else if (left > right) {
        xMax = @trunc(safeAreaLimits[0].x);
    } else {
        xMin = @trunc(safeAreaLimits[1].x);
    }

    const top = distance(Vector2.init(safeAreaLimits[0].x, 0), safeAreaLimits[0]);
    const bottom = distance(safeAreaLimits[1], Vector2.init(safeAreaLimits[1].x, vars.ScreenHeight));
    if (top == bottom) {
        const p = self.rand.float(f32);
        yMin = if (p >= 0.5) @trunc(safeAreaLimits[1].y) else yMin;
        yMax = if (p < 0.5) @trunc(safeAreaLimits[0].y) else yMax;
    } else if (top > bottom) {
        yMax = @trunc(safeAreaLimits[0].y);
    } else {
        yMin = @trunc(safeAreaLimits[1].y);
    }

    const x: f32 = @floatFromInt(self.rand.intRangeAtMost(i32, xMin, xMax));
    const y: f32 = @floatFromInt(self.rand.intRangeAtMost(i32, yMin, yMax));

    log.info("spawning apple at x: {d:.2}, y: {d:.2}", .{ x, y });
    return Apple.init(x, y);
}

fn detectCollision(self: *Game) bool {
    const playerHead: Part = self.player.body.items[0];
    if (!playerHead.isHead) @panic("head is not head");

    var apple: Apple = self.apple orelse return false;
    const appleLimits = apple.getLimits();

    const headMin = playerHead.pos;
    const headMax = playerHead.pos.add(self.player.size);

    for (appleLimits) |limit| {
        const hor = limit.x >= headMin.x and limit.x <= headMax.x;
        const ver = limit.y >= headMin.y and limit.y <= headMax.y;
        if (hor and ver) {
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
