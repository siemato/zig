const common = @import("./common.zig");
const floatToInt = @import("./int_to_float.zig").floatToInt;

pub const panic = common.panic;

comptime {
    @export(__fixtfti, .{ .name = "__fixtfti", .linkage = common.linkage });
}

fn __fixtfti(a: f128) callconv(.C) i128 {
    return floatToInt(i128, a);
}
