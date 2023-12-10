const std = @import("std");
const util = @import("util");

const Gear = struct { x: i32, y: i32, gearRatio: i32, adjacentParts: i32 };

const directions = [_][2]i8{ [_]i8{ 0, -1 }, [_]i8{ 1, 0 }, [_]i8{ 0, 1 }, [_]i8{ -1, 0 }, [_]i8{ -1, -1 }, [_]i8{ 1, -1 }, [_]i8{ 1, 1 }, [_]i8{ -1, 1 } };

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const map = try util.readFileLines(allocator);
    defer util.freeFileLines(map, allocator);
    var gearsMap = try buildGearsMap(map, allocator);
    defer gearsMap.deinit();
    var sum: i32 = 0;
    var iterator = gearsMap.iterator();

    while (iterator.next()) |entry| {
        var gear = entry.value_ptr.*;

        if (gear.adjacentParts == 2) sum += gear.gearRatio;
    }

    std.debug.print("Result: {d}\n", .{sum});
}

fn buildGearsMap(map: [][]const u8, allocator: std.mem.Allocator) !std.AutoHashMap(i32, Gear) {
    var gearsMap = std.AutoHashMap(i32, Gear).init(allocator);
    var gearX: i32 = undefined;
    var gearY: i32 = undefined;
    const width = map[0].len - 1;
    const height = map.len - 1;
    var y = @as(i32, @intCast(height));

    while (y >= 0) {
        var x = @as(i32, @intCast(width));

        while (x >= 0) {
            var isPartNumber = false;
            var currentNumber: i32 = 0;
            var digitCount: i32 = 0;

            while (x >= 0) {
                const c = map[@intCast(y)][@intCast(x)];

                if (c < '0' or c > '9') break;

                currentNumber += (c - '0') * (try std.math.powi(i32, 10, digitCount));
                isPartNumber = isPartNumber or hasAdjacentGear(map, x, y, &gearX, &gearY);
                digitCount += 1;
                x -= 1;
            }

            if (isPartNumber) {
                var gearKey = computeGearKey(gearX, gearY);
                var v = try gearsMap.getOrPut(gearKey);

                if (v.found_existing) {
                    v.value_ptr.*.adjacentParts += 1;
                    v.value_ptr.*.gearRatio *= currentNumber;
                } else {
                    try gearsMap.put(gearKey, .{ .x = gearX, .y = gearY, .gearRatio = currentNumber, .adjacentParts = 1 });
                }
            }

            x -= 1;
        }

        y -= 1;
    }

    return gearsMap;
}

fn computeGearKey(x: i32, y: i32) i32 {
    var tmp = (y + @divTrunc(x + 1, 2));

    return x + (tmp * tmp);
}

fn hasAdjacentGear(map: [][]const u8, x: i32, y: i32, gearX: *i32, gearY: *i32) bool {
    for (directions) |dir| {
        const gX = x + dir[0];
        const gY = y + dir[1];

        if (gX < 0 or gX >= map[0].len or gY < 0 or gY >= map.len) continue;

        const c = map[@intCast(gY)][@intCast(gX)];

        if (c == '*') {
            gearX.* = gX;
            gearY.* = gY;

            return true;
        }
    }

    return false;
}
