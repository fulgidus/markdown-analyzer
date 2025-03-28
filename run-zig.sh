#!/bin/bash

# Verifica che sia stato fornito un argomento
if [ $# -eq 0 ]; then
    echo "Usage: $0 <input_directory>"
    exit 1
fi

# Verifica che la directory esista
if [ ! -d "$1" ]; then
    echo "Error: Directory '$1' does not exist"
    exit 1
fi

# Esegue l'implementazione Zig
echo "Running Zig implementation..."
cd zig
zig build run -- "../$1"
cd .. 