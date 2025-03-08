const std = @import("std");

/// Returns true if y evenly divides x. Probably faster than x % y == 0
pub inline fn evenlyDivides(comptime T: type, x: T, y: T) bool {
    const Ti = comptime @typeInfo(T);
    comptime std.debug.assert(Ti == .Int);
    std.debug.assert(y != 0);

    return (@divFloor(x, y) * y) == x;
}

pub inline fn divCeil(comptime T: type, x: T, y: T) T {
    const Ti = comptime @typeInfo(T);
    comptime std.debug.assert(Ti == .Int);
    comptime std.debug.assert(Ti.Int.signedness == .unsigned);
    std.debug.assert(y != 0);

    return @divFloor(x, y) + @as(T, @intFromBool(!evenlyDivides(T, x, y)));
}
