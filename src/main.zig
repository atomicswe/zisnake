const std = @import("std");
const rl = @import("raylib");
const Game = @import("Game.zig");
const log = std.log;

pub fn main() anyerror!void {
    var game = Game.init();
    defer game.deinit();

    try game.gameLoop();
}

test {
    std.testing.refAllDecls(@import("Game.zig"));
    std.testing.refAllDecls(@import("Player.zig"));
    std.testing.refAllDecls(@import("Apple.zig"));
}
