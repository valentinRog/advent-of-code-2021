const std = @import("std");
const part1 = @import("part1.zig");
const part2 = @import("part2.zig");

pub fn main() !void {
    const stdin = std.io.getStdIn().reader();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();
    const raw = try stdin.readAllAlloc(alloc, 1 << 16);
    defer alloc.free(raw);
    const data = std.mem.trim(u8, raw, " \r\t\n");
    try part1.solve(data);
    try part2.solve(data);
}
