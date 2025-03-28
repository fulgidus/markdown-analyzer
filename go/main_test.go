package main

import (
	"math"
	"testing"
)

// floatEquals verifica se due float64 sono uguali entro una certa tolleranza
func floatEquals(a, b float64) bool {
	const epsilon = 0.000001
	return math.Abs(a-b) < epsilon
}

func TestCountWords(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected int
	}{
		{
			name:     "Testo vuoto",
			input:    "",
			expected: 0,
		},
		{
			name:     "Testo con una parola",
			input:    "ciao",
			expected: 1,
		},
		{
			name:     "Testo con più parole",
			input:    "ciao mondo",
			expected: 2,
		},
		{
			name:     "Testo con spazi multipli",
			input:    "ciao   mondo",
			expected: 2,
		},
		{
			name:     "Testo con caratteri speciali",
			input:    "ciao, mondo!",
			expected: 2,
		},
		{
			name:     "Testo con numeri",
			input:    "ciao 123 mondo",
			expected: 3,
		},
		{
			name:     "Testo con newline",
			input:    "ciao\nmondo",
			expected: 2,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := countWords(tt.input)
			if result != tt.expected {
				t.Errorf("countWords(%q) = %d; want %d", tt.input, result, tt.expected)
			}
		})
	}
}

func TestCountHeadings(t *testing.T) {
	tests := []struct {
		name     string
		input    []string
		expected int
	}{
		{
			name:     "Nessun heading",
			input:    []string{"testo normale"},
			expected: 0,
		},
		{
			name:     "Un heading",
			input:    []string{"# Titolo", "Testo"},
			expected: 1,
		},
		{
			name:     "Più heading",
			input:    []string{"# Titolo 1", "## Titolo 2", "### Titolo 3"},
			expected: 3,
		},
		{
			name:     "Heading con spazi",
			input:    []string{"  #  Titolo  "},
			expected: 1,
		},
		{
			name:     "Heading non valido",
			input:    []string{"testo # non è un heading"},
			expected: 0,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := countHeadings(tt.input)
			if result != tt.expected {
				t.Errorf("countHeadings(%v) = %d; want %d", tt.input, result, tt.expected)
			}
		})
	}
}

func TestCountLinks(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected int
	}{
		{
			name:     "Nessun link",
			input:    "testo normale",
			expected: 0,
		},
		{
			name:     "Un link",
			input:    "[Link](http://example.com)",
			expected: 1,
		},
		{
			name:     "Più link",
			input:    "[Link1](http://example.com) [Link2](http://example.org)",
			expected: 2,
		},
		{
			name:     "Link non valido",
			input:    "testo [ non è un link",
			expected: 0,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := countLinks(tt.input)
			if result != tt.expected {
				t.Errorf("countLinks(%q) = %d; want %d", tt.input, result, tt.expected)
			}
		})
	}
}

func TestCalculateReadabilityScore(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected float64
	}{
		{
			name:     "Testo vuoto",
			input:    "",
			expected: 100,
		},
		{
			name:     "Testo semplice",
			input:    "Questa è una frase. Questa è un'altra frase.",
			expected: 94,
		},
		{
			name:     "Testo complesso",
			input:    "Questa è una frase molto lunga con molte parole che dovrebbe abbassare il punteggio di leggibilità. Questa è un'altra frase lunga.",
			expected: 85.333333,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := calculateReadabilityScore(tt.input)
			if !floatEquals(result, tt.expected) {
				t.Errorf("calculateReadabilityScore(%q) = %f; want %f", tt.input, result, tt.expected)
			}
		})
	}
} 