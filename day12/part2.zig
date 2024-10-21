const std = @import("std");

const Map = std.StringHashMap([]const u8);

const Graph = struct {
    const M = std.StringHashMap(std.ArrayList([]const u8));
    m: M,

    fn init(alloc: std.mem.Allocator) @This() {
        return .{ .m = M.init(alloc) };
    }

    fn deinit(self: *@This()) void {
        var it = self.m.valueIterator();
        while (it.next()) |l| {
            l.deinit();
        }
        self.m.deinit();
    }

    fn addConn(self: *@This(), s1: []const u8, s2: []const u8) !void {
        for (&[_][2][]const u8{ [2][]const u8{ s1, s2 }, [2][]const u8{ s2, s1 } }) |a| {
            var res = try self.m.getOrPut(a[0]);
            if (!res.found_existing) {
                res.value_ptr.* = std.ArrayList([]const u8).init(self.m.allocator);
            }
            try res.value_ptr.append(a[1]);
        }
    }

    fn countPaths(self: *@This(), alloc: std.mem.Allocator) !u32 {
        var helper = try struct {
            const Paths = std.ArrayList(std.ArrayList([]const u8));
            alloc: std.mem.Allocator,
            g: *const Graph,
            paths: Paths,
            l: std.ArrayList([]const u8),
            seen: std.StringHashMap(void),

            fn init(aalloc: std.mem.Allocator, g: *const Graph) !@This() {
                var l = std.ArrayList([]const u8).init(aalloc);
                const start = g.m.getKey("start").?;
                try l.append(start);
                var seen = std.StringHashMap(void).init(aalloc);
                try seen.put(start, void{});
                return .{
                    .alloc = aalloc,
                    .g = g,
                    .paths = Paths.init(aalloc),
                    .l = l,
                    .seen = seen,
                };
            }

            fn deinit(selfHelper: *@This()) void {
                for (selfHelper.paths.items) |l| {
                    l.deinit();
                }
                selfHelper.paths.deinit();
                selfHelper.l.deinit();
                selfHelper.seen.deinit();
            }

            fn compute(selfHelper: *@This(), usedDoubleSmall: bool) !void {
                if (std.mem.eql(u8, selfHelper.l.getLast(), "end")) {
                    try selfHelper.paths.append(try selfHelper.l.clone());
                    return;
                }
                for (selfHelper.g.m.get(selfHelper.l.getLast()).?.items) |s| {
                    if (!std.ascii.isUpper(s[0]) and selfHelper.seen.contains(s)) {
                        if (!usedDoubleSmall and !std.mem.eql(u8, s, "start")) {
                            try selfHelper.l.append(s);
                            try selfHelper.compute(true);
                            _ = selfHelper.l.pop();
                        }
                        continue;
                    }
                    try selfHelper.l.append(s);
                    try selfHelper.seen.put(s, void{});
                    try selfHelper.compute(usedDoubleSmall);
                    _ = selfHelper.l.pop();
                    _ = selfHelper.seen.remove(s);
                }
            }
        }.init(alloc, self);
        defer helper.deinit();
        try helper.compute(false);
        return @intCast(helper.paths.items.len);
    }
};

pub fn solve(alloc: std.mem.Allocator, data: []const u8) !void {
    var g = Graph.init(alloc);
    defer g.deinit();
    {
        var it = std.mem.tokenizeScalar(u8, data, '\n');
        while (it.next()) |line| {
            var it2 = std.mem.tokenizeScalar(u8, line, '-');
            const s1 = it2.next().?;
            const s2 = it2.next().?;
            try g.addConn(s1, s2);
        }
    }
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const res = try g.countPaths(arena.allocator());
    try std.io.getStdOut().writer().print("{}\n", .{res});
}
