const std = @import("std");
const rl = @import("raylib");
const log = std.log;

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 800;
    const screenHeight = 450;

    rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - basic window");
    defer rl.closeWindow(); // Close window and OpenGL context

    var recPos = rl.Vector2.init(screenWidth / 2, screenHeight / 2);
    const recSize = rl.Vector2.init(50, 50);

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        if (rl.isKeyDown(.right)) {
            recPos.x += 2.0;
        }
        if (rl.isKeyDown(.left)) {
            recPos.x -= 2.0;
        }
        if (rl.isKeyDown(.up)) {
            recPos.y -= 2.0;
        }
        if (rl.isKeyDown(.down)) {
            recPos.y += 2.0;
        }
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);

        rl.drawText("Congrats! You created your first window!", 190, 200, 20, .light_gray);

        rl.drawRectangleV(recPos, recSize, .maroon);
        //----------------------------------------------------------------------------------
    }
}
