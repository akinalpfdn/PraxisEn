# PraxisEn Premium Subscription System Implementation Plan

## Overview
This document outlines the complete implementation of a premium subscription system for PraxisEn, transforming it from a free app to a freemium model with clear value propositions for upgrading.

## Subscription Tiers & Features

### Free Version
- **Levels**: A1, A2, B1 only (B2 is premium)
- **Sentences**: 3 sample sentences per word
- **Learned Words**: Last 50 learned words visible
- **Daily Swipes**: 30 card advances per day
- **Ads**: None (maintain clean experience)

### Premium Version (Monthly)
- **Levels**: All levels A1, A2, B1, B2
- **Sentences**: 10 sample sentences per word
- **Learned Words**: Complete learned words history
- **Daily Swipes**: Unlimited card advances
- **Price**: Monthly subscription via App Store

## Technical Architecture

### Data Model Changes

#### UserSettings.swift Extensions
```swift
// Add subscription tracking
@Transient var subscriptionTier: SubscriptionTier = .free
@Transient var subscriptionIsActive: Bool = false
@Transient var subscriptionExpirationDate: Date?
@Transient var dailySwipesUsed: Int = 0
@Transient var lastSwipeResetDate: Date = Date()
@Transient var subscriptionStartDate: Date?

enum SubscriptionTier: String, CaseIterable, Codable {
    case free = "free"
    case premium = "premium"
}
```

### New Service Classes

#### 1. SubscriptionManager.swift
**Purpose**: Central subscription state management and feature access checks
**Key Methods**:
- `isLevelUnlocked(_ level: String) -> Bool`
- `getMaxSentencesPerWord() -> Int`
- `getMaxLearnedWordsToShow() -> Int`
- `canMakeSwipe() -> Bool`
- `recordSwipe()`
- `refreshSubscriptionStatus()`

#### 2. PurchaseManager.swift
**Purpose**: StoreKit 2 integration for iOS subscriptions
**Key Methods**:
- `loadProducts()`
- `purchasePremium()`
- `restorePurchases()`
- `checkReceiptStatus()`
- `cancelSubscription()`

### Modified Existing Services

#### SpacedRepetitionManager.swift Changes
- Modify `selectNewWordWithSettings()` to filter out B2 words for free users
- Add subscription check in `selectNextWordWithSettings()`
- Ensure fallback logic when premium content is requested

#### FlashcardViewModel.swift Integration Points
1. **Swipe Counting**: Increment counter in `nextWord()` and `markCurrentWordAsKnown()`
2. **Daily Reset Logic**: Check and reset `dailySwipesUsed` at midnight
3. **Premium Content Checks**: Verify subscription status before loading B2 content
4. **Sentence Loading**: Limit to 3 sentences for free users in `loadExamplesForCurrentWord()`

## UI/UX Implementation

### SettingsView.swift Enhancements
- Add premium subscription management section
- Display current subscription status and expiration
- Add "Upgrade to Premium" CTA for free users
- Show subscription benefits comparison
- Add "Restore Purchases" and "Manage Subscription" options

### New Views Required

#### PremiumUpgradeView.swift
- Feature comparison table (Free vs Premium)
- Subscription benefits highlighting
- "Start Free Trial" or "Subscribe Now" buttons
- Terms and privacy links

#### DailyLimitExceededView.swift
- Engaging message about daily limit reached
- Premium upgrade CTA
- "Wait until tomorrow" option for free users
- Count down timer until daily reset

#### SubscriptionStatusView.swift
- Current plan display
- Renewal date
- Usage statistics (swipes remaining, etc.)

## Implementation Phases

### Phase 1: Foundation (Week 1-2)
**Objectives**: Establish core subscription infrastructure
1. Extend UserSettings model with subscription properties
2. Create SubscriptionManager service
3. Implement basic PurchaseManager with StoreKit 2
4. Add subscription state persistence

**Critical Files**:
- `Models/UserSettings.swift`
- `Services/SubscriptionManager.swift`
- `Services/PurchaseManager.swift`

### Phase 2: Content Integration (Week 3)
**Objectives**: Integrate subscription checks into existing logic
1. Modify SpacedRepetitionManager for level-based filtering
2. Update FlashcardViewModel with swipe counting
3. Implement sentence limiting logic
4. Add learned words filtering

