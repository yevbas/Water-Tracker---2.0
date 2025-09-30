//
//  AppConfigurator.swift
//  WaterTracker
//
//  Created by Assistant on 29/09/2025.
//

import Foundation
import SwiftUI
import SwiftData
import UserNotifications
import RevenueCat
import FirebaseCore
import FirebaseRemoteConfig
import GoogleMobileAds
import AppTrackingTransparency

@MainActor
enum AppConfigurator {
    static func configureAll(container: ModelContainer) async {
        // Firebase
        await configureFirebaseAndRemoteConfig()

        // Notifications
        let notifications = NotificationsManager.shared
        notifications.refreshAuthorizationStatus()
        notifications.registerCategories()
        if notifications.authorizationStatus == .notDetermined {
            let _ = await notifications.requestAuthorization()
        }
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared

        // Hydration service
        HydrationService.shared.configure(container: container)

        await requestTrackingAuthorization()

        await MobileAds.shared.start()

        // RevenueCat
        await configureRevenueCat()
    }

    private static func configureRevenueCat() async {
#if DEBUG
        Purchases.logLevel = .debug
#endif
        // Use RC API key from Remote Config
        let apiKey = RemoteConfigService.shared.string(for: .revenueCatAPIKey)
        Purchases.configure(withAPIKey: apiKey)

        // Initial entitlement check
        let monitor = RevenueCatMonitor()

        if monitor.userHasFullAccess == false {
            NotificationsManager.shared.keepOnlyOneReminder()
        }

        // Listen to entitlement changes
        Task {
            // Wait a moment to ensure Purchases is fully configured
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            for await info in Purchases.shared.customerInfoStream {
                let hasAccess = info.userHasFullAccess
                if hasAccess == false {
                    await MainActor.run {
                        NotificationsManager.shared.keepOnlyOneReminder()
                    }
                }
            }
        }
    }

    private static func configureFirebaseAndRemoteConfig() async {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        // Remote Config fetch & activate before any usage
        await RemoteConfigService.shared.fetchAndActivate()
    }

    private static func requestTrackingAuthorization() async {
        await withCheckedContinuation { continuation in
            ATTrackingManager.requestTrackingAuthorization { status in
                continuation.resume()
    #if DEBUG
                switch status {
                case .authorized:
                    // Tracking authorization dialog was shown
                    // and we are authorized
                    print("IDFA Authorized")
                case .denied:
                    // Tracking authorization dialog was
                    // shown and permission is denied
                    print("IDFA Denied")
                case .notDetermined:
                    // Tracking authorization dialog has not been shown
                    print("IDFA Not Determined")
                case .restricted:
                    print("IDFA Restricted")
                @unknown default:
                    print("Unknown")
                }
    #endif
            }
        }
    }

}


