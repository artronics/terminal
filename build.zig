const std = @import("std");
const example = @import("example/build.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "terminal",
        .root_source_file = .{ .path = "src/terminal.zig" },
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(lib);

    var term_exe = example.package(b, optimize, target);
    term_exe.linkLibrary(lib);
    b.installArtifact(term_exe);

    const run_example = b.addRunArtifact(term_exe);
    run_example.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_example.addArgs(args);
    }
    const run_step = b.step("example", "Run the example app");
    run_step.dependOn(&run_example.step);

    // tests
    const main_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/terminal.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_main_tests = b.addRunArtifact(main_tests);
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_main_tests.step);
    test_step.dependOn(example.runTests(b, optimize, target));
}
