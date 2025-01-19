const std = @import("std");

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

fn hs_equal(hs1: std.AutoHashMap(Vec3, void), hs2: std.AutoHashMap(Vec3, void)) bool {
    var it = hs1.keyIterator();
    while (it.next()) |k| if (!hs2.contains(k.*)) return false;
    return true;
}

fn generate_rotations(
    alloc: std.mem.Allocator,
    hs: std.AutoHashMap(Vec3, void),
) !std.ArrayList(std.AutoHashMap(Vec3, void)) {
    var l = std.ArrayList(std.AutoHashMap(Vec3, void)).init(alloc);
    const h = struct {
        l: *const @TypeOf(l),

        fn contains(self: *const @This(), hs1: std.AutoHashMap(Vec3, void)) bool {
            for (self.l.items) |hs2| {
                if (hs_equal(hs1, hs2)) return true;
            }
            return false;
        }
    }{ .l = &l };
    for (0..4) |rx| {
        for (0..4) |ry| {
            for (0..4) |rz| {
                var hs2 = std.AutoHashMap(Vec3, void).init(alloc);
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

fn translate(
    alloc: std.mem.Allocator,
    hs0: std.AutoHashMap(Vec3, void),
    d: Vec3,
) !std.AutoHashMap(Vec3, void) {
    var hs = std.AutoHashMap(Vec3, void).init(alloc);
    var it = hs0.keyIterator();
    while (it.next()) |v| {
        try hs.put(Vec3.new(v.x + d.x, v.y + d.y, v.z + d.z), {});
    }
    return hs;
}

fn intersectionCount(hs1: std.AutoHashMap(Vec3, void), hs2: std.AutoHashMap(Vec3, void)) usize {
    var n: usize = 0;
    var it = hs1.keyIterator();
    while (it.next()) |k| {
        if (hs2.contains(k.*)) n += 1;
    }
    return n;
}

const Scanners = struct {
    l: std.ArrayList(std.AutoHashMap(Vec3, void)),
    seen: std.AutoHashMap(usize, void),
    positions: std.AutoHashMap(usize, Vec3),
    alloc: std.mem.Allocator,

    fn init(alloc: std.mem.Allocator, hs0: std.AutoHashMap(Vec3, void)) !@This() {
        var self = @This(){
            .l = std.ArrayList(std.AutoHashMap(Vec3, void)).init(alloc),
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

    fn add_scanner(self: *@This(), l: std.ArrayList(std.AutoHashMap(Vec3, void))) !bool {
        for (0.., l.items) |i, hs| {
            if (self.seen.contains(i)) continue;
            for (self.l.items) |hs1| {
                var rotatedHs = try generate_rotations(self.alloc, hs);
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
                            var translatedHs2 = try translate(self.alloc, hs2, d);
                            if (intersectionCount(hs1, translatedHs2) >= 12) {
                                try self.l.append(translatedHs2);
                                try self.seen.put(i, {});
                                return true;
                            }
                            translatedHs2.deinit();
                        }
                    }
                }
            }
        }
        return false;
    }
};

pub fn solve(alloc: std.mem.Allocator, data: []const u8) !void {
    var l = std.ArrayList(std.AutoHashMap(Vec3, void)).init(alloc);
    defer {
        for (l.items) |*e| e.deinit();
        l.deinit();
    }
    {
        var it1 = std.mem.tokenizeSequence(u8, data, "\n\n");
        while (it1.next()) |block| {
            var m = std.AutoHashMap(Vec3, void).init(alloc);
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
    while (try scanners.add_scanner(l)) {}
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
