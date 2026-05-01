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

pub fn init(rand: Random) Game {
    const p = Player.init();

    return .{ .player = p, .rand = rand };
}

pub fn setup(_: *Game) void {
    rl.initWindow(vars.ScreenWidth, vars.ScreenHeight, "zisnake");
    rl.setTargetFPS(60);
}

pub fn deinit(_: *Game) void {
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
            std.log.info("player received +1 points. Current points: {d}", .{self.points});
        }

        if (rl.isKeyPressed(.up)) {
            self.player.switchDirection(.up);
        }
        if (rl.isKeyPressed(.down)) {
            self.player.switchDirection(.down);
        }
        if (rl.isKeyPressed(.right)) {
            self.player.switchDirection(.right);
        }
        if (rl.isKeyPressed(.left)) {
            self.player.switchDirection(.left);
        }
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

fn distance(p1: rl.Vector2, p2: rl.Vector2) f32 {
    const hor = p2.x - p1.x;
    const ver = p2.y - p1.y;
    const squareSum = math.exp2(hor) + math.exp2(ver);
    return math.sqrt(squareSum);
}

fn spawnApple(self: *Game) Apple {
    const safeAreaLimits = self.player.getSafeAreaLimits();

    var xMin: i32 = 0;
    var xMax: i32 = vars.ScreenWidth;
    var yMin: i32 = 0;
    var yMax: i32 = vars.ScreenHeight;

    if (distance(rl.Vector2.init(0, safeAreaLimits[0].y), safeAreaLimits[0]) > distance(safeAreaLimits[1], rl.Vector2.init(vars.ScreenWidth, safeAreaLimits[1].y))) {
        xMax = @intFromFloat(safeAreaLimits[0].x);
    } else {
        xMin = @intFromFloat(safeAreaLimits[1].x);
    }

    if (distance(rl.Vector2.init(safeAreaLimits[0].x, 0), safeAreaLimits[0]) > distance(safeAreaLimits[1], rl.Vector2.init(safeAreaLimits[1].x, vars.ScreenHeight))) {
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
        if (appleBottom.y == player.pos.y and (appleBottom.x >= player.pos.x and appleBottom.x <= player.pos.x + player.size.x)) {
            log.info("collision (player.top == apple.bottom) detected at x: {d}, y: {d}", .{ appleBottom.x, player.pos.y });
            return true;
        }
    }

    {
        // if player.bottom == apple.top -> collision
        const appleTop = apple.center.add(.init(0, -apple.radius));
        if (appleTop.y == (player.pos.y + player.size.y) and (appleTop.x >= player.pos.x and appleTop.x <= player.pos.x + player.size.x)) {
            log.info("collision (player.bottom == apple.top) detected at x: {d}, y: {d}", .{ appleTop.x, player.pos.y });
            return true;
        }
    }

    {
        // if player.left == apple.right -> collision
        const appleRight = apple.center.add(.init(apple.radius, 0));
        if (appleRight.x == player.pos.x and (appleRight.y >= player.pos.y and appleRight.y <= player.pos.y + player.size.y)) {
            log.info("collision (player.left == apple.right) detected at x: {d}, y: {d}", .{ player.pos.x, appleRight.y });
            return true;
        }
    }

    {
        // if player.right == apple.left -> collision
        const appleLeft = apple.center.add(.init(-apple.radius, 0));
        if (appleLeft.x == (player.pos.x + player.size.x) and (appleLeft.y >= player.pos.y and appleLeft.y <= player.pos.y + player.size.y)) {
            log.info("collision (player.right == apple.left) detected at x: {d}, y: {d}", .{ player.pos.x, appleLeft.y });
            return true;
        }
    }

    return false;
}

test "collisions" {
    const io = std.testing.io;
    const rng_impl: std.Random.IoSource = .{ .io = io };

    var sut = Game.init(rng_impl.interface());
    try testing.expectEqual(0, sut.points);

    sut.player = Player.init(); // player is at ScreenWidth/2, ScreenHeight/2 so, 200, 200
    try testing.expectEqual(384, sut.player.pos.x);
    try testing.expectEqual(184, sut.player.pos.y);

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
