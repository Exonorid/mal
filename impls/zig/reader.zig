const std = @import("std");
const types = @import("types.zig");

const PeekableReader = struct {
    str: []const u8,
    pos: usize = 0,

    pub fn next(self: *@This()) ?u8 {
        if(self.pos >= self.str.len) return null;
        const ch = self.str[self.pos];
        self.pos += 1;
        return ch;
    }

    pub fn peek(self: *@This()) ?u8 {
        if(self.pos >= self.str.len) return null;
        return self.str[self.pos];
    }

    pub fn peekAhead(self: *@This(), amt: usize) ?u8 {
        if(self.pos + amt >= self.str.len) return null;
        return self.str[self.pos + amt];
    }

    pub fn skip(self: *@This()) bool {
        if(self.pos >= self.str.len) return false;
        self.pos += 1;
        return true;
    }

    pub fn skipN(self: *@This(), n: usize) bool {
        if(self.pos + n > self.str.len) return false;
        self.pos += n;
        return true;
    }
};

test "PeekableReader interface" {
    var test_reader = PeekableReader{ .str = "Foobar abcdef" };
    try std.testing.expectEqual(@as(u8, 'F'), test_reader.next().?);

    try std.testing.expectEqual(@as(u8, 'o'), test_reader.peek().?);
    try std.testing.expectEqual(@as(u8, 'o'), test_reader.peekAhead(1).?);
    try std.testing.expectEqual(@as(usize, 1), test_reader.pos);

    try std.testing.expect(test_reader.skip());
    try std.testing.expectEqual(@as(u8, 'o'), test_reader.peek().?);
    try std.testing.expectEqual(@as(u8, 'b'), test_reader.peekAhead(1).?);
    try std.testing.expectEqual(@as(usize, 2), test_reader.pos);

    try std.testing.expect(test_reader.skipN(2));
    try std.testing.expectEqual(@as(u8, 'a'), test_reader.next().?);
    try std.testing.expect(test_reader.skipN(7));
    try std.testing.expectEqual(@as(u8, 'f'), test_reader.next().?);
    try std.testing.expectEqual(@as(usize, 13), test_reader.pos);
    try std.testing.expectEqual(@as(?u8, null), test_reader.next());
    try std.testing.expect(!test_reader.skip());
    try std.testing.expect(!test_reader.skipN(1));
}

pub const Token = []const u8;

pub const TokenReader = struct {
    tokens: []const Token,
    pos: usize = 0,

    pub fn next(self: *@This()) ?Token {
        if(self.pos == self.tokens.len) return null;
        const token = self.tokens[self.pos];
        self.pos += 1;
        return token;
    }

    pub fn peek(self: *@This()) ?Token {
        if(self.pos == self.tokens.len) return null;
        return self.tokens[self.pos];
    }

    pub fn readForm(reader: *TokenReader, allocator: *std.mem.Allocator) !types.MalType {
        if(std.mem.eql(u8, reader.peek(), "(")) {
            return reader.readList(allocator);
        } else {
            return readAtom(reader);
        }
    }

    fn readList(reader: *TokenReader, allocator: *std.mem.Allocator) !types.MalType {
        std.debug.assert(reader.skip());
        var elems = std.ArrayList(MalType).init();
        defer elems.deinit();
        while(!std.mem.eql(u8, reader.peek() orelse break, ")")) {
            try elems.append(reader.readForm(allocator));
        } else {
            //End of list ')'
            return types.MalType{ .list = elems.toOwnedSlice() };
        }
        //EOF reached before ')'
        return error.UnterminatedList;
    }

    fn readInt(token: Token) !i64 {
        return std.fmt.parseInt(i64, token, 10);
    }

    fn readString(token: Token) ![]const u8 {
        if(token[token.len - 1] != '"') return error.UnterminatedString;
        return token[1..token.len - 2];
    }

    fn readAtom(reader: *TokenReader) !MalType {
        const token = reader.next().?;
        switch(token[0]) {
            //Integer
            '-' => {
                if(token.len > 1 and (token[1] >= '0' and token[1] <= '9'))
                    return types.MalType{ .Int = try readInt(token[1..]) * -1 };
            },
            '0'...'9' => {
                return types.MalType{ .Int = try readInt(token) };
            },
            //Nil
            'n' => {
                if(std.mem.eql(u8, token, "nil")) return types.MalType{ .Nil };
            },
            //Bool (true/false)
            't' => {
                if(std.mem.eql(u8, token, "true")) return types.MalType{ .Bool = true };
            },
            'f' => {
                if(std.mem.eql(u8, token, "false")) return types.MalType{ .Bool = false };
            },
            //String
            '"' => {
                return types.MalType{ .String = try readString(token) };
            },
            else => {}
        }
        //Default to symbol
        return types.MalType{ .Sym = token };
    }
};

