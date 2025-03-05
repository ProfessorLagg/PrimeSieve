const builtin = @import("builtin");
const std = @import("std");

pub const Sieve = struct {
    const TSelf = @This();
    allocator: std.mem.Allocator,
    isPrimeArr: []bool,
    sieveSize: usize,

    pub fn init(allocator: std.mem.Allocator, sieveSize: usize) !TSelf {
        const r = Sieve{
            .allocator = allocator,
            .sieveSize = sieveSize,
            .isPrimeArr = try allocator.alloc(bool, sieveSize / 2),
        };
        @memset(r.isPrimeArr, true);
        return r;
    }

    pub fn deinit(self: *TSelf) void {
        self.allocator.free(self.isPrimeArr);
    }

    inline fn getBit(self: *const TSelf, index: usize) bool {
        const i: usize = index / 2;
        std.debug.assert(i < self.isPrimeArr.len);
        return self.isPrimeArr[i];
    }

    inline fn clearBit(self: *TSelf, index: usize) void {
        const i: usize = index / 2;
        std.debug.assert(i < self.isPrimeArr.len);
        self.isPrimeArr[i] = false;
        // std.log.debug("{d} is not prime", .{index});
    }

    pub fn runSieve(self: *TSelf) void {
        const q = std.math.sqrt(self.isPrimeArr.len);
        var factor: usize = 3;

        while (factor < q) : (factor += 2) {
            std.log.debug("Checking factor: {d}", .{factor});

            var num: usize = factor;
            inner: while (num <= self.sieveSize) : (num += 1) {
                if (self.getBit(num)) {
                    factor = num;
                    break :inner;
                }
            }

            num = factor * 3;
            while (num <= self.sieveSize) : (num += factor * 2) {
                self.clearBit(num);
            }
        }
    }

    pub fn printResult(self: *const TSelf, showResults: bool, durationNanoseconds: f64, passCount: usize) !void {
        const stdout = std.io.getStdOut().writer();
        if (showResults) {
            try stdout.print("2, ", .{});
        }

        var count: usize = 1;
        for (0..self.sieveSize) |num| {
            if (self.getBit(num)) {
                if (showResults) {
                    try stdout.print("{d}, ", .{num});
                }
                count += 1;
            }
        }

        if (showResults) {
            try stdout.print("\n", .{});
        }

        const durationSeconds: f64 = durationNanoseconds / @as(f64, std.time.ns_per_s);
        const avg: f64 = durationSeconds / @as(f64, @floatFromInt(passCount));
        try stdout.print("Passes: {d}, Time: {d}s, Avg: {d}, Limit: {d}", .{ passCount, durationSeconds, avg, self.sieveSize });
    }
};
