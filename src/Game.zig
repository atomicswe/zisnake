const std = @import("std");
const testing = std.testing;

const rl = @import("raylib");

const Apple = @import("Apple.zig");
const Player = @import("Player.zig");
const vars = @import("vars.zig");

const log = std.log.scoped(.game);
const Game = @This();

player: Player,
apple: ?Apple = null,
points: i32 = 0,

pub fn init() Game {
    const p = Player.init(vars.ScreenWidth, vars.ScreenHeight);
    const a = Apple.init(300, 50);

    return .{ .player = p, .apple = a };
}

pub fn setup(_: *Game) void {
    rl.initWindow(vars.ScreenWidth, vars.ScreenHeight, "zisnake");
    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
}

pub fn deinit(_: *Game) void {
    rl.closeWindow(); // Close window and OpenGL context
}

pub fn gameLoop(self: *Game) !void {
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        if (self.apple == null) {
            log.info("creating new apple", .{});
            self.apple = Apple.init(self.player.pos.x + 200, self.player.pos.y - 100);
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

pub fn detectCollision(self: *Game) bool {
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
    var sut = Game.init();
    try testing.expectEqual(0, sut.points);

    sut.player = Player.init(400, 400); // player is at ScreenWidth/2, ScreenHeight/2 so, 200, 200
    try testing.expectEqual(200, sut.player.pos.x);
    try testing.expectEqual(200, sut.player.pos.y);

    {
        // if player.top == apple.bottom -> collision
        // player -> 200, 200, player.top -> y=200
        // apple -> 200, 192, apple.bottom -> y=200
        sut.apple = Apple.init(200, 200 - sut.apple.?.radius);
        try testing.expectEqual(true, sut.detectCollision());

        // player -> 200, 200, player.top -> y=200
        // apple -> 232, 192, apple.bottom -> y=200
        sut.apple = Apple.init(200 + sut.player.size.x, 200 - sut.apple.?.radius);
        try testing.expectEqual(true, sut.detectCollision());

        // player -> 200, 200, player.top -> y=200
        // apple -> 216, 192, apple.bottom -> y=200
        sut.apple = Apple.init(200 + (sut.player.size.x / 2), 200 - sut.apple.?.radius);
        try testing.expectEqual(true, sut.detectCollision());
    }

    {
        // if player.bottom == apple.top -> collision
        // player -> 200, 200, player.bottom -> y=232
        // apple -> 200, 240, apple.top -> y=232
        sut.apple = Apple.init(200, 200 + (sut.player.size.y + sut.apple.?.radius));
        try testing.expectEqual(true, sut.detectCollision());

        // player -> 200, 200, player.bottom -> y=232
        // apple -> 216, 240, apple.top -> y=232
        sut.apple = Apple.init(200 + sut.player.size.x, 200 + (sut.player.size.y + sut.apple.?.radius));
        try testing.expectEqual(true, sut.detectCollision());

        // player -> 200, 200, player.bottom -> y=232
        // apple -> 232, 240, apple.top -> y=232
        sut.apple = Apple.init(200 + (sut.player.size.x / 2), 200 + (sut.player.size.y + sut.apple.?.radius));
        try testing.expectEqual(true, sut.detectCollision());
    }

    {
        // if player.left == apple.right -> collision
        // player -> 200, 200, player.left -> x=200
        // apple -> 192, 200, apple.right -> x=200
        sut.apple = Apple.init(200 - sut.apple.?.radius, 200);
        try testing.expectEqual(true, sut.detectCollision());

        // player -> 200, 200, player.left -> x=200
        // apple -> 192, 232, apple.right -> x=200
        sut.apple = Apple.init(200 - sut.apple.?.radius, 200 + sut.player.size.y);
        try testing.expectEqual(true, sut.detectCollision());

        // player -> 200, 200, player.left -> x=200
        // apple -> 192, 216, apple.right -> x=200
        sut.apple = Apple.init(200 - sut.apple.?.radius, 200 + (sut.player.size.y / 2));
        try testing.expectEqual(true, sut.detectCollision());
    }

    {
        // if player.right == apple.left -> collision
        // player -> 200, 200, player.right -> x=232
        // apple -> 240, 200, apple.left -> x=232
        sut.apple = Apple.init(200 + (sut.player.size.x + sut.apple.?.radius), 200);
        try testing.expectEqual(true, sut.detectCollision());

        // player -> 200, 200, player.right -> x=232
        // apple -> 240, 232, apple.left -> x=232
        sut.apple = Apple.init(200 + (sut.player.size.x + sut.apple.?.radius), 200 + sut.player.size.y);
        try testing.expectEqual(true, sut.detectCollision());

        // player -> 200, 200, player.right -> x=232
        // apple -> 240, 216, apple.left -> x=232
        sut.apple = Apple.init(200 + (sut.player.size.x + sut.apple.?.radius), 200 + (sut.player.size.y / 2));
        try testing.expectEqual(true, sut.detectCollision());
    }
}
