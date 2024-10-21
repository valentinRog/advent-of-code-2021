const std = @import("std");

fn score(c: u8) u32 {
    return switch (c) {
        ')' => 3,
        ']' => 57,
        '}' => 1197,
        '>' => 25137,
        else => unreachable,
    };
}

fn matching(c: u8) u8 {
    return switch (c) {
        '(' => ')',
        '[' => ']',
        '{' => '}',
        '<' => '>',
        else => unreachable,
    };
}

fn compute(alloc: std.mem.Allocator, line: []const u8) !u32 {
    var l = std.ArrayList(u8).init(alloc);
    defer l.deinit();
    for (line) |c| {
        if (std.mem.indexOf(u8, "([{<", &[_]u8{c})) |_| {
            try l.append(c);
            continue;
        }
        if (l.items.len == 0) {
            return score(c);
        }
        const cc = l.pop();
        if (matching(cc) != c) {
            return score(c);
        }
    }
    return 0;
}

pub fn solve(alloc: std.mem.Allocator, data: []const u8) !void {
    var res : u32 = 0;
    var it = std.mem.splitScalar(u8, data, '\n');
    while (it.next()) |line| {
        res += try compute(alloc, line);
    }
    try std.io.getStdOut().writer().print("{}\n", .{res});
}
