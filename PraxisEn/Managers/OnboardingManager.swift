//
//  OnboardingManager.swift
//  PraxisEn
//
//  Created by Claude Code on 07.12.2025.
//

import Foundation

/// Manages user onboarding state and preferences
class OnboardingManager {
    static let shared = OnboardingManager()

    private let UserDefaults = Foundation.UserDefaults.standard
    private let hasCompletedOnboardingKey = "hasCompletedOnboarding"

    private init() {}

    /// Checks if user has completed onboarding
    var hasCompletedOnboarding: Bool {
        UserDefaults.bool(forKey: hasCompletedOnboardingKey)
    }

    /// Marks onboarding as completed
    func markOnboardingCompleted() {
        UserDefaults.set(true, forKey: hasCompletedOnboardingKey)
    }

    /// Resets onboarding status (for testing or user request)
    func resetOnboarding() {
        UserDefaults.removeObject(forKey: hasCompletedOnboardingKey)
    }
}