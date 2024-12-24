const std = @import("std");

const Counter = struct {
    const M = std.AutoHashMap(u8, u64);
    m: M,

    fn init(alloc: std.mem.Allocator) @This() {
        return .{ .m = M.init(alloc) };
    }

    fn deinit(self: *@This()) void {
        self.m.deinit();
    }

    fn clone(self: *const @This()) !@This() {
        return .{ .m = try self.m.clone() };
    }

    fn merge(self: *@This(), other: @This()) !void {
        var it = other.m.iterator();
        while (it.next()) |kv| {
            if (!self.m.contains(kv.key_ptr.*)) {
                try self.m.put(kv.key_ptr.*, 0);
            }
            self.m.getPtr(kv.key_ptr.*).?.* += kv.value_ptr.*;
        }
    }
};

fn compute(alloc: std.mem.Allocator, s0: []const u8, m: std.AutoHashMap([2]u8, u8)) !u64 {
    const Compute = struct {
        const Cache = std.AutoHashMap(struct { [2]u8, i32 }, Counter);
        cache: Cache,
        m: std.AutoHashMap([2]u8, u8),
        alloc: std.mem.Allocator,

        fn init(params: struct { alloc: std.mem.Allocator, m: std.AutoHashMap([2]u8, u8) }) @This() {
            return .{
                .cache = Cache.init(params.alloc),
                .m = params.m,
                .alloc = params.alloc,
            };
        }

        fn deinit(self: *@This()) void {
            var it = self.cache.valueIterator();
            while (it.next()) |v| {
                v.deinit();
            }
            self.cache.deinit();
        }

        fn compute(self: *@This(), p: [2]u8, depth: i32) !Counter {
            if (self.cache.contains(.{ p, depth })) {
                return try self.cache.get(.{ p, depth }).?.clone();
            }
            var c = Counter.init(self.alloc);
            if (depth == 10) {
                try c.m.put(p[1], 1);
                return c;
            }
            var c2 = try self.compute([2]u8{ p[0], self.m.get(p).? }, depth + 1);
            defer c2.deinit();
            try c.merge(c2);
            var c3 = try self.compute([2]u8{ self.m.get(p).?, p[1] }, depth + 1);
            defer c3.deinit();
            try c.merge(c3);
            try self.cache.put(.{ p, depth }, try c.clone());
            return c;
        }
    };
    var c = Compute.init(.{ .alloc = alloc, .m = m });
    defer c.deinit();
    var counter = Counter.init(alloc);
    defer counter.deinit();
    try counter.m.put(s0[0], 1);
    for (0..s0.len - 1) |i| {
        var counter2 = try c.compute([2]u8{ s0[i], s0[i + 1] }, 0);
        defer counter2.deinit();
        try counter.merge(counter2);
    }
    var n1: u64 = std.math.minInt(u64);
    var n2: u64 = std.math.maxInt(u64);
    var it = counter.m.valueIterator();
    while (it.next()) |n| {
        n1 = @max(n1, n.*);
        n2 = @min(n2, n.*);
    }
    return n1 - n2;
}

pub fn solve(alloc: std.mem.Allocator, raw: []const u8) !void {
    var it = std.mem.tokenizeSequence(u8, raw, "\n\n");
    const s0 = it.next().?;
    var m = std.AutoHashMap([2]u8, u8).init(alloc);
    defer m.deinit();
    var it2 = std.mem.tokenizeScalar(u8, it.next().?, '\n');
    while (it2.next()) |line| {
        var it3 = std.mem.tokenizeSequence(u8, line, " -> ");
        const s = it3.next().?;
        try m.put([2]u8{ s[0], s[1] }, it3.next().?[0]);
    }
    const n = try compute(alloc, s0, m);
    try std.io.getStdOut().writer().print("{}\n", .{n});
}
