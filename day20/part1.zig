const std = @import("std");
const Complex = std.math.Complex(i32);
const Hs = std.AutoHashMap(Complex, void);

const Compute = struct {
    const Cache = std.AutoHashMap(struct { z: Complex, step: i32 }, bool);

    s: []const u8,
    hs: Hs,
    cache: Cache,

    fn init(alloc: std.mem.Allocator, s: []const u8) @This() {
        return .{
            .s = s,
            .hs = Hs.init(alloc),
            .cache = Cache.init(alloc),
        };
    }

    fn deinit(self: *@This()) void {
        self.hs.deinit();
        self.cache.deinit();
    }

    fn isLit(self: *@This(), z: Complex, step: i32) !bool {
        if (self.cache.get(.{ .z = z, .step = step })) |v| return v;
        if (step == 0) return self.hs.contains(z);
        var i: usize = 0;
        for (&[_]Complex{
            Complex.init(-1, -1),
            Complex.init(0, -1),
            Complex.init(1, -1),
            Complex.init(-1, 0),
            Complex.init(0, 0),
            Complex.init(1, 0),
            Complex.init(-1, 1),
            Complex.init(0, 1),
            Complex.init(1, 1),
        }) |d| {
            i <<= 1;
            if (try self.isLit(z.add(d), step - 1)) i |= 1;
        }
        try self.cache.put(.{ .z = z, .step = step }, self.s[i] == '#');
        return self.s[i] == '#';
    }
};

pub fn solve(alloc: std.mem.Allocator, data: []const u8) !void {
    var it1 = std.mem.tokenizeSequence(u8, data, "\n\n");
    var compute = Compute.init(alloc, it1.next().?);
    defer compute.deinit();
    {
        var it2 = std.mem.tokenizeScalar(u8, it1.next().?, '\n');
        var y: i32 = 0;
        while (it2.next()) |line| : (y += 1) {
            var x: i32 = 0;
            for (line) |c| {
                if (c == '#') try compute.hs.put(Complex.init(x, y), {});
                x += 1;
            }
        }
    }
    var xMin: i32 = std.math.maxInt(i32);
    var xMax: i32 = std.math.minInt(i32);
    var yMin: i32 = std.math.maxInt(i32);
    var yMax: i32 = std.math.minInt(i32);
    {
        var it = compute.hs.keyIterator();
        while (it.next()) |z| {
            xMin = @min(xMin, z.re);
            xMax = @max(xMax, z.re);
            yMin = @min(yMin, z.im);
            yMax = @max(yMax, z.im);
        }
    }
    const steps = 2;
    var res: u32 = 0;
    var y = yMin - steps;
    while (y <= yMax + steps) : (y += 1) {
        var x = xMin - steps;
        while (x <= xMax + steps) : (x += 1) {
            if (try compute.isLit(Complex.init(x, y), steps)) res += 1;
        }
    }
    try std.io.getStdOut().writer().print("{}\n", .{res});
}
