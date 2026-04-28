const std = @import("std");
const rl = @import("raylib");

const Apple = @import("Apple.zig");
const Player = @import("Player.zig");

const Game = @This();

const ScreenWidth = 800;
const ScreenHeight = 450;

player: Player,
apple: ?Apple,
points: i32 = 0,

pub fn init() Game {
    rl.initWindow(ScreenWidth, ScreenHeight, "zisnake");
    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second

    const p = Player.init(ScreenWidth, ScreenHeight);

    return .{ .player = p };
}

pub fn deinit(_: *Game) void {
    rl.closeWindow(); // Close window and OpenGL context
}

pub fn gameLoop(self: *Game) !void {
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
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
        } else {}
        //----------------------------------------------------------------------------------
    }
}

// if player.top == apple.bottom -> collision
// if player.bottom == apple.top -> collision
// if player.left == apple.right -> collision
// if player.right == apple.left -> collision
// pub fn detectCollision(self: *Game, player: Player, apple: Apple) bool {}
