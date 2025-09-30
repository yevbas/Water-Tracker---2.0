//
//  NotificationDelegate.swift
//  WaterTracker
//
//  Created by Assistant on 29/09/2025.
//

import Foundation
import UserNotifications

@MainActor
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    private override init() { super.init() }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.banner, .list, .sound]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let id = response.actionIdentifier
        let unitsPref = UserDefaults.standard.string(forKey: "measurement_units") ?? "ml"
        let unit: WaterUnit = WaterUnit.fromString(unitsPref)
        func amountForAction() -> Double {
            switch unit {
            case .ounces:
                switch id {
                case NotificationsManager.ActionId.quickAddSmall.rawValue: return 6
                case NotificationsManager.ActionId.quickAddMedium.rawValue: return 8
                case NotificationsManager.ActionId.quickAddLarge.rawValue: return 12
                default: return 0
                }
            case .millilitres:
                switch id {
                case NotificationsManager.ActionId.quickAddSmall.rawValue: return 150
                case NotificationsManager.ActionId.quickAddMedium.rawValue: return 250
                case NotificationsManager.ActionId.quickAddLarge.rawValue: return 350
                default: return 0
                }
            }
        }
        switch id {
        case NotificationsManager.ActionId.quickAddSmall.rawValue,
             NotificationsManager.ActionId.quickAddMedium.rawValue,
             NotificationsManager.ActionId.quickAddLarge.rawValue:
            let amount = amountForAction()
            if amount > 0 {
                await MainActor.run {
                    HydrationService.shared.addPortion(amount: amount, unit: unit)
                }
            }
        default:
            break
        }
    }
}


