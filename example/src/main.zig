const std = @import("std");
const term = @import("terminal");

pub fn main() !void {
    var in = std.io.getStdIn();
    var out = std.io.getStdOut();

    try term.enableRawMode(in);
    defer term.disableRawMode(in);

    var t = term.Terminal.init(in, out);
    const pos = try t.getCursorPos();

    std.debug.print("\n\rterm pos: rows: {d} cols: {d}\n", .{pos.y, pos.x});
}

test "simple test" {
    std.testing.expect(true);
}
