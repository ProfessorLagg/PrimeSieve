const std = @import("std");

/// Returns true if y evenly divides x. Probably faster than x % y == 0
pub inline fn evenlyDivides(comptime T: type, x: T, y: T) bool {
    const Ti = comptime @typeInfo(T);
    comptime std.debug.assert(Ti == .Int);
    std.debug.assert(y != 0);

    return (@divFloor(x, y) * y) == x;
}

/// Returns true if n is even. Throws a compile error if n is not an unsigned integer
pub inline fn isEvenUInt(n: anytype) bool {
    const T = comptime @TypeOf(n);
    comptime {
        const Ti = @typeInfo(T);
        if (Ti != .Int) @compileError("Expected integer, but found: " + @typeName(T));
        if (Ti.Int.signedness != .unsigned) @compileError("Expected unsigned integer, but found: " + @typeName(T));
    }

    return (n & 1) == 0;
}

/// Returns true if n is not even. Throws a compile error if n is not an unsigned integer
pub inline fn isUnevenUInt(n: anytype) bool {
    const T = comptime @TypeOf(n);
    comptime {
        const Ti = @typeInfo(T);
        if (Ti != .Int) @compileError("Expected integer, but found: " + @typeName(T));
        if (Ti.Int.signedness != .unsigned) @compileError("Expected unsigned integer, but found: " + @typeName(T));
    }

    return (n & 1) == 1;
}

pub inline fn divCeil(comptime T: type, x: T, y: T) T {
    const Ti = comptime @typeInfo(T);
    comptime std.debug.assert(Ti == .Int);
    comptime std.debug.assert(Ti.Int.signedness == .unsigned);
    std.debug.assert(y != 0);

    return @divFloor(x, y) + @as(T, @intFromBool(!evenlyDivides(T, x, y)));
}
