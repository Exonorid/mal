const std = @import("std");

pub const MalType = union(enum) {
    Nil: void,
    List: []MalType,
    Vector: []MalType,
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
            .Vector => |vec| {
                for(vec) |elem| {
                    elem.free(allocator);
                }
                allocator.free(vec);
            },
            .String => |str| {
                allocator.free(str);
            },
            else => {}
        }
    }
};