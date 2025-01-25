const std = @import("std");

const Prog = struct {
    kind: enum { first, second },
    n1: i64,
    n2: i64,

    fn compute(self: *const @This(), z: i64, w: i64) i64 {
        const b = w == @rem(z, 26) + self.n1;
        return switch (self.kind) {
            .first => if (b) z else z * 26 + w + self.n2,
            .second => if (b) @divFloor(z, 26) else z - @rem(z, 26) + w + self.n2,
        };
    }
};

fn backTracking(alloc: std.mem.Allocator, l: []const Prog) !i64 {
    var compute = struct {
        cache: std.AutoHashMap(struct { usize, i64 }, ?i64),
        l: []const Prog,

        fn compute(self: *@This(), i: usize, z: i64) !?i64 {
            if (self.cache.get(.{ i, z })) |v| return v;
            var res: ?i64 = null;
            if (i == 13) {
                var w: i64 = 1;
                while (w < 10) : (w += 1) {
                    if (self.l[i].compute(z, w) == 0) {
                        try self.cache.put(.{ i, z }, w);
                        return w;
                    }
                }
                return null;
            }
            if (self.l[i].kind == .first and self.l[i].n1 <= 9) {
                const w = @rem(z, 26) + self.l[i].n1;
                if (w > 9) return null;
                if (try self.compute(i + 1, self.l[i].compute(z, w))) |n| {
                    res = w * std.math.pow(i64, 10, @intCast(13 - i)) + n;
                }
            } else {
                var w: i64 = 1;
                while (w < 10) : (w += 1) {
                    if (try self.compute(i + 1, self.l[i].compute(z, w))) |n| {
                        res = w * std.math.pow(i64, 10, @intCast(13 - i)) + n;
                        break;
                    }
                }
            }
            try self.cache.put(.{ i, z }, res);
            return res;
        }
    }{
        .cache = std.AutoHashMap(struct { usize, i64 }, ?i64).init(alloc),
        .l = l,
    };
    defer compute.cache.deinit();
    return (try compute.compute(0, 0)).?;
}

pub fn solve(alloc: std.mem.Allocator, data: []const u8) !void {
    var l = std.ArrayList(Prog).init(alloc);
    defer l.deinit();
    {
        var it1 = std.mem.tokenizeScalar(u8, data, '\n');
        _ = it1.next();
        var i: u32 = 1;
        var progData: Prog = undefined;
        while (it1.next()) |line| : (i += 1) {
            if (std.mem.startsWith(u8, line, "inp")) {
                try l.append(progData);
                i = 0;
                continue;
            }
            var it2 = std.mem.tokenizeScalar(u8, line, ' ');
            var lastToken: []const u8 = undefined;
            while (it2.next()) |w| lastToken = w;
            if (std.fmt.parseInt(i64, lastToken, 10)) |n| {
                switch (i) {
                    4 => progData.kind = if (n == 1) .first else .second,
                    5 => progData.n1 = n,
                    15 => progData.n2 = n,
                    else => {},
                }
            } else |_| {}
        }
        try l.append(progData);
        const res = try backTracking(alloc, l.items);
        try std.io.getStdOut().writer().print("{}\n", .{res});
    }
}
