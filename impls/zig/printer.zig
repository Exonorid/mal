const std = @import("std");
const types = @import("types.zig");

//It'd be more idiomatic to add a format function to MalType,
//I'm just doing this to match the guide
pub fn prStr(writer: anytype, value: types.MalType, print_readably: bool) @TypeOf(writer).Error!void {
    switch(value) {
        .Nil => try writer.writeAll("nil"),
        .List => |list| {
            try writer.writeByte('(');
            for(list) |elem, i| {
                if(i > 0) try writer.writeByte(' ');
                try prStr(writer, elem, print_readably);
            }
            try writer.writeByte(')');
        },
        .Vector => |vec| {
            try writer.writeByte('[');
            for(vec) |elem, i| {
                if(i > 0) try writer.writeByte(' ');
                try prStr(writer, elem, print_readably);
            }
            try writer.writeByte(']');
        },
        .HashMap => |map| {
            try writer.writeByte('{');
            var iter = map.iterator();
            var first: bool = true;
            while(iter.next()) |entry| {
                if(!first) try writer.writeByte(' ');
                try prStr(writer, types.MalType{ .String = entry.key_ptr.* }, print_readably);
                try writer.writeByte(' ');
                try prStr(writer, entry.value_ptr.*, print_readably);
                first = false;
            }
            try writer.writeByte('}');
        },
        .Int => |int| try writer.print("{d}", .{int}),
        .Bool => |b| try writer.print("{}", .{b}),
        .String => |str| {
            if(std.mem.startsWith(u8, str, "\u{029E}")) { //Keyword
                try writer.print(":{s}", .{str["\u{029E}".len..]});
            } else {
                if(print_readably) {
                    try writer.writeByte('"');
                    for(str) |ch| {
                        try writer.writeAll(switch(ch) {
                            '\n' => "\\n",
                            '\\' => "\\\\",
                            '"' => "\\\"",
                            else => &[_]u8{ ch }
                        });
                    }
                    try writer.writeByte('"');
                } else {
                    try writer.print("\"{s}\"", .{str});
                }
            }
        },
        .Sym => |sym| try writer.print("{s}", .{sym}),
    }
}

test "" {
    _ = prStr;
}