const std = @import("std");
const util = @import("util");

const Vec2 = struct {
    x: i32,
    y: i32,

    pub fn make(x: i32, y: i32) Vec2 {
        return .{ .x = x, .y = y };
    }

    pub fn add(self: Vec2, other: Vec2) Vec2 {
        return .{ .x = self.x + other.x, .y = self.y + other.y };
    }
};

const Start = struct { pos: Vec2, dir: Direction };

const Direction = enum {
    Up,
    Down,
    Left,
    Right,

    fn toVec2(self: Direction) Vec2 {
        return switch (self) {
            Direction.Up => Vec2.make(0, -1),
            Direction.Down => Vec2.make(0, 1),
            Direction.Left => Vec2.make(-1, 0),
            Direction.Right => Vec2.make(1, 0),
        };
    }
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const map = try util.readFileLines(allocator);
    defer util.freeFileLines(map, allocator);

    const start = findLoopStart(map);
    const steps = @divTrunc(walkMap(map, start.pos, start.dir), 2);
    std.debug.print("Steps: {}\n", .{steps});
}

fn walkMap(map: [][]const u8, currentPos: Vec2, currentDir: Direction) i32 {
    var steps: i32 = 1;

    if (map[@intCast(currentPos.y)][@intCast(currentPos.x)] == 'S') return steps;

    const newDir = getNextDirection(map, currentPos, currentDir).?;

    return steps + walkMap(map, currentPos.add(newDir.toVec2()), newDir);
}

fn findLoopStart(map: [][]const u8) Start {
    for (0..map.len) |y| {
        for (0..map[0].len) |x| {
            if (map[y][x] == 'S') {
                const startPos: Vec2 = .{ .x = @intCast(x), .y = @intCast(y) };

                inline for (std.meta.fields(Direction)) |field| {
                    const dir: Direction = @enumFromInt(field.value);
                    const pos = startPos.add(dir.toVec2());

                    if (getNextDirection(map, pos, dir)) |_| return .{ .pos = pos, .dir = dir };
                }
            }
        }
    }

    unreachable;
}

fn getNextDirection(map: [][]const u8, pos: Vec2, currentDir: Direction) ?Direction {
    return switch (map[@intCast(pos.y)][@intCast(pos.x)]) {
        'L' => {
            return switch (currentDir) {
                Direction.Left => Direction.Up,
                Direction.Down => Direction.Right,
                else => null,
            };
        },
        'J' => {
            return switch (currentDir) {
                Direction.Right => Direction.Up,
                Direction.Down => Direction.Left,
                else => null,
            };
        },
        '7' => {
            return switch (currentDir) {
                Direction.Right => Direction.Down,
                Direction.Up => Direction.Left,
                else => null,
            };
        },
        'F' => {
            return switch (currentDir) {
                Direction.Left => Direction.Down,
                Direction.Up => Direction.Right,
                else => null,
            };
        },
        '-' => {
            return switch (currentDir) {
                Direction.Left, Direction.Right => currentDir,
                else => null,
            };
        },
        '|' => {
            return switch (currentDir) {
                Direction.Up, Direction.Down => currentDir,
                else => null,
            };
        },
        '.' => null,
        else => currentDir,
    };
}
