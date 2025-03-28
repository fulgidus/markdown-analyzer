# 📊 Markdown Analyzer

**Markdown Analyzer** is a cross-language CLI tool built in **Rust**, **Zig**, and **Go**.  
It scans one or more Markdown files—or entire directories—and extracts useful statistics such as:

- 📄 Total word count
- 🧵 Number of headings
- 🔗 Number of links
- ⏱ Estimated reading time
- 📚 Readability score (Flesch–Kincaid)
- 📤 JSON export of all results

> This project was built as a personal exploration of three systems programming languages,  
> not as a replacement for production tools. It's a learning exercise, and a fun one at that!

---

## 💡 Features

- ✅ Analyze individual `.md` files or full directory trees
- ✅ Recursive folder support
- ✅ Extract content statistics from Markdown
- ✅ Estimate reading time (200 wpm)
- ✅ Compute a basic readability score
- ✅ Export full report in JSON format

---

## 🧪 Example Output

### 📋 Terminal Summary
```bash
File: input/notes.md
────────────────────────────
• Words:           1,234
• Headings:           12
• Links:              23
• Reading Time:        6 min
• Readability Score:  67.4
────────────────────────────
```

### 📤 JSON Output (output/stats.json)

```json
[
  {
    "file": "input/notes.md",
    "words": 1234,
    "headings": 12,
    "links": 23,
    "reading_time_min": 6,
    "readability_score": 67.4
  }
]
```

## 📂 Project Structure

``` graphql
markdown-analyzer/
├── input/                  # Markdown files to analyze
│   ├── notes.md
│   └── docs/
│       └── guide.md
├── output/                 # JSON report output
│   └── stats.json
├── rust/                   # Rust implementation
│   └── main.rs
├── go/                     # Go implementation
│   └── main.go
├── zig/                    # Zig implementation
│   └── main.zig
├── README.md               # This file
```

## 🚀 How to Run
### 🦀 Rust
```bash
cd rust
cargo run -- ../input
```

### ⚙️ Go

```bash
cd go
go run main.go ../input
```

### ⚡ Zig

```bash
cd zig
zig run main.zig -- ../input
```

## 🎯 Why Three Languages?

This project is an opportunity to explore how different programming languages:

- Handle file I/O and directory traversal
- Work with strings and pattern matching
- Structure command-line applications
- Deal with performance, safety, and ergonomics

Each version does the same thing, but the implementation varies.  
That’s the point — to compare and learn from the differences.
## 📚 Learning Goals

- Write idiomatic code in Rust, Go, and Zig
- Explore how each language handles errors, types, and performance
- Practice building cross-language tools with the same functional spec
- Document and share the experience

## 🙌 License

This project is released under the MIT License.
Feel free to fork, learn, or adapt — it's all about learning and having fun.

> ℹ️  
> Built for fun.  
> Powered by curiosity.  
> Inspired by the need to tinker with Rust, Go, and Zig.