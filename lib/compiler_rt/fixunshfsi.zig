const common = @import("./common.zig");
const floatToInt = @import("./int_to_float.zig").floatToInt;

pub const panic = common.panic;

comptime {
    @export(__fixunshfsi, .{ .name = "__fixunshfsi", .linkage = common.linkage });
}

fn __fixunshfsi(a: f16) callconv(.C) u32 {
    return floatToInt(u32, a);
}
