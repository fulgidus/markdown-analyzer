use std::fs::{ create_dir_all, write };
use std::path::Path;
use std::env;

fn generate_markdown_content(index: usize) -> String {
    let heading = format!("# File {}\n\n", index);
    let mut body = String::new();

    for i in 0..50 {
        body.push_str(&format!("Paragraph {} with some content. ", i));
        if i % 10 == 0 {
            body.push_str("[Click here](https://example.com) ");
        }
        if i % 7 == 0 {
            body.push_str("## Subheading\n");
        }
    }

    format!("{}{}", heading, body)
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let count: usize = args
        .get(1)
        .and_then(|s| s.parse().ok())
        .unwrap_or(100);

    let input_dir = Path::new("../input");
    create_dir_all(&input_dir).expect("Could not create input directory");

    for i in 0..count {
        let filename = input_dir.join(format!("file_{i:04}.md"));
        let content = generate_markdown_content(i);
        write(&filename, content).expect("Could not write file");
    }

    println!("✅ Generated {count} markdown files in '../input'");
}
