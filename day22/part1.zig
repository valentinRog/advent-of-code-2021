const std = @import("std");

const Cube = struct {
    sign: i8,
    p1: [3]i32,
    p2: [3]i32,

    fn intersection(self: *const @This(), other: @This()) ?@This() {
        var p1: [3]i32 = undefined;
        var p2: [3]i32 = undefined;
        for (0..3) |i| {
            p1[i] = @max(self.p1[i], other.p1[i]);
            p2[i] = @min(self.p2[i], other.p2[i]);
            if (p1[i] > p2[i]) return null;
        }
        return .{ .sign = 1, .p1 = p1, .p2 = p2 };
    }

    fn revertSign(self: *const @This()) @This() {
        return .{ .sign = -1 * self.sign, .p1 = self.p1, .p2 = self.p2 };
    }

    fn volume(self: *const @This()) i64 {
        var n: i64 = 1;
        for (0..3) |i| n *= self.p2[i] - self.p1[i] + 1;
        return self.sign * n;
    }
};

fn compute(alloc: std.mem.Allocator, l: std.ArrayList(Cube)) !i64 {
    var cubes = std.ArrayList(Cube).init(alloc);
    defer cubes.deinit();
    for (l.items) |cube1| {
        var new_cubes = std.ArrayList(Cube).init(alloc);
        defer new_cubes.deinit();
        for (cubes.items) |cube2| {
            if (cube1.intersection(cube2)) |interCube| {
                if (cube1.sign == 1 and cube2.sign == 1) {
                    try new_cubes.append(interCube.revertSign());
                } else if (cube1.sign == 1 and cube2.sign == -1) {
                    try new_cubes.append(interCube);
                } else if (cube1.sign == -1 and cube2.sign == 1) {
                    try new_cubes.append(interCube.revertSign());
                } else {
                    try new_cubes.append(interCube);
                }
            }
        }
        try cubes.appendSlice(new_cubes.items);
        if (cube1.sign == 1) try cubes.append(cube1);
    }
    var n: i64 = 0;
    for (cubes.items) |cube| n += cube.volume();
    return n;
}

pub fn solve(alloc: std.mem.Allocator, data: []const u8) !void {
    var l = std.ArrayList(Cube).init(alloc);
    defer l.deinit();
    {
        var it1 = std.mem.tokenizeScalar(u8, data, '\n');
        out: while (it1.next()) |line| {
            var cube: Cube = undefined;
            cube.sign = if (std.mem.startsWith(u8, line, "on")) 1 else -1;
            const cleanLine = try alloc.dupe(u8, line);
            defer alloc.free(cleanLine);
            for (cleanLine) |*c| {
                if (!std.ascii.isDigit(c.*) and c.* != '-') c.* = ' ';
            }
            var it2 = std.mem.tokenizeScalar(u8, cleanLine, ' ');
            var i: usize = 0;
            while (it2.next()) |w| {
                const n = try std.fmt.parseInt(i32, w, 10);
                if (@abs(n) > 50) continue :out;
                const p: *[3]i32 = if (@rem(i, 2) == 0) &cube.p1 else &cube.p2;
                p[@divFloor(i, 2)] = n;
                i += 1;
            }
            try l.append(cube);
        }
    }
    const res = try compute(alloc, l);
    try std.io.getStdOut().writer().print("{}\n", .{res});
}
