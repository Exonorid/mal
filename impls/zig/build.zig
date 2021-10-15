const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const steps = [_][:0]const u8{
        "repl"
    };
    for(steps) |step_name, i| {
        const file_name = std.fmt.allocPrint(b.allocator, "step{X}_{s}.zig", .{i, step_name}) catch unreachable;
        const exe = b.addExecutable(file_name[0..file_name.len - 4], file_name);
        exe.setTarget(target);
        exe.setBuildMode(mode);
        exe.install();
        const run = exe.run();
        const step = b.step(exe.name, exe.name);
        step.dependOn(&run.step);
        b.default_step.dependOn(&exe.step);
    }
}
