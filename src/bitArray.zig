const builtin = @import("builtin");
const std = @import("std");

/// Returns true if y evenly divides x. Probably faster than x % y == 0
inline fn evenlyDivides(comptime T: type, x: T, y: T) bool {
    const Ti = comptime @typeInfo(T);
    comptime std.debug.assert(Ti == .Int);
    std.debug.assert(y != 0);

    return (@divFloor(x, y) * y) == x;
}

inline fn divCeil(comptime T: type, x: T, y: T) T {
    const Ti = comptime @typeInfo(T);
    comptime std.debug.assert(Ti == .Int);
    comptime std.debug.assert(Ti.Int.signedness == .unsigned);
    std.debug.assert(y != 0);

    return @divFloor(x, y) + @as(T, @intFromBool(!evenlyDivides(T, x, y)));
}

pub fn BitArray(comptime T: type) type {
    comptime {
        const supportedTypes = [_]type{
            u8,
            u16,
            u32,
            u64,
            usize,
        };
        const valid_type: bool = std.mem.indexOfScalar(type, supportedTypes[0..], T) != null;
        if (!valid_type) @compileError("Unsupported Type " + @typeName(T));
    }

    return struct {
        const TSelf: type = @This();
        const TShift: type = std.meta.Int(.unsigned, std.math.log2_int_ceil(u16, @as(u16, @bitSizeOf(T))));
        const allSetT: T = @as(T, 1) <<| @bitSizeOf(T);
        const nonSetT: T = 0;
        const fstSetT: T = @as(T, 1) << (@bitSizeOf(T) - 1);

        allocator: std.mem.Allocator,

        bitCount: usize,
        buffer: []T,

        // === con- and destructor(s) ===
        pub fn init(allocator: std.mem.Allocator, bitCount: usize) !TSelf {
            const bufSize: usize = divCeil(usize, bitCount, @bitSizeOf(T));
            return TSelf{ // NO FOLD
                .allocator = allocator,
                .bitCount = bitCount,
                .buffer = try allocator.alloc(T, bufSize),
            };
        }
        pub fn deinit(self: *TSelf) void {
            self.allocator.free(self.buffer);
        }

        // === private functions and methods ===

        // === public functions and methods ===

        /// Sets every bit in the BitArray
        pub fn setAll(self: *TSelf) void {
            @memset(self.buffer, allSetT);
        }

        /// Clears every bit in the BitArray
        pub fn clearAll(self: *TSelf) void {
            @memset(self.buffer, @as(T, 0));
        }

        /// Sets the bit at index i
        pub fn setBit(self: *TSelf, i: usize) void {
            std.debug.assert(i < self.bitCount);

            const bufIndex: usize = @divFloor(i, @bitSizeOf(T));
            const bitIndex = @as(TShift, @intCast(i - (bufIndex * @bitSizeOf(T))));
            const mask: T = fstSetT >> bitIndex;
            self.buffer[bufIndex] |= mask;
        }

        /// Clears the bit at index i
        pub fn clearBit(self: *TSelf, i: usize) void {
            std.debug.assert(i < self.bitCount);

            const bufIndex: usize = @divFloor(i, @bitSizeOf(T));
            const bitIndex = @as(TShift, @intCast(i - (bufIndex * @bitSizeOf(T))));
            const mask: T = ~(fstSetT >> bitIndex);
            self.buffer[bufIndex] &= mask;
        }

        /// Gets the bit at index i
        pub fn getBit(self: *const TSelf, i: usize) u1 {
            std.debug.assert(i < self.bitCount);

            const bufIndex: usize = @divFloor(i, @bitSizeOf(T));
            const bitIndex = @as(TShift, @intCast(i - (bufIndex * @bitSizeOf(T))));
            const mask: T = fstSetT >> bitIndex;

            const bit: u1 = @intFromBool((self.buffer[bufIndex] & mask) != 0);
            return bit;
        }
    };
}
