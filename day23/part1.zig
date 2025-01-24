const std = @import("std");

const Complex = std.math.Complex(i32);
const N_AMPHIPODS = 8;

fn manhattan(z1: Complex, z2: Complex) i32 {
    return @intCast(@abs(z1.re - z2.re) + @abs(z1.im - z2.im));
}

const Shape = struct {
    const topRowXs = [_]i32{ 1, 2, 4, 6, 8, 10, 11 };

    hs: std.AutoHashMap(Complex, void),
    a0: [N_AMPHIPODS]Complex,
    bucketXTarget: [N_AMPHIPODS]i32,

    fn cToBucketX(c: u8) i32 {
        return switch (c) {
            'A' => 3,
            'B' => 5,
            'C' => 7,
            'D' => 9,
            else => unreachable,
        };
    }

    fn bucketXToCost(bucketX: i32) i32 {
        return switch (bucketX) {
            3 => 1,
            5 => 10,
            7 => 100,
            9 => 1000,
            else => unreachable,
        };
    }

    fn init(alloc: std.mem.Allocator, s: []const u8) !@This() {
        var shape: Shape = undefined;
        shape.hs = @TypeOf(shape.hs).init(alloc);
        var id: usize = 0;
        var y: i32 = 0;
        var it = std.mem.tokenizeScalar(u8, s, '\n');
        while (it.next()) |line| : (y += 1) {
            var x: i32 = 0;
            for (line) |c| {
                if (std.mem.indexOf(u8, ".ABCD", &[_]u8{c})) |_| {
                    const z = Complex.init(x, y);
                    try shape.hs.put(z, {});
                    if (c != '.') {
                        shape.a0[id] = z;
                        shape.bucketXTarget[id] = Shape.cToBucketX(c);
                        id += 1;
                    }
                }
                x += 1;
            }
        }
        return shape;
    }

    fn deinit(self: *@This()) void {
        self.hs.deinit();
    }
};

const State = struct {
    shape: Shape,
    a: [N_AMPHIPODS]Complex,

    fn getId(self: *const @This(), z: Complex) ?usize {
        for (self.a, 0..) |zz, i| {
            if (zz.re == z.re and zz.im == z.im) return i;
        }
        return null;
    }

    fn isInWrongBucket(self: *const @This(), id: usize) bool {
        if (self.a[id].im == 1) return false;
        return self.shape.bucketXTarget[id] != self.a[id].re;
    }

    fn isInRightBucket(self: *const @This(), id: usize) bool {
        if (self.a[id].im == 1) return false;
        return !self.isInWrongBucket(id);
    }

    fn bucketLevel(self: *const @This(), bucketX: i32) i8 {
        const depth = @divExact(N_AMPHIPODS, 4);
        var n: i8 = 0;
        var y: i32 = 1 + depth;
        while (y > 1) : (y -= 1) {
            if (self.getId(Complex.init(bucketX, y))) |id| {
                if (self.shape.bucketXTarget[id] != bucketX) break;
            } else {
                break;
            }
            n += 1;
        }
        return n;
    }

    fn isBucketClean(self: *const @This(), bucketX: i32) bool {
        const depth = @divExact(N_AMPHIPODS, 4);
        var y: i32 = 1 + depth;
        while (y > 1) : (y -= 1) {
            if (self.getId(Complex.init(bucketX, y))) |id| {
                if (self.shape.bucketXTarget[id] != bucketX) return false;
            }
        }
        return true;
    }

    fn getLowestBucketEmptyZ(self: *const @This(), bucketX: i32) ?Complex {
        if (!self.isBucketClean(bucketX)) return null;
        const depth = @divExact(N_AMPHIPODS, 4);
        var y: i32 = 1 + depth;
        while (y > 1) : (y -= 1) {
            if (self.getId(Complex.init(bucketX, y)) == null) {
                return Complex.init(bucketX, y);
            }
        }
        return null;
    }

    fn travelCosts(self: *const @This(), alloc: std.mem.Allocator, id: usize, lz: []const Complex) ![]struct { Complex, i32 } {
        const DFS = struct {
            seen: std.AutoHashMap(Complex, void),
            moveCost: i32,
            alloc: std.mem.Allocator,
            state: *const State,
            id: usize,
            lz: []const Complex,
            res: std.ArrayList(struct { Complex, i32 }),

            fn init(par: struct {
                alloc: std.mem.Allocator,
                state: *const State,
                id: usize,
                lz: []const Complex,
            }) @This() {
                return .{
                    .seen = std.AutoHashMap(Complex, void).init(par.alloc),
                    .moveCost = Shape.bucketXToCost(par.state.shape.bucketXTarget[par.id]),
                    .alloc = par.alloc,
                    .state = par.state,
                    .id = par.id,
                    .lz = par.lz,
                    .res = std.ArrayList(struct { Complex, i32 }).init(par.alloc),
                };
            }

            fn deinit(selfDFS: *@This()) void {
                selfDFS.seen.deinit();
            }

            fn inLz(selfDFS: *const @This(), z: Complex) bool {
                for (selfDFS.lz) |zz| {
                    if (z.re == zz.re and z.im == zz.im) return true;
                }
                return false;
            }

            fn dfs(selfDFS: *@This(), z: Complex, cost: i32) !void {
                if (selfDFS.inLz(z)) {
                    try selfDFS.res.append(.{ z, cost });
                }
                for ([_]Complex{
                    Complex.init(0, -1),
                    Complex.init(1, 0),
                    Complex.init(0, 1),
                    Complex.init(-1, 0),
                }) |d| {
                    const zz = z.add(d);
                    if (selfDFS.seen.contains(zz)) continue;
                    try selfDFS.seen.put(zz, {});
                    if (!selfDFS.state.shape.hs.contains(zz)) continue;
                    if (selfDFS.state.getId(zz)) |_| continue;
                    try selfDFS.dfs(zz, cost + selfDFS.moveCost);
                }
            }
        };
        var dfs = DFS.init(.{
            .alloc = alloc,
            .state = self,
            .id = id,
            .lz = lz,
        });
        defer dfs.deinit();
        try dfs.dfs(self.a[id], 0);
        return dfs.res.toOwnedSlice();
    }

    fn generateMoves(self: *const @This(), alloc: std.mem.Allocator, id: usize) ![]struct { Complex, i32 } {
        var l = std.ArrayList(struct { Complex, i32 }).init(alloc);
        if (self.isInWrongBucket(id) or (self.isInRightBucket(id) and !self.isBucketClean(self.a[id].re))) {
            var lz: [Shape.topRowXs.len]Complex = undefined;
            for (Shape.topRowXs, 0..) |x, i| lz[i] = Complex.init(x, 1);
            const a = try self.travelCosts(alloc, id, &lz);
            defer alloc.free(a);
            try l.appendSlice(a);
        } else if (self.a[id].im == 1) {
            if (self.getLowestBucketEmptyZ(self.shape.bucketXTarget[id])) |z1| {
                const a = try self.travelCosts(alloc, id, &[_]Complex{z1});
                defer alloc.free(a);
                try l.appendSlice(a);
            }
        }
        return l.toOwnedSlice();
    }

    fn isFinalState(self: *const @This()) bool {
        const depth = @divExact(N_AMPHIPODS, 4);
        for ([_]i32{ 3, 5, 7, 9 }) |x| {
            if (self.bucketLevel(x) < depth) return false;
        }
        return true;
    }

    fn hCost(self: *const @This()) i32 {
        var cost: i32 = 0;
        for (0..self.a.len) |id| {
            const moveCost = Shape.bucketXToCost(self.shape.bucketXTarget[id]);
            if (self.isInRightBucket(id)) continue;
            const z1 = Complex.init(self.shape.bucketXTarget[id], 2);
            const z = self.a[id];
            if (self.isInWrongBucket(id)) {
                cost += (z.im - 1) * moveCost;
                cost += manhattan(Complex.init(z.re, 1), z1) * moveCost;
            } else {
                cost += manhattan(z, z1) * moveCost;
            }
        }
        return cost;
    }
};

