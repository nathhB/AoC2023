const std = @import("std");
const util = @import("util");

const digits = [_][]const u8{ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const lines = try util.readFileLines(allocator);
    defer util.freeFileLines(lines, allocator);
    var total: i32 = 0;

    for (lines) |line| {
        var firstDigit: ?u8 = null;
        var lastDigit: u8 = undefined;
        var i: usize = 0;

        while (i < line.len) {
            var digit: ?u8 = readDigitAt(line, i);

            if (digit) |d| {
                if (firstDigit == null) firstDigit = d;
                lastDigit = d;
            }

            i += 1;
        }

        total += firstDigit.? * 10 + lastDigit;
    }

    std.debug.print("Result : {d}\n", .{total});
}

fn readDigitAt(line: []const u8, i: usize) ?u8 {
    var c = line[i];

    if (c >= '0' and c <= '9') {
        return c - '0';
    }

    var d: u8 = 1;

    for (digits) |digit| {
        if (std.mem.indexOf(u8, line[i..], digit) == 0) {
            return d;
        }

        d += 1;
    }

    return undefined;
}
