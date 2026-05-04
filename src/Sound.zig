const std = @import("std");
const Allocator = std.mem.Allocator;

const rl = @import("raylib");
const Wave = rl.Wave;

const log = std.log.scoped(.sound);

const Sound = @This();

sounds: std.StringHashMap(rl.Sound),

pub fn init(allocator: Allocator) Sound {
    return .{ .sounds = .init(allocator) };
}

pub fn deinit(self: *Sound) void {
    var it = self.sounds.valueIterator();
    while (it.next()) |sound| {
        rl.unloadSound(sound.*);
    }

    self.sounds.deinit();
}

pub fn loadSound(self: *Sound, fileName: [:0]const u8, name: []const u8) !void {
    const newWave: Wave = try rl.loadWave(fileName);
    defer rl.unloadWave(newWave);

    if (!rl.isWaveValid(newWave)) {
        log.err("the wave '{s}' is not valid, not adding it to the sounds map", .{name});
        return;
    }

    const newSound = rl.loadSoundFromWave(newWave);
    try self.sounds.put(name, newSound);
    log.info("successfully loaded the sound '{s}'", .{name});
}

pub fn playSound(self: *Sound, name: []const u8) void {
    const sound = self.sounds.get(name);
    if (sound == null) {
        log.err("the sound '{s}' does not exist or hasn't been loaded", .{name});
        return;
    }

    rl.playSound(sound.?);
    log.info("sound '{s}' played successfully", .{name});
}
