const std = @import("std");
const util = @import("util");

const Race = struct { time: i32, distance: i32 };

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const lines = try util.readFileLines(allocator);
    defer util.freeFileLines(lines, allocator);
    const races = try parseRaces(lines, allocator);
    defer races.deinit();

    var result: i32 = 0;

    for (races.items) |race| {
        var ways: i32 = 0;

        for (0..@intCast(race.time)) |pressTime| {
            const speed: i32 = @intCast(pressTime);
            const remainingTime = race.time - @as(i32, @intCast(pressTime));
            const distance = speed * remainingTime;

            if (distance > race.distance) ways += 1;
        }

        result = if (result == 0) ways else result * ways;
    }

    std.debug.print("Result: {d}\n", .{result});
}

fn parseRaces(lines: [][]const u8, allocator: std.mem.Allocator) !std.ArrayList(Race) {
    var races = std.ArrayList(Race).init(allocator);
    errdefer races.deinit();

    const timeParts = try util.splitString(lines[0], "Time: ", allocator);
    defer allocator.free(timeParts);

    const distanceParts = try util.splitString(lines[1], "Distance: ", allocator);
    defer allocator.free(distanceParts);

    const times = timeParts[1];
    var iter = std.mem.split(u8, times, " ");

    while (iter.next()) |n| {
        const time = std.fmt.parseInt(i32, n, 10) catch continue;

        try races.append(.{ .time = time, .distance = 0 });
    }

    const distances = distanceParts[1];
    iter = std.mem.split(u8, distances, " ");
    var i: i32 = 0;

    while (iter.next()) |n| {
        const distance = std.fmt.parseInt(i32, n, 10) catch continue;

        races.items[@intCast(i)].distance = distance;
        i += 1;
    }

    return races;
}
