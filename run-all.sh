#!/bin/bash

# Ottieni il percorso assoluto della directory corrente
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Executing markdown analyzer in all its versions..."
echo "----------------------------------------"

# Esegui la versione Rust
echo "Executing Rust version..."
cd rust && cargo build && cd ..
rust/target/debug/markdown_analyzer -i "$(pwd)/input"
echo "----------------------------------------"

# Esegui la versione Zig
echo "Executing Zig version..."
cd zig && zig build && cd ..
zig/zig-out/bin/markdown-analyzer -i "$(pwd)/input"
echo "----------------------------------------"

# Esegui la versione Go
echo "Executing Go version..."
cd go && go run main.go -input "$(pwd)/../input"
echo "----------------------------------------"

echo "All programs have been executed successfully!"
echo "Results are available in:"
echo "- output/stats-rust.json"
echo "- output/stats-zig.json"
echo "- output/stats-go.json"

echo -e "\nComparing results..."
echo "----------------------------------------"
cd "$ROOT_DIR" && python3 compare_results.py