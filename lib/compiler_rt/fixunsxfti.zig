const common = @import("./common.zig");
const floatToInt = @import("./int_to_float.zig").floatToInt;

pub const panic = common.panic;

comptime {
    @export(__fixunsxfti, .{ .name = "__fixunsxfti", .linkage = common.linkage });
}

fn __fixunsxfti(a: f80) callconv(.C) u128 {
    return floatToInt(u128, a);
}
