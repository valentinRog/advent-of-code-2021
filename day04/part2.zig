const std = @import("std");

const grid_size = 5;

const Grid = struct {
    arr: [grid_size][grid_size]i32,

    fn parse(block: []const u8) !Grid {
        var grid: Grid = undefined;
        var it = std.mem.tokenizeAny(u8, block, "\n");
        var i: usize = 0;
        while (it.next()) |line| {
            var it2 = std.mem.tokenizeAny(u8, line, " ");
            var j: usize = 0;
            while (it2.next()) |w| {
                const n = try std.fmt.parseInt(i32, w, 10);
                grid.arr[i][j] = n;
                j += 1;
            }
            i += 1;
        }
        return grid;
    }

    fn checkRow(self: *const @This(), hs: *std.AutoHashMap(i32, void), i: usize) bool {
        for (0..grid_size) |j| {
            if (hs.get(self.arr[i][j]) == null) {
                return false;
            }
        }
        return true;
    }

    fn checkColumn(self: *const @This(), hs: *std.AutoHashMap(i32, void), j: usize) bool {
        for (0..grid_size) |i| {
            if (hs.get(self.arr[i][j]) == null) {
                return false;
            }
        }
        return true;
    }

    fn computeScore(self: *const @This(), hs: *std.AutoHashMap(i32, void)) i32 {
        var n: i32 = 0;
        for (0..grid_size) |i| {
            for (0..grid_size) |j| {
                if (hs.get(self.arr[i][j]) == null) {
                    n += self.arr[i][j];
                }
            }
        }
        return n;
    }

    fn computeScoreColumn(self: *const @This(), column_j: usize) i32 {
        var n: i32 = 0;
        for (0..grid_size) |i| {
            for (0..grid_size) |j| {
                if (j != column_j) {
                    n += self.arr[i][j];
                }
            }
        }
        return n;
    }

    fn score(self: *const @This(), hs: *std.AutoHashMap(i32, void)) ?i32 {
        for (0..grid_size) |i| {
            if (self.checkRow(hs, i) or self.checkColumn(hs, i)) {
                return self.computeScore(hs);
            }
        }
        return null;
    }
};

fn compute(numbers: []i32, grids: []Grid, alloc: std.mem.Allocator) !i32 {
    var hs = std.AutoHashMap(i32, void).init(alloc);
    defer hs.deinit();
    var remain = std.AutoHashMap(usize, void).init(alloc);
    defer remain.deinit();
    for (0..grids.len) |i| {
        try remain.put(i, void{});
    }
    for (numbers) |n| {
        try hs.put(n, void{});
        for (0..grids.len) |i| {
            if (remain.get(i) == null) {
                continue;
            }
            if (grids[i].score(&hs)) |score| {
                if (remain.count() == 1) {
                    return n * score;
                }
                _ = remain.remove(i);
            }
        }
    }
    unreachable;
}

pub fn solve(data: []const u8, alloc: std.mem.Allocator) !void {
    var numbers = std.ArrayList(i32).init(alloc);
    defer numbers.deinit();
    var grids = std.ArrayList(Grid).init(alloc);
    defer grids.deinit();
    var it = std.mem.tokenizeSequence(u8, data, "\n\n");
    {
        var it2 = std.mem.tokenizeSequence(u8, it.next().?, ",");
        while (it2.next()) |w| {
            try numbers.append(try std.fmt.parseInt(u8, w, 10));
        }
    }
    while (it.next()) |block| {
        try grids.append(try Grid.parse(block));
    }

    const res = try compute(numbers.items, grids.items, alloc);
    try std.io.getStdOut().writer().print("{}\n", .{res});
}
