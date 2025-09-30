//
//  ContentView.swift
//  WaterTracker
//
//  Created by Jackson  on 08/09/2025.
//

import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var healthKitService: HealthKitService
    
    var body: some View {
//        TabView {
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("Dashboard", systemImage: "house")
            }
            .onAppear {
                // Initialize HealthKit service with model context
                healthKitService.setModelContext(modelContext)
                
                // Always refresh health data on app launch if HealthKit is enabled
                if healthKitService.isHealthKitEnabled() {
                    healthKitService.refreshHealthData()
                }
            }

//            NavigationStack {
//                ScheduleView()
//            }
//            .tabItem {
//                Label("Schedule", systemImage: "clock")
//            }
//
//            NavigationStack {
//                SettingsView()
//            }
//            .tabItem {
//                Label("Settings", systemImage: "gear")
//            }
//        }
    }
}

#Preview {
    MainView()
}
