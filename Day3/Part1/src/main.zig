const std = @import("std");
const util = @import("util");

const directions = [_][2]i8{ [_]i8{ 0, -1 }, [_]i8{ 1, 0 }, [_]i8{ 0, 1 }, [_]i8{ -1, 0 }, [_]i8{ -1, -1 }, [_]i8{ 1, -1 }, [_]i8{ 1, 1 }, [_]i8{ -1, 1 } };

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const map = try util.readFileLines(allocator);
    defer util.freeFileLines(map, allocator);
    const width = map[0].len - 1;
    const height = map.len - 1;
    var y = @as(i32, @intCast(height));
    var sum: i32 = 0;

    while (y >= 0) {
        var x = @as(i32, @intCast(width));

        while (x >= 0) {
            var currentNumber: i32 = 0;
            var digitCount: i32 = 0;
            var isPartNumber = false;

            while (x >= 0) {
                const c = map[@intCast(y)][@intCast(x)];

                if (c < '0' or c > '9') break;

                currentNumber += (c - '0') * (try std.math.powi(i32, 10, digitCount));
                isPartNumber = isPartNumber or hasAdjacentSymbol(map, x, y);
                digitCount += 1;
                x -= 1;
            }

            if (isPartNumber) sum += currentNumber;

            x -= 1;
        }

        y -= 1;
    }

    std.debug.print("Result: {d}\n", .{sum});
}

fn hasAdjacentSymbol(map: [][]const u8, x: i32, y: i32) bool {
    for (directions) |dir| {
        const sX = x + dir[0];
        const sY = y + dir[1];

        if (sX < 0 or sX >= map[0].len or sY < 0 or sY >= map.len) continue;

        const c = map[@intCast(sY)][@intCast(sX)];

        if ((c < '0' or c > '9') and c != '.') return true;
    }

    return false;
}
