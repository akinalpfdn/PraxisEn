# Translation Validator Test Cases

## Test Cases for Fuzzy Matching

### Test Case 1: Exact Match
**Input:** "merhaba"
**Correct:** "merhaba"
**Expected:** Correct with confidence 1.0, feedback: .perfect

### Test Case 2: Case Insensitive Match
**Input:** "MERHABA"
**Correct:** "merhaba"
**Expected:** Correct with confidence 1.0, feedback: .perfect

### Test Case 3: Minor Typo (1 character difference)
**Input:** "merhaba"
**Correct:** "merhba"
**Expected:** Correct with high confidence, feedback: .minorTypo

### Test Case 4: Turkish Character Substitution
**Input:** "merhaba"
**Correct:** "merhaba"
**Expected:** Correct with medium confidence, feedback: .phoneticSimilarity

### Test Case 5: Multiple Valid Translations
**Input:** "house"
**Correct:** "ev, bina"
**Expected:** Correct if matches either "ev" or "bina"

### Test Case 6: Completely Wrong
**Input:** "araba"
**Correct:** "ev"
**Expected:** Incorrect, feedback: .incorrect

### Test Case 7: Whitespace Handling
**Input:** "  merhaba  "
**Correct:** "merhaba"
**Expected:** Correct after trimming whitespace

### Test Case 8: Multi-word Translation
**Input:** "how are you"
**Correct:** "nasılsın"
**Expected:** Correct if fuzzy matching allows reasonable differences

## Testing Procedure

1. Create unit tests in Xcode
2. Test various Turkish words with common character substitutions
3. Test typo tolerance limits
4. Test multiple translation support
5. Test edge cases (empty input, only whitespace, etc.)

## Performance Considerations

- Levenshtein distance algorithm is O(n*m) where n and m are string lengths
- For long words, consider early termination if distance exceeds threshold
- Cache common Turkish character substitutions for better performance

## Future Enhancements

- Add phonetic matching for Turkish pronunciation patterns
- Support for common Turkish suffix variations
- Machine learning based similarity scoring
- Context-aware translation validation