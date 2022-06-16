const common = @import("./common.zig");
const floatToInt = @import("./int_to_float.zig").floatToInt;

pub const panic = common.panic;

comptime {
    @export(__fixxfdi, .{ .name = "__fixxfdi", .linkage = common.linkage });
}

fn __fixxfdi(a: f80) callconv(.C) i64 {
    return floatToInt(i64, a);
}
