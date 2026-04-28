const std = @import("std");
const rl = @import("raylib");
const Player = @import("Player.zig");
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
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        if (rl.isKeyPressed(.up)) {
            try player.switchDirection(.up);
        }
        if (rl.isKeyPressed(.down)) {
            try player.switchDirection(.down);
        }
        if (rl.isKeyPressed(.right)) {
            try player.switchDirection(.right);
        }
        if (rl.isKeyPressed(.left)) {
            try player.switchDirection(.left);
        }
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.black);

        try player.drawPlayer();

        //----------------------------------------------------------------------------------
    }
}
