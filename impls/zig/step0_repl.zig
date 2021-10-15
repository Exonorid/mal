const std = @import("std");

fn read(str: []const u8) []const u8 {
    return str;
}

fn eval(str: []const u8) []const u8 {
    return str;
}

fn print(str: []const u8) []const u8 {
    return str;
}

fn rep(str: []const u8) []const u8 {
    return print(eval(read(str)));
}

pub fn main() !void {
    const stdout = std.io.getStdOut();
    const stdin = std.io.getStdIn();
    const writer = stdout.writer();
    const reader = stdin.reader();

    while(true) {
        try writer.writeAll("user> ");
        var input_buf: [128]u8 = undefined;
        const input = (reader.readUntilDelimiterOrEof(input_buf[0..], '\n') catch |err| switch(err) {
            error.StreamTooLong => {
                std.log.err("That expression is too long, please try again", .{});
                //Discard the rest of the line
                while((try reader.readByte()) != '\n') {}
                continue;
            },
            else => {
                std.log.emerg("Unrecoverable error: {}", .{err});
                std.process.exit(1);
            }
        }) orelse break;
        try writer.print("{s}\n", .{rep(input)});
    }
    try writer.writeByte('\n');
}
