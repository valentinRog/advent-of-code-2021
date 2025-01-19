const std = @import("std");
const Hs = std.AutoHashMap(Vec3, void);

const Vec3 = struct {
    x: i32,
    y: i32,
    z: i32,

    fn new(x: i32, y: i32, z: i32) @This() {
        return .{ .x = x, .y = y, .z = z };
    }

    fn manhattan(self: *const @This(), other: @This()) i32 {
        return @intCast(@abs(self.x - other.x) + @abs(self.y - other.y) + @abs(self.z - other.z));
    }

    fn rx(self: *const @This()) @This() {
        return new(self.x, -self.z, self.y);
    }
    fn ry(self: *const @This()) @This() {
        return new(self.z, self.y, -self.x);
    }
    fn rz(self: *const @This()) @This() {
        return new(-self.y, self.x, self.z);
    }
};

fn hsEqual(hs1: Hs, hs2: Hs) bool {
    var it = hs1.keyIterator();
    while (it.next()) |k| if (!hs2.contains(k.*)) return false;
    return true;
}

fn generateRotations(alloc: std.mem.Allocator, hs: Hs) !std.ArrayList(Hs) {
    var l = std.ArrayList(Hs).init(alloc);
    const h = struct {
        l: *const @TypeOf(l),

        fn contains(self: *const @This(), hs1: Hs) bool {
            for (self.l.items) |hs2| {
                if (hsEqual(hs1, hs2)) return true;
            }
            return false;
        }
    }{ .l = &l };
    for (0..4) |rx| {
        for (0..4) |ry| {
            for (0..4) |rz| {
                var hs2 = Hs.init(alloc);
                var it = hs.keyIterator();
                while (it.next()) |v0| {
                    var v = v0.*;
                    for (0..rx) |_| v = v.rx();
                    for (0..ry) |_| v = v.ry();
                    for (0..rz) |_| v = v.rz();
                    try hs2.put(v, {});
                }
                if (!h.contains(hs2)) {
                    try l.append(hs2);
                } else {
                    hs2.deinit();
                }
            }
        }
    }
    return l;
}

fn translate(alloc: std.mem.Allocator, hs0: Hs, d: Vec3) !Hs {
    var hs = Hs.init(alloc);
    var it = hs0.keyIterator();
    while (it.next()) |v| {
        try hs.put(Vec3.new(v.x + d.x, v.y + d.y, v.z + d.z), {});
    }
    return hs;
}

const Scanners = struct {
    l: std.ArrayList(Hs),
    seen: std.AutoHashMap(usize, void),
    positions: std.AutoHashMap(usize, Vec3),
    alloc: std.mem.Allocator,

    fn init(alloc: std.mem.Allocator, hs0: Hs) !@This() {
        var self = @This(){
            .l = std.ArrayList(Hs).init(alloc),
            .seen = std.AutoHashMap(usize, void).init(alloc),
            .positions = std.AutoHashMap(usize, Vec3).init(alloc),
            .alloc = alloc,
        };
        try self.l.append(try hs0.cloneWithAllocator(alloc));
        try self.seen.put(0, {});
        try self.positions.put(0, Vec3.new(0, 0, 0));
        return self;
    }

    fn deinit(self: *@This()) void {
        for (self.l.items) |*e| e.deinit();
        self.l.deinit();
        self.seen.deinit();
        self.positions.deinit();
    }

    fn addScanner(self: *@This(), l: std.ArrayList(Hs)) !bool {
        for (0.., l.items) |i, hs| {
            if (self.seen.contains(i)) continue;
            for (self.l.items) |hs1| {
                var rotatedHs = try generateRotations(self.alloc, hs);
                defer {
                    for (rotatedHs.items) |*e| e.deinit();
                    rotatedHs.deinit();
                }
                for (rotatedHs.items) |hs2| {
                    var it1 = hs1.keyIterator();
                    while (it1.next()) |t1| {
                        var it2 = hs2.keyIterator();
                        while (it2.next()) |t2| {
                            const d = Vec3.new(t1.x - t2.x, t1.y - t2.y, t1.z - t2.z);
                            try self.positions.put(i, d);
                            var n: u32 = 0;
                            var it3 = hs2.keyIterator();
                            while (it3.next()) |v| {
                                if (hs1.contains(Vec3.new(v.x + d.x, v.y + d.y, v.z + d.z))) n += 1;
                            }
                            if (n >= 12) {
                                const translatedHs2 = try translate(self.alloc, hs2, d);
                                try self.l.append(translatedHs2);
                                try self.seen.put(i, {});
                                return true;
                            }
                        }
                    }
                }
            }
        }
        return false;
    }
};

pub fn solve(alloc: std.mem.Allocator, data: []const u8) !void {
    var l = std.ArrayList(Hs).init(alloc);
    defer {
        for (l.items) |*e| e.deinit();
        l.deinit();
    }
    {
        var it1 = std.mem.tokenizeSequence(u8, data, "\n\n");
        while (it1.next()) |block| {
            var m = Hs.init(alloc);
            var it2 = std.mem.tokenizeScalar(u8, block, '\n');
            _ = it2.next();
            while (it2.next()) |line| {
                var it3 = std.mem.tokenizeScalar(u8, line, ',');
                var ll = std.ArrayList(i32).init(alloc);
                defer ll.deinit();
                while (it3.next()) |w| {
                    const n = try std.fmt.parseInt(i32, w, 10);
                    try ll.append(n);
                }
                try m.put(Vec3.new(ll.items[0], ll.items[1], ll.items[2]), {});
            }
            try l.append(m);
        }
    }
    var scanners = try Scanners.init(alloc, l.items[0]);
    defer scanners.deinit();
    while (try scanners.addScanner(l)) {}
    var dist: i32 = std.math.minInt(i32);
    {
        var it1 = scanners.positions.valueIterator();
        while (it1.next()) |v1| {
            var it2 = scanners.positions.valueIterator();
            while (it2.next()) |v2| {
                dist = @max(dist, v1.manhattan(v2.*));
            }
        }
    }
    try std.io.getStdOut().writer().print("{}\n", .{dist});
}
