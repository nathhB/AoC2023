const std = @import("std");
const util = @import("util");

const Direction = enum { Left, Right };
const Node = struct { name: []const u8, left: ?*Node, right: ?*Node };
const Graph = std.StringHashMap(*Node);

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const lines = try util.readFileLines(allocator);
    defer util.freeFileLines(lines, allocator);
    const directions = try parseDirections(lines[0], allocator);
    defer allocator.free(directions);
    var nodes = try buildGraph(lines[2..], allocator);
    defer nodes.deinit();
    // TODO: free tree

    const steps = walkGraph(nodes.get("AAA").?, directions);

    std.debug.print("Result: {}\n", .{steps});
}

fn parseDirections(str: []const u8, allocator: std.mem.Allocator) ![]Direction {
    var directions = try allocator.alloc(Direction, str.len);

    for (str, 0..) |c, i| {
        directions[i] = switch (c) {
            'L' => Direction.Left,
            'R' => Direction.Right,
            else => unreachable,
        };
    }

    return directions;
}

fn walkGraph(root: *Node, directions: []Direction) i32 {
    var current = root;
    var steps: usize = 0;

    while (true) {
        const dir = directions[steps % directions.len];
        current = switch (dir) {
            Direction.Left => current.*.left.?,
            Direction.Right => current.*.right.?,
        };

        steps += 1;

        if (std.mem.eql(u8, current.*.name, "ZZZ")) break;
    }

    return @intCast(steps);
}

fn buildGraph(lines: [][]const u8, allocator: std.mem.Allocator) !Graph {
    var nodes = Graph.init(allocator);

    for (lines) |line| {
        const parts = try util.splitString(line, " = ", allocator);
        defer allocator.free(parts);
        const nodeName = parts[0];
        const children = parts[1];
        const childrenParts = try util.splitString(children[1..(children.len - 1)], ", ", allocator);
        defer allocator.free(childrenParts);
        const leftNodeName = childrenParts[0];
        const rightNodeName = childrenParts[1];
        const node = try getOrCreateNode(nodeName, &nodes, allocator);

        node.*.left = try getOrCreateNode(leftNodeName, &nodes, allocator);
        node.*.right = try getOrCreateNode(rightNodeName, &nodes, allocator);
    }

    return nodes;
}

fn getOrCreateNode(name: []const u8, nodes: *Graph, allocator: std.mem.Allocator) !*Node {
    var entry = try nodes.*.getOrPut(name);

    if (entry.found_existing) {
        return entry.value_ptr.*;
    }

    var node = try allocator.create(Node);

    node.* = .{ .name = name, .left = null, .right = null };
    try nodes.*.put(name, node);

    return node;
}
