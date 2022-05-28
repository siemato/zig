const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    const lib_a = b.addStaticLibrary("a", null);
    lib_a.addCSourceFiles(&.{ "c.c", "a.c", "b.c" }, &.{"-fcommon"});
    lib_a.setBuildMode(mode);
    lib_a.setTarget(target);

    const test_exe = b.addTest("main.zig");
    test_exe.setBuildMode(mode);
    test_exe.setTarget(target);
    test_exe.linkLibrary(lib_a);

    const test_step = b.step("test", "Test it");
    test_step.dependOn(&test_exe.step);
}
