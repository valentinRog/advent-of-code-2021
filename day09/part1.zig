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
    var res: u32 = 0;
    {
        var it = m.iterator();
        while (it.next()) |kv| {
            if (isLow(&m, kv.key_ptr.*)) {
                res += kv.value_ptr.* + 1;
            }
        }
    }
    try std.io.getStdOut().writer().print("{}\n", .{res});
}
