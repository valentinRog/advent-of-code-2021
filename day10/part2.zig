const std = @import("std");

fn score(c: u8) u32 {
    return switch (c) {
        ')' => 1,
        ']' => 2,
        '}' => 3,
        '>' => 4,
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

fn isValid(alloc: std.mem.Allocator, line: []const u8) !bool {
    var l = std.ArrayList(u8).init(alloc);
    defer l.deinit();
    for (line) |c| {
        if (std.mem.indexOf(u8, "([{<", &[_]u8{c})) |_| {
            try l.append(c);
            continue;
        }
        if (l.items.len == 0) {
            return false;
        }
        const cc = l.pop();
        if (matching(cc) != c) {
            return false;
        }
    }
    return true;
}

fn isClosing(c: u8) bool {
    return std.mem.indexOf(u8, ")]}>", &[_]u8{c}) != null;
}

fn compute(alloc: std.mem.Allocator, line: []const u8) !u64 {
    var res: u64 = 0;
    var l = std.ArrayList(u8).init(alloc);
    defer l.deinit();
    for (line) |c| {
        try l.append(c);
    }
    while (l.items.len > 0) {
        const c = l.pop();
        if (isClosing(c)) {
            var depth: i32 = 1;
            while (depth > 0) {
                depth += if (isClosing(l.pop())) 1 else -1;
            }
            continue;
        }
        res *= 5;
        res += score(matching(c));
    }
    return res;
}

pub fn solve(alloc: std.mem.Allocator, data: []const u8) !void {
    var l = std.ArrayList(u64).init(alloc);
    defer l.deinit();
    var it = std.mem.splitScalar(u8, data, '\n');
    while (it.next()) |line| {
        if (try isValid(alloc, line)) {
            try l.append(try compute(alloc, line));
        }
    }
    std.mem.sort(u64, l.items, {}, std.sort.asc(u64));
    const res = l.items[@divExact(l.items.len - 1, 2)];
    try std.io.getStdOut().writer().print("{}\n", .{res});
}
