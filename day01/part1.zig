const std = @import("std");

pub fn solve(alloc: std.mem.Allocator, data: []const u8) !void {
    var l = std.ArrayList(i32).init(alloc);
    defer l.deinit();
    {
        var it = std.mem.splitSequence(u8, data, "\n");
        while (it.next()) |line| {
            const n = try std.fmt.parseInt(i32, std.mem.trim(u8, line, " \r"), 10);
            try l.append(n);
        }
    }
    var res: usize = 0;
    for (1..(l.items.len)) |i| {
        if (l.items[i - 1] < l.items[i]) {
            res += 1;
        }
    }
    try std.io.getStdOut().writer().print("{}\n", .{res});
}
