const std = @import("std");
const util = @import("util");

const Card = struct { matches: i32, copies: i32 };

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const lines = try util.readFileLines(allocator);
    defer util.freeFileLines(lines, allocator);
    var cardList = std.ArrayList(*Card).init(allocator);
    defer freeCardList(cardList, allocator);

    for (lines) |line| {
        const parts = try util.splitString(line, ": ", allocator);
        defer allocator.free(parts);
        const numbers = try util.splitString(parts[1], "|", allocator);
        defer allocator.free(numbers);
        const winningNumbers = numbers[0];
        const myNumbers = numbers[1];
        var card = try buildCard(winningNumbers, myNumbers, allocator);

        try cardList.append(card);
    }

    var totalCards: i32 = 0;

    for (cardList.items, 0..) |card, i| {
        totalCards += card.copies;

        for (0..@intCast(card.copies)) |_| {
            for (0..@intCast(card.matches)) |m| {
                cardList.items[@intCast(i + m + 1)].*.copies += 1;
            }
        }
    }

    std.debug.print("Result: {d}\n", .{totalCards});
}

fn buildCard(winningNumbersStr: []const u8, myNumbersStr: []const u8, allocator: std.mem.Allocator) !*Card {
    const winningList = try buildNumberList(winningNumbersStr, std.heap.page_allocator);
    defer winningList.deinit();
    const myList = try buildNumberList(myNumbersStr, std.heap.page_allocator);
    defer myList.deinit();

    var card = try allocator.create(Card);

    card.* = .{ .matches = computeCardMatches(winningList, myList), .copies = 1 };

    return card;
}

fn computeCardMatches(winningList: std.ArrayList([]const u8), myList: std.ArrayList([]const u8)) i32 {
    var matches: i32 = 0;

    for (myList.items) |n| {
        for (winningList.items) |wn| {
            if (std.mem.eql(u8, n, wn)) {
                matches += 1;
                break;
            }
        }
    }

    return matches;
}

fn buildNumberList(numbersStr: []const u8, allocator: std.mem.Allocator) !std.ArrayList([]const u8) {
    var list = std.ArrayList([]const u8).init(allocator);
    var iter = std.mem.split(u8, numbersStr, " ");

    while (iter.next()) |n| {
        if (n.len == 0) continue;

        try list.append(n);
    }

    return list;
}

fn freeCardList(list: std.ArrayList(*Card), allocator: std.mem.Allocator) void {
    for (list.items) |card| {
        allocator.destroy(card);
    }

    list.deinit();
}
