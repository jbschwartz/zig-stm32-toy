const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = std.builtin.OptimizeMode.ReleaseSmall;

    const target = b.resolveTargetQuery(.{
        .cpu_arch = .thumb,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m0 },
        .os_tag = .freestanding,
        .abi = .eabi,
    });

    const startup = b.addObject(.{
        .name = "startup",
        .root_source_file = b.path("src/startup.zig"),
        .target = target,
        .optimize = optimize,
        .single_threaded = true,
    });

    const elf = b.addExecutable(.{
        .name = "zig-stm32-toy.elf",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .single_threaded = true,
    });

    elf.setLinkerScriptPath(b.path("linker.ld"));
    elf.entry = .{ .symbol_name = "resetHandler" };
    elf.addObject(startup);

    b.installArtifact(elf);

    // Generate a binary file from the ELF file (objcopy).
    const generate_bin = b.addObjCopy(elf.getEmittedBin(), .{ .format = .bin });
    generate_bin.step.dependOn(&elf.step);

    // Install the binary file to the output directory.
    const install_bin = b.addInstallBinFile(generate_bin.getOutput(), "zig-stm32-toy.bin");
    install_bin.step.dependOn(&generate_bin.step);

    b.default_step.dependOn(&install_bin.step);
}
