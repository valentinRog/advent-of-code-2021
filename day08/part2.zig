const std = @import("std");

const digitStrings = [_][]const u8{
    "abcefg",
    "cf",
    "acdeg",
    "acdfg",
    "bcdf",
    "abdfg",
    "abdefg",
    "acf",
    "abcdefg",
    "abcdfg",
};

const Sequences = struct {
    const SequencesList = std.ArrayList(std.ArrayList(u8));

    sequences: SequencesList,

    fn init(alloc: std.mem.Allocator) Sequences {
        return .{ .sequences = SequencesList.init(alloc) };
    }

    fn deinit(self: *@This()) void {
        for (self.sequences.items) |e| {
            e.deinit();
        }
        self.sequences.deinit();
    }

    fn compute(self: *@This(), alloc: std.mem.Allocator) !void {
        var sequences = Sequences.init(alloc);
        try sequences.sequences.append(std.ArrayList(u8).init(alloc));
        var i: i32 = 0;
        while (i < 7) {
            var new_sequences = Sequences.init(alloc);

            for (sequences.sequences.items) |sequence| {
                for ('a'..'g' + 1) |c| {
                    const needle = [_]u8{@intCast(c)};
                    if (std.mem.count(u8, sequence.items, &needle) > 0) {
                        continue;
                    }
                    var new_sequence = try sequence.clone();
                    try new_sequence.append(@intCast(c));
                    try new_sequences.sequences.append(new_sequence);
                }
            }
            sequences.deinit();
            sequences = new_sequences;
            i += 1;
        }
        self.sequences = sequences.sequences;
    }
};

fn transformWithSequence(alloc: std.mem.Allocator, sequence: []const u8, s: []const u8) !std.ArrayList(u8) {
    var l = std.ArrayList(u8).init(alloc);
    for (s) |c| {
        try l.append(sequence[c - 'a']);
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

    fn validSequence(self: *const @This(), alloc: std.mem.Allocator, sequence: []const u8) !bool {
        const data = [_][][]const u8{ self.signals.items, self.output.items };
        for (data) |items| {
            for (items) |s| {
                const l = try transformWithSequence(alloc, sequence, s);
                defer l.deinit();
                const any: bool = out: {
                    for (digitStrings) |ds| {
                        if (std.mem.eql(u8, l.items, ds)) {
                            break :out true;
                        }
                    }
                    break :out false;
                };
                if (!any) {
                    return false;
                }
            }
        }
        return true;
    }

    fn compute(self: *const @This(), alloc: std.mem.Allocator, sequence: []const u8) !u64 {
        var res: u64 = 0;
        for (self.output.items, 0..) |s, i| {
            const l = try transformWithSequence(alloc, sequence, s);
            defer l.deinit();
            var n: u64 = 0;
            while (true) {
                if (std.mem.eql(u8, l.items, digitStrings[n])) {
                    break;
                }
                n += 1;
            }
            res += n * std.math.pow(u64, 10, @intCast(self.output.items.len - 1 - i));
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
    var sequences = Sequences.init(alloc);
    defer sequences.deinit();
    try sequences.compute(alloc);

    var res: u64 = 0;
    for (sequences.sequences.items) |sequence| {
        for (l.items) |*entry| {
            if (!try entry.validSequence(alloc, sequence.items)) {
                continue;
            }
            res += try entry.compute(alloc, sequence.items);
        }
    }
    try std.io.getStdOut().writer().print("{}\n", .{res});
}
