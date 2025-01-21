const std = @import("std");

const Player = struct {
    p: u32,
    score: u32,

    fn play(self: *@This(), n: u32) void {
        self.p += n;
        self.p = switch (@rem(self.p, 10)) {
            0 => 10,
            else => |v| v,
        };
        self.score += self.p;
    }
};

fn compute(alloc: std.mem.Allocator, players: [2]Player) ![2]u64 {
    const H = struct {
        const Par = struct { players: [2]Player, turn: u8, rem: u8, acc: u32 };
        cache: std.AutoHashMap(Par, [2]u64),

        fn compute(self: *@This(), par: Par) ![2]u64 {
            if (self.cache.get(par)) |v| return v;
            if (par.rem == 0) {
                var new_players = par.players;
                new_players[par.turn].play(par.acc);
                return self.compute(.{
                    .players = new_players,
                    .turn = @rem(par.turn + 1, 2),
                    .rem = 3,
                    .acc = 0,
                });
            }
            const target = 21;
            if (par.players[0].score >= target) return .{ 1, 0 };
            if (par.players[1].score >= target) return .{ 0, 1 };
            var res = [2]u64{ 0, 0 };
            var die: u32 = 1;
            while (die <= 3) : (die += 1) {
                const output = try self.compute(.{
                    .players = par.players,
                    .turn = par.turn,
                    .rem = par.rem - 1,
                    .acc = par.acc + die,
                });
                for (0..2) |i| res[i] += output[i];
            }
            try self.cache.put(par, res);
            return res;
        }
    };
    var h = H{ .cache = std.AutoHashMap(H.Par, [2]u64).init(alloc) };
    defer h.cache.deinit();
    return try h.compute(.{ .players = players, .turn = 0, .rem = 3, .acc = 0 });
}

pub fn solve(alloc: std.mem.Allocator, data: []const u8) !void {
    var players: [2]Player = undefined;
    {
        var it1 = std.mem.tokenizeScalar(u8, data, '\n');
        for (0..2) |i| {
            const line = it1.next().?;
            players[i] = .{ .p = line[line.len - 1] - '0', .score = 0 };
        }
    }
    const output = try compute(alloc, players);
    const res = @max(output[0], output[1]);
    try std.io.getStdOut().writer().print("{}\n", .{res});
}
