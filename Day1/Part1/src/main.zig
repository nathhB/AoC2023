const std = @import("std");
const util = @import("util");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const lines = try util.readFileLines(allocator);
    defer util.freeFileLines(lines, allocator);
    var total: i32 = 0;

    for (lines) |line| {
        var firstDigit: ?u8 = null;
        var lastDigit: u8 = undefined;

        for (line) |c| {
            if (c >= '0' and c <= '9') {
                if (firstDigit == null) {
                    firstDigit = c;
                }

                lastDigit = c;
            }
        }

        var number = (firstDigit.? - '0') * 10 + (lastDigit - '0');

        total += number;
    }

    std.debug.print("Result: {d}\n", .{total});
}
