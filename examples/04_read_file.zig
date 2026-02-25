// This file will take a CLI argument for a file and then parse that CSV file

const zcsv = @import("zcsv");
const std = @import("std");

pub fn main() !void {
    var args = std.process.args();
    _ = args.skip();

    const file = args.next() orelse "test.csv";
    try parseFile(file);
}

pub fn parseFile(fileName: []const u8) !void {
    // Get our allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    // Open our file
    const file = try std.fs.cwd().openFile(fileName, .{});
    defer file.close();

    var stderr_buffer: [1024]u8 = undefined;
    var stderr_writer = std.fs.File.stderr().writer(&stderr_buffer);
    const stderr = &stderr_writer.interface;
    defer stderr.flush() catch {};

    const csv = try file.readToEndAlloc(alloc, std.math.maxInt(usize));
    defer alloc.free(csv);
    var file_stream = std.io.fixedBufferStream(csv);

    // We can read directly from our file reader
    var parser = zcsv.allocs.column.init(alloc, file_stream.reader(), .{});
    while (parser.next()) |row| {
        // Clean up our memory
        defer row.deinit();

        try stderr.writeAll("\nROW:");

        // Iterate over our fields
        var fieldIter = row.iter();
        while (fieldIter.next()) |field| {
            try stderr.writeAll(" Field: ");
            try stderr.writeAll(field.data());
        }
    }

}
