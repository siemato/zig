const common = @import("./common.zig");
const floatToInt = @import("./int_to_float.zig").floatToInt;

pub const panic = common.panic;

comptime {
    @export(__fixunssfti, .{ .name = "__fixunssfti", .linkage = common.linkage });
}

fn __fixunssfti(a: f32) callconv(.C) u128 {
    return floatToInt(u128, a);
}
