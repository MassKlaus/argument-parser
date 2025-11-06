const std = @import("std");
const argument_parser = @import("argument_parser");

pub fn main() !void {
    // Prints to stderr, ignoring potential errors.
    var dbg = std.heap.DebugAllocator(.{}).init;
    defer _ = dbg.deinit();
    const allocator = dbg.allocator();

    var parser = try argument_parser.ArgsParser.init(allocator);
    defer parser.deinit(allocator);

    const poop = parser.getArgumentValue("p");
    const MUSTSTRING = parser.getRequiredPositional() catch "missing_string";
    const MUSTSTRINGS = parser.getRemainingPositional(allocator) catch &[_][]const u8{"missing_string"};
    defer allocator.free(MUSTSTRINGS);
    const dee = parser.hasFlag("d");
    const fee = parser.hasFlag("f");

    _ = std.os.windows.kernel32.SetConsoleOutputCP(65001);

    std.log.debug("{s} {s} {} {} {} {} {} 我喜欢学习编程", .{ poop orelse "null", MUSTSTRING, MUSTSTRING.len, MUSTSTRINGS.len, dee, fee, parser.passthrough_index orelse 0 });
}
