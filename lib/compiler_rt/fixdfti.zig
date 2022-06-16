const common = @import("./common.zig");
const floatToInt = @import("./int_to_float.zig").floatToInt;

pub const panic = common.panic;

comptime {
    @export(__fixdfti, .{ .name = "__fixdfti", .linkage = common.linkage });
}

fn __fixdfti(a: f64) callconv(.C) i128 {
    return floatToInt(i128, a);
}
