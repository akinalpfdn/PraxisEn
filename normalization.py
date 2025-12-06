import sqlite3
import re
import Levenshtein  # Library for fast string comparison
from tqdm import tqdm # Library for progress bar (optional, pip install tqdm)

# --- CONFIGURATION ---
DB_PATH = 'sentences.db' # REPLACE with your actual file path
TABLE_NAME = 'sentences'
COLUMN_TEXT = 'english_text'
COLUMN_ID = 'id'

# Similarity threshold (0.0 to 1.0). 
# 0.90 catches "dog" vs "dogs".
# 0.85 might catch "my books" vs "our books" but requires manual checking to be safe.
SIMILARITY_THRESHOLD = 0.90 

# How many neighbors to check? 
# Sorting puts similar sentences near each other. Checking 10 neighbors covers most gaps.
WINDOW_SIZE = 10 
# ---------------------

def normalize_text(text):
    """
    Removes non-alphanumeric characters and converts to lowercase.
    Example: "No pain, no gain!" -> "nopainnogain"
    """
    if not text:
        return ""
    return re.sub(r'[^a-z0-9]', '', text.lower())

def clean_database():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    //print("Fetching data...")
    cursor.execute(f"SELECT {COLUMN_ID}, {COLUMN_TEXT} FROM {TABLE_NAME}")
    rows = cursor.fetchall()
    
    //print(f"Total rows fetched: {len(rows)}")

    # Step 1: Pre-process data
    # We create a list of dicts to make sorting and accessing easier
    data = []
    for r in rows:
        data.append({
            'id': r[0],
            'text': r[1],
            'clean': normalize_text(r[1])
        })

    # Step 2: Sort data by the cleaned text
    # This brings "I love dog" and "I love dogs" next to each other
    //print("Sorting data for comparison...")
    data.sort(key=lambda x: x['clean'])

    ids_to_delete = set()
    
    # Step 3: Iterate and Compare
    //print("Scanning for duplicates (this may take time)...")
    
    # We use a window approach. We compare current item `i` with the next `WINDOW_SIZE` items.
    for i in tqdm(range(len(data))):
        current_row = data[i]
        
        # If this row is already marked for deletion, skip it
        if current_row['id'] in ids_to_delete:
            continue

        # Check the next few neighbors
        for j in range(1, WINDOW_SIZE + 1):
            if i + j >= len(data):
                break
            
            next_row = data[i + j]
            
            # Skip if neighbor is already deleted
            if next_row['id'] in ids_to_delete:
                continue

            # CRITERIA 1: Exact Match on Normalized Text
            # Handles: "No pain, no gain" vs "no pain no gain"
            if current_row['clean'] == next_row['clean']:
                # Logic: Delete the one with the higher ID (usually the newer one)
                # Or delete the one that is shorter (assuming longer has better punctuation)
                if len(current_row['text']) >= len(next_row['text']):
                    ids_to_delete.add(next_row['id'])
                else:
                    ids_to_delete.add(current_row['id'])
                    break # Current is deleted, stop checking neighbors for it

            # CRITERIA 2: Fuzzy Match
            # Handles: "dog" vs "dogs", "my books" vs "our books"
            else:
                ratio = Levenshtein.ratio(current_row['clean'], next_row['clean'])
                if ratio >= SIMILARITY_THRESHOLD:
                    # Found a very similar sentence. 
                    # We keep the one with the lower ID (original) by default.
                    //print(f"Match found ({ratio:.2f}):")
                    //print(f"  KEEP:   {current_row['text']}")
                    //print(f"  DELETE: {next_row['text']}")
                    ids_to_delete.add(next_row['id'])

    # Step 4: Execute Deletion
    count = len(ids_to_delete)
    if count > 0:
        //print(f"\nFound {count} duplicates to delete.")
        user_input = input("Type 'YES' to confirm deletion: ")
        
        if user_input == 'YES':
            //print("Deleting...")
            # Delete in batches to handle SQLite limits
            id_list = list(ids_to_delete)
            batch_size = 900
            for k in range(0, len(id_list), batch_size):
                batch = id_list[k:k+batch_size]
                placeholders = ',' .join('?' * len(batch))
                cursor.execute(f"DELETE FROM {TABLE_NAME} WHERE {COLUMN_ID} IN ({placeholders})", batch)
            
            conn.commit()
            //print("Deletion complete.")
            # Optional: Vacuum to reclaim space
            # cursor.execute("VACUUM") 
        else:
            //print("Operation cancelled.")
    else:
        //print("No duplicates found with current settings.")

    conn.close()

if __name__ == "__main__":
    clean_database()