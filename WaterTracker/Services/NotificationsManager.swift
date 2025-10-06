//
//  NotificationsManager.swift
//  WaterTracker
//
//  Created by Assistant on 29/09/2025.
//

import Foundation
import UserNotifications

@MainActor
final class NotificationsManager: ObservableObject {
    static let shared = NotificationsManager()

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    static let categoryId = "WATER_REMINDER_CATEGORY"
    enum ActionId: String {
        case quickAddSmall = "WATER_QUICK_ADD_SMALL"
        case quickAddMedium = "WATER_QUICK_ADD_MEDIUM"
        case quickAddLarge = "WATER_QUICK_ADD_LARGE"
    }

    private init() {
        refreshAuthorizationStatus()
    }

    func refreshAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.authorizationStatus = settings.authorizationStatus
            }
        }
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.refreshAuthorizationStatus()
            }
            return granted
        } catch {
            return false
        }
    }

    @MainActor
    func registerCategories() {
        let unitsString = UserDefaults.standard.string(forKey: "measurement_units") ?? "ml"
        let units = WaterUnit.fromString(unitsString)
        let titles: (String, String, String)
        switch units {
        case .ounces:
            titles = (
                String(localized: "+6 fl oz"),
                String(localized: "+8 fl oz"),
                String(localized: "+12 fl oz")
            )
        case .millilitres:
            titles = (
                String(localized: "+150 ml"),
                String(localized: "+250 ml"),
                String(localized: "+350 ml")
            )
        }
        let small = UNNotificationAction(identifier: ActionId.quickAddSmall.rawValue, title: titles.0, options: [])
        let medium = UNNotificationAction(identifier: ActionId.quickAddMedium.rawValue, title: titles.1, options: [])
        let large = UNNotificationAction(identifier: ActionId.quickAddLarge.rawValue, title: titles.2, options: [])
        let category = UNNotificationCategory(identifier: Self.categoryId, actions: [small, medium, large], intentIdentifiers: [], options: [.customDismissAction])
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    func scheduleDailyReminder(id: String = UUID().uuidString, hour: Int, minute: Int, title: String = String(localized: "Time to drink water"), body: String = String(localized: "Stay hydrated and healthy!")) async throws -> String {
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = Self.categoryId

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try await UNUserNotificationCenter.current().add(request)
        return id
    }

    func cancelReminder(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func keepOnlyOneReminder() {
        Task {
            let requests = await listPendingReminders()
            guard requests.count > 1 else { return }
            
            // Keep the first reminder (earliest time) and cancel the rest
            let sortedRequests = requests.sorted { request1, request2 in
                guard let trigger1 = request1.trigger as? UNCalendarNotificationTrigger,
                      let trigger2 = request2.trigger as? UNCalendarNotificationTrigger,
                      let hour1 = trigger1.dateComponents.hour,
                      let minute1 = trigger1.dateComponents.minute,
                      let hour2 = trigger2.dateComponents.hour,
                      let minute2 = trigger2.dateComponents.minute else {
                    return false
                }
                return (hour1 * 60 + minute1) < (hour2 * 60 + minute2)
            }
            
            // Cancel all except the first one
            let remindersToCancel = Array(sortedRequests.dropFirst())
            let identifiersToCancel = remindersToCancel.map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToCancel)
        }
    }

    func listPendingReminders() async -> [UNNotificationRequest] {
        return await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                continuation.resume(returning: requests)
            }
        }
    }
}


