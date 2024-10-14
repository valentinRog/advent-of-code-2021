const std = @import("std");

fn computeFuel(l: []const i32, i: i32) i32 {
    var res: i32 = 0;
    for (l) |n| {
        const d: i32 = @intCast(@abs(i - n));
        res += @divExact(d * (d + 1), 2);
    }
    return res;
}

pub fn solve(alloc: std.mem.Allocator, data: []const u8) !void {
    var l = std.ArrayList(i32).init(alloc);
    defer l.deinit();
    {
        var it = std.mem.tokenizeScalar(u8, data, ',');
        while (it.next()) |w| {
            try l.append(try std.fmt.parseInt(i32, w, 0));
        }
    }
    var maxN = l.items[0];
    for (l.items[1..]) |n| {
        maxN = @max(maxN, n);
    }
    var res = computeFuel(l.items, 0);
    {
        var i: i32 = 1;
        while (i <= maxN) {
            res = @min(res, computeFuel(l.items, i));
            i += 1;
        }
    }
    try std.io.getStdOut().writer().print("{}\n", .{res});
}
