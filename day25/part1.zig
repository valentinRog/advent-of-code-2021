const std = @import("std");

const Complex = std.math.Complex(i32);

const M = struct {
    m: std.AutoHashMap(Complex, u8),

    fn init(alloc: std.mem.Allocator) @This() {
        return .{ .m = std.AutoHashMap(Complex, u8).init(alloc) };
    }

    fn deinit(self: *@This()) void {
        self.m.deinit();
    }

    fn move(self: *@This()) !bool {
        var any = false;
        for (">v") |c0| {
            const d = switch (c0) {
                '>' => Complex.init(1, 0),
                'v' => Complex.init(0, 1),
                else => unreachable,
            };
            var m = @TypeOf(self.m).init(self.m.allocator);
            var it = self.m.iterator();
            while (it.next()) |kv| {
                const z = kv.key_ptr.*;
                const c = kv.value_ptr.*;
                if (c != c0) {
                    if (!m.contains(z)) try m.put(z, c);
                } else {
                    if (c == '.') unreachable;
                    var zz = z.add(d);
                    if (!self.m.contains(zz)) zz = switch (c0) {
                        '>' => Complex.init(0, zz.im),
                        'v' => Complex.init(zz.re, 0),
                        else => unreachable,
                    };
                    if (self.m.get(zz).? == '.') {
                        try m.put(zz, c);
                        try m.put(z, '.');
                        any = true;
                    } else {
                        try m.put(z, c);
                    }
                }
            }
            self.m.deinit();
            self.m = m;
        }
        return any;
    }
};

pub fn solve(alloc: std.mem.Allocator, data: []const u8) !void {
    var m = M.init(alloc);
    defer m.deinit();
    {
        var it = std.mem.tokenizeScalar(u8, data, '\n');
        var y: i32 = 0;
        while (it.next()) |line| : (y += 1) {
            var x: i32 = 0;
            for (line) |c| {
                try m.m.put(Complex.init(x, y), c);
                x += 1;
            }
        }
    }
    var res: u32 = 0;
    while (try m.move()) : (res += 1) {}
    try std.io.getStdOut().writer().print("{}\n", .{res + 1});
}