fn aStar(alloc: std.mem.Allocator, shape: Shape) !i32 {
    const Node = struct {
        state: State,
        gCost: i32,
        hCost: i32,
    };
    var openSet = std.PriorityQueue(Node, void, struct {
        fn cmp(_: void, lhs: Node, rhs: Node) std.math.Order {
            const cost1 = lhs.gCost + lhs.hCost;
            const cost2 = rhs.gCost + rhs.hCost;
            if (cost1 == cost2) return std.math.order(lhs.hCost, rhs.hCost);
            return std.math.order(cost1, cost2);
        }
    }.cmp).init(alloc, {});
    defer openSet.deinit();
    var openG = std.AutoHashMap([N_AMPHIPODS]Complex, i32).init(alloc);
    defer openG.deinit();
    {
        const state0 = State{ .a = shape.a0, .shape = shape };
        try openSet.add(.{ .state = state0, .gCost = 0, .hCost = state0.hCost() });
        try openG.put(state0.a, 0);
    }
    var closedSet = std.AutoHashMap([N_AMPHIPODS]Complex, void).init(alloc);
    defer closedSet.deinit();
    while (true) {
        const node = openSet.remove();
        _ = openG.remove(node.state.a);
        const state = node.state;
        if (state.isFinalState()) return node.gCost;
        for (0..state.a.len) |id| {
            const moves = try state.generateMoves(alloc, id);
            defer alloc.free(moves);
            for (moves) |move| {
                const z1 = move[0];
                const k = move[1];
                var newState = state;
                newState.a[id] = z1;
                if (closedSet.contains(newState.a)) continue;
                const newNode = Node{
                    .state = newState,
                    .gCost = node.gCost + k,
                    .hCost = newState.hCost(),
                };
                const res = try openG.getOrPut(newState.a);
                if (res.found_existing and res.value_ptr.* <= newNode.gCost) continue;
                res.value_ptr.* = newNode.gCost;
                try openSet.add(newNode);
            }
        }
        try closedSet.put(node.state.a, {});
    }
}

pub fn solve(alloc: std.mem.Allocator, data: []const u8) !void {
    var shape: Shape = try Shape.init(alloc, data);
    defer shape.deinit();
    const res = try aStar(alloc, shape);
    try std.io.getStdOut().writer().print("{}\n", .{res});
}
