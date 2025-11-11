#!/usr/bin/env python3
"""
Comprehensive Oxford 3000 PDF parser - extracts ALL 3000+ words
"""

import pdfplumber
import re
import csv

def parse_comprehensive(pdf_path):
    """Extract all words with improved regex patterns"""
    word_levels = {}

    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            text = page.extract_text()
            if not text:
                continue

            # Split into lines
            lines = text.split('\n')

            for line in lines:
                line = line.strip()

                # Skip headers/footers
                if not line or 'Oxford' in line or '©' in line or line.startswith('The Oxford') or '/' in line[:20]:
                    continue

                # Find all CEFR level mentions (A1, A2, B1, B2)
                if not re.search(r'[AB][12]', line):
                    continue

                # Pattern 1: Standard format "word pos. level"
                # Pattern 2: Multi-part speech "word pos., pos. level"
                # Pattern 3: Compound words "compound word pos. level"

                # Extract: everything before the level indicators
                # Find the first occurrence of part-of-speech indicators
                pos_pattern = r'\s+((?:[a-z]+\.|number|det\.|pron\.|prep\.|adv\.|conj\.|exclam\.|auxiliary v\.|modal v\.|indefinite article|definite article)[,\s/]*)+\s*([AB][12])'

                match = re.search(pos_pattern, line)
                if match:
                    # Everything before the POS is the word
                    word_part = line[:match.start()].strip()

                    # Get the level (first occurrence)
                    levels = re.findall(r'[AB][12]', line)
                    if levels:
                        level = levels[0]

                        # Clean word
                        word_part = re.sub(r'\s+', ' ', word_part)

                        if word_part and len(word_part) < 50:  # Sanity check
                            key = word_part.lower()
                            if key not in word_levels:
                                word_levels[key] = {
                                    'word': word_part,
                                    'level': level
                                }

    return list(word_levels.values())

def main():
    pdf_path = 'The_Oxford_3000.pdf'

    print(f"📖 Parsing {pdf_path} comprehensively...")
    word_levels = parse_comprehensive(pdf_path)

    # Sort alphabetically
    word_levels.sort(key=lambda x: x['word'].lower())

    # Write to CSV
    output_file = 'oxford3000_word_levels.csv'
    with open(output_file, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=['word', 'level'])
        writer.writeheader()
        writer.writerows(word_levels)

    print(f"✅ Extracted {len(word_levels)} unique words")
    print(f"✅ Saved to {output_file}")

    # Statistics
    level_counts = {}
    for item in word_levels:
        level = item['level']
        level_counts[level] = level_counts.get(level, 0) + 1

    print("\n📊 Level distribution:")
    total = sum(level_counts.values())
    for level in ['A1', 'A2', 'B1', 'B2']:
        count = level_counts.get(level, 0)
        pct = (count / total * 100) if total > 0 else 0
        print(f"  {level}: {count:4d} words ({pct:5.1f}%)")

    print(f"\n📝 First 20 words:")
    for item in word_levels[:20]:
        print(f"  {item['word']:<25} → {item['level']}")

if __name__ == '__main__':
    main()
