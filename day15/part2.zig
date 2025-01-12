const std = @import("std");
const Complex = std.math.Complex(i32);

fn extend(m: *std.AutoHashMap(Complex, i32)) !void {
    const toi32 = struct {
        fn toi32(n: usize) i32 {
            return @as(i32, @intCast(n));
        }
    }.toi32;
    const wh: usize = std.math.sqrt(m.count());
    for (0..5) |tile_y| {
        for (0..5) |tile_x| {
            for (0..wh) |y| {
                for (0..wh) |x| {
                    const k = Complex.init(toi32(x + tile_x * wh), toi32(y + tile_y * wh));
                    var v = m.get(Complex.init(toi32(x), toi32(y))).? + toi32(tile_x + tile_y);
                    if (v > 9) v -= 9;
                    try m.put(k, v);
                }
            }
        }
    }
}

fn dijkstra(alloc: std.mem.Allocator, m: std.AutoHashMap(Complex, i32)) !i32 {
    const wh = std.math.sqrt(m.count());
    const z1 = Complex.init(wh - 1, wh - 1);
    const Node = struct { z: Complex, cost: i32 };
    var q = std.PriorityQueue(Node, void, struct {
        fn cmp(_: void, e1: Node, e2: Node) std.math.Order {
            return std.math.order(e1.cost, e2.cost);
        }
    }.cmp).init(alloc, void{});
    defer q.deinit();
    try q.add(Node{ .z = Complex.init(0, 0), .cost = 0 });
    var open_set = std.AutoHashMap(Complex, i32).init(alloc);
    defer open_set.deinit();
    try open_set.put(q.peek().?.z, 0);
    var closed_set = std.AutoHashMap(Complex, i32).init(alloc);
    defer closed_set.deinit();
    while (true) {
        const node = q.remove();
        _ = open_set.remove(node.z);
        if (node.z.re == z1.re and node.z.im == z1.im) return node.cost;
        try closed_set.put(node.z, node.cost);
        for ([_]Complex{
            Complex.init(1, 0),
            Complex.init(0, 1),
            Complex.init(-1, 0),
            Complex.init(0, -1),
        }) |d| {
            const z = node.z.add(d);
            if (closed_set.contains(z) or !m.contains(z)) continue;
            const cost = node.cost + m.get(z).?;
            const res = try open_set.getOrPut(z);
            if (res.found_existing and res.value_ptr.* <= cost) continue;
            res.value_ptr.* = cost;
            try q.add(Node{ .z = z, .cost = cost });
        }
    }
}

pub fn solve(alloc: std.mem.Allocator, data: []const u8) !void {
    var m = std.AutoHashMap(Complex, i32).init(alloc);
    defer m.deinit();
    {
        var it = std.mem.tokenizeScalar(u8, data, '\n');
        var y: i32 = 0;
        while (it.next()) |line| {
            for (0.., line) |x, c| {
                try m.put(Complex.init(@intCast(x), y), c - '0');
            }
            y += 1;
        }
    }
    try extend(&m);
    const n = try dijkstra(alloc, m);
    try std.io.getStdOut().writer().print("{}\n", .{n});
}
