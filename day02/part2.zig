const std = @import("std");

pub fn solve(data: []const u8) !void {
    var x: i32 = 0;
    var y: i32 = 0;
    var aim: i32 = 0;
    {
        var it = std.mem.tokenizeSequence(u8, data, "\n");
        while (it.next()) |line| {
            var it2 = std.mem.tokenizeSequence(u8, std.mem.trim(u8, line, "\r"), " ");
            const ins = it2.next().?;
            const n = try std.fmt.parseInt(i32, it2.next().?, 10);
            if (std.mem.eql(u8, ins, "forward")) {
                x += n;
                y += aim * n;
            } else if (std.mem.eql(u8, ins, "down")) {
                aim += n;
            } else {
                aim -= n;
            }
        }
    }
    try std.io.getStdOut().writer().print("{}\n", .{x * y});
}
