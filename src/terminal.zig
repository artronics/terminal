const std = @import("std");
const io = std.io;
const fs = std.fs;
const c = @cImport({
    @cInclude("termios.h");
    @cInclude("sys/ioctl.h");
});

var orig_termios: c.struct_termios = undefined;

const TerminalError = error{ RawMode, ReadError, WriteError };

pub fn enableRawMode(in: fs.File) !void {
    if (c.tcgetattr(in.handle, &orig_termios) == -1) {
        return TerminalError.RawMode;
    }

    var raw = orig_termios;

    raw.c_iflag &= ~@as(c_ulong, c.BRKINT | c.ICRNL | c.INPCK | c.ISTRIP | c.IXON);
    raw.c_oflag &= ~@as(c_ulong, c.OPOST);
    raw.c_cflag |= @as(c_ulong, c.CS8);
    raw.c_lflag &= ~@as(c_ulong, c.ECHO | c.ICANON | c.IEXTEN | c.ISIG);
    raw.c_cc[c.VMIN] = 0;
    raw.c_cc[c.VTIME] = 1;

    if (c.tcsetattr(in.handle, c.TCSAFLUSH, &raw) == -1) {
        return TerminalError.RawMode;
    }
}

pub fn disableRawMode(in: fs.File) void {
    _ = c.tcsetattr(in.handle, c.TCSAFLUSH, &orig_termios);
}

const esc_get_pos = "\x1b[6n";

pub const Terminal = struct {
    in: fs.File,
    out: fs.File,

    orig_termios: c.struct_termios = undefined,

    pub const Pos = struct { x: usize, y: usize };

    const Self = @This();
    fn init(in: fs.File, out: fs.File) Self {
        return Terminal{
            .in = in,
            .out = out,
        };
    }

    fn getCursorPos(self: Self) !Terminal.Pos {
        try self.out.writeAll(esc_get_pos);

        var in_reader = self.in.reader();
        if (try in_reader.readByte() != '\x1b' or try in_reader.readByte() != '[') return TerminalError.ReadError;

        var buf: [32]u8 = undefined;
        var response = io.fixedBufferStream(&buf);

        try in_reader.streamUntilDelimiter(response.writer(), ';', 32);
        const y = try std.fmt.parseInt(usize, response.buffer[0..try response.getPos()], 10);

        response.reset();

        try in_reader.streamUntilDelimiter(response.writer(), 'R', 32);
        const x = try std.fmt.parseInt(usize, response.buffer[0..try response.getPos()], 10);

        return .{ .x = x, .y = y };
    }

    fn setCursorPos(self: Self, pos: Pos) !void {
        var buf: [32]u8 = undefined;
        const seq = try std.fmt.bufPrint(&buf, "\x1b[{d};{d}H", .{ pos.y, pos.x });
        try self.out.writeAll(seq);
    }

    fn getWindowSize(self: Self) !Pos {
        const cur_pos = try self.getCursorPos();

        try self.out.writeAll("\x1b[999C\x1b[999B");
        const size = try self.getCursorPos();

        try self.setCursorPos(cur_pos);
        return size;
    }
};

const testing = std.testing;
const expectEq = testing.expectEqual;
const expectSliceEq = testing.expectEqualSlices;

test "test" {
    var tmp_dir = testing.tmpDir(.{});
    defer tmp_dir.cleanup();
    // var buf: [64]u8 = undefined;

    var in = try tmp_dir.dir.createFile("in", .{ .read = true });
    defer in.close();
    var out = try tmp_dir.dir.createFile("out", .{ .read = true });
    defer out.close();

    const term = Terminal.init(in, out);
    _ = term;
}
