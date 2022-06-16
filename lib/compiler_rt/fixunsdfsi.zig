const common = @import("./common.zig");
const floatToInt = @import("./int_to_float.zig").floatToInt;

pub const panic = common.panic;

comptime {
    if (common.want_eabi) {
        @export(__aeabi_d2uiz, .{ .name = "__aeabi_d2uiz", .linkage = common.linkage });
    } else {
        @export(__fixunsdfsi, .{ .name = "__fixunsdfsi", .linkage = common.linkage });
    }
}

fn __fixunsdfsi(a: f64) callconv(.C) u32 {
    return floatToInt(u32, a);
}

fn __aeabi_d2uiz(a: f64) callconv(.AAPCS) u32 {
    return floatToInt(u32, a);
}
