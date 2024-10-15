const std = @import("std");
// const part1 = @import("part1.zig");
const part2 = @import("part2.zig");

pub fn removeAllCR(alloc: std.mem.Allocator, data: []const u8) !std.ArrayList(u8) {
    var res = std.ArrayList(u8).init(alloc);
    for (data) |c| {
        if (c != '\r') {
            try res.append(c);
        }
    }
    return res;
}

pub fn main() !void {
    const stdin = std.io.getStdIn().reader();
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();
    const raw = try stdin.readAllAlloc(alloc, 1 << 16);
    const cleanRaw = try removeAllCR(alloc, raw);
    alloc.free(raw);
    defer cleanRaw.deinit();
    const data = std.mem.trim(u8, cleanRaw.items, " \t\n");
    // try part1.solve(alloc, data);
    try part2.solve(alloc, data);
}
