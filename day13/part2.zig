const std = @import("std");

const Point = struct {
    x: i32,
    y: i32,
};

const FoldType = enum { X, Y };
const Fold = union(FoldType) {
    X: i32,
    Y: i32,

    fn parse(s: []const u8) !@This() {
        var it = std.mem.tokenizeScalar(u8, s, ' ');
        for (0..2) |_| {
            _ = it.next();
        }
        it = std.mem.tokenizeScalar(u8, it.next().?, '=');
        const c = it.next().?[0];
        const n = try std.fmt.parseInt(i32, it.next().?, 0);
        return switch (c) {
            'x' => .{ .X = n },
            'y' => .{ .Y = n },
            else => unreachable,
        };
    }
};

const Grid = struct {
    m: std.AutoHashMap(Point, void),

    fn init(alloc: std.mem.Allocator) @This() {
        return .{ .m = std.AutoHashMap(Point, void).init(alloc) };
    }

    fn deinit(self: *@This()) void {
        self.m.deinit();
    }

    fn parseAndAddPoint(self: *@This(), s: []const u8) !void {
        var it = std.mem.tokenizeScalar(u8, s, ',');
        var p: Point = undefined;
        p.x = try std.fmt.parseInt(i32, it.next().?, 0);
        p.y = try std.fmt.parseInt(i32, it.next().?, 0);
        try self.m.put(p, {});
    }

    fn fold(self: *@This(), f: Fold) !void {
        var m = std.AutoHashMap(Point, void).init(self.m.allocator);
        var it = self.m.keyIterator();
        while (it.next()) |p| {
            var np = p.*;
            const Helper = struct {
                fn sym(v: i32, axe: i32) i32 {
                    return if (v > axe) v - 2 * (v - axe) else v;
                }
            };
            switch (f) {
                .X => |v| {
                    np.x = Helper.sym(np.x, v);
                },
                .Y => |v| {
                    np.y = Helper.sym(np.y, v);
                },
            }
            try m.put(np, {});
        }
        self.m.deinit();
        self.m = m;
    }

    fn dump(self: *const @This()) !void {
        var p0: ?Point = null;
        var p1: ?Point = null;
        {
            var it = self.m.keyIterator();
            while (it.next()) |p| {
                if (p0 == null) {
                    p0 = p.*;
                }
                if (p1 == null) {
                    p1 = p.*;
                }
                p0.?.x = @min(p0.?.x, p.x);
                p0.?.y = @min(p0.?.y, p.y);
                p1.?.x = @max(p1.?.x, p.x);
                p1.?.y = @max(p1.?.y, p.y);
            }
        }
        var y = p0.?.y;
        while (y <= p1.?.y) {
            var x = p0.?.x;
            while (x <= p1.?.x) {
                var c: u8 = ' ';
                if (self.m.contains(.{ .x = @intCast(x), .y = @intCast(y) })) {
                    c = '#';
                }
                try std.io.getStdOut().writer().print("{c}", .{c});
                x += 1;
            }
            try std.io.getStdOut().writer().print("\n", .{});
            y += 1;
        }
    }
};

pub fn solve(alloc: std.mem.Allocator, data: []const u8) !void {
    var g = Grid.init(alloc);
    defer g.deinit();
    var block1: []const u8 = undefined;
    var block2: []const u8 = undefined;
    {
        var it = std.mem.tokenizeSequence(u8, data, "\n\n");
        block1 = it.next().?;
        block2 = it.next().?;
    }
    {
        var it = std.mem.tokenizeScalar(u8, block1, '\n');
        while (it.next()) |line| {
            try g.parseAndAddPoint(line);
        }
    }
    var it = std.mem.tokenizeScalar(u8, block2, '\n');
    while (it.next()) |line| {
        try g.fold(try Fold.parse(line));
    }
    try g.dump();
}
