const common = @import("./common.zig");
const floatToInt = @import("./int_to_float.zig").floatToInt;

pub const panic = common.panic;

comptime {
    @export(__fixhfdi, .{ .name = "__fixhfdi", .linkage = common.linkage });
}

fn __fixhfdi(a: f16) callconv(.C) i64 {
    return floatToInt(i64, a);
}
