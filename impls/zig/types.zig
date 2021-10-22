const std = @import("std");

pub const MalType = union(enum) {
    Nil: void,
    List: []MalType,
    Int: i64,
    Bool: bool,
    String: []const u8,
    Sym: []const u8,

    pub fn free(value: MalType, allocator: *std.mem.Allocator) void {
        switch(value) {
            .List => |list| {
                for(list) |elem| {
                    elem.free(allocator);
                }
                allocator.free(list);
            },
            .String => |str| {
                allocator.free(str);
            },
            else => {}
        }
    }
};