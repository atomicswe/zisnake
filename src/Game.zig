const std = @import("std");
const rl = @import("raylib");
const log = std.log;

const Apple = @import("Apple.zig");
const Player = @import("Player.zig");

const Game = @This();

const ScreenWidth = 800;
const ScreenHeight = 450;

player: Player,
apple: ?Apple = null,
points: i32 = 0,

pub fn init() Game {
    rl.initWindow(ScreenWidth, ScreenHeight, "zisnake");
    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second

    const p = Player.init(ScreenWidth, ScreenHeight);
    const a = Apple.init(300, 50);

    return .{ .player = p, .apple = a };
}

pub fn deinit(_: *Game) void {
    rl.closeWindow(); // Close window and OpenGL context
}

pub fn gameLoop(self: *Game) !void {
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------

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
        } else {
            self.apple = Apple.init(self.player.pos.x + 200, self.player.pos.y - 100);
        }
        //----------------------------------------------------------------------------------
    }
}

pub fn detectCollision(self: *Game) bool {
    const player: Player = self.player;
    const apple: Apple = self.apple orelse return false;

    // TODO: currently these collisions are testing for lines
    // so, for example, if the apple is on x=100, y=2 and the player
    // is on x = 300, y=2 it will trigger a collision

    {
        // if player.top == apple.bottom -> collision
        const appleBottom = apple.center.add(.init(0, -apple.radius));
        if (appleBottom.y == player.pos.y) {
            log.info("collision (player.top == apple.bottom) detected at x: {d}, y: {d}", .{ appleBottom.x, player.pos.y });
            return true;
        }
    }

    {
        // if player.bottom == apple.top -> collision
        const appleTop = apple.center.add(.init(0, apple.radius));
        if (appleTop.y == (player.pos.y + player.size.y)) {
            log.info("collision (player.bottom == apple.top) detected at x: {d}, y: {d}", .{ appleTop.x, player.pos.y });
            return true;
        }
    }

    {
        // if player.left == apple.right -> collision
        const appleRight = apple.center.add(.init(apple.radius, 0));
        if (appleRight.x == player.pos.x) {
            log.info("collision (player.left == apple.right) detected at x: {d}, y: {d}", .{ player.pos.x, appleRight.y });
            return true;
        }
    }

    {
        // if player.right == apple.left -> collision
        const appleLeft = apple.center.add(.init(-apple.radius, 0));
        if (appleLeft.x == (player.pos.x + player.size.x)) {
            log.info("collision (player.right == apple.left) detected at x: {d}, y: {d}", .{ player.pos.x, appleLeft.y });
            return true;
        }
    }

    return false;
}
