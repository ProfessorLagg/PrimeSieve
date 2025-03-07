const builtin = @import("builtin");
const std = @import("std");
const PackedIntSlice = std.packed_int_array.PackedIntSlice;

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

    isPrimeArr: []bool,
    N: usize,

    pub fn init(allocator: std.mem.Allocator, sieveSize: usize) !TSelf {
        var r = TSelf{
            .allocator = allocator,
            .N = sieveSize,
            .isPrimeArr = undefined,
        };
        r.isPrimeArr = try allocator.alloc(bool, (sieveSize + 1) / 2);
        @memset(r.isPrimeArr, true);
        r.isPrimeArr[0] = false;
        return r;
    }

    pub fn deinit(self: *TSelf) void {
        self.allocator.free(self.isPrimeArr);
    }

    inline fn getBit(self: *const TSelf, index: usize) bool {
        const i = index / 2;
        std.debug.assert(index < self.N);
        return self.isPrimeArr[i];
    }

    inline fn clearBit(self: *TSelf, index: usize) void {
        const i = index / 2;
        std.debug.assert(index < self.N);
        self.isPrimeArr[i] = false;
        std.log.debug("cleared bit {d} | index {d}", .{i, index});
    }

    pub fn runSieve(self: *TSelf) void {
        const q: usize = std.math.sqrt(self.N);

        var i: usize = 3;
        while (i <= q) : (i += 1) {
            if (self.getBit(i)) {
                var j: usize = i * 3;
                while (j < self.N) : (j += 2) {
                    self.clearBit(j);
                }
            }
        }
    }

    pub fn printResult(self: *const TSelf, showResults: bool, durationNanoseconds: f64, passCount: usize) !void {
        const stdout = std.io.getStdOut().writer();
        if (showResults) {
            try stdout.print("2, ", .{});
        }

        var count: usize = 0;
        for (0..self.N) |num| {
            const isPrime = self.getBit(num);
            count += @intFromBool(isPrime);
            if (isPrime) {
                if (showResults) {
                    try stdout.print("{d}, ", .{num});
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
