#!/bin/bash

echo "Executing markdown analyzer in all its versions..."
echo "----------------------------------------"

# Ottieni il percorso assoluto della directory corrente
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_FILES="$ROOT_DIR/input"

# Esegui la versione Rust
echo "Executing Rust version..."
cd "$ROOT_DIR/rust" && cargo run -- -i "$TEST_FILES" || exit 1
cd "$ROOT_DIR"
echo "----------------------------------------"

# Esegui la versione Zig
echo "Executing Zig version..."
cd "$ROOT_DIR/zig" && zig build run -- -i "$TEST_FILES" || exit 1
cd "$ROOT_DIR"
echo "----------------------------------------"

# Esegui la versione Go
echo "Executing Go version..."
cd "$ROOT_DIR/go" && go build -o markdown-analyzer && ./markdown-analyzer -input "$TEST_FILES" || exit 1
cd "$ROOT_DIR"
echo "----------------------------------------"

echo "All programs have been executed successfully!"
echo "Results are available in:"
echo "- output/stats-rust.json"
echo "- output/stats-zig.json"
echo "- output/stats-go.json"

# Optionally, show differences between files
echo -e "\nComparing results..."
echo "----------------------------------------"
echo "Differences between Rust and Go:"
diff output/stats-rust.json output/stats-go.json || true
echo "----------------------------------------"
echo "Differences between Zig and Go:"
diff output/stats-zig.json output/stats-go.json || true
echo "----------------------------------------"
echo "Differences between Rust and Zig:"
diff output/stats-rust.json output/stats-zig.json || true