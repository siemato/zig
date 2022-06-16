const common = @import("./common.zig");
const floatToInt = @import("./int_to_float.zig").floatToInt;

pub const panic = common.panic;

comptime {
    @export(__fixsfti, .{ .name = "__fixsfti", .linkage = common.linkage });
}

fn __fixsfti(a: f32) callconv(.C) i128 {
    return floatToInt(i128, a);
}