**Critical Files**:
- `Helpers/SpacedRepetitionManager.swift`
- `ViewModels/FlashcardViewModel.swift`
- `Views/Stats/LearnedWordsView.swift`

### Phase 3: UI/UX Implementation (Week 4)
**Objectives**: Create premium upgrade flows and settings integration
1. Build PremiumUpgradeView
2. Create DailyLimitExceededView
3. Enhance SettingsView with subscription management
4. Add subscription status indicators throughout app

**Critical Files**:
- `Views/Settings/SettingsView.swift`
- `Views/Premium/PremiumUpgradeView.swift`
- `Views/Premium/DailyLimitExceededView.swift`

### Phase 4: Enhanced Features (Week 5)
**Objectives**: Complete subscription experience
1. Implement subscription validation and receipt checking
2. Add subscription expiration handling
3. Create upgrade prompts at natural usage points
4. Implement subscription management features

**Critical Files**:
- `Services/PurchaseManager.swift`
- `Services/SubscriptionManager.swift`
- `ViewModels/FlashcardViewModel.swift`

### Phase 5: Testing & Launch (Week 6)
**Objectives**: Ensure robust subscription system
1. Test all subscription flows
2. Verify free tier limitations work correctly
3. Test purchase, restore, and cancellation flows
4. Performance optimization and bug fixes

## Key Integration Points

### Word Selection Process
```swift
// Enhanced word selection with subscription checks
func selectNextWordWithSettings() -> VocabularyWord? {
    // 1. Check subscription level access
    let availableLevels = SubscriptionManager.shared.getUnlockedLevels()

    // 2. Filter words by unlocked levels
    let candidateWords = allWords.filter { availableLevels.contains($0.level) }

    // 3. Apply existing spaced repetition algorithm
    return selectWordFromCandidates(candidateWords)
}
```

### Swipe Limit Implementation
```swift
// In FlashcardViewModel
func nextWord() {
    guard SubscriptionManager.shared.canMakeSwipe() else {
        showDailyLimitExceeded()
        return
    }

    SubscriptionManager.shared.recordSwipe()
    // ... existing nextWord logic
}
```

### Sentence Limiting Logic
```swift
// Modify sentence loading based on subscription
func loadExamplesForCurrentWord() {
    let maxSentences = SubscriptionManager.shared.getMaxSentencesPerWord()
    let sentences = Array(allExamples.prefix(maxSentences))
    // Load limited sentences
}
```

### Learned Words Filtering
```swift
// In LearnedWordsView
var filteredLearnedWords: [VocabularyWord] {
    let allLearned = getAllLearnedWords()
    let maxToShow = SubscriptionManager.shared.getMaxLearnedWordsToShow()

    if maxToShow == Int.max { // Premium
        return allLearned
    } else { // Free - show most recent
        return Array(allLearned.suffix(maxToShow))
    }
}
```

## StoreKit 2 Integration Details

### Product Configuration
```swift
// Product IDs for App Store Connect
enum ProductID: String, CaseIterable {
    case premiumMonthly = "praxisen_premium_monthly"
    case premiumYearly = "praxisen_premium_yearly" // Future option
}
```

### Purchase Flow
1. Load products from App Store
2. Present premium upgrade view
3. Handle purchase via StoreKit 2
4. Update subscription status in SubscriptionManager
5. Refresh app UI with premium features

## Business Logic Considerations

### Graceful Degradation
- Free users hitting limits should see helpful upgrade prompts
- Network issues shouldn't block app functionality
- Subscription validation failures default to free tier temporarily

### User Experience Priorities
- Clear communication about limitations
- Smooth upgrade process
- Valuable premium features that justify cost
- Non-intrusive upgrade prompts at natural usage points

### Migration Strategy
- Existing users automatically become free tier
- No data loss during transition
- Optional upgrade promotions for early users

## Success Metrics
- Conversion rate from free to premium
- User retention after subscription implementation
- Daily active user maintenance
- Subscription cancellation rate
- User satisfaction with free tier limitations

## Testing Strategy
1. Unit tests for SubscriptionManager logic
2. UI tests for purchase flows
3. Integration tests for subscription state management
4. Sandbox testing for StoreKit purchases
5. Edge case testing (network issues, expired subscriptions)

This implementation plan provides a comprehensive roadmap for adding premium subscriptions to PraxisEn while maintaining the excellent user experience and leveraging the existing robust architecture.