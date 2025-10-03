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

struct MainTabView: View {
    @State var selectedTab: WaterTrackerTab = .dashboard

    var body: some View {
        Group {
            if #available(iOS 18.0, *) {
                TabView(selection: $selectedTab) {
                    Tab("Reminders", systemImage: "clock", value: .reminders) {
                        NavigationStack {
                            ScheduleView()
                                .navigationTitle("Reminders")
                                .navigationBarTitleDisplayMode(.inline)
                        }
                    }
                    Tab("Dashboard", systemImage: "drop", value: .dashboard) {
                        NavigationStack {
                            DashboardView()
                                .navigationTitle("Dashboard")
                                .navigationBarTitleDisplayMode(.inline)
                        }
                    }
                    Tab("Settings", systemImage: "gear", value: .settings) {
                        NavigationStack {
                            SettingsView()
                                .navigationTitle("Settings")
                                .navigationBarTitleDisplayMode(.inline)
                        }
                    }
                }
            } else {
                TabView(selection: $selectedTab) {
                    NavigationStack {
                        ScheduleView()
                            .navigationTitle("Reminders")
                            .navigationBarTitleDisplayMode(.inline)
                            .id(WaterTrackerTab.reminders)
                            .tabItem {
                                Image(systemName: "clock")
                            }
                    }
                    NavigationStack {
                        DashboardView()
                            .navigationTitle("Dashboard")
                            .navigationBarTitleDisplayMode(.inline)
                            .id(WaterTrackerTab.dashboard)
                            .tabItem {
                                Image(systemName: "drop")
                            }
                    }
                    NavigationStack {
                        SettingsView()
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
    MainTabView()
        .modelContainer(for: [WaterPortion.self, WeatherAnalysisCache.self, SleepAnalysisCache.self], inMemory: true)
        .environmentObject(RevenueCatMonitor(state: .preview(true)))
        .environmentObject(WeatherService())
        .environmentObject(SleepService())
        .environmentObject(HealthKitService())
}
