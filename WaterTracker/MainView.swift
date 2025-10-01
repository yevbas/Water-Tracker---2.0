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
