const std = @import("std");
const util = @import("util");

const Game = struct { id: i32, isValid: bool };

const maxRed = 12;
const maxBlue = 14;
const maxGreen = 13;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const lines = try util.readFileLines(allocator);
    defer util.freeFileLines(lines, allocator);
    var sumIds: i32 = 0;

    for (lines) |line| {
        if (try parseGame(line)) |gameId| {
            sumIds += gameId;
        }
    }

    std.debug.print("Result: {d}\n", .{sumIds});
}

pub fn parseGame(line: []const u8) !?i32 {
    const allocator = std.heap.page_allocator;
    const gameAndSets = try util.splitString(line, ": ", allocator);
    defer allocator.free(gameAndSets);
    const gameAndId = try util.splitString(gameAndSets[0], " ", allocator);
    defer allocator.free(gameAndId);
    const gameId = try std.fmt.parseInt(i32, gameAndId[1], 10);
    const gameSets = try util.splitString(gameAndSets[1], "; ", allocator);
    defer allocator.free(gameSets);

    for (gameSets) |set| {
        const cubes = try util.splitString(set, ", ", allocator);
        defer allocator.free(cubes);

        for (cubes) |cubesParts| {
            const countAndColor = try util.splitString(cubesParts, " ", allocator);
            defer allocator.free(countAndColor);
            var count = try std.fmt.parseInt(i32, countAndColor[0], 10);
            var color = countAndColor[1];

            if (std.mem.eql(u8, color, "red")) {
                if (count > maxRed) {
                    return undefined;
                }
            } else if (std.mem.eql(u8, color, "blue")) {
                if (count > maxBlue) {
                    return undefined;
                }
            } else if (std.mem.eql(u8, color, "green")) {
                if (count > maxGreen) {
                    return undefined;
                }
            }
        }
    }

    return gameId;
}
