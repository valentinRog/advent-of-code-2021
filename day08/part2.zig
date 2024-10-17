const std = @import("std");

const digitChar = "abcdefg";

const digitStringToInt = std.StaticStringMap(u8).initComptime([_]struct { []const u8, u32 }{
    .{ "abcefg", 0 },
    .{ "cf", 1 },
    .{ "acdeg", 2 },
    .{ "acdfg", 3 },
    .{ "bcdf", 4 },
    .{ "abdfg", 5 },
    .{ "abdefg", 6 },
    .{ "acf", 7 },
    .{ "abcdefg", 8 },
    .{ "abcdfg", 9 },
});

const Sequence = std.AutoHashMap(u8, u8);

fn applySequence(alloc: std.mem.Allocator, m: *const Sequence, s: []const u8) !std.ArrayList(u8) {
    var l = std.ArrayList(u8).init(alloc);
    for (s) |c| {
        try l.append(m.get(c).?);
    }
    std.mem.sort(u8, l.items, {}, std.sort.asc(u8));
    return l;
}

const Entry = struct {
    signals: std.ArrayList([]const u8),
    output: std.ArrayList([]const u8),

    fn init(alloc: std.mem.Allocator) @This() {
        return .{
            .signals = std.ArrayList([]const u8).init(alloc),
            .output = std.ArrayList([]const u8).init(alloc),
        };
    }

    fn deinit(self: *@This()) void {
        self.signals.deinit();
        self.output.deinit();
    }

    fn parse(alloc: std.mem.Allocator, s: []const u8) !@This() {
        var e: Entry = @This().init(alloc);
        var i: usize = 0;
        var targets = [_]*std.ArrayList([]const u8){ &e.signals, &e.output };
        {
            var it = std.mem.tokenizeScalar(u8, s, ' ');
            while (it.next()) |w| {
                if (std.mem.eql(u8, w, "|")) {
                    i += 1;
                    continue;
                }
                try targets[i].append(w);
            }
        }
        return e;
    }

    fn validSequence(self: *@This(), alloc: std.mem.Allocator, m: *const Sequence) !bool {
        const data = [_][][]const u8{ self.signals.items, self.output.items };
        for (data) |items| {
            for (items) |s| {
                const l = try applySequence(alloc, m, s);
                defer l.deinit();
                if (!digitStringToInt.has(l.items)) {
                    return false;
                }
            }
        }
        return true;
    }

    fn findSequence(self: *@This(), alloc: std.mem.Allocator) !Sequence {
        var helper = struct {
            alloc: std.mem.Allocator,
            entry: *Entry,
            m: Sequence,

            fn find(selfHelper: *@This()) !?Sequence {
                if (selfHelper.m.count() == digitChar.len) {
                    if (try selfHelper.entry.validSequence(selfHelper.alloc, &selfHelper.m)) {
                        return selfHelper.m;
                    }
                    return null;
                }
                for (digitChar) |c| {
                    if (selfHelper.m.get(c)) |_| {
                        continue;
                    }
                    try selfHelper.m.put(c, @intCast(selfHelper.m.count() + 'a'));
                    if (try selfHelper.find()) |res| {
                        return res;
                    }
                    _ = selfHelper.m.remove(c);
                }
                return null;
            }
        }{ .alloc = alloc, .entry = self, .m = Sequence.init(alloc) };
        return (try helper.find()).?;
    }

    fn compute(self: *@This(), alloc: std.mem.Allocator) !u32 {
        var m = try self.findSequence(alloc);
        defer m.deinit();
        var res: u32 = 0;
        for (self.output.items, 0..) |s, i| {
            const l = try applySequence(alloc, &m, s);
            defer l.deinit();
            res += digitStringToInt.get(l.items).? * std.math.pow(u32, 10, @intCast(self.output.items.len - i - 1));
        }
        return res;
    }
};

pub fn solve(alloc: std.mem.Allocator, data: []const u8) !void {
    var l = std.ArrayList(Entry).init(alloc);
    defer {
        for (l.items) |*e| {
            e.deinit();
        }
        l.deinit();
    }
    {
        var it = std.mem.tokenizeScalar(u8, data, '\n');
        while (it.next()) |line| {
            try l.append(try Entry.parse(alloc, line));
        }
    }

    var res: u32 = 0;
    for (l.items) |*e| {
        var arena = std.heap.ArenaAllocator.init(alloc);
        defer arena.deinit();
        res += try e.compute(arena.allocator());
    }
    try std.io.getStdOut().writer().print("{}\n", .{res});
}
