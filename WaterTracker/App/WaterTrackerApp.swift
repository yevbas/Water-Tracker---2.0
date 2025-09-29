//
//  WaterTrackerApp.swift
//  WaterTracker
//
//  Created by Jackson  on 08/09/2025.
//

import SwiftUI
import SwiftData

@main
struct WaterTrackerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            WaterPortion.self,
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
            MainView()
                .modelContainer(sharedModelContainer)
//            DrinkSelector()
        }
    }
}
