const common = @import("./common.zig");
const floatToInt = @import("./int_to_float.zig").floatToInt;

pub const panic = common.panic;

comptime {
    if (common.want_eabi) {
        @export(__aeabi_f2iz, .{ .name = "__aeabi_f2iz", .linkage = common.linkage });
    } else {
        @export(__fixsfsi, .{ .name = "__fixsfsi", .linkage = common.linkage });
    }
}

fn __fixsfsi(a: f32) callconv(.C) i32 {
    return floatToInt(i32, a);
}

fn __aeabi_f2iz(a: f32) callconv(.AAPCS) i32 {
    return floatToInt(i32, a);
}
