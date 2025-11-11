#!/usr/bin/env python3
"""
Merge Oxford 3000 vocabulary CSV with word levels CSV.
Creates a comprehensive vocabulary database with levels.
"""

import csv
import pandas as pd

def load_csv_with_encoding(filepath):
    """Try different encodings to load CSV"""
    encodings = ['utf-8', 'utf-8-sig', 'latin-1', 'iso-8859-1', 'cp1252']

    for encoding in encodings:
        try:
            df = pd.read_csv(filepath, encoding=encoding)
            print(f"✅ Loaded {filepath} with {encoding} encoding")
            return df
        except UnicodeDecodeError:
            continue
        except Exception as e:
            print(f"❌ Error with {encoding}: {e}")
            continue

    raise ValueError(f"Could not load {filepath} with any encoding")

def merge_vocabulary_data():
    """Merge vocabulary CSV with word levels"""

    print("📚 Loading vocabulary dataset...")
    vocab_df = load_csv_with_encoding('oxford3000_vocabulary_with_collocations_and_definitions_datasets.csv')

    print("📊 Loading word levels...")
    levels_df = load_csv_with_encoding('oxford3000_word_levels.csv')

    print(f"\n📈 Initial counts:")
    print(f"  Vocabulary entries: {len(vocab_df)}")
    print(f"  Word levels: {len(levels_df)}")

    # Normalize word columns for matching
    vocab_df['word_normalized'] = vocab_df['Word'].str.lower().str.strip()
    levels_df['word_normalized'] = levels_df['word'].str.lower().str.strip()

    # Merge on normalized word
    merged_df = vocab_df.merge(
        levels_df[['word_normalized', 'level']],
        on='word_normalized',
        how='left'
    )

    # Drop the normalized column
    merged_df = merged_df.drop('word_normalized', axis=1)

    # Rename columns to be more Swift-friendly
    merged_df = merged_df.rename(columns={
        'Word': 'word',
        'Definition': 'definition',
        'Turkish Translation': 'turkish_translation',
        'Example Sentence': 'example_sentence',
        'Part of Speech': 'part_of_speech',
        'Related Forms': 'related_forms',
        'Synonyms': 'synonyms',
        'Antonyms': 'antonyms',
        'Collocations': 'collocations'
    })

    # Fill missing levels with 'Unknown'
    merged_df['level'] = merged_df['level'].fillna('B2')  # Default to B2 for unknown

    # Save merged data
    output_file = 'vocabulary_with_levels.csv'
    merged_df.to_csv(output_file, index=False, encoding='utf-8')

    print(f"\n✅ Merged data saved to {output_file}")
    print(f"📊 Total vocabulary entries: {len(merged_df)}")

    # Statistics
    level_counts = merged_df['level'].value_counts().sort_index()
    print("\n📊 Level distribution in vocabulary:")
    for level in ['A1', 'A2', 'B1', 'B2', 'Unknown']:
        count = level_counts.get(level, 0)
        if count > 0:
            print(f"  {level}: {count:4d} words")

    # Check match rate
    matched = merged_df['level'].notna().sum()
    match_rate = (matched / len(merged_df)) * 100
    print(f"\n✨ Match rate: {match_rate:.1f}% ({matched}/{len(merged_df)} words matched with levels)")

    # Show sample
    print("\n📝 Sample merged data (first 10 rows):")
    print(merged_df[['word', 'level', 'part_of_speech', 'turkish_translation']].head(10).to_string(index=False))

    return merged_df

def main():
    try:
        merged_df = merge_vocabulary_data()
        print("\n🎉 Merge completed successfully!")
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    main()
