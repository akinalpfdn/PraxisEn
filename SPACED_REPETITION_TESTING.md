# New Spaced Repetition System Testing

## Test Cases for the Repeat Count System

### Test 1: New vs Review Word Selection Ratio
**Scenario**: User has 5 words in review system
- Expected: 100% new words should be selected
- Test: Call `shouldSelectNewWord()` with `wordsInReview = 5`
- Result: Should return true 100% of the time

### Test 2: New vs Review Word Selection Ratio
**Scenario**: User has 15 words in review system
- Expected: 70% new words, 30% review words
- Test: Call `shouldSelectNewWord()` with `wordsInReview = 15`
- Result: Should return true ~70% of the time

### Test 3: New vs Review Word Selection Ratio
**Scenario**: User has 35 words in review system
- Expected: 30% new words, 70% review words
- Test: Call `shouldSelectNewWord()` with `wordsInReview = 35`
- Result: Should return true ~30% of the time

### Test 4: New vs Review Word Selection Ratio
**Scenario**: User has 60 words in review system
- Expected: 0% new words, 100% review words
- Test: Call `shouldSelectNewWord()` with `wordsInReview = 60`
- Result: Should return false 100% of the time

### Test 5: Review Word Selection by Repetition Count
**Scenario**: Review words with different repetition counts
- Words in system:
  - Word A: repetitions = 1
  - Word B: repetitions = 2
  - Word C: repetitions = 3
- Expected: Should select Word A (lowest repetition count)

### Test 6: Time-based Preference
**Scenario**: Multiple words with same repetition count
- Words with repetitions = 1:
  - Word X: lastReviewedDate = 2 days ago
  - Word Y: lastReviewedDate = 1 day ago
  - Word Z: never reviewed
- Expected: Should prefer Word Z (never reviewed), then Word X (oldest)

### Test 7: Known Words Exclusion
**Scenario**: Mix of known and unknown words
- Known words: Should be completely excluded from selection
- Unknown words: Should be selected normally
- Expected: Only unknown words should be returned

## Manual Testing Steps

### Step 1: Fresh Install
1. Install the app fresh
2. Start learning new words
3. Verify first 10 words are all new (100% new ratio)

### Step 2: Build Review Queue
1. Continue learning until you have ~15 words in review
2. Verify mix of new and review words (~70/30 ratio)

### Step 3: Medium Review Queue
1. Continue until ~35 words in review
2. Verify mostly review words (~30/70 ratio)

### Step 4: Large Review Queue
1. Continue until 50+ words in review
2. Verify only review words (0% new words)

### Step 5: Time-based Selection
1. Use the app, then stop for a day
2. Come back and verify words seen longer ago are prioritized

## Key Improvements Verified
✅ No calendar pressure - can take breaks without overdue pile-up
✅ Adaptive difficulty - focuses on appropriate challenge level
✅ Simpler logic - no date calculations needed
✅ Better user experience - smooth progression through repetition groups