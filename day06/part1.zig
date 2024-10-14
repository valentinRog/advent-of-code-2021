const std = @import("std");

const Compute = struct {
    const CacheKey = struct { n: u32, day: u32 };
    const Cache = std.AutoHashMap(CacheKey, u64);

    cache: Cache,

    fn init(alloc: std.mem.Allocator) Compute {
        return .{ .cache = Compute.Cache.init(alloc) };
    }

    fn deinit(self: *@This()) void {
        self.cache.deinit();
    }

    fn compute(self: *@This(), n: u32) !u64 {
        var helper = struct {
            cache: *Compute.Cache,

            fn compute(selfHelper: *@This(), nn: u32, day: u32) !u64 {
                if (day == 80) {
                    return 1;
                }
                const key = Compute.CacheKey{ .n = nn, .day = day };
                if (selfHelper.cache.get(key)) |v| {
                    return v;
                }
                const v = v: {
                    if (nn == 0) {
                        break :v try selfHelper.compute(6, day + 1) + try selfHelper.compute(8, day + 1);
                    } else {
                        break :v try selfHelper.compute(nn - 1, day + 1);
                    }
                };
                try selfHelper.cache.put(key, v);
                return selfHelper.compute(nn, day);
            }
        }{ .cache = &self.cache };
        return try helper.compute(n, 0);
    }
};

pub fn solve(data: []const u8, alloc: std.mem.Allocator) !void {
    var res: u64 = 0;
    var compute = Compute.init(alloc);
    defer compute.deinit();
    var it = std.mem.tokenizeScalar(u8, data, ',');
    while (it.next()) |w| {
        res += try compute.compute(try std.fmt.parseInt(u32, w, 0));
    }
    try std.io.getStdOut().writer().print("{}\n", .{res});
}
