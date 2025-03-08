const builtin = @import("builtin");
const std = @import("std");

const math = @import("math.zig");

fn PackedBits(comptime T: type) type {
    comptime switch (T) {
        u8, usize => {},
        else => {
            const Ti = @typeInfo(T);
            const errmsg = "Unsupported Type " + @typeName(T);
            if (Ti != .Int) @compileError(errmsg);
            if (Ti.Int.signedness != .unsigned) @compileError(errmsg);
            if (@sizeOf(usize) < @sizeOf(T)) @compileError(errmsg);
            // TODO Check that it is an actual hardware int type
        },
    };

    return struct {
        const TSelf = @This();
        pub const TShift: type = switch (@bitSizeOf(T)) {
            8 => u3,
            16 => u4,
            32 => u5,
            64 => u6,
            128 => u7,
            256 => u8,
            512 => u9,
            1024 => u10,
            2048 => u11,
            4096 => u12,
            8192 => u13,
            16384 => u14,
            32768 => u15,
            65536 => u16,
            else => @compileError("Missing shift type for " + @typeName(T)),
        };

        pub const allSetT: T = @as(T, 1) <<| @bitSizeOf(T);
        pub const noneSetT: T = 0;
        pub const lastSetT: T = @as(T, 1);
        pub const firstSetT: T = lastSetT << (@bitSizeOf(T) - 1);

        pub const allSet: TSelf = TSelf{ .integer = allSetT };
        pub const noneSet: T = TSelf{ .integer = noneSetT };
        pub const lastSet: T = TSelf{ .integer = lastSetT };
        pub const firstSet: T = TSelf{ .integer = firstSetT };

        integer: T = 0,

        pub fn getBit(self: TSelf, index: TShift) u1 {
            std.debug.assert(index < @bitSizeOf(T));
            const mask: T = firstSetT >> index;
            const rT: T = (self.integer & mask) >> (@bitSizeOf(T) - 1 - index);
            return @intCast(rT);
        }
        pub fn getBitR(self: *const TSelf, index: TShift) u1 {
            std.debug.assert(index < @bitSizeOf(T));
            const mask: T = firstSetT >> index;
            const rT: T = (self.integer & mask) >> (@bitSizeOf(T) - 1 - index);
            return @intCast(rT);
        }

        pub fn setBit(self: TSelf, index: TShift) TSelf {
            std.debug.assert(index < @bitSizeOf(T));
            const mask = firstSetT >> index;
            self.integer |= mask;
            return self;
        }
        pub fn setBitR(self: *TSelf, index: TShift) void {
            std.debug.assert(index < @bitSizeOf(T));
            const mask = firstSetT >> index;
            self.integer |= mask;
        }

        pub fn clearBit(self: TSelf, index: TShift) TSelf {
            std.debug.assert(index < @bitSizeOf(T));
            const mask = ~(firstSetT >> index);
            self.integer &= mask;
            return self;
        }
        pub fn clearBitR(self: *TSelf, index: TShift) void {
            std.debug.assert(index < @bitSizeOf(T));
            const mask = ~(firstSetT >> index);
            self.integer &= mask;
        }
    };
}

pub fn BitArray(comptime T: type) type {
    return struct {
        const TSelf: type = @This();
        const TPack: type = PackedBits(T);

        allocator: std.mem.Allocator,

        bitCount: usize,
        buffer: []TPack,

        // === con- and destructor(s) ===
        pub fn init(allocator: std.mem.Allocator, bitCount: usize) !TSelf {
            const bufSize: usize = math.divCeil(usize, bitCount, @bitSizeOf(T));
            return TSelf{ // NO FOLD
                .allocator = allocator,
                .bitCount = bitCount,
                .buffer = try allocator.alloc(TPack, bufSize),
            };
        }
        pub fn deinit(self: *TSelf) void {
            self.allocator.free(self.buffer);
        }

        // === private functions and methods ===

        // === public functions and methods ===

        /// Sets every bit in the BitArray
        pub fn setAll(self: *TSelf) void {
            @memset(self.buffer, TPack.allSet);
        }

        /// Clears every bit in the BitArray
        pub fn clearAll(self: *TSelf) void {
            @memset(self.buffer, TPack.noneSet);
        }

        /// Sets the bit at index i
        pub fn setBit(self: *TSelf, i: usize) void {
            std.debug.assert(i < self.bitCount);

            const bufIndex: usize = @divFloor(i, @bitSizeOf(T));
            const bitIndex: TPack.TShift = @intCast(i % @bitSizeOf(T));
            self.buffer[bufIndex].setBitR(bitIndex);
        }

        /// Clears the bit at index i
        pub fn clearBit(self: *TSelf, i: usize) void {
            std.debug.assert(i < self.bitCount);

            const bufIndex: usize = @divFloor(i, @bitSizeOf(T));
            const bitIndex: TPack.TShift = @intCast(i % @bitSizeOf(T));
            self.buffer[bufIndex].clearBitR(bitIndex);
        }

        /// Gets the bit at index i
        pub fn getBit(self: *const TSelf, i: usize) u1 {
            std.debug.assert(i < self.bitCount);

            const bufIndex: usize = @divFloor(i, @bitSizeOf(T));
            const bitIndex: TPack.TShift = @intCast(i % @bitSizeOf(T));
            return self.buffer[bufIndex].getBit(bitIndex);
        }
    };
}
