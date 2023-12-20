const std = @import("std");
const util = @import("util");
const expect = std.testing.expect;
const epsilon = 1e-5;

const Vec2 = struct {
    x: f32,
    y: f32,

    pub fn make(x: f32, y: f32) Vec2 {
        return .{ .x = x, .y = y };
    }

    pub fn add(self: Vec2, other: Vec2) Vec2 {
        return .{ .x = self.x + other.x, .y = self.y + other.y };
    }
};

const Line = struct {
    start: Vec2,
    end: Vec2,

    pub fn intersects(self: *const Line, other: Line) bool {
        return intersectsOnX(self.*, other) and intersectsOnY(self.*, other);
    }

    pub fn isPointOnLine(self: *const Line, point: Vec2) bool {
        return self.intersects(.{ .start = point, .end = point });
    }

    pub fn isVertical(self: *const Line) bool {
        return self.start.x == self.end.x;
    }

    fn intersectsOnX(l1: Line, l2: Line) bool {
        var self_start_x = @min(l1.start.x, l1.end.x);
        var self_end_x = @max(l1.start.x, l1.end.x);
        var other_start_x = @min(l2.start.x, l2.end.x);
        var other_end_x = @max(l2.start.x, l2.end.x);

        return (self_start_x >= other_start_x and self_start_x <= other_end_x) or
            (other_start_x >= self_start_x and other_start_x <= self_end_x);
    }

    fn intersectsOnY(l1: Line, l2: Line) bool {
        var self_start_y = @min(l1.start.y, l1.end.y);
        var self_end_y = @max(l1.start.y, l1.end.y);
        var other_start_y = @min(l2.start.y, l2.end.y);
        var other_end_y = @max(l2.start.y, l2.end.y);

        return (self_start_y >= other_start_y and self_start_y <= other_end_y) or
            (other_start_y >= self_start_y and other_start_y <= self_end_y);
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
    const edges = try getLoopEdges(map, start.pos, start.dir, allocator);
    defer edges.deinit();
    const res = countPointsInsideLoop(map, edges);

    std.debug.print("Result: {}\n", .{res});
}

fn countPointsInsideLoop(map: [][]const u8, edges: std.ArrayList(Line)) i32 {
    var count: i32 = 0;

    for (map, 0..) |line, y| {
        for (line, 0..) |_, x| {
            const point = Vec2.make(@floatFromInt(x), @floatFromInt(y));

            if (isPointOnTheLoop(point, edges)) continue;
            if (isPointInTheLoop(point, edges)) count += 1;
        }
    }

    return count;
}

fn isPointInTheLoop(pos: Vec2, edges: std.ArrayList(Line)) bool {
    const ray: Line = .{ .start = Vec2.make(pos.x, pos.y + epsilon), .end = Vec2.make(999, pos.y + epsilon) };
    var intersectionCount: i32 = 0;

    for (edges.items) |e| {
        if (e.isVertical() and ray.intersects(e)) {
            intersectionCount += 1;
        }
    }

    return @mod(intersectionCount, 2) != 0;
}

fn isPointOnTheLoop(pos: Vec2, edges: std.ArrayList(Line)) bool {
    for (edges.items) |e| {
        if (e.isPointOnLine(pos)) return true;
    }

    return false;
}

fn getLoopEdges(map: [][]const u8, startPos: Vec2, startDir: Direction, allocator: std.mem.Allocator) !std.ArrayList(Line) {
    var currentPos = startPos;
    var currentDir = startDir;
    var prevChangeDirPos = startPos;
    var edges = std.ArrayList(Line).init(allocator);

    while (true) {
        if (getNextDirection(map, currentPos, currentDir)) |dir| {
            if (dir != currentDir) {
                try edges.append(.{ .start = prevChangeDirPos, .end = currentPos });
                prevChangeDirPos = currentPos;
            }

            currentDir = dir;
        }

        currentPos = currentPos.add(currentDir.toVec2());

        if (map[@intFromFloat(currentPos.y)][@intFromFloat(currentPos.x)] == 'S') {
            try edges.append(.{ .start = prevChangeDirPos, .end = currentPos });
            break;
        }
    }

    return edges;
}

fn findLoopStart(map: [][]const u8) Start {
    const height: f32 = @floatFromInt(map.len);
    const width: f32 = @floatFromInt(map[0].len);

    for (0..map.len) |y| {
        for (0..map[0].len) |x| {
            if (map[y][x] == 'S') {
                const startPos: Vec2 = .{ .x = @floatFromInt(x), .y = @floatFromInt(y) };

                inline for (std.meta.fields(Direction)) |field| {
                    const dir: Direction = @enumFromInt(field.value);
                    const pos = startPos.add(dir.toVec2());

                    if (pos.y >= 0 and pos.x >= 0 and pos.y < height and pos.x < width) {
                        if (getNextDirection(map, pos, dir)) |_| return .{ .pos = startPos, .dir = dir };
                    }
                }
            }
        }
    }

    unreachable;
}

fn getNextDirection(map: [][]const u8, pos: Vec2, currentDir: Direction) ?Direction {
    return switch (map[@intFromFloat(pos.y)][@intFromFloat(pos.x)]) {
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
