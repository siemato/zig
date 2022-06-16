const common = @import("./common.zig");
const floatToInt = @import("./int_to_float.zig").floatToInt;

pub const panic = common.panic;

comptime {
    if (common.want_eabi) {
        @export(__aeabi_d2iz, .{ .name = "__aeabi_d2iz", .linkage = common.linkage });
    } else {
        @export(__fixdfsi, .{ .name = "__fixdfsi", .linkage = common.linkage });
    }
}

fn __fixdfsi(a: f64) callconv(.C) i32 {
    return floatToInt(i32, a);
}

fn __aeabi_d2iz(a: f64) callconv(.AAPCS) i32 {
    return floatToInt(i32, a);
}
