const std = @import("std");
const util = @import("util");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const map = try util.readFileLines(allocator);
    defer util.freeFileLines(map, allocator);
    const load = tiltNorth(map);

    std.debug.print("Load: {}\n", .{load});
}

fn tiltNorth(map: [][]const u8) i32 {
    const width = map[0].len;
    const height = map.len;
    var load: i32 = 0;

    for (map, 0..height) |row, y| {
        for (row, 0..width) |rock, x| {
            if (rock == 'O') {
                var y2 = y;
                var toto: usize = 0;

                while (y2 >= 1) {
                    if (map[y2 - 1][x] == '#') break;
                    if (map[y2 - 1][x] == 'O') toto += 1;

                    y2 -= 1;
                }

                const rockLoad = height - (y2 + toto);

                load += @intCast(rockLoad);
            }
        }
    }

    return load;
}

fn printMap(map: [][]const u8) void {
    for (map) |row| {
        for (row) |rock| {
            std.debug.print("{c}", .{rock});
        }

        std.debug.print("\n", .{});
    }
}
