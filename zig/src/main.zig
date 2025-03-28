const std = @import("std");
const fs = std.fs;
const analyzer = @import("analyzer.zig");
const json = std.json;

fn saveStatsToJson(allocator: std.mem.Allocator, stats: []const analyzer.FileStats) !void {
    var string = std.ArrayList(u8).init(allocator);
    defer string.deinit();

    try string.appendSlice("[\n");
    for (stats, 0..) |stat, i| {
        if (i > 0) try string.appendSlice(",\n");
        try string.appendSlice("  {\n");
        try std.fmt.format(string.writer(), "    \"file\": \"{s}\",\n", .{stat.file});
        try std.fmt.format(string.writer(), "    \"words\": {d},\n", .{stat.words});
        try std.fmt.format(string.writer(), "    \"headings\": {d},\n", .{stat.headings});
        try std.fmt.format(string.writer(), "    \"links\": {d},\n", .{stat.links});
        try std.fmt.format(string.writer(), "    \"reading_time_min\": {d},\n", .{stat.reading_time_min});
        try std.fmt.format(string.writer(), "    \"readability_score\": {d:.10}\n", .{stat.readability_score});
        try string.appendSlice("  }");
    }
    try string.appendSlice("\n]\n");

    // Crea la directory di output se non esiste
    fs.cwd().makeDir("output") catch |err| {
        if (err != error.PathAlreadyExists) {
            return err;
        }
    };

    // Salva il file JSON
    const file = try fs.cwd().createFile("output/stats-zig.json", .{});
    defer file.close();

    try file.writeAll(string.items);
}

fn analyzeDirectory(allocator: std.mem.Allocator, dir: fs.Dir, base_path: []const u8) !void {
    var walker = try dir.walk(allocator);
    defer walker.deinit();

    var stats_list = std.ArrayList(analyzer.FileStats).init(allocator);
    defer {
        for (stats_list.items) |*stat| {
            stat.deinit(allocator);
        }
        stats_list.deinit();
    }

    while (try walker.next()) |entry| {
        if (entry.kind != .file) continue;
        
        // Verifica se il file è un markdown
        if (!std.mem.endsWith(u8, entry.path, ".md")) continue;

        // Costruisci il percorso completo per la visualizzazione
        const full_path = try std.fs.path.join(allocator, &[_][]const u8{ base_path, entry.path });
        defer allocator.free(full_path);

        const stats = try analyzer.analyzeMarkdownFile(allocator, dir, full_path);
        try stats_list.append(stats);

        // Stampa i risultati
        std.debug.print("\nAnalysis of: {s}\n", .{stats.file});
        std.debug.print("Words: {d}\n", .{stats.words});
        std.debug.print("Headings: {d}\n", .{stats.headings});
        std.debug.print("Links: {d}\n", .{stats.links});
        std.debug.print("Estimated reading time: {d} minutes\n", .{stats.reading_time_min});
        std.debug.print("Readability score: {d:.1}\n", .{stats.readability_score});
        std.debug.print("-----------------------------------------\n", .{});
    }

    // Salva i risultati in JSON
    try saveStatsToJson(allocator, stats_list.items);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    // Salta il nome del programma
    _ = args.next();

    // Leggi il percorso da analizzare
    var path = args.next() orelse {
        std.debug.print("Usage: markdown-analyzer <directory or file.md>\n", .{});
        std.process.exit(1);
    };

    // Gestisci l'opzione -i
    if (std.mem.eql(u8, path, "-i")) {
        path = args.next() orelse {
            std.debug.print("Error: no path specified after -i\n", .{});
            std.process.exit(1);
        };
    }

    // Risolvi il percorso assoluto
    const abs_path = try fs.path.resolve(allocator, &[_][]const u8{path});
    defer allocator.free(abs_path);

    // Verifica se il percorso è una directory o un file
    const path_info = try fs.cwd().statFile(abs_path);
    
    if (path_info.kind == .directory) {
        // Se è una directory, analizza ricorsivamente
        var dir = try fs.cwd().openDir(abs_path, .{ .iterate = true });
        defer dir.close();
        try analyzeDirectory(allocator, dir, abs_path);
    } else {
        // Se è un file, analizza solo quello
        var stats = try analyzer.analyzeMarkdownFile(allocator, fs.cwd(), abs_path);
        defer stats.deinit(allocator);

        std.debug.print("\nAnalysis of: {s}\n", .{abs_path});
        std.debug.print("Words: {d}\n", .{stats.words});
        std.debug.print("Headings: {d}\n", .{stats.headings});
        std.debug.print("Links: {d}\n", .{stats.links});
        std.debug.print("Estimated reading time: {d} minutes\n", .{stats.reading_time_min});
        std.debug.print("Readability score: {d:.1}\n", .{stats.readability_score});

        // Salva i risultati in JSON
        const stats_array = [_]analyzer.FileStats{stats};
        try saveStatsToJson(allocator, &stats_array);
    }

    std.debug.print("\nResults saved in: output/stats-zig.json\n", .{});
}
