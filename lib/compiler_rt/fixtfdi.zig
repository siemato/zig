const common = @import("./common.zig");
const floatToInt = @import("./int_to_float.zig").floatToInt;

pub const panic = common.panic;

comptime {
    if (common.want_ppc_abi) {
        @export(__fixkfdi, .{ .name = "__fixkfdi", .linkage = common.linkage });
    } else {
        @export(__fixtfdi, .{ .name = "__fixtfdi", .linkage = common.linkage });
    }
}

fn __fixtfdi(a: f128) callconv(.C) i64 {
    return floatToInt(i64, a);
}

fn __fixkfdi(a: f128) callconv(.C) i64 {
    return floatToInt(i64, a);
}
