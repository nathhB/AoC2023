const std = @import("std");
const util = @import("util");
const expect = std.testing.expect;

const Lens = struct { label: []const u8, focalLength: u32 = 0 };

const Box = struct {
    lenses: std.ArrayList(Lens),

    pub fn init(allocator: std.mem.Allocator) Box {
        return .{ .lenses = std.ArrayList(Lens).init(allocator) };
    }

    pub fn deinit(self: *Box) void {
        self.lenses.deinit();
    }

    pub fn addLens(self: *Box, newLens: Lens) !void {
        for (self.lenses.items, 0..) |lens, i| {
            if (std.mem.eql(u8, newLens.label, lens.label)) {
                self.lenses.items[i] = newLens;
                return;
            }
        }

        try self.lenses.append(newLens);
    }

    pub fn removeLens(self: *Box, label: []const u8) void {
        for (self.lenses.items, 0..) |lens, i| {
            if (std.mem.eql(u8, label, lens.label)) {
                _ = self.lenses.orderedRemove(i);
                return;
            }
        }
    }
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const lines = try util.readFileLines(allocator);
    defer util.freeFileLines(lines, allocator);
    const parts = try util.splitString(lines[0], ",", allocator);
    defer allocator.free(parts);
    var boxes = std.AutoHashMap(u32, Box).init(allocator);
    defer boxes.deinit();
    var focusingPower: u32 = 0;

    for (parts) |str| {
        try processOperation(str, &boxes, allocator);
    }

    var it = boxes.iterator();

    while (it.next()) |pair| {
        const boxNumber = pair.key_ptr.*;
        const box = pair.value_ptr.*;

        std.debug.print("Box {}\n", .{boxNumber});

        for (box.lenses.items, 0..) |lens, i| {
            focusingPower += (boxNumber + 1) * (@as(u32, @intCast(i)) + 1) * lens.focalLength;
            std.debug.print("Lens {s} {}\n", .{ lens.label, lens.focalLength });
        }
    }

    std.debug.print("Focusing power: {}\n", .{focusingPower});
}

fn processOperation(str: []const u8, boxes: *std.AutoHashMap(u32, Box), allocator: std.mem.Allocator) !void {
    if (std.mem.containsAtLeast(u8, str, 1, "=")) {
        try addLens(str, boxes, allocator);
    } else if (std.mem.containsAtLeast(u8, str, 1, "-")) {
        try removeLens(str, boxes, allocator);
    } else {
        unreachable;
    }
}

fn addLens(str: []const u8, boxes: *std.AutoHashMap(u32, Box), allocator: std.mem.Allocator) !void {
    const parts = try util.splitString(str, "=", allocator);
    defer allocator.free(parts);
    const label = parts[0];
    const focalLength = try std.fmt.parseInt(u32, parts[1], 10);
    const boxNumber = computeHash(label);
    var boxEntry = try boxes.*.getOrPut(boxNumber);

    if (!boxEntry.found_existing) {
        boxEntry.value_ptr.* = Box.init(allocator);
    }

    try boxEntry.value_ptr.*.addLens(.{ .label = label, .focalLength = focalLength });

    std.debug.print("Add lens {s} to box {d}\n", .{ label, boxNumber });
}

fn removeLens(str: []const u8, boxes: *std.AutoHashMap(u32, Box), allocator: std.mem.Allocator) !void {
    const parts = try util.splitString(str, "-", allocator);
    defer allocator.free(parts);
    const label = parts[0];
    const boxNumber = computeHash(label);
    var boxEntry = try boxes.*.getOrPut(boxNumber);

    if (!boxEntry.found_existing) {
        boxEntry.value_ptr.* = Box.init(allocator);
    }

    boxEntry.value_ptr.*.removeLens(label);

    std.debug.print("Remove lens {s} from box {d}\n", .{ label, boxNumber });
}

fn computeHash(str: []const u8) u32 {
    var hash: u32 = 0;

    for (str) |c| {
        hash += @intCast(c);
        hash *= 17;
        hash %= 256;
    }

    return hash;
}

test {
    const allocator = std.testing.allocator;
    var box = Box.init(allocator);
    defer box.deinit();

    try box.addLens(.{ .label = "qm", .focalLength = 42 });
    try box.addLens(.{ .label = "ot", .focalLength = 10 });
    try box.addLens(.{ .label = "qb", .focalLength = 22 });

    try expect(std.mem.eql(u8, box.lenses.items[0].label, "qm"));
    try expect(std.mem.eql(u8, box.lenses.items[1].label, "ot"));
    try expect(std.mem.eql(u8, box.lenses.items[2].label, "qb"));
    try expect(box.lenses.items[1].focalLength == 10);

    try box.addLens(.{ .label = "ot", .focalLength = 150 });

    try expect(std.mem.eql(u8, box.lenses.items[1].label, "ot"));
    try expect(box.lenses.items[1].focalLength == 150);

    box.removeLens("qm");

    try expect(box.lenses.items.len == 2);
    try expect(std.mem.eql(u8, box.lenses.items[0].label, "ot"));
    try expect(std.mem.eql(u8, box.lenses.items[1].label, "qb"));

    box.removeLens("qb");

    try expect(box.lenses.items.len == 1);
    try expect(std.mem.eql(u8, box.lenses.items[0].label, "ot"));

    box.removeLens("pp");
}
