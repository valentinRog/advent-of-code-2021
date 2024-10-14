const std = @import("std");

const Point = struct {
    x: i32,
    y: i32,

    fn parse(s: []const u8) !Point {
        var it = std.mem.tokenizeScalar(u8, s, ',');
        return .{
            .x = try std.fmt.parseInt(i32, it.next().?, 0),
            .y = try std.fmt.parseInt(i32, it.next().?, 0),
        };
    }
};

const Vent = struct {
    p1: Point,
    p2: Point,

    fn parse(s: []const u8) !Vent {
        var vent: Vent = undefined;
        var it = std.mem.tokenizeSequence(u8, s, " -> ");

        vent.p1 = try Point.parse(it.next().?);
        vent.p2 = try Point.parse(it.next().?);
        return vent;
    }

    fn addToMap(self: *const @This(), m: *std.AutoHashMap(Point, usize)) !void {
        if (self.p1.x != self.p2.x and self.p1.y != self.p2.y) {
            return;
        }

        const utils = struct {
            m: *std.AutoHashMap(Point, usize),

            fn addPointToMap(selfUtils: @This(), p: Point) !void {
                const v = try selfUtils.m.getOrPut(.{ .x = p.x, .y = p.y });
                if (!v.found_existing) {
                    v.value_ptr.* = 0;
                }
                v.value_ptr.* += 1;
            }
        }{ .m = m };

        var x = self.p1.x;
        var y = self.p1.y;
        const dx = std.math.sign(self.p2.x - self.p1.x);
        const dy = std.math.sign(self.p2.y - self.p1.y);
        while (x != self.p2.x or y != self.p2.y) {
            try utils.addPointToMap(.{ .x = x, .y = y });
            x += dx;
            y += dy;
        }
        try utils.addPointToMap(.{ .x = x, .y = y });
    }
};

pub fn solve(alloc: std.mem.Allocator, data: []const u8) !void {
    var l = std.ArrayList(Vent).init(alloc);
    defer l.deinit();
    {
        var it = std.mem.tokenizeSequence(u8, data, "\n");
        while (it.next()) |line| {
            try l.append(try Vent.parse(line));
        }
    }

    var m = std.AutoHashMap(Point, usize).init(alloc);
    defer m.deinit();
    for (l.items) |v| {
        try v.addToMap(&m);
    }

    var res: usize = 0;
    {
        var it = m.valueIterator();
        while (it.next()) |v| {
            if (v.* >= 2) {
                res += 1;
            }
        }
    }
    try std.io.getStdOut().writer().print("{}\n", .{res});
}
