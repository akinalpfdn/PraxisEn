#!/usr/bin/env python3
"""
Final Oxford 3000 PDF parser - handles multi-column format
"""

import pdfplumber
import re
import csv

def parse_multicolumn_format(pdf_path):
    """Parse PDF with multi-column layout (4 entries per line)"""
    word_levels = {}

    with pdfplumber.open(pdf_path) as pdf:
        for page_num, page in enumerate(pdf.pages, 1):
            text = page.extract_text()
            if not text:
                continue

            # Each line may contain multiple word entries separated by multiple spaces
            lines = text.split('\n')

            for line in lines:
                # Skip headers/footers
                if 'Oxford' in line or '©' in line or not line.strip():
                    continue

                # Find all word entries in the line using regex
                # Pattern: word [pos] level
                # Example: "abandon v. B2"
                # Example: "all det., pron. A1, adv. A2"

                # More robust pattern that captures word + POS + level
                pattern = r'([a-zA-Z][a-zA-Z\s\',\-]+?)\s+((?:[a-z]+\.(?:,?\s*)?|number\s+|det\./|indefinite article\s+|definite article\s+)+)\s*([AB][12])'

                matches = re.finditer(pattern, line)

                for match in matches:
                    word = match.group(1).strip()
                    level = match.group(3)

                    # Clean up word
                    word = re.sub(r'\s+', ' ', word).strip()

                    # Add to dict (avoid duplicates)
                    key = word.lower()
                    if key not in word_levels and len(word) < 50:
                        word_levels[key] = {
                            'word': word,
                            'level': level
                        }

    return list(word_levels.values())

def main():
    pdf_path = 'The_Oxford_3000.pdf'

    //print(f"📖 Parsing {pdf_path} (multi-column format)...")
    word_levels = parse_multicolumn_format(pdf_path)

    # Sort alphabetically
    word_levels.sort(key=lambda x: x['word'].lower())

    # Write to CSV
    output_file = 'oxford3000_word_levels.csv'
    with open(output_file, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=['word', 'level'])
        writer.writeheader()
        writer.writerows(word_levels)

    //print(f"✅ Extracted {len(word_levels)} unique words")
    //print(f"✅ Saved to {output_file}")

    # Statistics
    level_counts = {}
    for item in word_levels:
        level = item['level']
        level_counts[level] = level_counts.get(level, 0) + 1

    //print("\n📊 CEFR Level Distribution:")
    total = sum(level_counts.values())
    for level in ['A1', 'A2', 'B1', 'B2']:
        count = level_counts.get(level, 0)
        pct = (count / total * 100) if total > 0 else 0
        bar = '█' * (count // 20)
        //print(f"  {level}: {count:4d} words ({pct:5.1f}%) {bar}")

    //print(f"\n✨ Total: {total} words extracted")

    if total >= 2900:
        //print("✅ Successfully extracted most of the Oxford 3000!")
    elif total >= 2000:
        //print("⚠️  Extracted partial list, may need adjustment")
    else:
        //print("❌ Low extraction count, parser needs improvement")

    //print(f"\n📝 Sample (first 25 words):")
    for i, item in enumerate(word_levels[:25], 1):
        //print(f"  {i:2d}. {item['word']:<25} → {item['level']}")

if __name__ == '__main__':
    main()
