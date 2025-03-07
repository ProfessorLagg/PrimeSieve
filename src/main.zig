const builtin = @import("builtin");
const std = @import("std");
const root = @import("root.zig");
// const Sieve = root.SieveDaveClone;
const Sieve = root.SieveLagg;

pub const std_options: std.Options = .{
    // Set the log level to info to .debug. use the scope levels instead
    .log_level = switch (builtin.mode) {
        .Debug => .debug,
        .ReleaseSafe => .info,
        .ReleaseSmall => .info,
        .ReleaseFast => .warn,
    },
    // .log_scope_levels = &[_]std.log.ScopeLevel{},
};

var SequenceLength: usize = switch (builtin.mode) {
    .Debug => 1_000,
    else => 1_000_000,
};

inline fn toSeconds(ns: i128) i128 {
    const ns_per_s: i128 = comptime std.time.ns_per_s;
    return @divFloor(ns, ns_per_s);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const start: i128 = std.time.nanoTimestamp();
    var passes: usize = 0;
    var runtimeSeconds: i128 = 0;
    var sieve: ?Sieve = null;
    while (runtimeSeconds < 5) : (runtimeSeconds = toSeconds(std.time.nanoTimestamp() - start)) {
        if (sieve != null) {
            sieve.?.deinit();
        }
        sieve = try Sieve.init(allocator, SequenceLength);

        sieve.?.runSieve();
        passes += 1;
    }
    const tD: f64 = @floatFromInt(std.time.nanoTimestamp() - start);
    if (sieve != null) {
        try sieve.?.printResult(false, tD, passes);
        sieve.?.deinit();
    }
}
