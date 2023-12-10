const std = @import("std");
const util = @import("util");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const lines = try util.readFileLines(allocator);
    defer util.freeFileLines(lines, allocator);
    var totalPoints: i32 = 0;

    for (lines) |line| {
        const parts = try util.splitString(line, ": ", allocator);
        defer allocator.free(parts);
        const numbers = try util.splitString(parts[1], "|", allocator);
        defer allocator.free(numbers);
        const winningNumbers = numbers[0];
        const myNumbers = numbers[1];
        const winningList = try buildNumberList(winningNumbers, allocator);
        defer winningList.deinit();
        const myList = try buildNumberList(myNumbers, allocator);
        defer myList.deinit();
        var points: i32 = 0;

        for (myList.items) |n| {
            if (isWinningNumber(n, winningList)) {
                points = if (points == 0) 1 else points * 2;
            }
        }

        totalPoints += points;
    }

    std.debug.print("Result: {d}\n", .{totalPoints});
}

fn isWinningNumber(n: []const u8, winningList: std.ArrayList([]const u8)) bool {
    for (winningList.items) |wn| {
        if (std.mem.eql(u8, n, wn)) return true;
    }

    return false;
}

fn buildNumberList(numbersStr: []const u8, allocator: std.mem.Allocator) !std.ArrayList([]const u8) {
    var list = std.ArrayList([]const u8).init(allocator);
    var iter = std.mem.split(u8, numbersStr, " ");

    while (iter.next()) |n| {
        if (n.len == 0) continue;

        try list.append(n);
    }

    return list;
}
