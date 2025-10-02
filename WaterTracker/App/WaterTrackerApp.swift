//
//  WaterTrackerApp.swift
//  WaterTracker
//
//  Created by Jackson  on 08/09/2025.
//

import SwiftUI
import SwiftData
import UserNotifications
import RevenueCat
import StoreKit

@main
struct WaterTrackerApp: App {
    @AppStorage("onboarding_passed")
    private var onboardingPassed = false
    @State private var isConfigured = false
    @StateObject private var healthKitService = HealthKitService()
    @StateObject private var revenueCatMonitor = RevenueCatMonitor()
    @StateObject private var weatherService = WeatherService()
    @StateObject private var aiClient = AIDrinkAnalysisClient()
    @StateObject private var sleepService = SleepService()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            WaterPortion.self,
            WeatherAnalysisCache.self,
            SleepAnalysisCache.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if isConfigured {
                    if onboardingPassed {
                        MainView()
                            .modelContainer(sharedModelContainer)
                            .environmentObject(revenueCatMonitor)
                            .environmentObject(healthKitService)
                            .environmentObject(weatherService)
                            .environmentObject(aiClient)
                            .environmentObject(sleepService)
                            .onAppear {
                                // Clean up old sleep data on app start
                                let context = sharedModelContainer.mainContext
                                SleepAnalysisCache.cleanupOldData(modelContext: context)
                            }
                    } else {
                        PersonalizedOnboarding()
                            .modelContainer(sharedModelContainer)
                            .environmentObject(revenueCatMonitor)
                            .environmentObject(healthKitService)
                    }
                } else {
                    ConfigureView(container: sharedModelContainer, healthKitService: healthKitService) {
                        isConfigured = true
                    }
                    .onAppear {
                        onboardingPassed = true
                    }
                }
            }
        }
    }

#warning("In future, decide whether to show additional review request in the app in order to check if user gonna rate it positive or negative.")
    static func requestReview() {
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0 is UIWindowScene } ) as? UIWindowScene else {
            return
        }
//        guard let keyVC = windowScene.keyWindow?.rootViewController else { return }
#if DEBUG
        guard let keyVC = windowScene.keyWindow?.rootViewController else { return }
        let alert = UIAlertController(
            title: "Rate this app",
            message: "This alert is only shown in debug mode",
            preferredStyle: .alert
        )
        alert.addAction(.init(title: "Rate", style: .default))
        keyVC.present(alert, animated: true)
#else
//        let alert = UIAlertController(
//            title: "Do you like it?",
//            message: nil,
//            preferredStyle: .alert
//        )
//        alert.addAction(.init(title: "Yes", style: .default, handler: { _ in
        AppStore.requestReview(in: windowScene)
//        }))
//        alert.addAction(.init(title: "No", stayle: .cancel))
//        keyVC.present(alert, animated: true)
#endif
    }

}

// Moved RevenueCat configuration into AppConfigurator
