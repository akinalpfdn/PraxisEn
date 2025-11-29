import Foundation

/// Notification names for subscription-related events
extension Notification.Name {
    static let subscriptionDidExpire = Notification.Name("subscriptionDidExpire")
    static let subscriptionWillExpire = Notification.Name("subscriptionWillExpire")
    static let subscriptionDidActivate = Notification.Name("subscriptionDidActivate")
    static let subscriptionDidDeactivate = Notification.Name("subscriptionDidDeactivate")
}