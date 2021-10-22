const std = @import("std");
const reader = @import("reader.zig");
const printer = @import("printer.zig");
const types = @import("types.zig");

fn read(str: []const u8, allocator: *std.mem.Allocator) !reader.TokenReader {
    return reader.readStr(allocator, str);
}

fn eval(token_reader: *reader.TokenReader, allocator: *std.mem.Allocator) !types.MalType {
    return token_reader.readForm(allocator);
}

fn print(value: types.MalType, writer: anytype) !void {
    return printer.prStr(writer, value);
}

fn rep(str: []const u8, allocator: *std.mem.Allocator, writer: anytype) !void {
    var token_reader = try read(str, allocator);
    defer token_reader.free(allocator);

    const parsed = try eval(&token_reader, allocator);
    defer parsed.free(allocator);

    try print(parsed, writer);
    try writer.writeByte('\n');
}

pub fn main() !void {
    const stdout = std.io.getStdOut();
    const stdin = std.io.getStdIn();
    const stdout_writer = stdout.writer();
    const stdin_reader = stdin.reader();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var allocator = &gpa.allocator;

    while(true) {
        try stdout_writer.writeAll("user> ");
        var input_buf: [128]u8 = undefined;
        const input = (stdin_reader.readUntilDelimiterOrEof(input_buf[0..], '\n') catch |err| switch(err) {
            error.StreamTooLong => {
                std.log.err("That expression is too long, please try again", .{});
                //Discard the rest of the line
                while((try stdin_reader.readByte()) != '\n') {}
                continue;
            },
            else => {
                std.log.emerg("Unrecoverable error {}", .{err});
                std.process.exit(1);
            }
        }) orelse break;
        rep(input, allocator, stdout_writer) catch |err| switch(err) {
            error.EndOfTokens => {
                std.log.err("end of input", .{});
                continue;
            },
            error.UnterminatedList => {
                std.log.err("unbalanced parentheses", .{});
                continue;
            },
            error.UnterminatedString => {
                std.log.err("unbalanced quotes", .{});
                continue;
            },
            error.Overflow => {
                std.log.err("integer value is too large", .{});
                continue;
            },
            error.InvalidCharacter => {
                std.log.err("unexpected character in integer literal", .{});
                continue;
            },
            error.InvalidEscape => {
                std.log.err("invalid escape sequence in string literal", .{});
                continue;
            },
            else => {
                std.log.emerg("Unrecoverable error {}", .{err});
                std.process.exit(1);
            }
        };
    }
}

