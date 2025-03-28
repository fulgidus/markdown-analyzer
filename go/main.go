package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
	"unicode"
)

type Stats struct {
	File            string  `json:"file"`
	Words           int     `json:"words"`
	Headings        int     `json:"headings"`
	Links           int     `json:"links"`
	ReadingTimeMin  int     `json:"reading_time_min"`
	ReadabilityScore float64 `json:"readability_score"`
}

func processDirectory(path string) ([]Stats, error) {
	var stats []Stats

	// Verifica se il percorso è un file o una directory
	info, err := os.Stat(path)
	if err != nil {
		return nil, err
	}

	if info.IsDir() {
		// Processa tutti i file .md nella directory
		err = filepath.Walk(path, func(filePath string, info os.FileInfo, err error) error {
			if err != nil {
				return err
			}
			if !info.IsDir() && strings.HasSuffix(filePath, ".md") {
				stat, err := processFile(filePath)
				if err != nil {
					fmt.Printf("Errore nel processare %s: %v\n", filePath, err)
					return nil
				}
				stats = append(stats, stat)
			}
			return nil
		})
	} else if strings.HasSuffix(path, ".md") {
		// Processa un singolo file
		stat, err := processFile(path)
		if err != nil {
			return nil, err
		}
		stats = append(stats, stat)
	} else {
		return nil, fmt.Errorf("il file %s non è un file markdown", path)
	}

	return stats, nil
}

func processFile(filePath string) (Stats, error) {
	content, err := ioutil.ReadFile(filePath)
	if err != nil {
		return Stats{}, err
	}

	text := string(content)
	lines := strings.Split(text, "\n")

	// Calcola le statistiche
	words := countWords(text)
	headings := countHeadings(lines)
	links := countLinks(text)
	readingTime := calculateReadingTime(words)
	readabilityScore := calculateReadabilityScore(text)

	return Stats{
		File:            filePath,
		Words:           words,
		Headings:        headings,
		Links:           links,
		ReadingTimeMin:  readingTime,
		ReadabilityScore: readabilityScore,
	}, nil
}

func countWords(text string) int {
	words := strings.FieldsFunc(text, func(r rune) bool {
		return !unicode.IsLetter(r) && !unicode.IsNumber(r)
	})
	return len(words)
}

func countHeadings(lines []string) int {
	count := 0
	for _, line := range lines {
		if strings.HasPrefix(strings.TrimSpace(line), "#") {
			count++
		}
	}
	return count
}

func countLinks(text string) int {
	count := 0
	for _, line := range strings.Split(text, "\n") {
		count += strings.Count(line, "](")
	}
	return count
}

func calculateReadingTime(words int) int {
	// Assumiamo una velocità di lettura media di 200 parole al minuto
	return (words + 199) / 200
}

func calculateReadabilityScore(text string) float64 {
	// Implementazione semplificata del punteggio di leggibilità
	// Basata sul numero medio di parole per frase
	sentences := strings.Split(text, ".")
	words := countWords(text)
	if len(sentences) == 0 {
		return 0
	}
	avgWordsPerSentence := float64(words) / float64(len(sentences))
	return 100 - (avgWordsPerSentence * 2)
}

func main() {
	inputPath := flag.String("input", ".", "Path to markdown file or directory")
	flag.Parse()

	stats, err := processDirectory(*inputPath)
	if err != nil {
		fmt.Printf("Errore durante l'analisi: %v\n", err)
		os.Exit(1)
	}

	// Stampa il riepilogo nel terminale
	for _, stat := range stats {
		fmt.Printf("File: %s\n", stat.File)
		fmt.Println("────────────────────────────")
		fmt.Printf("• Words:           %d\n", stat.Words)
		fmt.Printf("• Headings:        %d\n", stat.Headings)
		fmt.Printf("• Links:           %d\n", stat.Links)
		fmt.Printf("• Reading Time:    %d min\n", stat.ReadingTimeMin)
		fmt.Printf("• Readability Score: %.1f\n", stat.ReadabilityScore)
		fmt.Println("────────────────────────────")
	}

	// Salva i risultati in JSON
	jsonData, err := json.MarshalIndent(stats, "", "  ")
	if err != nil {
		fmt.Printf("Errore durante la generazione del JSON: %v\n", err)
		os.Exit(1)
	}

	// Crea la directory di output se non esiste
	os.MkdirAll("../output", 0755)

	err = ioutil.WriteFile("../output/stats-go.json", jsonData, 0644)
	if err != nil {
		fmt.Printf("Errore durante il salvataggio del file JSON: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("Risultati salvati in: ../output/stats-go.json")
} 