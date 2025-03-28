#!/bin/bash

# Colori per l'output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funzione per stampare i messaggi
print_status() {
    echo -e "${YELLOW}[TEST]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Directory principale del progetto
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Crea la directory di test se non esiste
mkdir -p "$ROOT_DIR/test-files"



# Test Rust
print_status "Testing Rust version..."
cd "$ROOT_DIR/rust"
if cargo test; then
    print_success "Rust tests passed"
else
    print_error "Rust tests failed"
    exit 1
fi

# Test Zig
print_status "Testing Zig version..."
cd "$ROOT_DIR/zig"
if zig test src/main.zig; then
    print_success "Zig tests passed"
else
    print_error "Zig tests failed"
    exit 1
fi

# Test Go
print_status "Testing Go version..."
cd "$ROOT_DIR/go"
if go test ./...; then
    print_success "Go tests passed"
else
    print_error "Go tests failed"
    exit 1
fi

# Esegui l'analizzatore su tutti i file
print_status "Running analyzer on test files..."
cd "$ROOT_DIR"

# Esegui Rust
print_status "Running Rust analyzer..."
cd "$ROOT_DIR/rust"
cargo run -- -i "$ROOT_DIR/input"
if [ $? -ne 0 ]; then
    print_error "Rust analyzer failed"
    exit 1
fi

# Esegui Zig
print_status "Running Zig analyzer..."
cd "$ROOT_DIR/zig"
zig build
./zig-out/bin/markdown-analyzer -i "$ROOT_DIR/input"
if [ $? -ne 0 ]; then
    print_error "Zig analyzer failed"
    exit 1
fi

# Esegui Go
print_status "Running Go analyzer..."
cd "$ROOT_DIR/go"
go run main.go -input "$ROOT_DIR/input"
if [ $? -ne 0 ]; then
    print_error "Go analyzer failed"
    exit 1
fi

# Confronta i risultati
print_status "Comparing results..."
cd "$ROOT_DIR"
python3 compare_results.py

print_success "All tests completed successfully!" 