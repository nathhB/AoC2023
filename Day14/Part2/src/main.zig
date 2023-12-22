const std = @import("std");
const util = @import("util");

const Tile = enum { Free, BlockingRock, MovingRock };

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const rawMap = try util.readFileLines(allocator);
    defer util.freeFileLines(rawMap, allocator);
    const map = try createMap(rawMap, allocator);
    defer destroyMap(map, allocator);
    const res = try doTiltCyclesUntilRepeated(map);
    const cyclesToPerform = @mod(1_000_000_000 - res.cycle, res.count);

    doTiltCycles(map, cyclesToPerform);

    const load = computeNorthLoad(map);

    std.debug.print("North load: {}\n", .{load});
}

fn computeNorthLoad(map: [][]Tile) u32 {
    const height = map.len;
    var load: u32 = 0;

    for (map, 0..) |line, y| {
        for (line) |tile| {
            if (tile == Tile.MovingRock) {
                load += @as(u32, @intCast(height - y));
            }
        }
    }

    return load;
}

fn doTiltCycles(map: [][]Tile, count: i32) void {
    for (0..@intCast(count)) |_| {
        doTiltCycle(map);
    }
}

fn doTiltCyclesUntilRepeated(map: [][]Tile) !struct { cycle: i32, count: i32 } {
    const allocator = std.heap.page_allocator;
    var previousCycles = std.AutoHashMap(u32, i32).init(allocator);
    defer previousCycles.deinit();

    try previousCycles.put(mapToHash(map), 0);

    var cycleCount: i32 = 0;

    while (true) {
        cycleCount += 1;
        doTiltCycle(map);

        const hash = mapToHash(map);

        if (previousCycles.get(hash)) |prevCycle| {
            return .{ .cycle = prevCycle, .count = cycleCount - prevCycle };
        }

        try previousCycles.put(hash, cycleCount);
    }
}

fn doTiltCycle(map: [][]Tile) void {
    tiltMapNorth(map);
    tiltMapWest(map);
    tiltMapSouth(map);
    tiltMapEast(map);
}

fn tiltMapNorth(map: [][]Tile) void {
    const width = map[0].len;
    const height = map.len;

    for (0..height) |y| {
        for (0..width) |x| {
            if (map[y][x] != Tile.MovingRock) continue;

            var y2 = y;

            while (y2 >= 1 and map[y2 - 1][x] == Tile.Free) : (y2 -= 1) {}
            moveRockToTile(map, x, y, x, y2);
        }
    }
}

fn tiltMapSouth(map: [][]Tile) void {
    const width = map[0].len;
    const height = map.len;
    var y = @as(i32, @intCast(height - 1));

    while (y >= 0) : (y -= 1) {
        for (0..width) |x| {
            if (map[@intCast(y)][x] != Tile.MovingRock) continue;

            var y2 = y;

            while (y2 < height - 1 and map[@intCast(y2 + 1)][x] == Tile.Free) : (y2 += 1) {}
            moveRockToTile(map, x, @intCast(y), x, @intCast(y2));
        }
    }
}

fn tiltMapEast(map: [][]Tile) void {
    const width = map[0].len;
    const height = map.len;

    for (0..height) |y| {
        var x: i32 = @as(i32, @intCast(width - 1));

        while (x >= 0) : (x -= 1) {
            if (map[y][@intCast(x)] != Tile.MovingRock) continue;

            var x2 = x;

            while (x2 < width - 1 and map[y][@intCast(x2 + 1)] == Tile.Free) : (x2 += 1) {}
            moveRockToTile(map, @intCast(x), y, @intCast(x2), y);
        }
    }
}

fn tiltMapWest(map: [][]Tile) void {
    const width = map[0].len;
    const height = map.len;

    for (0..height) |y| {
        for (0..width) |x| {
            if (map[y][x] != Tile.MovingRock) continue;

            var x2 = x;

            while (x2 >= 1 and map[y][x2 - 1] == Tile.Free) : (x2 -= 1) {}
            moveRockToTile(map, x, y, x2, y);
        }
    }
}

fn moveRockToTile(map: [][]Tile, x: usize, y: usize, x2: usize, y2: usize) void {
    map[y][x] = Tile.Free;
    map[y2][x2] = Tile.MovingRock;
}

fn createMap(rawMap: [][]const u8, allocator: std.mem.Allocator) ![][]Tile {
    const map = try allocator.alloc([]Tile, rawMap.len);

    for (0..rawMap.len) |y| {
        map[y] = try allocator.alloc(Tile, rawMap[y].len);

        for (0..rawMap[y].len) |x| {
            map[y][x] = switch (rawMap[y][x]) {
                'O' => Tile.MovingRock,
                '#' => Tile.BlockingRock,
                else => Tile.Free,
            };
        }
    }

    return map;
}

fn destroyMap(map: [][]Tile, allocator: std.mem.Allocator) void {
    for (map) |line| {
        allocator.free(line);
    }

    allocator.free(map);
}

fn mapToHash(map: [][]Tile) u32 {
    var hash: u32 = 19;

    for (map, 0..) |line, y| {
        for (line, 0..) |tile, x| {
            if (tile == Tile.MovingRock) {
                hash = hash *% 19 + @as(u32, @intCast(x));
                hash = hash *% 19 + @as(u32, @intCast(y));
            }
        }
    }

    return hash;
}
