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

    // Conteggio parole: ignora la punteggiatura e conta solo le parole effettive
    let word_count = content
        .split_whitespace()
        .filter(|word| word.chars().any(|c| c.is_alphabetic()))
        .count();

    // Conteggio headings: considera solo le righe che iniziano con #
    let heading_count = content
        .lines()
        .filter(|l| l.trim_start().starts_with('#'))
        .count();

    // Conteggio link: regex migliorata per catturare i link markdown
    let link_re = Regex::new(r"\[([^\]]+)\]\(([^)]+)\)").unwrap();
    let link_count = link_re.find_iter(&content).count();

    // Tempo di lettura stimato (200 parole al minuto)
    let reading_time = (word_count as f64 / 200.0).ceil() as usize;

    // Calcolo leggibilità (Flesch Reading Ease)
    let sentence_count = content
        .matches(|c| c == '.' || c == '!' || c == '?')
        .count()
        .max(1);

    // Stima più accurata delle sillabe (approssimativa)
    let syllable_estimate = word_count as f64 * 1.3; // media di 1.3 sillabe per parola

    let readability = 206.835
        - (1.015 * (word_count as f64 / sentence_count as f64))
        - (84.6 * (syllable_estimate / word_count as f64));

    // Normalizza il punteggio tra 0 e 100
    let normalized_readability = readability.max(0.0).min(100.0);

    Some(FileStats {
        file: path.to_string_lossy().to_string(),
        words: word_count,
        headings: heading_count,
        links: link_count,
        reading_time_min: reading_time,
        readability_score: (normalized_readability * 10.0).round() / 10.0,
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
