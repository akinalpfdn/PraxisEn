#!/usr/bin/env python3
"""
Parse Oxford 3000 PDF to extract ALL words and their CEFR levels.
Uses pdfplumber to read the actual PDF file.
"""

import pdfplumber
import re
import csv

def parse_pdf_with_pdfplumber(pdf_path):
    """Extract all words and levels from the PDF using pdfplumber"""
    word_levels = {}

    with pdfplumber.open(pdf_path) as pdf:
        for page_num, page in enumerate(pdf.pages, 1):
            text = page.extract_text()
            if not text:
                continue

            # Process each line
            for line in text.split('\n'):
                line = line.strip()
                if not line or line.startswith('©') or 'Oxford' in line:
                    continue

                # Match pattern: word [part_of_speech] level
                # Examples:
                #   "abandon v. B2"
                #   "all det., pron. A1, adv. A2"
                #   "all right adj./adv., exclam. A2"

                # Extract all CEFR levels from the line
                levels = re.findall(r'[AB][12]', line)
                if not levels:
                    continue

                # Extract the word (everything before the first part of speech indicator)
                word_match = re.match(r'^([a-zA-Z\s\'\-]+?)(?:\s+[a-z]+\.)', line)
                if word_match:
                    word = word_match.group(1).strip()

                    # Take the first (most common/basic) level
                    level = levels[0]

                    # Store in dict to avoid duplicates (keep first occurrence)
                    if word.lower() not in word_levels:
                        word_levels[word.lower()] = {
                            'word': word,
                            'level': level
                        }

    return list(word_levels.values())

def main():
    pdf_path = 'The_Oxford_3000.pdf'

    //print(f"📖 Reading PDF: {pdf_path}")
    word_levels = parse_pdf_with_pdfplumber(pdf_path)

    # Sort by word alphabetically
    word_levels.sort(key=lambda x: x['word'].lower())

    # Write to CSV
    output_file = 'oxford3000_word_levels.csv'
    with open(output_file, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=['word', 'level'])
        writer.writeheader()
        writer.writerows(word_levels)

    //print(f"✅ Extracted {len(word_levels)} words with CEFR levels")
    //print(f"✅ Saved to {output_file}")

    # Show statistics
    level_counts = {}
    for item in word_levels:
        level = item['level']
        level_counts[level] = level_counts.get(level, 0) + 1

    //print("\n📊 Distribution by level:")
    for level in ['A1', 'A2', 'B1', 'B2']:
        count = level_counts.get(level, 0)
        //print(f"  {level}: {count:4d} words")

    //print("\n📝 Sample entries:")
    for item in word_levels[:15]:
        //print(f"  {item['word']:<20} → {item['level']}")

if __name__ == '__main__':
    main()
