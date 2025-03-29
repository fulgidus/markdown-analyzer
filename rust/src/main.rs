mod analyzer;

use analyzer::FileStats;
use crossbeam::channel::unbounded;
use std::env;
use std::fs::{ create_dir_all, File };
use std::io::Write;
use std::path::PathBuf;
use std::thread;
use walkdir::WalkDir;

fn get_markdown_files(root: &str) -> Vec<PathBuf> {
    WalkDir::new(root)
        .into_iter()
        .filter_map(Result::ok)
        .filter(|e| {
            e.path().is_file() &&
                e
                    .path()
                    .extension()
                    .map(|ext| ext == "md")
                    .unwrap_or(false)
        })
        .map(|e| e.into_path())
        .collect()
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let input_path = args.get(1).expect("❗ Please provide an input path (e.g. './input')");

    println!("🔍 Scanning markdown files in '{}'\n", input_path);

    let markdown_files = get_markdown_files(input_path);

    let (tx, rx) = unbounded();
    let mut handles = vec![];

    for path in markdown_files {
        let tx = tx.clone();
        let path_clone = path.clone();

        let handle = thread::spawn(move || {
            if let Some(stats) = analyzer::analyze_markdown_file(&path_clone) {
                tx.send(stats).expect("Send failed");
            }
        });

        handles.push(handle);
    }

    drop(tx); // 🔚 Important: closes the channel when all threads are done

    let mut results = vec![];

    for stat in rx {
        println!("📄 Analyzed: {}", stat.file);
        println!("• Words:            {}", stat.words);
        println!("• Headings:         {}", stat.headings);
        println!("• Links:            {}", stat.links);
        println!("• Reading Time:     {} min", stat.reading_time_min);
        println!("• Readability Score: {:.1}", stat.readability_score);
        println!("────────────────────────────────────\n");

        results.push(stat);
    }

    for handle in handles {
        handle.join().expect("Thread panicked");
    }

    create_dir_all("../output").expect("Failed to create output folder");

    let mut file = File::create("../output/stats-rust.json").expect("Failed to create stats.json");
    let json = serde_json::to_string_pretty(&results).expect("Failed to serialize JSON");

    file.write_all(json.as_bytes()).expect("Failed to write JSON file");

    println!("✅ Analysis complete! Results saved to output/stats.json");
}
