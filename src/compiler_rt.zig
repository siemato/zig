const std = @import("std");
const builtin = @import("builtin");
const build_options = @import("build_options");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const mem = std.mem;
const tracy = @import("tracy.zig");
const trace = tracy.trace;

const Cache = @import("Cache.zig");
const Compilation = @import("Compilation.zig");
const CRTFile = Compilation.CRTFile;
const LinkObject = Compilation.LinkObject;
const Package = @import("Package.zig");

pub fn buildCompilerRtLib(comp: *Compilation, compiler_rt_lib: *?CRTFile) !void {
    const tracy_trace = trace(@src());
    defer tracy_trace.end();

    var arena_allocator = std.heap.ArenaAllocator.init(comp.gpa);
    defer arena_allocator.deinit();
    const arena = arena_allocator.allocator();

    const target = comp.getTarget();

    // Use the global cache directory.
    var cache_parent: Cache = .{
        .gpa = comp.gpa,
        .manifest_dir = try comp.global_cache_directory.handle.makeOpenPath("h", .{}),
    };
    defer cache_parent.manifest_dir.close();

    var cache = cache_parent.obtain();
    defer cache.deinit();

    cache.hash.add(sources.len);
    for (sources) |source| {
        const full_path = try comp.zig_lib_directory.join(arena, &[_][]const u8{source});
        _ = try cache.addFile(full_path, null);
    }

    cache.hash.addBytes(build_options.version);
    cache.hash.addBytes(comp.zig_lib_directory.path orelse ".");
    cache.hash.add(target.cpu.arch);
    cache.hash.add(target.os.tag);
    cache.hash.add(target.abi);

    const hit = try cache.hit();
    const digest = cache.final();
    const o_sub_path = try std.fs.path.join(arena, &[_][]const u8{ "o", &digest });

    var o_directory: Compilation.Directory = .{
        .handle = try comp.global_cache_directory.handle.makeOpenPath(o_sub_path, .{}),
        .path = try std.fs.path.join(arena, &[_][]const u8{ comp.global_cache_directory.path.?, o_sub_path }),
    };
    defer o_directory.handle.close();

    const ok_basename = "ok";
    const actual_hit = if (hit) blk: {
        o_directory.handle.access(ok_basename, .{}) catch |err| switch (err) {
            error.FileNotFound => break :blk false,
            else => |e| return e,
        };
        break :blk true;
    } else false;

    const root_name = "compiler_rt";
    const basename = try std.zig.binNameAlloc(arena, .{
        .root_name = root_name,
        .target = target,
        .output_mode = .Lib,
    });

    if (!actual_hit) {
        var progress: std.Progress = .{ .dont_print_on_dumb = true };
        var progress_node = progress.start("Compile Compiler-RT", sources.len + 1);
        defer progress_node.end();
        if (comp.color == .off) progress.terminal = null;

        progress_node.activate();

        var link_objects: [sources.len]LinkObject = undefined;
        for (sources) |source, i| {
            var obj_progress_node = progress_node.start(source, 0);
            obj_progress_node.activate();
            defer obj_progress_node.end();

            var tmp_crt_file: ?CRTFile = null;
            defer if (tmp_crt_file) |*crt| crt.deinit(comp.gpa);
            try comp.buildOutputFromZig(source, .Obj, &tmp_crt_file, .compiler_rt);
            link_objects[i] = .{
                .path = try arena.dupe(u8, tmp_crt_file.?.full_object_path),
                .must_link = true,
            };
        }

        var lib_progress_node = progress_node.start(root_name, 0);
        lib_progress_node.activate();
        defer lib_progress_node.end();

        // TODO: This is extracted into a local variable to work around a stage1 miscompilation.
        const emit_bin = Compilation.EmitLoc{
            .directory = o_directory, // Put it in the cache directory.
            .basename = basename,
        };
        const sub_compilation = try Compilation.create(comp.gpa, .{
            .local_cache_directory = comp.global_cache_directory,
            .global_cache_directory = comp.global_cache_directory,
            .zig_lib_directory = comp.zig_lib_directory,
            .cache_mode = .whole,
            .target = target,
            .root_name = root_name,
            .main_pkg = null,
            .output_mode = .Lib,
            .link_mode = .Static,
            .function_sections = true,
            .thread_pool = comp.thread_pool,
            .libc_installation = comp.bin_file.options.libc_installation,
            .emit_bin = emit_bin,
            .optimize_mode = comp.compilerRtOptMode(),
            .want_sanitize_c = false,
            .want_stack_check = false,
            .want_red_zone = comp.bin_file.options.red_zone,
            .omit_frame_pointer = comp.bin_file.options.omit_frame_pointer,
            .want_valgrind = false,
            .want_tsan = false,
            .want_pic = comp.bin_file.options.pic,
            .want_pie = comp.bin_file.options.pie,
            .want_lto = comp.bin_file.options.lto,
            .emit_h = null,
            .strip = comp.compilerRtStrip(),
            .is_native_os = comp.bin_file.options.is_native_os,
            .is_native_abi = comp.bin_file.options.is_native_abi,
            .self_exe_path = comp.self_exe_path,
            .link_objects = &link_objects,
            .verbose_cc = comp.verbose_cc,
            .verbose_link = comp.bin_file.options.verbose_link,
            .verbose_air = comp.verbose_air,
            .verbose_llvm_ir = comp.verbose_llvm_ir,
            .verbose_cimport = comp.verbose_cimport,
            .verbose_llvm_cpu_features = comp.verbose_llvm_cpu_features,
            .clang_passthrough_mode = comp.clang_passthrough_mode,
            .skip_linker_dependencies = true,
            .parent_compilation_link_libc = comp.bin_file.options.link_libc,
        });
        defer sub_compilation.destroy();

        try sub_compilation.updateSubCompilation();

        if (o_directory.handle.createFile(ok_basename, .{})) |file| {
            file.close();
        } else |err| {
            std.log.warn("compiler-rt lib: failed to mark completion: {s}", .{@errorName(err)});
        }
    }

    try cache.writeManifest();

    assert(compiler_rt_lib.* == null);
    compiler_rt_lib.* = .{
        .full_object_path = try std.fs.path.join(comp.gpa, &[_][]const u8{
            comp.global_cache_directory.path.?,
            o_sub_path,
            basename,
        }),
        .lock = cache.toOwnedLock(),
    };
}

