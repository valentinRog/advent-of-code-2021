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

const Die = struct {
    n: u32,
    k: u32,

    fn init() @This() {
        return .{ .n = 1, .k = 0 };
    }

    fn roll(self: *@This()) u32 {
        self.k += 1;
        const n = self.n;
        self.n += 1;
        return n;
    }
};

pub fn solve(data: []const u8) !void {
    var players: [2]Player = undefined;
    {
        var it1 = std.mem.tokenizeScalar(u8, data, '\n');
        for (0..2) |i| {
            const line = it1.next().?;
            players[i] = .{ .p = line[line.len - 1] - '0', .score = 0 };
        }
    }
    var die = Die.init();
    out: while (true) {
        for (&players) |*p| {
            var n: u32 = 0;
            for (0..3) |_| n += die.roll();
            p.play(n);
            if (p.score >= 1000) break :out;
        }
    }
    const res = @min(players[0].score, players[1].score) * die.k;
    try std.io.getStdOut().writer().print("{}\n", .{res});
}
