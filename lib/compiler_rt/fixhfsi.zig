const common = @import("./common.zig");
const floatToInt = @import("./int_to_float.zig").floatToInt;

pub const panic = common.panic;

comptime {
    @export(__fixhfsi, .{ .name = "__fixhfsi", .linkage = common.linkage });
}

fn __fixhfsi(a: f16) callconv(.C) i32 {
    return floatToInt(i32, a);
}
