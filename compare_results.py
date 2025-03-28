#!/usr/bin/env python3

import json
import sys
from pathlib import Path
from typing import Dict, List, Set

def load_json(file_path: str) -> List[Dict]:
    with open(file_path, 'r') as f:
        return json.load(f)

def normalize_stats(stats: List[Dict]) -> Dict[str, Dict]:
    """Normalizza le statistiche usando il nome del file come chiave"""
    return {stat['file']: stat for stat in stats}

def compare_stats(stats1: Dict[str, Dict], stats2: Dict[str, Dict], name1: str, name2: str):
    """Confronta le statistiche tra due implementazioni"""
    all_files = set(stats1.keys()) | set(stats2.keys())
    print(f"\nComparison between {name1} and {name2}:")
    print("=" * 50)
    
    for file in sorted(all_files):
        if file not in stats1:
            print(f"❌ {file} missing in {name1}")
            continue
        if file not in stats2:
            print(f"❌ {file} missing in {name2}")
            continue
            
        s1 = stats1[file]
        s2 = stats2[file]
        
        differences = []
        
        # Confronta ogni campo
        for field in ['words', 'headings', 'links', 'reading_time_min']:
            if s1[field] != s2[field]:
                differences.append(f"{field}: {s1[field]} vs {s2[field]}")
        
        # Confronta il punteggio di leggibilità con una tolleranza
        if abs(s1['readability_score'] - s2['readability_score']) > 0.1:
            differences.append(f"readability_score: {s1['readability_score']:.2f} vs {s2['readability_score']:.2f}")
        
        if differences:
            print(f"\n📄 {file}")
            for diff in differences:
                print(f"  • {diff}")
        else:
            print(f"\n📄 {file} - No difference detected.")

def main():
    output_dir = Path("output")
    
    # Carica i risultati
    try:
        rust_stats = load_json(output_dir / "stats-rust.json")
        zig_stats = load_json(output_dir / "stats-zig.json")
        go_stats = load_json(output_dir / "stats-go.json")
    except FileNotFoundError as e:
        print(f"❌ Error: {e}")
        print("Make sure all JSON files are present in the output/ directory")
        sys.exit(1)
    
    # Normalizza i risultati
    rust_norm = normalize_stats(rust_stats)
    zig_norm = normalize_stats(zig_stats)
    go_norm = normalize_stats(go_stats)
    
    # Esegui i confronti
    compare_stats(rust_norm, zig_norm, "Rust", "Zig")
    compare_stats(rust_norm, go_norm, "Rust", "Go")
    compare_stats(zig_norm, go_norm, "Zig", "Go")

if __name__ == "__main__":
    main() 