//
//  MainTabView.swift
//  WaterTracker
//
//  Created by Jackson  on 03/10/2025.
//

import Foundation
import SwiftUI

enum WaterTrackerTab: Hashable {
    case reminders
    case dashboard
    case settings
}

struct MainTabScreen: View {
    @State var selectedTab: WaterTrackerTab = .dashboard

    var body: some View {
        Group {
            if #available(iOS 18.0, *) {
                TabView(selection: $selectedTab) {
                    Tab("Reminders", systemImage: "clock", value: .reminders) {
                        NavigationStack {
                            WaterScheduleScreen()
                                .navigationTitle("Reminders")
                                .navigationBarTitleDisplayMode(.inline)
                        }
                    }
                    Tab("Dashboard", systemImage: "drop", value: .dashboard) {
                        NavigationStack {
                            DashboardScreen()
                                .navigationTitle("Dashboard")
                                .navigationBarTitleDisplayMode(.inline)
                        }
                    }
                    Tab("Settings", systemImage: "gear", value: .settings) {
                        NavigationStack {
                            SettingsScreen()
                                .navigationTitle("Settings")
                                .navigationBarTitleDisplayMode(.inline)
                        }
                    }
                }
            } else {
                TabView(selection: $selectedTab) {
                    NavigationStack {
                        WaterScheduleScreen()
                            .navigationTitle("Reminders")
                            .navigationBarTitleDisplayMode(.inline)
                            .id(WaterTrackerTab.reminders)
                            .tabItem {
                                Image(systemName: "clock")
                            }
                    }
                    NavigationStack {
                        DashboardScreen()
                            .navigationTitle("Dashboard")
                            .navigationBarTitleDisplayMode(.inline)
                            .id(WaterTrackerTab.dashboard)
                            .tabItem {
                                Image(systemName: "drop")
                            }
                    }
                    NavigationStack {
                        SettingsScreen()
                            .navigationTitle("Settings")
                            .navigationBarTitleDisplayMode(.inline)
                            .id(WaterTrackerTab.settings)
                            .tabItem {
                                Image(systemName: "gear")
                            }
                    }
                }
            }
        }
    }
}

#Preview {
    MainTabScreen()
        .modelContainer(for: [WaterProgress.self, WaterPortion.self, WeatherAnalysisCache.self, SleepAnalysisCache.self], inMemory: true)
        .environmentObject(RevenueCatMonitor(state: .preview(true)))
        .environmentObject(WeatherService())
        .environmentObject(SleepService())
        .environmentObject(HealthKitService())
}
