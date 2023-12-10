const std = @import("std");
const util = @import("util");
const expect = std.testing.expect;
const assert = @import("std").debug.assert;

const HandType = enum { FiveOfKind, FourOfKind, FullHouse, ThreeOfKind, TwoPairs, OnePair, HighCard };
const Hand = struct { cards: [5]u8, bid: i32, type: HandType };
const allCards = [_]u8{ '2', '3', '4', '5', '6', '7', '8', '9', 'T', 'J', 'Q', 'K', 'A' };

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const lines = try util.readFileLines(allocator);
    defer util.freeFileLines(lines, allocator);
    const hands = try parseHands(lines, allocator);
    defer hands.deinit();

    std.sort.pdq(Hand, hands.items, {}, cmpHand);

    var sum: i32 = 0;

    for (hands.items, 1..) |hand, rank| {
        sum += hand.bid * @as(i32, @intCast(rank));
    }

    std.debug.print("Result: {d}\n", .{sum});
}

fn cmpHand(context: void, a: Hand, b: Hand) bool {
    _ = context;
    const scoreA = @intFromEnum(a.type);
    const scoreB = @intFromEnum(b.type);

    if (scoreA != scoreB) {
        return scoreA > scoreB;
    }

    for (0..5) |i| {
        const rankA = getCardRank(a.cards[i]);
        const rankB = getCardRank(b.cards[i]);

        if (rankA == rankB) continue;

        return rankA < rankB;
    }

    return false;
}

fn getCardRank(card: u8) i32 {
    return @as(i32, @intCast(std.mem.indexOf(u8, &allCards, &[1]u8{card}).?));
}

fn parseHands(lines: [][]const u8, allocator: std.mem.Allocator) !std.ArrayList(Hand) {
    var hands = std.ArrayList(Hand).init(allocator);

    for (lines) |line| {
        const parts = try util.splitString(line, " ", allocator);
        defer allocator.free(parts);

        var cards: [5]u8 = undefined;

        std.mem.copyForwards(u8, &cards, parts[0]);

        var hand: Hand = .{ .cards = cards, .bid = try std.fmt.parseInt(i32, parts[1], 10), .type = try getHandType(&cards, allocator) };

        try hands.append(hand);
    }

    return hands;
}

fn getHandType(cards: []u8, allocator: std.mem.Allocator) !HandType {
    var map = std.AutoHashMap(u8, i32).init(allocator);
    defer map.deinit();

    var maxIdenticalCards: i32 = 0;

    for (cards) |card| {
        const entry = try map.getOrPut(card);

        if (entry.found_existing) {
            entry.value_ptr.* += 1;

            if (entry.value_ptr.* > maxIdenticalCards) maxIdenticalCards = entry.value_ptr.*;
        } else {
            entry.value_ptr.* = 1;
        }
    }

    return switch (maxIdenticalCards) {
        5 => HandType.FiveOfKind,
        4 => HandType.FourOfKind,
        3 => blk: {
            break :blk if (map.count() == 2) HandType.FullHouse else HandType.ThreeOfKind;
        },
        2 => blk: {
            break :blk if (map.count() == 3) HandType.TwoPairs else HandType.OnePair;
        },
        else => HandType.HighCard,
    };
}
