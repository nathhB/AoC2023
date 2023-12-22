const std = @import("std");
const util = @import("util");

const Direction = enum {
    Up,
    Down,
    Left,
    Right,

    fn toVec2(self: Direction) [2]i32 {
        return switch (self) {
            Direction.Up => [_]i32{ 0, -1 },
            Direction.Down => [_]i32{ 0, 1 },
            Direction.Left => [_]i32{ -1, 0 },
            Direction.Right => [_]i32{ 1, 0 },
        };
    }
};

const TileType = enum { Empty, RightMirror, LeftMirror, HorizontalSplitter, VerticalSplitter };

const Tile = struct { type: TileType, isEnergized: bool, splitCount: i32 };

const Beam = struct {
    x: i32,
    y: i32,
    dir: Direction,

    pub fn create(x: i32, y: i32, dir: Direction) Beam {
        return .{ .x = x, .y = y, .dir = dir };
    }
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const rawMap = try util.readFileLines(allocator);
    defer util.freeFileLines(rawMap, allocator);
    const map = try createMap(rawMap, allocator);
    defer destroyMap(map, allocator);

    var initialBeam = Beam.create(0, 0, Direction.Right);
    const res = updateBeam(map, &initialBeam);

    std.debug.print("Enegized tiles: {}\n", .{res});
}

fn updateBeam(map: [][]Tile, beam: *Beam) i32 {
    var energizedTiles: i32 = 0;

    while (true) {
        const currentTile = &map[@intCast(beam.y)][@intCast(beam.x)];

        if (!currentTile.*.isEnergized) {
            currentTile.*.isEnergized = true;
            energizedTiles += 1;
        }

        if (currentTile.type == TileType.VerticalSplitter and beam.*.dir != Direction.Up and beam.*.dir != Direction.Down) {
            currentTile.*.splitCount += 1;

            energizedTiles += handleVerticalSplitter(map, beam);
            break;
        }

        if (currentTile.type == TileType.HorizontalSplitter and beam.*.dir != Direction.Left and beam.*.dir != Direction.Right) {
            currentTile.*.splitCount += 1;

            energizedTiles += handleHorizontalSplitter(map, beam);
            break;
        }

        if (currentTile.type == TileType.RightMirror) {
            handleRightMirror(beam);
        } else if (currentTile.type == TileType.LeftMirror) {
            handleLeftMirror(beam);
        }

        const vec2 = beam.dir.toVec2();
        const newX = beam.x + vec2[0];
        const newY = beam.y + vec2[1];

        if (newX < 0 or newX > map[0].len - 1 or newY < 0 or newY > map.len - 1) {
            break;
        } else {
            beam.x = newX;
            beam.y = newY;
        }
    }

    return energizedTiles;
}

fn handleVerticalSplitter(map: [][]Tile, beam: *Beam) i32 {
    const tile = map[@intCast(beam.*.y)][@intCast(beam.*.x)];

    if (tile.splitCount >= 4) return 0;

    var energizedTiles: i32 = 0;

    if (beam.*.y > 0) {
        var newBeam = Beam.create(beam.*.x, beam.*.y - 1, Direction.Up);

        energizedTiles += updateBeam(map, &newBeam);
    }

    if (beam.*.y < map.len - 1) {
        var newBeam = Beam.create(beam.*.x, beam.*.y + 1, Direction.Down);

        energizedTiles += updateBeam(map, &newBeam);
    }

    return energizedTiles;
}

fn handleHorizontalSplitter(map: [][]Tile, beam: *Beam) i32 {
    const tile = map[@intCast(beam.*.y)][@intCast(beam.*.x)];

    if (tile.splitCount >= 4) return 0;

    var energizedTiles: i32 = 0;

    if (beam.*.x > 0) {
        var newBeam = Beam.create(beam.*.x - 1, beam.*.y, Direction.Left);

        energizedTiles += updateBeam(map, &newBeam);
    }

    if (beam.*.x < map[0].len - 1) {
        var newBeam = Beam.create(beam.*.x + 1, beam.*.y, Direction.Right);

        energizedTiles += updateBeam(map, &newBeam);
    }

    return energizedTiles;
}

fn handleRightMirror(beam: *Beam) void {
    beam.*.dir = switch (beam.*.dir) {
        Direction.Right => Direction.Up,
        Direction.Left => Direction.Down,
        Direction.Up => Direction.Right,
        Direction.Down => Direction.Left,
    };
}

fn handleLeftMirror(beam: *Beam) void {
    beam.*.dir = switch (beam.*.dir) {
        Direction.Right => Direction.Down,
        Direction.Left => Direction.Up,
        Direction.Up => Direction.Left,
        Direction.Down => Direction.Right,
    };
}

fn createMap(rawMap: [][]const u8, allocator: std.mem.Allocator) ![][]Tile {
    var map = try allocator.alloc([]Tile, rawMap.len);

    for (0..rawMap.len) |y| {
        const width = rawMap[y].len;

        map[y] = try allocator.alloc(Tile, width);

        for (0..width) |x| {
            const tileType = switch (rawMap[y][x]) {
                '.' => TileType.Empty,
                '|' => TileType.VerticalSplitter,
                '-' => TileType.HorizontalSplitter,
                '/' => TileType.RightMirror,
                '\\' => TileType.LeftMirror,
                else => unreachable,
            };

            map[y][x] = .{ .type = tileType, .isEnergized = false, .splitCount = 0 };
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
