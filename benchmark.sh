#!/bin/bash

echo "🧹 Cleaning up output folder..."
rm -rf output
mkdir output

echo "⚙️ Benchmarking Rust..."
cd rust
time cargo run -- ../input > ../output/rust.txt
cd ..

echo "⚙️ Benchmarking Go..."
cd go
time go run main.go ../input > ../output/go.txt
cd ..

echo "⚙️ Benchmarking Zig..."
cd zig
time zig run src/main.zig -- ../input > ../output/zig.txt
cd ..

echo "✅ Benchmark complete! See output/*.txt"
