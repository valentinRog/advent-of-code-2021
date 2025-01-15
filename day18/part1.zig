const std = @import("std");

const TokenType = enum {
    OpenBracket,
    CloseBracket,
    Comma,
    Number,
};

const Token = union(TokenType) {
    OpenBracket,
    CloseBracket,
    Comma,
    Number: i32,

    fn clone(self: *const @This(), alloc: std.mem.Allocator) !*@This() {
        const tokenP = try alloc.create(Token);
        tokenP.* = self.*;
        return tokenP;
    }
};

const Lexer = struct {
    i: usize,
    s: []const u8,
    alloc: std.mem.Allocator,

    fn next(self: *@This()) !?Token {
        if (self.i == self.s.len) return null;
        switch (self.s[self.i]) {
            '[' => {
                self.i += 1;
                return Token{ .OpenBracket = {} };
            },
            ']' => {
                self.i += 1;
                return Token{ .CloseBracket = {} };
            },
            ',' => {
                self.i += 1;
                return Token{ .Comma = {} };
            },
            else => {
                var l = std.ArrayList(u8).init(self.alloc);
                defer l.deinit();
                while (std.ascii.isDigit(self.s[self.i])) : (self.i += 1) {
                    try l.append(self.s[self.i]);
                }
                return Token{ .Number = try std.fmt.parseInt(i32, l.items, 10) };
            },
        }
    }
};

fn tokenize(alloc: std.mem.Allocator, data: []const u8) ![]Token {
    var l = std.ArrayList(Token).init(alloc);
    var lexer = Lexer{ .i = 0, .s = data, .alloc = alloc };
    while (try lexer.next()) |token| {
        try l.append(token);
    }
    return l.toOwnedSlice();
}

const L = struct {
    alloc: std.mem.Allocator,
    l: std.ArrayList(*Token),

    fn init(alloc: std.mem.Allocator, l0: []const Token) !@This() {
        var l = std.ArrayList(*Token).init(alloc);
        for (l0) |token| {
            try l.append(try token.clone(alloc));
        }
        return .{ .alloc = alloc, .l = l };
    }

    fn deinit(self: *@This()) void {
        for (self.l.items) |tokenP| {
            self.alloc.destroy(tokenP);
        }
        self.l.deinit();
    }

    fn add(self: *@This(), rhs: []const Token) !void {
        var l = std.ArrayList(*Token).init(self.alloc);
        try l.append(try (Token{ .OpenBracket = {} }).clone(self.alloc));
        try l.appendSlice(self.l.items);
        try l.append(try (Token{ .Comma = {} }).clone(self.alloc));
        for (rhs) |token| {
            try l.append(try token.clone(self.alloc));
        }
        try l.append(try (Token{ .CloseBracket = {} }).clone(self.alloc));
        self.l.deinit();
        self.l = l;
    }

    fn extractNumbers(self: *const @This(), i: usize) ?struct { n1: i32, n2: i32 } {
        const items = self.l.items;
        switch (items[i].*) {
            .OpenBracket => {},
            else => return null,
        }
        const n1: i32 = switch (items[i + 1].*) {
            .Number => |n| n,
            else => return null,
        };
        switch (items[i + 2].*) {
            .Comma => {},
            else => return null,
        }
        const n2: i32 = switch (items[i + 3].*) {
            .Number => |n| n,
            else => return null,
        };
        switch (items[i + 4].*) {
            .CloseBracket => {},
            else => return null,
        }
        return .{ .n1 = n1, .n2 = n2 };
    }

    fn explode(self: *@This()) !bool {
        var depth: i32 = 0;
        const items = self.l.items;
        for (0..items.len - 4) |i| {
            switch (items[i].*) {
                .OpenBracket => depth += 1,
                .CloseBracket => {
                    depth -= 1;
                    continue;
                },
                else => continue,
            }
            const numbers = self.extractNumbers(i) orelse continue;
            if (depth < 5) continue;
            var iLeft = i;
            while (iLeft > 0) : (iLeft -= 1) {
                switch (items[iLeft - 1].*) {
                    .Number => |*n| {
                        n.* += numbers.n1;
                        break;
                    },
                    else => {},
                }
            }
            var iRight = i + 5;
            while (iRight < items.len) : (iRight += 1) {
                switch (items[iRight].*) {
                    .Number => |*n| {
                        n.* += numbers.n2;
                        break;
                    },
                    else => {},
                }
            }
            for (items[i .. i + 5]) |ptr| self.alloc.destroy(ptr);
            try self.l.replaceRange(i, 5, &[_]*Token{try (Token{ .Number = 0 }).clone(self.alloc)});
            return true;
        }
        return false;
    }

    fn split(self: *@This()) !bool {
        const items = self.l.items;
        for (0..items.len) |i| {
            const n: i32 = switch (items[i].*) {
                .Number => |nn| nn,
                else => continue,
            };
            if (n <= 9) continue;
            const n1 = @divFloor(n, 2);
            const n2 = @divFloor(n + 1, 2);
            var l = std.ArrayList(*Token).init(self.alloc);
            defer l.deinit();
            try l.append(try (Token{ .OpenBracket = {} }).clone(self.alloc));
            try l.append(try (Token{ .Number = n1 }).clone(self.alloc));
            try l.append(try (Token{ .Comma = {} }).clone(self.alloc));
            try l.append(try (Token{ .Number = n2 }).clone(self.alloc));
            try l.append(try (Token{ .CloseBracket = {} }).clone(self.alloc));
            self.alloc.destroy(items[i]);
            try self.l.replaceRange(i, 1, l.items);
            return true;
        }
        return false;
    }

    fn reduce(self: *@This()) !void {
        const items = self.l.items;
        var i: usize = 0;
        while (i + 4 < self.l.items.len) {
            const numbers = self.extractNumbers(i) orelse {
                i += 1;
                continue;
            };
            const n = 3 * numbers.n1 + 2 * numbers.n2;
            for (items[i .. i + 5]) |ptr| self.alloc.destroy(ptr);
            try self.l.replaceRange(i, 5, &[_]*Token{try (Token{ .Number = n }).clone(self.alloc)});
            i = 0;
        }
    }
};

pub fn solve(alloc: std.mem.Allocator, data: []const u8) !void {
    var it = std.mem.tokenizeScalar(u8, data, '\n');
    const l0 = try tokenize(alloc, it.next().?);
    defer alloc.free(l0);
    var l = try L.init(alloc, l0);
    defer l.deinit();
    while (it.next()) |line| {
        const ll = try tokenize(alloc, line);
        defer alloc.free(ll);
        try l.add(ll);
        while (try l.explode() or try l.split()) {}
    }
    try l.reduce();
    switch (l.l.items[0].*) {
        .Number => |n| try std.io.getStdOut().writer().print("{}\n", .{n}),
        else => unreachable,
    }
}
