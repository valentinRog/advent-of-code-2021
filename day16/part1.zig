const std = @import("std");

fn make_bin_string(alloc: std.mem.Allocator, data: []const u8) ![]const u8 {
    var l = std.ArrayList(u8).init(alloc);
    for (data) |c| {
        const n = try std.fmt.parseInt(u32, &[_]u8{c}, 16);
        const s = try std.fmt.allocPrint(alloc, "{b:0>4}", .{n});
        defer alloc.free(s);
        try l.appendSlice(s);
    }
    return l.toOwnedSlice();
}

fn read_packet(alloc: std.mem.Allocator, s: []const u8) !struct { n: usize, version_sum: u32 } {
    const version = try std.fmt.parseInt(u32, s[0..3], 2);
    const id = try std.fmt.parseInt(u32, s[3..6], 2);
    var i: usize = 6;
    switch (id) {
        4 => {
            var l = std.ArrayList(u8).init(alloc);
            defer l.deinit();
            var it = std.mem.window(u8, s[i..], 5, 5);
            while (it.next()) |w| {
                i += 5;
                try l.appendSlice(w[1..]);
                if (w[0] == '0') break;
            }
            return .{
                .n = i,
                .version_sum = version,
            };
        },
        else => {
            var version_sum = version;
            switch (s[i]) {
                '0' => {
                    i += 1;
                    const n = try std.fmt.parseInt(u32, s[i .. i + 15], 2);
                    i += 15;
                    var read: usize = 0;
                    while (read < n) {
                        const packet = try read_packet(alloc, s[i..]);
                        read += packet.n;
                        version_sum += packet.version_sum;
                        i += packet.n;
                    }
                },
                '1' => {
                    i += 1;
                    const n = try std.fmt.parseInt(u32, s[i .. i + 11], 2);
                    i += 11;
                    for (0..n) |_| {
                        const packet = try read_packet(alloc, s[i..]);
                        version_sum += packet.version_sum;
                        i += packet.n;
                    }
                },
                else => unreachable,
            }
            return .{
                .n = i,
                .version_sum = version_sum,
            };
        },
    }
}

pub fn solve(alloc: std.mem.Allocator, data: []const u8) !void {
    const s = try make_bin_string(alloc, data);
    defer alloc.free(s);
    const res = try read_packet(alloc, s);
    try std.io.getStdOut().writer().print("{}\n", .{res.version_sum});
}
