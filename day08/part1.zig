const std = @import("std");

pub fn solve(data: []const u8) !void {
    var res: u32 = 0;
    var it = std.mem.tokenizeScalar(u8, data, '\n');
    while (it.next()) |line| {
        var it2 = std.mem.tokenizeScalar(u8, line, '|');
        _ = it2.next();
        var it3 = std.mem.tokenizeScalar(u8, it2.next().?, ' ');
        while (it3.next()) |w| {
            res += switch (w.len) {
                2 => 1,
                4 => 1,
                3 => 1,
                7 => 1,
                else => 0,
            };
        }
    }
    try std.io.getStdOut().writer().print("{}\n", .{res});
}
