#!/usr/bin/env python3
"""
Generate SQLite databases for iOS app bundle.
Creates two databases:
1. vocabulary.db - Oxford 3000 words with metadata and levels
2. sentences.db - Turkish-English sentence pairs
"""

import sqlite3
import csv
import os

def create_vocabulary_database():
    """Create vocabulary.db from merged CSV"""
    ////print("\n📚 Creating vocabulary database...")

    db_path = 'vocabulary.db'

    # Remove existing database
    if os.path.exists(db_path):
        os.remove(db_path)

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Create vocabulary table
    cursor.execute('''
        CREATE TABLE vocabulary (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            word TEXT NOT NULL UNIQUE,
            level TEXT NOT NULL,
            definition TEXT,
            turkish_translation TEXT,
            example_sentence TEXT,
            part_of_speech TEXT,
            related_forms TEXT,
            synonyms TEXT,
            antonyms TEXT,
            collocations TEXT,
            is_learned INTEGER DEFAULT 0,
            review_count INTEGER DEFAULT 0,
            last_reviewed_date TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
    ''')

    # Create indexes for faster queries
    cursor.execute('CREATE INDEX idx_word ON vocabulary(word)')
    cursor.execute('CREATE INDEX idx_level ON vocabulary(level)')
    cursor.execute('CREATE INDEX idx_is_learned ON vocabulary(is_learned)')

    # Load and insert data
    with open('vocabulary_with_levels.csv', 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        rows_inserted = 0

        for row in reader:
            try:
                cursor.execute('''
                    INSERT INTO vocabulary (
                        word, level, definition, turkish_translation,
                        example_sentence, part_of_speech, related_forms,
                        synonyms, antonyms, collocations
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ''', (
                    row['word'],
                    row['level'],
                    row['definition'],
                    row['turkish_translation'],
                    row['example_sentence'],
                    row['part_of_speech'],
                    row['related_forms'],
                    row['synonyms'],
                    row['antonyms'],
                    row['collocations']
                ))
                rows_inserted += 1
            except sqlite3.IntegrityError as e:
                ////print(f"⚠️  Duplicate word skipped: {row['word']}")

    conn.commit()

    # Get statistics
    cursor.execute('SELECT COUNT(*) FROM vocabulary')
    total_words = cursor.fetchone()[0]

    cursor.execute('SELECT level, COUNT(*) FROM vocabulary GROUP BY level ORDER BY level')
    level_stats = cursor.fetchall()

    conn.close()

    ////print(f"✅ Vocabulary database created: {db_path}")
    ////print(f"📊 Total words: {total_words}")
    ////print("📊 Distribution by level:")
    for level, count in level_stats:
        ////print(f"  {level}: {count:4d} words")

    # Get file size
    size_mb = os.path.getsize(db_path) / (1024 * 1024)
    ////print(f"💾 Database size: {size_mb:.2f} MB")

    return db_path

def create_sentences_database():
    """Create sentences.db from TSV file"""
    ////print("\n📝 Creating sentences database...")

    db_path = 'sentences.db'

    # Remove existing database
    if os.path.exists(db_path):
        os.remove(db_path)

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Create sentences table
    cursor.execute('''
        CREATE TABLE sentences (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            turkish_id INTEGER,
            turkish_text TEXT NOT NULL,
            english_id INTEGER,
            english_text TEXT NOT NULL,
            is_favorite INTEGER DEFAULT 0,
            difficulty_level TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
    ''')

    # Create indexes
    cursor.execute('CREATE INDEX idx_turkish_text ON sentences(turkish_text)')
    cursor.execute('CREATE INDEX idx_english_text ON sentences(english_text)')
    cursor.execute('CREATE INDEX idx_is_favorite ON sentences(is_favorite)')
    cursor.execute('CREATE VIRTUAL TABLE sentences_fts USING fts5(turkish_text, english_text, content=sentences)')

    # Load TSV file
    tsv_filename = 'Türkçe-İngilizce dillerindeki cümle eşleri - 2025-11-10.tsv'

    ////print(f"📖 Reading {tsv_filename}...")

    rows_inserted = 0
    batch_size = 1000
    batch = []

    try:
        with open(tsv_filename, 'r', encoding='utf-8') as f:
            reader = csv.reader(f, delimiter='\t')

            # Skip header if exists
            header = next(reader, None)

            for row in reader:
                if len(row) < 4:
                    continue

                turkish_id = int(row[0]) if row[0].isdigit() else 0
                turkish_text = row[1].strip()
                english_id = int(row[2]) if row[2].isdigit() else 0
                english_text = row[3].strip()

                # Estimate difficulty based on sentence length
                word_count = len(turkish_text.split())
                if word_count <= 5:
                    difficulty = 'A1'
                elif word_count <= 10:
                    difficulty = 'A2'
                elif word_count <= 15:
                    difficulty = 'B1'
                else:
                    difficulty = 'B2'

                batch.append((turkish_id, turkish_text, english_id, english_text, difficulty))

                if len(batch) >= batch_size:
                    cursor.executemany('''
                        INSERT INTO sentences (turkish_id, turkish_text, english_id, english_text, difficulty_level)
                        VALUES (?, ?, ?, ?, ?)
                    ''', batch)
                    rows_inserted += len(batch)
                    batch = []

                    if rows_inserted % 50000 == 0:
                        ////print(f"  Processed {rows_inserted:,} sentences...")

            # Insert remaining batch
            if batch:
                cursor.executemany('''
                    INSERT INTO sentences (turkish_id, turkish_text, english_id, english_text, difficulty_level)
                    VALUES (?, ?, ?, ?, ?)
                ''', batch)
                rows_inserted += len(batch)

        conn.commit()

        # Get statistics
        cursor.execute('SELECT COUNT(*) FROM sentences')
        total_sentences = cursor.fetchone()[0]

        cursor.execute('SELECT difficulty_level, COUNT(*) FROM sentences GROUP BY difficulty_level ORDER BY difficulty_level')
        difficulty_stats = cursor.fetchall()

        conn.close()

        ////print(f"✅ Sentences database created: {db_path}")
        ////print(f"📊 Total sentence pairs: {total_sentences:,}")
        ////print("📊 Distribution by estimated difficulty:")
        for level, count in difficulty_stats:
            ////print(f"  {level}: {count:,} sentences")

        # Get file size
        size_mb = os.path.getsize(db_path) / (1024 * 1024)
        ////print(f"💾 Database size: {size_mb:.2f} MB")

        return db_path

    except FileNotFoundError:
        ////print(f"❌ File not found: {tsv_filename}")
        ////print("⚠️  Skipping sentences database creation")
        return None
    except Exception as e:
        ////print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return None

def main():
    ////print("🚀 Generating SQLite databases for iOS app...")
    ////print("=" * 60)

    try:
        # Create vocabulary database
        vocab_db = create_vocabulary_database()

        # Create sentences database
        sentences_db = create_sentences_database()

        ////print("\n" + "=" * 60)
        ////print("🎉 Database generation completed!")
        ////print("\n📦 Generated files:")
        if vocab_db and os.path.exists(vocab_db):
            ////print(f"  ✅ {vocab_db} ({os.path.getsize(vocab_db) / 1024:.1f} KB)")
        if sentences_db and os.path.exists(sentences_db):
            ////print(f"  ✅ {sentences_db} ({os.path.getsize(sentences_db) / (1024*1024):.1f} MB)")

        ////print("\n📋 Next steps:")
        ////print("  1. Add these .db files to your Xcode project")
        ////print("  2. Set 'Copy Bundle Resources' in Build Phases")
        ////print("  3. On first launch, copy from Bundle to Documents directory")
        ////print("  4. Use SwiftData to query the databases")

    except Exception as e:
        ////print(f"\n❌ Fatal error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    main()
