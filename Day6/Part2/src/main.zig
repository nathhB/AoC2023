const std = @import("std");
const util = @import("util");

const Race = struct { time: u64, distance: u64 };

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const lines = try util.readFileLines(allocator);
    defer allocator.free(lines);

    const race = try parseRace(lines, allocator);
    var ways: i32 = 0;

    for (0..@intCast(race.time)) |pressTime| {
        const speed: u64 = @intCast(pressTime);
        const remainingTime = race.time - @as(u64, @intCast(pressTime));
        const distance = speed * remainingTime;

        if (distance > race.distance) ways += 1;
    }

    std.debug.print("Result: {d}\n", .{ways});
}

fn parseRace(lines: [][]const u8, allocator: std.mem.Allocator) !Race {
    const timeParts = try util.splitString(lines[0], "Time: ", allocator);
    defer allocator.free(timeParts);
    const distanceParts = try util.splitString(lines[1], "Distance: ", allocator);
    defer allocator.free(distanceParts);
    const timeStr = try util.removeCharactersFromString(timeParts[1], ' ', allocator);
    defer allocator.free(timeStr);
    const distanceStr = try util.removeCharactersFromString(distanceParts[1], ' ', allocator);
    defer allocator.free(distanceStr);

    return .{ .time = try std.fmt.parseInt(u64, timeStr, 10), .distance = try std.fmt.parseInt(u64, distanceStr, 10) };
}
