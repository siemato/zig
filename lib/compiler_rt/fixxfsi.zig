const common = @import("./common.zig");
const floatToInt = @import("./int_to_float.zig").floatToInt;

pub const panic = common.panic;

comptime {
    @export(__fixxfsi, .{ .name = "__fixxfsi", .linkage = common.linkage });
}

fn __fixxfsi(a: f80) callconv(.C) i32 {
    return floatToInt(i32, a);
}
