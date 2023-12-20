const std = @import("std");
const util = @import("util");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const lines = try util.readFileLines(allocator);
    defer util.freeFileLines(lines, allocator);
    var sumHashes: u32 = 0;
    const parts = try util.splitString(lines[0], ",", allocator);
    defer allocator.free(parts);

    for (parts) |str| {
        const hash = computeHash(str);

        sumHashes += hash;
    }

    std.debug.print("{}\n", .{sumHashes});
}

fn computeHash(str: []const u8) u32 {
    var hash: u32 = 0;

    for (str) |c| {
        hash += @intCast(c);
        hash *= 17;
        hash %= 256;
    }

    return hash;
}