pub fn readStr(allocator: *std.mem.Allocator, str: []const u8) !TokenReader {
    return TokenReader{
        .tokens = try tokenize(allocator, str)
    };
}

pub fn tokenize(allocator: *std.mem.Allocator, str: []const u8) ![]Token {
    var reader = PeekableReader{ .str = str };

    var tokens = std.ArrayList(Token).init(allocator);
    defer tokens.deinit();
    while(reader.next()) |ch| {
        switch(ch) {
            // [\s,]
            ' ', '\n', '\t', '\r', ',' => continue,
            // ~@?
            '~' => {
                if(reader.peek()) |next_ch| {
                    if(next_ch == '@') {
                        std.debug.assert(reader.skip());
                        try tokens.append(str[reader.pos - 2..reader.pos]);
                        continue;
                    }
                }
                try tokens.append(str[reader.pos - 1..reader.pos]);
            },
            // [\[\]{}()'`^@]
            '[', ']', '{', '}', '(', ')', '\'', '`', '^', '@' => {
                try tokens.append(str[reader.pos - 1..reader.pos]);
            },
            // "(?:\\.|[^\\"])*"?
            '"' => {
                const start = reader.pos - 1;
                while(reader.peek()) |next_ch| {
                    switch(next_ch) {
                        '\\' => {
                            if(reader.peekAhead(1)) |_| {
                                std.debug.assert(reader.skipN(2));
                            } else break;
                        },
                        '"' => {
                            std.debug.assert(reader.skip());
                            break;
                        },
                        else => {
                            std.debug.assert(reader.skip());
                        }
                    }
                }
                try tokens.append(str[start..reader.pos]);
            },
            // ;.*
            ';' => {
                const start = reader.pos - 1;
                while(reader.next()) |_| {}
                try tokens.append(str[start..reader.pos]);
            },
            // [^\s\[\]{}('"`,;)]*
            else => {
                const start = reader.pos - 1;
                while(reader.peek()) |next_ch| {
                    if(std.mem.indexOf(u8, " \n\t\r[]{}()'\"`,;", &[_]u8{ next_ch })) |_| {
                        break;
                    } else std.debug.assert(reader.skip());
                }
                try tokens.append(str[start..reader.pos]);
            }
        }
    }
    return tokens.toOwnedSlice();
}

fn expectTokenization(allocator: *std.mem.Allocator, expected: []const Token, str: []const u8) !void {
    const actual = try tokenize(allocator, str);
    defer allocator.free(actual);

    if (expected.len != actual.len) {
        std.debug.print("slice lengths differ. expected {d}, found {d}\n", .{ expected.len, actual.len });
        return error.TestExpectedEqual;
    }
    var i: usize = 0;
    while (i < expected.len) : (i += 1) {
        if (!std.mem.eql(u8, expected[i], actual[i])) {
            std.debug.print("index {} incorrect. expected '{s}', found '{s}'\n", .{ i, expected[i], actual[i] });
            return error.TestExpectedEqual;
        }
    }
}

test "tokenize" {
    var allocator = std.testing.allocator;

    try expectTokenization(
        allocator,
        &[_]Token{ },
        ""
    );

    try expectTokenization(
        allocator,
        &[_]Token{ },
        "   \n\t"
    );

    try expectTokenization(
        allocator,
        &[_]Token{ "abcd", "hello", ";this [] is () a comment hopefully" },
        "abcd,hello;this [] is () a comment hopefully"
    );

    try expectTokenization(
        allocator,
        &[_]Token{ "doremi", "abc123" },
        "doremi abc123"
    );

    try expectTokenization(
        allocator,
        &[_][]const u8{ "(", "123", "456", "789", ")" },
        "(123 456 789)"
    );
}
