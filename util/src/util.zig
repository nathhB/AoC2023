const std = @import("std");
const expect = std.testing.expect;

pub fn readFileLines(allocator: std.mem.Allocator) ![][]const u8 {
    var file = try std.fs.cwd().openFile("data", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [32000]u8 = undefined;
    var lineList = std.ArrayList([]const u8).init(allocator);
    defer lineList.deinit();

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        try lineList.append(try allocator.dupe(u8, line));
    }

    const lines = try allocator.alloc([]const u8, lineList.items.len);

    for (lineList.items, 0..) |line, i| {
        lines[i] = line;
    }

    return lines;
}

pub fn freeFileLines(lines: [][]const u8, allocator: std.mem.Allocator) void {
    for (lines) |line| allocator.free(line);

    allocator.free(lines);
}

pub fn splitString(line: []const u8, delim: []const u8, allocator: std.mem.Allocator) ![][]const u8 {
    var iter = std.mem.split(u8, line, delim);
    var list = std.ArrayList([]const u8).init(allocator);
    defer list.deinit();

    while (iter.next()) |subStr| try list.append(subStr);

    const subStrs = try allocator.alloc([]const u8, list.items.len);

    for (list.items, 0..) |subStr, i| {
        subStrs[i] = subStr;
    }

    return subStrs;
}

pub fn removeCharactersFromString(str: []const u8, rmChar: u8, allocator: std.mem.Allocator) ![]u8 {
    const resSize = str.len - std.mem.count(u8, str, &[1]u8{rmChar});
    var resStr = try allocator.alloc(u8, resSize);
    var i: i32 = 0;

    for (str) |char| {
        if (char != rmChar) {
            resStr[@intCast(i)] = char;
            i += 1;
        }
    }

    return resStr;
}

test "readFileLines" {
    const lines = try readFileLines(std.testing.allocator);
    defer freeFileLines(lines, std.testing.allocator);

    try expect(std.mem.eql(u8, lines[0], "foo"));
    try expect(std.mem.eql(u8, lines[1], "bar"));
    try expect(std.mem.eql(u8, lines[2], "plop"));
}

test "splitString" {
    const subStrs = try splitString("foo bar plop", " ", std.testing.allocator);
    defer std.testing.allocator.free(subStrs);

    try expect(std.mem.eql(u8, subStrs[0], "foo"));
    try expect(std.mem.eql(u8, subStrs[1], "bar"));
    try expect(std.mem.eql(u8, subStrs[2], "plop"));
}

test "removeCharactersFromString" {
    const str = "foo bar plop";
    const resStr = try removeCharactersFromString(str, ' ', std.testing.allocator);
    defer std.testing.allocator.free(resStr);

    try expect(std.mem.eql(u8, resStr, "foobarplop"));
}
