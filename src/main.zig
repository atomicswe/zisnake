const std = @import("std");
const Game = @import("Game.zig");

pub fn main(init: std.process.Init) anyerror!void {
    var source: std.Random.IoSource = .{ .io = init.io };

    var game = try Game.init(source.interface(), init.gpa);
    defer game.deinit();

    game.setup();

    try game.gameLoop();
}

test {
    std.testing.refAllDecls(@import("Game.zig"));
    std.testing.refAllDecls(@import("Player.zig"));
    std.testing.refAllDecls(@import("Apple.zig"));
}
