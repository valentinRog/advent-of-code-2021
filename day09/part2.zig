const std = @import("std");

const Point = struct {
    x: i32,
    y: i32,

    fn add(self: @This(), p: @This()) @This() {
        return .{ .x = self.x + p.x, .y = self.y + p.y };
    }
};

const Map = std.AutoArrayHashMap(Point, u8);

fn isLow(m: *const Map, p: Point) bool {
    const n = m.get(p).?;
    const nb = [_]Point{
        p.add(.{ .x = 1, .y = 0 }),
        p.add(.{ .x = -1, .y = 0 }),
        p.add(.{ .x = 0, .y = 1 }),
        p.add(.{ .x = 0, .y = -1 }),
    };
    for (nb) |pp| {
        if (m.get(pp)) |nn| {
            if (nn <= n) {
                return false;
            }
        }
    }
    return true;
}

fn basinSize(alloc: std.mem.Allocator, m0: *const Map, p0: Point) !u32 {
    var m = std.AutoHashMap(Point, void).init(alloc);
    try m.put(p0, void{});
    while (true) {
        var nm = try m.clone();
        var it = m.keyIterator();
        while (it.next()) |p| {
            const n = m0.get(p.*).?;
            const nb = [_]Point{
                p.add(.{ .x = 1, .y = 0 }),
                p.add(.{ .x = -1, .y = 0 }),
                p.add(.{ .x = 0, .y = 1 }),
                p.add(.{ .x = 0, .y = -1 }),
            };
            for (nb) |pp| {
                if (nm.get(pp)) |_| {
                    continue;
                }
                if (m0.get(pp)) |nn| {
                    if (nn > n and nn < 9) {
                        try nm.put(pp, void{});
                    }
                }
            }
        }
        if (nm.count() == m.count()) {
            const res = nm.count();
            m.deinit();
            nm.deinit();
            return res;
        }
        m.deinit();
        m = nm;
    }
}

pub fn solve(alloc: std.mem.Allocator, data: []const u8) !void {
    var m = Map.init(alloc);
    defer m.deinit();
    {
        var it = std.mem.tokenizeScalar(u8, data, '\n');
        var y: i32 = 0;
        while (it.next()) |line| {
            var x: i32 = 0;
            for (line) |c| {
                try m.put(.{ .x = x, .y = y }, c - '0');
                x += 1;
            }
            y += 1;
        }
    }
    var l = std.ArrayList(u32).init(alloc);
    defer l.deinit();
    {
        var it = m.iterator();
        while (it.next()) |kv| {
            if (isLow(&m, kv.key_ptr.*)) {
                const n = try basinSize(alloc, &m, kv.key_ptr.*);
                try l.append(n);
            }
        }
        std.mem.sort(u32, l.items, {}, std.sort.desc(u32));
    }
    const res = l.items[0] * l.items[1] * l.items[2];
    try std.io.getStdOut().writer().print("{}\n", .{res});
}
