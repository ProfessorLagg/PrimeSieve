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

const SequenceLength: usize = switch (builtin.mode) {
    .Debug => 1_000,
    else => 1_000_000,
};

inline fn toSeconds(ns: i128) i128 {
    const ns_per_s: i128 = comptime std.time.ns_per_s;
    return @divFloor(ns, ns_per_s);
}

/// How long to test for, in nanoseconds
const maxRuntimeNanoseconds: i128 = 10 * std.time.ns_per_s;
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    // const allocator = std.heap.c_allocator;

    var passCount: usize = 0;
    var sieve: Sieve = try Sieve.init(allocator, SequenceLength);
    var total_ns: i128 = 0.0;

    const start: i128 = std.time.nanoTimestamp();
    while ((std.time.nanoTimestamp() - start) < maxRuntimeNanoseconds) {
        const loopStart = std.time.nanoTimestamp();
        nosuspend {
            sieve.deinit();
            sieve = try Sieve.init(allocator, SequenceLength);
            sieve.runSieve();
        }
        const loopEnd = std.time.nanoTimestamp();
        total_ns += (loopEnd - loopStart);
        passCount += 1;
    }

    try sieve.printResult(false, @as(f64, @floatFromInt(total_ns)), passCount);
    sieve.deinit();
}
