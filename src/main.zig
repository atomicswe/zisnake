const std = @import("std");
const Game = @import("Game.zig");

pub fn main() anyerror!void {
    var game = Game.init();
    defer game.deinit();

    game.setup();

    try game.gameLoop();
}

test {
    std.testing.refAllDecls(@import("Game.zig"));
    std.testing.refAllDecls(@import("Player.zig"));
    std.testing.refAllDecls(@import("Apple.zig"));
}
