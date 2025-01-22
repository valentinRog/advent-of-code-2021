const std = @import("std");

const Cube = struct {
    on: bool,
    p1: [3]i32,
    p2: [3]i32,

    fn contains(self: *const @This(), p: [3]i32) bool {
        for (0..3) |i| {
            if (!((p[i] >= self.p1[i] and p[i] <= self.p2[i]) or
                (p[i] >= self.p2[i] and p[i] <= self.p1[i]))) return false;
        }
        return true;
    }
};

fn isOn(l: std.ArrayList(Cube), p: [3]i32) bool {
    var on = false;
    for (l.items) |cube| {
        if (cube.contains(p)) on = cube.on;
    }
    return on;
}

fn compute(alloc: std.mem.Allocator, l: std.ArrayList(Cube)) !u64 {
    const Lookup = struct {
        alloc: std.mem.Allocator,
        a: [3]std.ArrayList(i32),
        l: std.ArrayList(Cube),

        fn init(par: struct { alloc: std.mem.Allocator, l: std.ArrayList(Cube) }) !@This() {
            var a: [3]std.ArrayList(i32) = undefined;
            for (&a) |*ll| {
                ll.* = std.ArrayList(i32).init(par.alloc);
            }
            for (par.l.items) |cube| {
                for (&[_][3]i32{ cube.p1, cube.p2 }) |p| {
                    for (0..3) |i| try a[i].append(p[i]);
                }
            }
            for (&a) |*ll| {
                std.mem.sort(i32, ll.items, {}, std.sort.asc(i32));
            }
            return .{ .alloc = par.alloc, .a = a, .l = par.l };
        }

        fn deinit(self: *@This()) void {
            for (self.a) |ll| ll.deinit();
        }

        fn get_next_e(self: *const @This(), e: i32, i: usize) i32 {
            var @"i1": usize = 0;
            var @"i2": usize = self.a[i].items.len;
            while (@"i2" - @"i1" > 1) {
                const @"i3" = @divFloor(@"i2" + @"i1", 2);
                if (self.a[i].items[@"i3"] == e) return e + 1;
                if (self.a[i].items[@"i3"] > e) {
                    @"i2" = @"i3";
                } else {
                    @"i1" = @"i3";
                }
            }
            return @max(self.a[i].items[@"i2"] - 1, e + 1);
        }
    };
    var lookup = try Lookup.init(.{ .alloc = alloc, .l = l });
    defer lookup.deinit();
    const a = lookup.a;
    var n: u64 = 0;
    var x = a[0].items[0];
    while (x <= a[0].items[a[0].items.len - 1]) {
        const nx = lookup.get_next_e(x, 0);
        var nn: u64 = 0;
        var y = a[1].items[0];
        while (y <= a[1].items[a[1].items.len - 1]) {
            const ny = lookup.get_next_e(y, 1);
            var nnn: u64 = 0;
            var z = a[2].items[0];
            while (z <= a[2].items[a[2].items.len - 1]) {
                const nz = lookup.get_next_e(z, 2);
                if (isOn(l, [3]i32{ x, y, z })) nnn += @as(u64, @intCast(nz - z));
                z = nz;
            }
            nn += @as(u64, @intCast(ny - y)) * nnn;
            y = ny;
        }
        n += @as(u64, @intCast(nx - x)) * nn;
        x = nx;
    }
    return n;
}

pub fn solve(alloc: std.mem.Allocator, data: []const u8) !void {
    var l = std.ArrayList(Cube).init(alloc);
    defer l.deinit();
    {
        var it1 = std.mem.tokenizeScalar(u8, data, '\n');
        while (it1.next()) |line| {
            var cube: Cube = undefined;
            cube.on = std.mem.startsWith(u8, line, "on");
            const cleanLine = try alloc.dupe(u8, line);
            defer alloc.free(cleanLine);
            for (cleanLine) |*c| {
                if (!std.ascii.isDigit(c.*) and c.* != '-') c.* = ' ';
            }
            var it2 = std.mem.tokenizeScalar(u8, cleanLine, ' ');
            var i: usize = 0;
            while (it2.next()) |w| {
                const n = try std.fmt.parseInt(i32, w, 10);
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
