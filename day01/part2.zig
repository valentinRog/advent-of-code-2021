const std = @import("std");

pub fn solve(data: []const u8, alloc: std.mem.Allocator) !void {
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
    for (3..(l.items.len)) |i| {
        const arr = l.items;
        if (arr[i - 3] + arr[i - 2] + arr[i - 1] < arr[i - 2] + arr[i - 1] + arr[i]) {
            res += 1;
        }
    }
    try std.io.getStdOut().writer().print("{}\n", .{res});
}
