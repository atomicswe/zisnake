const std = @import("std");
const rl = @import("raylib");
const Player = @import("Player.zig");
const Apple = @import("Apple.zig");
const log = std.log;

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 800;
    const screenHeight = 450;

    rl.initWindow(screenWidth, screenHeight, "zisnake");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second

    var player = Player.init(screenWidth, screenHeight);
    var apple = Apple.init((screenWidth / 2) + 100, (screenHeight / 2) - 100);
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        if (rl.isKeyPressed(.up)) {
            player.switchDirection(.up);
        }
        if (rl.isKeyPressed(.down)) {
            player.switchDirection(.down);
        }
        if (rl.isKeyPressed(.right)) {
            player.switchDirection(.right);
        }
        if (rl.isKeyPressed(.left)) {
            player.switchDirection(.left);
        }
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.black);

        player.drawPlayer();
        apple.drawApple();

        //----------------------------------------------------------------------------------
    }
}
