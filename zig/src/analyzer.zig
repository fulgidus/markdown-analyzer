const std = @import("std");
const fs = std.fs;
const mem = std.mem;
const Allocator = std.mem.Allocator;
const testing = std.testing;

pub const FileStats = struct {
    file: []const u8,
    words: usize,
    headings: usize,
    links: usize,
    reading_time_min: usize,
    readability_score: f64,

    pub fn deinit(self: *FileStats, allocator: Allocator) void {
        allocator.free(self.file);
    }
};

pub fn analyzeMarkdownFile(allocator: Allocator, dir: fs.Dir, path: []const u8) !FileStats {
    const file = try dir.openFile(path, .{});
    defer file.close();

    const file_size = try file.getEndPos();
    const buffer = try allocator.alloc(u8, file_size);
    defer allocator.free(buffer);

    const bytes_read = try file.readAll(buffer);
    if (bytes_read != file_size) {
        return error.IncompleteRead;
    }

    const content = buffer[0..file_size];

    // Conteggio parole: ignora la punteggiatura e conta solo le parole effettive
    var word_count: usize = 0;
    var in_word = false;
    for (content) |c| {
        if (std.ascii.isAlphabetic(c) or std.ascii.isDigit(c) or c == '-' or c == '_') {
            if (!in_word) {
                word_count += 1;
                in_word = true;
            }
        } else if (std.ascii.isWhitespace(c) or c == '.' or c == ',' or c == '!' or c == '?' or c == ':' or c == ';') {
            in_word = false;
        }
    }

    // Conteggio headings
    var heading_count: usize = 0;
    var lines = mem.splitScalar(u8, content, '\n');
    while (lines.next()) |line| {
        const trimmed = mem.trimLeft(u8, line, " \t");
        if (trimmed.len > 0 and trimmed[0] == '#') {
            heading_count += 1;
        }
    }

    // Conteggio link (cerca il pattern ]( come in Go)
    var link_count: usize = 0;
    var i: usize = 0;
    while (i < content.len - 1) : (i += 1) {
        if (content[i] == ']' and content[i + 1] == '(') {
            link_count += 1;
        }
    }

    // Tempo di lettura stimato (200 parole al minuto)
    const reading_time = @divTrunc(word_count + 199, 200);

    // Calcolo leggibilità (formula semplificata come in Go)
    var sentence_count: usize = 0;
    for (content) |c| {
        if (c == '.') {
            sentence_count += 1;
        }
    }
    if (sentence_count == 0) sentence_count = 1;

    const avg_words_per_sentence = @as(f64, @floatFromInt(word_count)) / @as(f64, @floatFromInt(sentence_count));
    const readability = 100 - (avg_words_per_sentence * 2);

    // Normalizza il punteggio tra 0 e 100
    const normalized_readability = @max(0.0, @min(100.0, readability));

    const file_path = try allocator.dupe(u8, path);

    return FileStats{
        .file = file_path,
        .words = word_count,
        .headings = heading_count,
        .links = link_count,
        .reading_time_min = reading_time,
        .readability_score = @round(normalized_readability * 10.0) / 10.0,
    };
}

test "test word count" {
    var tmp_dir = testing.tmpDir(.{});
    defer tmp_dir.cleanup();

    const content = "Hello world! This is a test.";
    const file = try tmp_dir.dir.createFile("test.md", .{});
    defer file.close();
    try file.writeAll(content);

    var stats = try analyzeMarkdownFile(testing.allocator, tmp_dir.dir, "test.md");
    defer stats.deinit(testing.allocator);

    try testing.expectEqual(@as(usize, 6), stats.words);
}

test "test heading count" {
    var tmp_dir = testing.tmpDir(.{});
    defer tmp_dir.cleanup();

    const content = "# Heading 1\nText\n## Heading 2\nMore text";
    const file = try tmp_dir.dir.createFile("test.md", .{});
    defer file.close();
    try file.writeAll(content);

    var stats = try analyzeMarkdownFile(testing.allocator, tmp_dir.dir, "test.md");
    defer stats.deinit(testing.allocator);

    try testing.expectEqual(@as(usize, 2), stats.headings);
}

test "test link count" {
    var tmp_dir = testing.tmpDir(.{});
    defer tmp_dir.cleanup();

    const content = "This is a [link](https://example.com).";
    const file = try tmp_dir.dir.createFile("test.md", .{});
    defer file.close();
    try file.writeAll(content);

    var stats = try analyzeMarkdownFile(testing.allocator, tmp_dir.dir, "test.md");
    defer stats.deinit(testing.allocator);

    try testing.expectEqual(@as(usize, 1), stats.links);
}

test "test reading time estimate" {
    var tmp_dir = testing.tmpDir(.{});
    defer tmp_dir.cleanup();

    var content: [2000]u8 = undefined;
    var i: usize = 0;
    while (i < 400) : (i += 1) {
        _ = std.fmt.bufPrint(content[i * 5 ..], "word ", .{}) catch unreachable;
    }
    const file = try tmp_dir.dir.createFile("test.md", .{});
    defer file.close();
    try file.writeAll(content[0..2000]);

    var stats = try analyzeMarkdownFile(testing.allocator, tmp_dir.dir, "test.md");
    defer stats.deinit(testing.allocator);

    try testing.expectEqual(@as(usize, 2), stats.reading_time_min);
}

test "test readability score bounds" {
    var tmp_dir = testing.tmpDir(.{});
    defer tmp_dir.cleanup();

    const content = "This is a test. It is only a test. This text is simple.";
    const file = try tmp_dir.dir.createFile("test.md", .{});
    defer file.close();
    try file.writeAll(content);

    var stats = try analyzeMarkdownFile(testing.allocator, tmp_dir.dir, "test.md");
    defer stats.deinit(testing.allocator);

    try testing.expect(stats.readability_score >= 0.0);
    try testing.expect(stats.readability_score <= 100.0);
}
