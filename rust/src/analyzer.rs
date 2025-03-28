use regex::Regex;
use serde::Serialize;
use std::fs;
use std::path::Path;

#[derive(Serialize)]
pub struct FileStats {
    pub file: String,
    pub words: usize,
    pub headings: usize,
    pub links: usize,
    pub reading_time_min: usize,
    pub readability_score: f64,
}

pub fn analyze_markdown_file(path: &Path) -> Option<FileStats> {
    let content = match fs::read_to_string(path) {
        Ok(content) => content,
        Err(_) => return None,
    };

    // Conteggio parole: usa lo stesso algoritmo di Go e Zig
    let word_count = content
        .split(|c: char| !(c.is_alphabetic() || c.is_numeric()))
        .filter(|word| !word.is_empty())
        .count();

    // Conteggio headings: considera solo le righe che iniziano con #
    let heading_count = content
        .lines()
        .filter(|l| l.trim_start().starts_with('#'))
        .count();

    // Conteggio link: cerca il pattern ]( come in Go e Zig
    let link_count = content.matches("](").count();

    // Tempo di lettura stimato (200 parole al minuto)
    let reading_time = (word_count + 199) / 200;

    // Calcolo leggibilità (formula semplificata come in Go e Zig)
    let sentence_count = content.matches('.').count().max(1);
    let avg_words_per_sentence = word_count as f64 / sentence_count as f64;
    let readability = 100.0 - (avg_words_per_sentence * 2.0);

    // Normalizza il punteggio tra 0 e 100
    let normalized_readability = readability.max(0.0).min(100.0);

    Some(FileStats {
        file: path.to_string_lossy().to_string(),
        words: word_count,
        headings: heading_count,
        links: link_count,
        reading_time_min: reading_time,
        readability_score: normalized_readability,
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;
    use tempfile::NamedTempFile;

    #[test]
    fn test_word_count() {
        let content = "Hello world! This is a test.";
        let temp_file = NamedTempFile::new().unwrap();
        fs::write(temp_file.path(), content).unwrap();
        let stats = analyze_markdown_file(temp_file.path()).unwrap();
        assert_eq!(stats.words, 6);
    }

    #[test]
    fn test_heading_count() {
        let content = "# Heading 1\nText\n## Heading 2\nMore text";
        let temp_file = NamedTempFile::new().unwrap();
        fs::write(temp_file.path(), content).unwrap();
        let stats = analyze_markdown_file(temp_file.path()).unwrap();
        assert_eq!(stats.headings, 2);
    }

    #[test]
    fn test_link_count() {
        let content = "This is a [link](https://example.com).";
        let temp_file = NamedTempFile::new().unwrap();
        fs::write(temp_file.path(), content).unwrap();
        let stats = analyze_markdown_file(temp_file.path()).unwrap();
        assert_eq!(stats.links, 1);
    }

    #[test]
    fn test_reading_time_estimate() {
        let content = "word ".repeat(400); // 400 parole → 2 min
        let temp_file = NamedTempFile::new().unwrap();
        fs::write(temp_file.path(), &content).unwrap();
        let stats = analyze_markdown_file(temp_file.path()).unwrap();
        assert_eq!(stats.reading_time_min, 2);
    }

    #[test]
    fn test_readability_score_bounds() {
        let content = "This is a test. It is only a test. This text is simple.";
        let temp_file = NamedTempFile::new().unwrap();
        fs::write(temp_file.path(), content).unwrap();
        let stats = analyze_markdown_file(temp_file.path()).unwrap();
        assert!(stats.readability_score >= 0.0 && stats.readability_score <= 100.0);
    }
}
