const std = @import("std");
const util = @import("util");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const lines = try util.readFileLines(allocator);
    defer util.freeFileLines(lines, allocator);
    var sum: i32 = 0;

    for (lines) |line| {
        const history = try parseHistory(line, allocator);
        defer allocator.free(history);

        sum += try extrapolateHistory(history, allocator);
    }

    std.debug.print("Result: {}\n", .{sum});
}

fn parseHistory(line: []const u8, allocator: std.mem.Allocator) ![]i32 {
    const numbers = try util.splitString(line, " ", allocator);
    defer allocator.free(numbers);
    var history = try allocator.alloc(i32, numbers.len);

    for (numbers, 0..) |n, i| {
        history[i] = try std.fmt.parseInt(i32, n, 10);
    }

    return history;
}

fn extrapolateHistory(seq: []i32, allocator: std.mem.Allocator) !i32 {
    var newSeq = try allocator.alloc(i32, seq.len - 1);
    defer allocator.free(newSeq);

    var i: usize = 0;
    var allZeroes = true;

    while (i < seq.len - 1) {
        const diff = seq[i + 1] - seq[i];
        newSeq[i] = diff;
        if (diff != 0) allZeroes = false;
        i += 1;
    }

    return if (allZeroes) seq[0] else seq[0] - try extrapolateHistory(newSeq, allocator);
}

fn printSequence(seq: []i32) void {
    for (seq) |v| {
        std.debug.print("{} ", .{v});
    }

    std.debug.print("\n", .{});
}
