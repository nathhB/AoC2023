const std = @import("std");
const util = @import("util");

const Map = struct { srcStart: i64, destStart: i64, range: i64 };

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const lines = try util.readFileLines(allocator);
    defer util.freeFileLines(lines, allocator);

    var seeds = try parseSeeds(lines[0], allocator);
    defer seeds.deinit();

    var seedToSoil = try buildMaps(lines, "seed-to-soil", allocator);
    defer seedToSoil.deinit();

    var soilToFert = try buildMaps(lines, "soil-to-fertilizer", allocator);
    defer soilToFert.deinit();

    var fertToWater = try buildMaps(lines, "fertilizer-to-water", allocator);
    defer fertToWater.deinit();

    var waterToLight = try buildMaps(lines, "water-to-light", allocator);
    defer waterToLight.deinit();

    var lightToTemp = try buildMaps(lines, "light-to-temperature", allocator);
    defer lightToTemp.deinit();

    var tempToHumidity = try buildMaps(lines, "temperature-to-humidity", allocator);
    defer tempToHumidity.deinit();

    var humidityToLoc = try buildMaps(lines, "humidity-to-location", allocator);
    defer humidityToLoc.deinit();

    var minLoc: i64 = std.math.maxInt(i64);

    for (seeds.items) |seed| {
        const soil = getMapping(seed, seedToSoil);
        const fert = getMapping(soil, soilToFert);
        const water = getMapping(fert, fertToWater);
        const light = getMapping(water, waterToLight);
        const temp = getMapping(light, lightToTemp);
        const humidity = getMapping(temp, tempToHumidity);
        const loc = getMapping(humidity, humidityToLoc);

        if (loc < minLoc) minLoc = loc;
    }

    std.debug.print("Result: {d}\n", .{minLoc});
}

fn getMapping(value: i64, maps: std.ArrayList(Map)) i64 {
    for (maps.items) |map| {
        if (value >= map.srcStart and value < map.srcStart + map.range) {
            return map.destStart + (value - map.srcStart);
        }
    }

    return value;
}

fn buildMaps(lines: [][]const u8, name: []const u8, allocator: std.mem.Allocator) !std.ArrayList(Map) {
    var maps = std.ArrayList(Map).init(allocator);

    for (lines, 0..) |line, i| {
        if (std.mem.startsWith(u8, line, name)) {
            for (lines[(i + 1)..]) |line2| {
                if (line2.len == 0) break;

                const parts = try util.splitString(line2, " ", allocator);
                defer allocator.free(parts);
                var destStart = try std.fmt.parseInt(i64, parts[0], 10);
                var srcStart = try std.fmt.parseInt(i64, parts[1], 10);
                var range = try std.fmt.parseInt(i64, parts[2], 10);

                try maps.append((Map){ .destStart = destStart, .srcStart = srcStart, .range = range });
            }
        }
    }

    return maps;
}

fn parseSeeds(line: []const u8, allocator: std.mem.Allocator) !std.ArrayList(i64) {
    var list = std.ArrayList(i64).init(allocator);
    var parts = try util.splitString(line, "seeds: ", allocator);
    defer allocator.free(parts);
    var iter = std.mem.split(u8, parts[1], " ");

    while (iter.next()) |seed| {
        try list.append(try std.fmt.parseInt(i64, seed, 10));
    }

    return list;
}
