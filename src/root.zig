//! By convention, root.zig is the root source file when making a library.
const std = @import("std");

// -- will have a value
// - boolean flag
// the rest are positinal arguments
// subcommands are something else to worry about later
pub const ArgsParser = struct {
    args: []const [:0]const u8,
    index: usize = 1, // Start right after the name, this is used to track our last positional argument check
    passthrough_index: ?usize,

    pub fn init(args: []const [:0]const u8) !@This() {
        const index: ?usize = index_finder: for (args, 0..) |arg, i| {
            if (std.mem.eql(u8, arg, "--")) {
                break :index_finder i;
            }
        } else null;

        return .{
            .args = args,
            .passthrough_index = index,
        };
    }

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        std.process.argsFree(allocator, self.args);
    }

    fn skipNonPositional(self: *@This()) void {
        const stop = self.passthrough_index orelse self.args.len - 1;
        while (self.index <= stop) : (self.index += 1) {
            if (std.mem.eql(u8, self.args[self.index], "--")) continue;

            if (std.mem.startsWith(u8, self.args[self.index], "--")) {
                self.index += 1;
                continue;
            }
            if (std.mem.startsWith(u8, self.args[self.index], "-")) continue;

            break;
        }
    }

    pub fn getRequiredPositional(self: *@This()) ![]const u8 {
        self.skipNonPositional();
        if (self.index >= self.args.len) return error.ExaustedPositionalArguments;

        const result = self.args[self.index];
        self.index += 1;
        return result;
    }

    pub fn getRemainingPositional(self: *@This(), allocator: std.mem.Allocator) ![]const []const u8 {
        var elements = std.ArrayList([]const u8).empty;
        errdefer elements.deinit(allocator);

        while (true) {
            self.skipNonPositional();
            if (self.index >= self.args.len) break;
            try elements.append(allocator, self.args[self.index]);
            self.index += 1;
        }

        return elements.toOwnedSlice(allocator);
    }

    pub fn getPositional(self: *@This()) ?[]const u8 {
        self.skipNonPositional();
        if (self.index >= self.args.len) return null;

        const result = self.args[self.index];
        self.index += 1;
        return result;
    }

    pub fn getArgumentValue(self: *@This(), flagname: []const u8) ?[]const u8 {
        const stop = self.passthrough_index orelse self.args.len;

        for (self.args[0..stop], 0..) |arg, index| {
            if (arg.len > 2 and std.mem.startsWith(u8, arg, "--") and std.mem.eql(u8, arg[2..], flagname)) {
                if (index + 1 < self.args.len) {
                    return self.args[index + 1];
                }
            }
        }

        return null;
    }

    pub fn hasFlag(self: *@This(), flagname: []const u8) bool {
        const stop = self.passthrough_index orelse self.args.len;
        for (self.args[0..stop]) |arg| {
            if (arg.len > 1 and arg[0] == '-' and std.mem.indexOf(u8, arg[1..], flagname) != null) {
                return true;
            }
        }

        return false;
    }
};
