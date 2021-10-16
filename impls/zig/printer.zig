const types = @import("types.zig");

//It'd be more idiomatic to add a format function to MalType,
//I'm just doing this to match the guide
pub fn prStr(writer: anytype, value: types.MalType) @TypeOf(writer).Error!void {
    switch(value) {
        .Nil => try writer.writeAll("nil"),
        .List => |list| {
            try writer.writeByte('(');
            for(list) |elem, i| {
                if(i > 0) try writer.writeByte(' ');
                try prStr(writer, elem);
            }
            try writer.writeByte(')');
        },
        .Int => |int| try writer.print("{d}", .{int}),
        .Bool => |b| try writer.print("{}", .{b}),
        .String => |str| try writer.print("\"{s}\"", .{str}),
        .Sym => |sym| try writer.print("{s}", .{sym}),
    }
}

test "" {
    _ = prStr;
}