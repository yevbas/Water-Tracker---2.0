//
//  HealthKitSyncSettingsView.swift
//  WaterTracker
//
//  Created by Claude Code
//

import SwiftUI

struct HealthKitSyncSettingsView: View {
    @Binding var syncWater: Bool
    @Binding var syncCaffeine: Bool
    @Binding var syncAlcohol: Bool

    let hasWaterWritePermission: Bool
    let hasCaffeineWritePermission: Bool
    let hasAlcoholWritePermission: Bool

    var body: some View {
        VStack(spacing: 16) {
            // Section Title
            HStack {
                Text("Sync Settings")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(.horizontal, 16)

            VStack(spacing: 10) {
                // Water Sync Toggle
                SyncToggleRow(
                    title: "Water Intake",
                    subtitle: "Sync water portions to HealthKit",
                    icon: "drop.fill",
                    color: .blue,
                    isOn: $syncWater
                )
                .opacity(hasWaterWritePermission ? 1.0 : 0.6)

                // Caffeine Sync Toggle
                SyncToggleRow(
                    title: "Caffeine",
                    subtitle: "Sync caffeinated drinks to HealthKit",
                    icon: "cup.and.saucer.fill",
                    color: .brown,
                    isOn: $syncCaffeine
                )
                .opacity(hasCaffeineWritePermission ? 1.0 : 0.6)

                // Alcohol Sync Toggle
                SyncToggleRow(
                    title: "Alcohol",
                    subtitle: "Sync alcoholic drinks to HealthKit",
                    icon: "wineglass.fill",
                    color: .purple,
                    isOn: $syncAlcohol
                )
                .opacity(hasAlcoholWritePermission ? 1.0 : 0.6)
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
    }
}
