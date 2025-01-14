const std = @import("std");
const Complex = std.math.Complex(i32);

fn get_clean_data(alloc: std.mem.Allocator, data: []const u8) ![]const u8 {
    const res = try alloc.dupe(u8, data);
    for (res) |*c| {
        if (!std.ascii.isDigit(c.*) and c.* != '-') c.* = ' ';
    }
    return res;
}

fn hit(vx0: i32, vy0: i32, x0: i32, x1: i32, y0: i32, y1: i32) bool {
    var x: i32 = 0;
    var y: i32 = 0;
    var vx = vx0;
    var vy = vy0;
    var maxY: i32 = std.math.minInt(i32);
    while (x <= x1 and y >= y0) {
        x += vx;
        y += vy;
        maxY = @max(maxY, y);
        if (vx > 0) vx -= 1;
        vy -= 1;
        if (x >= x0 and x <= x1 and y >= y0 and y <= y1) return true;
    }
    return false;
}

pub fn solve(alloc: std.mem.Allocator, data: []const u8) !void {
    const clean_data = try get_clean_data(alloc, data);
    defer alloc.free(clean_data);
    var x0: i32 = undefined;
    var x1: i32 = undefined;
    var y0: i32 = undefined;
    var y1: i32 = undefined;
    {
        var l = std.ArrayList(i32).init(alloc);
        defer l.deinit();
        var it = std.mem.tokenizeScalar(u8, clean_data, ' ');
        while (it.next()) |w| {
            const n = try std.fmt.parseInt(i32, w, 10);
            try l.append(n);
        }
        x0 = l.items[0];
        x1 = l.items[1];
        y0 = l.items[2];
        y1 = l.items[3];
    }
    const vyMin: i32 = y0;
    const vyMax: i32 = @intCast(@abs(y0));
    const vxMin: i32 = @intFromFloat(std.math.sqrt(@as(f32, @floatFromInt(2 * x0))));
    const vxMax: i32 = x1;
    var vx = vxMin;
    var res: i32 = 0;
    while (vx <= vxMax) : (vx += 1) {
        var vy = vyMin;
        while (vy <= vyMax) : (vy += 1) {
            if (hit(vx, vy, x0, x1, y0, y1)) {
                res += 1;
            }
        }
    }
    try std.io.getStdOut().writer().print("{}\n", .{res});
}
