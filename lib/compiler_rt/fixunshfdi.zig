const common = @import("./common.zig");
const floatToInt = @import("./int_to_float.zig").floatToInt;

pub const panic = common.panic;

comptime {
    @export(__fixunshfdi, .{ .name = "__fixunshfdi", .linkage = common.linkage });
}

fn __fixunshfdi(a: f16) callconv(.C) u64 {
    return floatToInt(u64, a);
}
