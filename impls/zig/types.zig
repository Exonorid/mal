pub const MalType = union(enum) {
    Nil: void,
    List: []MalType,
    Int: i64,
    Bool: bool,
    String: []const u8,
    Sym: []const u8,
};