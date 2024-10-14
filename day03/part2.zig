const std = @import("std");

fn compute(
    l: [][]const u8,
    i: usize,
    option: enum { most_common, least_common },
    alloc: std.mem.Allocator,
) !u32 {
    if (l.len == 1) {
        var res: u32 = 0;
        for (l[0]) |c| {
            res <<= 1;
            res |= if (c == '1') 1 else 0;
        }
        return res;
    }
    var n: usize = 0;
    for (l) |line| {
        if (line[i] == '1') {
            n += 1;
        }
    }
    const c: u8 = switch (option) {
        .most_common => if (2 * n >= l.len) '1' else '0',
        .least_common => if (2 * n < l.len) '1' else '0',
    };
    var nl = std.ArrayList([]const u8).init(alloc);
    defer nl.deinit();
    for (l) |line| {
        if (line[i] == c) {
            try nl.append(line);
        }
    }
    return try compute(nl.items, i + 1, option, alloc);
}

pub fn solve(alloc: std.mem.Allocator, data: []const u8) !void {
    var l = std.ArrayList([]const u8).init(alloc);
    defer l.deinit();
    {
        var it = std.mem.tokenizeSequence(u8, std.mem.trim(u8, data, "\r"), "\n");
        while (it.next()) |line| {
            try l.append(std.mem.trim(u8, line, "\r"));
        }
    }
    const n1 = try compute(l.items, 0, .most_common, alloc);
    const n2 = try compute(l.items, 0, .least_common, alloc);
    try std.io.getStdOut().writer().print("{}\n", .{n1 * n2});
}
