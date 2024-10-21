const std = @import("std");

const Point = struct {
    x: i32,
    y: i32,

    fn add(self: @This(), p: @This()) @This() {
        return .{ .x = self.x + p.x, .y = self.y + p.y };
    }
};

const State = struct {
    alloc: std.mem.Allocator,
    m: std.AutoHashMap(Point, u8),

    fn init(alloc: std.mem.Allocator) @This() {
        return .{ .alloc = alloc, .m = std.AutoHashMap(Point, u8).init(alloc) };
    }

    fn deinit(self: *@This()) void {
        self.m.deinit();
    }

    fn nextState(self: *@This()) !u32 {
        var flashed = std.AutoHashMap(Point, void).init(self.alloc);
        defer flashed.deinit();
        var m = try self.m.clone();
        {
            var it = m.valueIterator();
            while (it.next()) |v| {
                v.* += 1;
            }
        }
        var willFlash = struct {
            hs: std.AutoHashMap(Point, void),
            flashed: *const std.AutoHashMap(Point, void),

            fn update(selfWillFlash: *@This(), mm: *const std.AutoHashMap(Point, u8)) !void {
                selfWillFlash.hs.clearRetainingCapacity();
                var it = mm.iterator();
                while (it.next()) |kv| {
                    if (kv.value_ptr.* > 9 and !selfWillFlash.flashed.contains(kv.key_ptr.*)) {
                        try selfWillFlash.hs.put(kv.key_ptr.*, void{});
                    }
                }
            }
        }{ .hs = std.AutoHashMap(Point, void).init(self.alloc), .flashed = &flashed };
        defer willFlash.hs.deinit();
        try willFlash.update(&m);
        while (willFlash.hs.count() > 0) {
            var it = willFlash.hs.keyIterator();
            while (it.next()) |p| {
                try flashed.put(p.*, void{});
                try m.put(p.*, 0);
                const nb = [_]Point{
                    p.add(.{ .x = 0, .y = -1 }),
                    p.add(.{ .x = 1, .y = -1 }),
                    p.add(.{ .x = 1, .y = 0 }),
                    p.add(.{ .x = 1, .y = 1 }),
                    p.add(.{ .x = 0, .y = 1 }),
                    p.add(.{ .x = -1, .y = 1 }),
                    p.add(.{ .x = -1, .y = 0 }),
                    p.add(.{ .x = -1, .y = -1 }),
                };
                for (nb) |pp| {
                    if (m.contains(pp) and !flashed.contains(pp)) {
                        m.getPtr(pp).?.* += 1;
                    }
                }
            }
            try willFlash.update(&m);
        }
        self.m.deinit();
        self.m = m;
        return flashed.count();
    }
};

pub fn solve(alloc: std.mem.Allocator, data: []const u8) !void {
    var state = State.init(alloc);
    defer state.deinit();
    {
        var it = std.mem.tokenizeScalar(u8, data, '\n');
        var y: i32 = 0;
        while (it.next()) |line| {
            var x: i32 = 0;
            for (line) |c| {
                try state.m.put(.{ .x = x, .y = y }, c - '0');
                x += 1;
            }
            y += 1;
        }
    }
    var res: u32 = 1;
    while (try state.nextState() != state.m.count()) {
        res += 1;
    }
    try std.io.getStdOut().writer().print("{}\n", .{res});
}