const sources = &[_][]const u8{
    "compiler_rt/atomics.zig",
    "compiler_rt/sin.zig",
    "compiler_rt/cos.zig",
    "compiler_rt/sincos.zig",
    "compiler_rt/ceil.zig",
    "compiler_rt/exp.zig",
    "compiler_rt/exp2.zig",
    "compiler_rt/fabs.zig",
    "compiler_rt/floor.zig",
    "compiler_rt/fma.zig",
    "compiler_rt/fmax.zig",
    "compiler_rt/fmin.zig",
    "compiler_rt/fmod.zig",
    "compiler_rt/log.zig",
    "compiler_rt/log10.zig",
    "compiler_rt/log2.zig",
    "compiler_rt/round.zig",
    "compiler_rt/sqrt.zig",
    "compiler_rt/tan.zig",
    "compiler_rt/trunc.zig",
    "compiler_rt/extendXfYf2.zig",
    "compiler_rt/extend_f80.zig",
    "compiler_rt/compareXf2.zig",
    "compiler_rt/stack_probe.zig",
    "compiler_rt/divti3.zig",
    "compiler_rt/modti3.zig",
    "compiler_rt/multi3.zig",
    "compiler_rt/udivti3.zig",
    "compiler_rt/udivmodti4.zig",
    "compiler_rt/umodti3.zig",
    "compiler_rt/truncXfYf2.zig",
    "compiler_rt/trunc_f80.zig",
    "compiler_rt/addXf3.zig",
    "compiler_rt/mulXf3.zig",
    "compiler_rt/divsf3.zig",
    "compiler_rt/divdf3.zig",
    "compiler_rt/divxf3.zig",
    "compiler_rt/divtf3.zig",
    "compiler_rt/floatXiYf.zig",
    "compiler_rt/fixXfYi.zig",
    "compiler_rt/count0bits.zig",
    "compiler_rt/parity.zig",
    "compiler_rt/popcount.zig",
    "compiler_rt/bswap.zig",
    "compiler_rt/int.zig",
    "compiler_rt/shift.zig",
    "compiler_rt/negXi2.zig",
    "compiler_rt/muldi3.zig",
    "compiler_rt/absv.zig",
    "compiler_rt/negv.zig",
    "compiler_rt/addo.zig",
    "compiler_rt/subo.zig",
    "compiler_rt/mulo.zig",
    "compiler_rt/cmp.zig",
    "compiler_rt/negXf2.zig",
    "compiler_rt/os_version_check.zig",
    "compiler_rt/emutls.zig",
    "compiler_rt/arm.zig",
    "compiler_rt/aulldiv.zig",
    "compiler_rt/sparc.zig",
    "compiler_rt/clear_cache.zig",
};
