const std = @import("std");
const util = @import("util");

const CubeColor = enum { Red, Blue, Green };

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const lines = try util.readFileLines(allocator);
    defer allocator.free(lines);
    var sumPowers: i32 = 0;

    for (lines) |line| {
        var minCubes = [3]i32{ 0, 0, 0 };

        try parseGame(line, &minCubes);
        sumPowers += minCubes[@intFromEnum(CubeColor.Red)] * minCubes[@intFromEnum(CubeColor.Blue)] * minCubes[@intFromEnum(CubeColor.Green)];
    }

    std.debug.print("Result: {d}\n", .{sumPowers});
}

pub fn parseGame(line: []const u8, minCubes: []i32) !void {
    const allocator = std.heap.page_allocator;
    const gameAndSets = try util.splitString(line, ": ", allocator);
    defer allocator.free(gameAndSets);
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
                if (count > minCubes[@intFromEnum(CubeColor.Red)]) {
                    minCubes[@intFromEnum(CubeColor.Red)] = count;
                }
            } else if (std.mem.eql(u8, color, "blue")) {
                if (count > minCubes[@intFromEnum(CubeColor.Blue)]) {
                    minCubes[@intFromEnum(CubeColor.Blue)] = count;
                }
            } else if (std.mem.eql(u8, color, "green")) {
                if (count > minCubes[@intFromEnum(CubeColor.Green)]) {
                    minCubes[@intFromEnum(CubeColor.Green)] = count;
                }
            }
        }
    }
}
