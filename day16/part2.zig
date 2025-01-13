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

fn read_packet(alloc: std.mem.Allocator, s: []const u8) !struct { n: usize, res: u64 } {
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
            const n = try std.fmt.parseInt(u64, l.items, 2);
            return .{
                .n = i,
                .res = n,
            };
        },
        else => {
            var l = std.ArrayList(u64).init(alloc);
            defer l.deinit();
            switch (s[i]) {
                '0' => {
                    i += 1;
                    const n = try std.fmt.parseInt(u32, s[i .. i + 15], 2);
                    i += 15;
                    var read: usize = 0;
                    while (read < n) {
                        const packet = try read_packet(alloc, s[i..]);
                        try l.append(packet.res);
                        read += packet.n;
                        i += packet.n;
                    }
                },
                '1' => {
                    i += 1;
                    const n = try std.fmt.parseInt(u32, s[i .. i + 11], 2);
                    i += 11;
                    for (0..n) |_| {
                        const packet = try read_packet(alloc, s[i..]);
                        try l.append(packet.res);
                        i += packet.n;
                    }
                },
                else => unreachable,
            }
            const res: u64 = out: switch (id) {
                0 => {
                    var res: u64 = 0;
                    for (l.items) |n| res += n;
                    break :out res;
                },
                1 => {
                    var res: u64 = 1;
                    for (l.items) |n| res *= n;
                    break :out res;
                },
                2 => {
                    var res: u64 = std.math.maxInt(u64);
                    for (l.items) |n| res = @min(res, n);
                    break :out res;
                },
                3 => {
                    var res: u64 = 0;
                    for (l.items) |n| res = @max(res, n);
                    break :out res;
                },
                5 => if (l.items[0] > l.items[1]) 1 else 0,
                6 => if (l.items[0] < l.items[1]) 1 else 0,
                7 => if (l.items[0] == l.items[1]) 1 else 0,
                else => unreachable,
            };
            return .{
                .n = i,
                .res = res,
            };
        },
    }
}

pub fn solve(alloc: std.mem.Allocator, data: []const u8) !void {
    const s = try make_bin_string(alloc, data);
    defer alloc.free(s);
    const res = (try read_packet(alloc, s)).res;
    try std.io.getStdOut().writer().print("{}\n", .{res});
}
