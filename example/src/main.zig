const std = @import("std");
const terminal = @import("terminal");

pub fn main() !void {
    std.debug.print("call to the terminal lib: ", .{"codebase"});
}

test "simple test" {
    std.testing.expect(true);
}
