mod analyzer;

use analyzer::analyze_markdown_file;
use serde_json::to_string_pretty;
use std::env;
use std::fs::{create_dir_all, File};
use std::io::Write;
use walkdir::WalkDir;

fn main() {
    let args: Vec<String> = env::args().collect();
    let mut input_path = args
        .get(1)
        .expect("❗ Please provide an input path, e.g. './input'")
        .to_string();

    // Gestisci l'opzione -i
    if input_path == "-i" {
        input_path = args
            .get(2)
            .expect("❗ Please provide a path after -i")
            .to_string();
    }

    // Converti in percorso assoluto
    let abs_path = std::fs::canonicalize(&input_path).expect("❗ Failed to resolve absolute path");

    let mut results = Vec::new();

    for entry in WalkDir::new(&abs_path)
        .into_iter()
        .filter_map(Result::ok)
        .filter(|e| {
            e.path().is_file() && e.path().extension().map(|ext| ext == "md").unwrap_or(false)
        })
    {
        if let Some(stats) = analyze_markdown_file(entry.path()) {
            println!("File: {}", stats.file);
            println!("────────────────────────────");
            println!("• Words:           {}", stats.words);
            println!("• Headings:        {}", stats.headings);
            println!("• Links:           {}", stats.links);
            println!("• Reading Time:    {} min", stats.reading_time_min);
            println!("• Readability Score: {:.1}", stats.readability_score);
            println!("────────────────────────────\n");

            results.push(stats);
        }
    }

    create_dir_all("output").expect("Could not create output folder");
    let mut file = File::create("output/stats-rust.json").expect("Failed to create JSON file");
    let json = to_string_pretty(&results).expect("Failed to serialize JSON");
    file.write_all(json.as_bytes())
        .expect("Failed to write JSON");

    println!("✅ Analysis complete. Results saved to output/stats-rust.json");
}
