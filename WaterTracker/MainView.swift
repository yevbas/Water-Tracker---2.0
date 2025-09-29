//
//  ContentView.swift
//  WaterTracker
//
//  Created by Jackson  on 08/09/2025.
//

import SwiftUI

struct MainView: View {
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
