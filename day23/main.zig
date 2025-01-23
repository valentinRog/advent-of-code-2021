const std = @import("std");
const part1 = @import("part1.zig");
const part2 = @import("part2.zig");

pub fn main() !void {
    const stdin = std.io.getStdIn().reader();
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();
    const raw = try stdin.readAllAlloc(alloc, 1 << 16);
    const trimmedRaw = std.mem.trim(u8, raw, "\n\t ");
    const data = try alloc.alloc(u8, std.mem.replacementSize(u8, trimmedRaw, "\r", ""));
    defer alloc.free(data);
    _ = std.mem.replace(u8, trimmedRaw, "\r", "", data);
    alloc.free(raw);
    try part1.solve(alloc, data);
    try part2.solve(alloc, data);
}
