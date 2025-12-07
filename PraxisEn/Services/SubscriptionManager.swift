import Foundation
import SwiftData
internal import Combine

/// Manages subscription state and feature access controls
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    // MARK: - Constants
    private let freeTierSwipeLimit = 30
    private let freeTierSentenceLimit = 3
    private let premiumTierSentenceLimit = 10
    private let freeTierLearnedWordsLimit = 50
    private let premiumLevels = ["A1", "A2", "B1"]
    private let allLevels = ["A1", "A2", "B1", "B2"]

    // MARK: - Published Properties
    @Published var isPremiumActive: Bool = false
    @Published var subscriptionTier: UserSettings.SubscriptionTier = .free
    @Published var dailySwipesRemaining: Int = 30
    @Published var subscriptionExpirationDate: Date?

    // MARK: - Private Properties
    @Published private var userSettings: UserSettings?
    private var modelContext: ModelContext?
    private var expirationCheckTimer: Timer?

    // MARK: - Initialization
    private init() {
        startExpirationCheckTimer()
    }

    deinit {
        expirationCheckTimer?.invalidate()
    }

    // MARK: - Configuration
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        loadUserSettings()
        // Check for daily reset on app launch
        updateDailySwipeCount()
    }

    // MARK: - User Settings Management
    private func loadUserSettings() {
        guard let modelContext = modelContext else { return }

        do {
            let descriptor = FetchDescriptor<UserSettings>()
            if let settings = try modelContext.fetch(descriptor).first {
                userSettings = settings
                updatePublishedProperties()
            }
        } catch {
            //print("❌ Failed to load user settings: \(error)")
        }
    }

    private func saveUserSettings() {
        guard let settings = userSettings,
              let modelContext = modelContext else { return }

        do {
            try modelContext.save()
            updatePublishedProperties()
        } catch {
            //print("❌ Failed to save user settings: \(error)")
        }
    }

    private func updatePublishedProperties() {
        guard let settings = userSettings else { return }

        // Update daily swipe count first (not on main thread)
        updateDailySwipeCount()

        DispatchQueue.main.async {
            self.subscriptionTier = settings.subscriptionTier
            self.isPremiumActive = settings.subscriptionIsActive && settings.subscriptionTier == .premium
            self.subscriptionExpirationDate = settings.subscriptionExpirationDate
        }
    }

    // MARK: - Feature Access Methods

    /// Returns true if the specified level is unlocked for the current subscription tier
    func isLevelUnlocked(_ level: String) -> Bool {
        guard let settings = userSettings else { return false }

        // Premium users have access to all levels
        if settings.subscriptionTier == .premium && settings.subscriptionIsActive {
            return allLevels.contains(level)
        }

        // Free users only have access to A1, A2, B1
        return premiumLevels.contains(level)
    }

    /// Returns the unlocked levels based on current subscription
    func getUnlockedLevels() -> [String] {
        guard let settings = userSettings else { return premiumLevels }

        if settings.subscriptionTier == .premium && settings.subscriptionIsActive {
            return allLevels
        } else {
            return premiumLevels
        }
    }

    /// Returns the maximum number of sentences per word for current subscription
    func getMaxSentencesPerWord() -> Int {
        guard let settings = userSettings else { return freeTierSentenceLimit }

        return settings.subscriptionTier == .premium && settings.subscriptionIsActive
               ? premiumTierSentenceLimit
               : freeTierSentenceLimit
    }

    /// Returns the maximum number of learned words to show for current subscription
    func getMaxLearnedWordsToShow() -> Int {
        guard let settings = userSettings else { return freeTierLearnedWordsLimit }

        return settings.subscriptionTier == .premium && settings.subscriptionIsActive
               ? Int.max
               : freeTierLearnedWordsLimit
    }

    /// Returns true if the user can make another swipe (card advance)
    func canMakeSwipe() -> Bool {
        // If no settings loaded yet, allow swipes by default for new users
        guard let settings = userSettings else {
            //print("⚠️ canMakeSwipe: No user settings found, allowing swipes by default")
            return true
        }

        // First check if we need to reset the daily counter (new day)
        updateDailySwipeCount()

        // Premium users have unlimited swipes - use the reactive @Published property
        if isPremiumActive {
            //print("✅ canMakeSwipe: Premium user with active subscription")
            return true
        }

        // Free users are limited to 30 swipes per day
        let canSwipe = settings.dailySwipesUsed < freeTierSwipeLimit
        //print("🎯 canMakeSwipe: Free user - \(settings.dailySwipesUsed)/\(freeTierSwipeLimit) used, can swipe: \(canSwipe)")
        return canSwipe
    }

    /// Records a swipe and updates daily count
    func recordSwipe() {
        guard let settings = userSettings else { return }

        // Only track swipes for free users
        if !isPremiumActive {
            // Reset if new day first
            updateDailySwipeCount()

            if settings.dailySwipesUsed < freeTierSwipeLimit {
                settings.dailySwipesUsed += 1
                settings.updatedAt = Date()
                saveUserSettings()

                // Update published property immediately
                DispatchQueue.main.async {
                    self.dailySwipesRemaining = max(0, self.freeTierSwipeLimit - settings.dailySwipesUsed)
                }
            }
        }
    }

    /// Updates the daily swipe count, resetting if necessary
    private func updateDailySwipeCount() {
        guard let settings = userSettings else { return }

        let now = Date()
        let calendar = Calendar.current

        // Check if we need to reset the daily counter (new day)
        if !calendar.isDate(settings.lastSwipeResetDate, inSameDayAs: now) {
            //print("🔄 Daily swipe reset triggered - was \(settings.dailySwipesUsed), now 0")
            settings.dailySwipesUsed = 0
            settings.lastSwipeResetDate = now
            settings.updatedAt = Date()
            saveUserSettings()
        }

        // Update published property
        let remaining = max(0, freeTierSwipeLimit - settings.dailySwipesUsed)
        DispatchQueue.main.async {
            self.dailySwipesRemaining = remaining
        }

        //print("📊 Daily swipe status: \(settings.dailySwipesUsed)/\(freeTierSwipeLimit) used")
    }

    /// Returns the current daily swipe usage information
    func getDailySwipeInfo() -> (used: Int, limit: Int, remaining: Int) {
        guard let settings = userSettings else {
            return (used: 0, limit: freeTierSwipeLimit, remaining: freeTierSwipeLimit)
        }

        let limit = (settings.subscriptionTier == .premium && settings.subscriptionIsActive)
                    ? Int.max
                    : freeTierSwipeLimit

        return (
            used: settings.dailySwipesUsed,
            limit: limit == Int.max ? freeTierSwipeLimit : limit,
            remaining: limit == Int.max ? freeTierSwipeLimit : max(0, limit - settings.dailySwipesUsed)
        )
    }

    // MARK: - Subscription Management Methods

    /// Updates subscription status after successful purchase
    func activatePremiumSubscription(startDate: Date, expirationDate: Date?) {
        guard let settings = userSettings else { return }

        settings.subscriptionTier = .premium
        settings.subscriptionIsActive = true
        settings.subscriptionStartDate = startDate
        settings.subscriptionExpirationDate = expirationDate
        settings.updatedAt = Date()

        // Update @Published properties for immediate UI update
        isPremiumActive = true
        subscriptionTier = .premium
        subscriptionExpirationDate = expirationDate

        saveUserSettings()
    }

    /// Deactivates premium subscription (for cancellation or expiration)
    func deactivatePremiumSubscription() {
        guard let settings = userSettings else { return }

        settings.subscriptionTier = .free
        settings.subscriptionIsActive = false
        settings.subscriptionExpirationDate = nil
        settings.updatedAt = Date()

        // Update @Published properties for immediate UI update
        isPremiumActive = false
        subscriptionTier = .free
        subscriptionExpirationDate = nil

        saveUserSettings()

        // Post notification for UI components to react
        NotificationCenter.default.post(
            name: .subscriptionDidDeactivate,
            object: nil,
            userInfo: ["previousTier": "premium"]
        )
    }

    /// Refreshes subscription status (call this on app launch)
    func refreshSubscriptionStatus() {
        guard let settings = userSettings else { return }

        // Check if subscription has expired
        if let expirationDate = settings.subscriptionExpirationDate {
            if expirationDate < Date() {
                handleSubscriptionExpiration()
                return
            }
        }

        updatePublishedProperties()
    }

    /// Handles subscription expiration with graceful degradation
    private func handleSubscriptionExpiration() {
        guard let settings = userSettings else { return }

        //print("🔄 Subscription expired, deactivating premium features")
        deactivatePremiumSubscription()

        // Post notification for UI components to react
        NotificationCenter.default.post(
            name: .subscriptionDidExpire,
            object: nil,
            userInfo: ["previousExpirationDate": settings.subscriptionExpirationDate as Any]
        )
    }

    /// Starts a timer to periodically check for subscription expiration
    private func startExpirationCheckTimer() {
        // Check every hour for subscription expiration and warnings
        expirationCheckTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.checkForExpiration()
            self?.checkForExpirationWarning()
        }
    }

    /// Checks if subscription has expired and handles it
    private func checkForExpiration() {
        guard let settings = userSettings,
              settings.subscriptionIsActive,
              let expirationDate = settings.subscriptionExpirationDate else { return }

        if expirationDate <= Date() {
            handleSubscriptionExpiration()
        }
    }

    /// Checks if subscription is expiring soon and posts warning notification
    private func checkForExpirationWarning() {
        guard let settings = userSettings,
              settings.subscriptionIsActive,
              let expirationDate = settings.subscriptionExpirationDate,
              isSubscriptionExpiringSoon() else { return }

        // Only post warning once per day
        let lastWarningDate = UserDefaults.standard.object(forKey: "lastExpirationWarningDate") as? Date ?? Date.distantPast
        let now = Date()

        if !Calendar.current.isDate(lastWarningDate, inSameDayAs: now) {
            UserDefaults.standard.set(now, forKey: "lastExpirationWarningDate")

            NotificationCenter.default.post(
                name: .subscriptionWillExpire,
                object: nil,
                userInfo: [
                    "expirationDate": expirationDate,
                    "daysUntilExpiration": getDaysUntilExpiration() ?? 0
                ]
            )
            //print("⚠️ Subscription expiring soon warning posted")
        }
    }

    /// Checks if subscription is expiring soon (within 3 days)
    func isSubscriptionExpiringSoon() -> Bool {
        guard let settings = userSettings,
              settings.subscriptionIsActive,
              let expirationDate = settings.subscriptionExpirationDate else { return false }

        let threeDaysFromNow = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        return expirationDate <= threeDaysFromNow && expirationDate > Date()
    }

    /// Returns days until expiration
    func getDaysUntilExpiration() -> Int? {
        guard let settings = userSettings,
              settings.subscriptionIsActive,
              let expirationDate = settings.subscriptionExpirationDate else { return nil }

        return Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day
    }

    /// Returns subscription information for UI display
    func getSubscriptionInfo() -> SubscriptionInfo {
        guard let settings = userSettings else {
            return SubscriptionInfo(
                tier: .free,
                isActive: false,
                expirationDate: nil,
                startDate: nil,
                dailySwipesUsed: 0,
                dailySwipesLimit: freeTierSwipeLimit
            )
        }

        return SubscriptionInfo(
            tier: settings.subscriptionTier,
            isActive: settings.subscriptionIsActive,
            expirationDate: settings.subscriptionExpirationDate,
            startDate: settings.subscriptionStartDate,
            dailySwipesUsed: settings.dailySwipesUsed,
            dailySwipesLimit: settings.subscriptionTier == .premium && settings.subscriptionIsActive
                                ? Int.max
                                : freeTierSwipeLimit
        )
    }
}

// MARK: - Supporting Structures

struct SubscriptionInfo {
    let tier: UserSettings.SubscriptionTier
    let isActive: Bool
    let expirationDate: Date?
    let startDate: Date?
    let dailySwipesUsed: Int
    let dailySwipesLimit: Int

    var isExpired: Bool {
        guard let expirationDate = expirationDate else { return false }
        return expirationDate < Date()
    }

    var daysUntilExpiration: Int? {
        guard let expirationDate = expirationDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day
    }
}
