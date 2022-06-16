const common = @import("./common.zig");
const floatToInt = @import("./int_to_float.zig").floatToInt;

pub const panic = common.panic;

comptime {
    @export(__fixunstfti, .{ .name = "__fixunstfti", .linkage = common.linkage });
}

fn __fixunstfti(a: f128) callconv(.C) u128 {
    return floatToInt(u128, a);
}
