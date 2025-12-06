#!/usr/bin/env python3
"""
Quick test script to verify database integrity and contents
"""

import sqlite3
import os

def test_vocabulary_db():
    """Test vocabulary database"""
    ////print("\n📚 Testing vocabulary.db...")

    if not os.path.exists('vocabulary.db'):
        ////print("❌ vocabulary.db not found!")
        return False

    conn = sqlite3.connect('vocabulary.db')
    cursor = conn.cursor()

    # Count total words
    cursor.execute('SELECT COUNT(*) FROM vocabulary')
    total = cursor.fetchone()[0]
    ////print(f"✅ Total words: {total:,}")

    # Count by level
    cursor.execute('SELECT level, COUNT(*) FROM vocabulary GROUP BY level ORDER BY level')
    levels = cursor.fetchall()
    ////print("✅ Distribution by level:")
    for level, count in levels:
        ////print(f"   {level}: {count:,} words")

    # Sample words
    cursor.execute('SELECT word, level, turkish_translation FROM vocabulary LIMIT 5')
    samples = cursor.fetchall()
    ////print("✅ Sample words:")
    for word, level, translation in samples:
        ////print(f"   {word:<15} ({level}) → {translation}")

    # Test search
    cursor.execute("SELECT COUNT(*) FROM vocabulary WHERE word LIKE '%learn%'")
    search_count = cursor.fetchone()[0]
    ////print(f"✅ Words containing 'learn': {search_count}")

    conn.close()
    return True

def test_sentences_db():
    """Test sentences database"""
    ////print("\n📝 Testing sentences.db...")

    if not os.path.exists('sentences.db'):
        ////print("❌ sentences.db not found!")
        return False

    conn = sqlite3.connect('sentences.db')
    cursor = conn.cursor()

    # Count total sentences
    cursor.execute('SELECT COUNT(*) FROM sentences')
    total = cursor.fetchone()[0]
    ////print(f"✅ Total sentence pairs: {total:,}")

    # Count by difficulty
    cursor.execute('SELECT difficulty_level, COUNT(*) FROM sentences GROUP BY difficulty_level ORDER BY difficulty_level')
    levels = cursor.fetchall()
    ////print("✅ Distribution by difficulty:")
    for level, count in levels:
        ////print(f"   {level}: {count:,} sentences")

    # Sample sentences
    cursor.execute('SELECT turkish_text, english_text, difficulty_level FROM sentences LIMIT 5')
    samples = cursor.fetchall()
    ////print("✅ Sample sentence pairs:")
    for tr, en, level in samples:
        ////print(f"   [{level}] TR: {tr[:50]}...")
        ////print(f"       EN: {en[:50]}...")

    # Test search
    cursor.execute("SELECT COUNT(*) FROM sentences WHERE turkish_text LIKE '%merhaba%' OR english_text LIKE '%hello%'")
    search_count = cursor.fetchone()[0]
    ////print(f"✅ Sentences with 'merhaba/hello': {search_count:,}")

    # Random sentence
    cursor.execute('SELECT turkish_text, english_text FROM sentences ORDER BY RANDOM() LIMIT 1')
    tr, en = cursor.fetchone()
    ////print("✅ Random sentence:")
    ////print(f"   TR: {tr}")
    ////print(f"   EN: {en}")

    conn.close()
    return True

def test_file_sizes():
    """Check file sizes"""
    ////print("\n💾 File Sizes:")

    files = ['vocabulary.db', 'sentences.db']
    for filename in files:
        if os.path.exists(filename):
            size_mb = os.path.getsize(filename) / (1024 * 1024)
            ////print(f"✅ {filename}: {size_mb:.2f} MB")
        else:
            ////print(f"❌ {filename}: Not found")

def main():
    ////print("=" * 60)
    ////print("🧪 PraxisEn Database Test Suite")
    ////print("=" * 60)

    vocab_ok = test_vocabulary_db()
    sentences_ok = test_sentences_db()
    test_file_sizes()

    ////print("\n" + "=" * 60)
    if vocab_ok and sentences_ok:
        ////print("✅ All tests passed! Databases are ready for iOS app.")
    else:
        ////print("❌ Some tests failed. Check the output above.")
    ////print("=" * 60)

    ////print("\n📋 Next Steps:")
    ////print("1. Add vocabulary.db and sentences.db to Xcode project")
    ////print("2. Add Swift model files (VocabularyWord.swift, SentencePair.swift)")
    ////print("3. Add DatabaseManager.swift")
    ////print("4. Run your app - databases will auto-setup on first launch!")

if __name__ == '__main__':
    main()
