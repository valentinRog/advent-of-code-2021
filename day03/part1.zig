const std = @import("std");

fn getBit(l: [][]const u8, i: usize, option: enum { most_common, least_common }) u32 {
    var n: usize = 0;
    for (l) |line| {
        if (line[i] == '1') {
            n += 1;
        }
    }
    return switch (option) {
        .most_common => if (2 * n >= l.len) 1 else 0,
        .least_common => if (2 * n < l.len) 1 else 0,
    };
}

pub fn solve(data: []const u8, alloc: std.mem.Allocator) !void {
    var l = std.ArrayList([]const u8).init(alloc);
    defer l.deinit();
    {
        var it = std.mem.tokenizeSequence(u8, std.mem.trim(u8, data, "\r"), "\n");
        while (it.next()) |line| {
            try l.append(std.mem.trim(u8, line, "\r"));
        }
    }

    var n1: u32 = 0;
    var n2: u32 = 0;
    for (0..l.items[0].len) |i| {
        n1 <<= 1;
        n2 <<= 1;
        n1 |= getBit(l.items, i, .most_common);
        n2 |= getBit(l.items, i, .least_common);
    }
    try std.io.getStdOut().writer().print("{}\n", .{n1 * n2});
}
