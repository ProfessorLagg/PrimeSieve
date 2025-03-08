const builtin = @import("builtin");
const std = @import("std");
const PackedIntSlice = std.packed_int_array.PackedIntSlice;
const BitArray = @import("bitArray.zig").BitArray(u8);
const math = @import("math.zig");

pub const SieveDaveClone = struct {
    const TSelf = @This();
    allocator: std.mem.Allocator,

    bitArrayBytes: []u8,
    bitArray: PackedIntSlice(u1),
    sieveSize: usize,

    pub fn init(allocator: std.mem.Allocator, sieveSize: usize) !TSelf {
        var r = TSelf{
            .allocator = allocator,
            .sieveSize = sieveSize,
            .bitArrayBytes = undefined,
            .bitArray = undefined,
        };

        const bitArrayByteCount = PackedIntSlice(u1).bytesRequired(sieveSize / 2);
        r.bitArrayBytes = try allocator.alloc(u8, bitArrayByteCount);
        r.bitArray = PackedIntSlice(u1).init(r.bitArrayBytes, sieveSize / 2);
        for (0..r.bitArray.len) |i| {
            r.bitArray.set(i, 1);
        }
        return r;
    }

    pub fn deinit(self: *TSelf) void {
        self.allocator.free(self.bitArrayBytes);
    }

    fn getBit(self: *const TSelf, index: usize) bool {
        const i: usize = index / 2;
        return self.bitArray.get(i) == 1;
    }

    fn clearBit(self: *TSelf, index: usize) void {
        const i: usize = index / 2;
        std.log.debug("clearing bit {d} | index {d}", .{ i, index });
        self.bitArray.set(i, 0);
    }

    pub fn runSieve(self: *TSelf) void {
        const q = std.math.sqrt(self.sieveSize);
        var factor: usize = 3;

        while (factor < q) : (factor += 2) {
            std.log.debug("Checking factor: {d}", .{factor});

            var num: usize = factor;
            inner: while (num < self.sieveSize) : (num += 1) {
                if (self.getBit(num)) {
                    factor = num;
                    break :inner;
                }
            }

            num = factor * 3;
            while (num < self.sieveSize) : (num += factor * 2) {
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
        try stdout.print("Passes: {d}, Time: {d}s, Avg: {d}, Limit: {d}, Prime Count: {d}", .{ passCount, durationSeconds, avg, self.sieveSize, count });
    }
};

pub const SieveLagg = struct {
    const TSelf = @This();
    allocator: std.mem.Allocator,

    bitArray: []u1,
    N: usize,

    pub fn init(allocator: std.mem.Allocator, sieveSize: usize) !TSelf {
        const r = TSelf{ // NO FOLD
            .allocator = allocator,
            .N = sieveSize,
            .bitArray = try allocator.alloc(u1, @divFloor(sieveSize + 1, 2)),
        };
        @memset(r.bitArray, 1);
        return r;
    }

    pub fn deinit(self: *TSelf) void {
        self.allocator.free(self.bitArray);
    }

    inline fn getBit(self: *const TSelf, index: usize) bool {
        const i = @divFloor(index, 2) - 1;
        return self.bitArray[i] == 1;
    }

    inline fn clearBit(self: *TSelf, index: usize) void {
        std.debug.assert(index >= 3);
        std.debug.assert((index % 2) != 0);
        const i = @divFloor(index, 2) - 1;
        self.bitArray[i] = 0;
    }

    fn calculateQ(N: usize) usize {
        const n: f128 = @floatFromInt(N);
        const sqrt_n: f128 = @sqrt(n);
        const ciel_sqrt_n: f128 = @ceil(sqrt_n);
        return @intFromFloat(ciel_sqrt_n);
    }

    pub fn runSieve(self: *TSelf) void {
        const q: usize = calculateQ(self.N);

        var i: usize = 3;
        while (i <= q) : (i += 2) {
            if (self.getBit(i)) {
                var j: usize = i * i;
                while (j < self.N) : (j += i) {
                    if (!math.evenlyDivides(usize, j, 2)) {
                        self.clearBit(j);
                    }
                }
            }
        }
    }

    pub fn countPrimes(self: *const TSelf) usize {
        var count: usize = 1;
        var i: usize = 3;
        while (i <= self.N) : (i += 2) {
            count += @intFromBool(self.getBit(i));
        }
        return count;
    }

    pub fn printResult(self: *const TSelf, showResults: bool, durationNanoseconds: f64, passCount: usize) !void {
        const stdout = std.io.getStdOut().writer();
        if (showResults) {
            try stdout.print("2, ", .{});
        }

        var count: usize = 0;
        var i: usize = 3;
        while (i <= self.N) : (i += 2) {
            const isPrime = self.getBit(i);
            count += @intFromBool(isPrime);
            if (isPrime) {
                if (showResults) {
                    try stdout.print("{d}, ", .{i});
                }
            }
        }

        if (showResults) {
            try stdout.print("\n", .{});
        }

        const durationSeconds: f64 = durationNanoseconds / @as(f64, std.time.ns_per_s);
        const avg: f64 = durationSeconds / @as(f64, @floatFromInt(passCount));
        try stdout.print("Passes: {d}, Time: {d}s, Avg: {d}, Limit: {d}, Prime Count: {d}", .{ passCount, durationSeconds, avg, self.N, count });
    }
};

test "SieveLagg" {
    const Narr = comptime [_]usize{
        10,
        100,
        1_000,
        // 10_000,
        // 100_000,
        // 1_000_000,
        // 10_000_000,
        // 100_000_000,
        // 1_000_000_000,
        // 10_000_000_000,
    };
    // number of primes below N. index matches Narr
    const Parr = comptime [_]usize{
        4,
        25,
        168,
        // 1_229,
        // 9_592,
        // 78_498,
        // 664_579,
        // 5_761_455,
        // 50_847_534,
        // 455_052_511,
    };

    for (0..Narr.len, Narr, Parr) |_, n, p| {
        var sieve: SieveLagg = try SieveLagg.init(std.testing.allocator, n);
        errdefer sieve.deinit();
        sieve.runSieve();
        try std.testing.expectEqual(p, sieve.countPrimes());
        sieve.deinit();
    }
}
