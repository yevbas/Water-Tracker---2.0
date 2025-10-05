//
//  HealthKitActionsView.swift
//  WaterTracker
//
//  Created by Claude Code
//

import SwiftUI

struct HealthKitActionsView: View {
    let canCalculateWaterIntake: Bool
    let hasAnySyncPermissions: Bool
    let isCalculatingWaterIntake: Bool
    let isSyncing: Bool
    let isPerformingAction: Bool

    let onCalculateWaterIntake: () -> Void
    let onSyncData: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Calculate Water Intake button
            Button(action: onCalculateWaterIntake) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(.blue.opacity(0.15))
                            .frame(width: 32, height: 32)

                        if isCalculatingWaterIntake {
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(.blue)
                        } else {
                            Image(systemName: "drop.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.blue)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Calculate Water Goal")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.primary)

                        Text("Use your HealthKit data to calculate daily goal")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.blue.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(.blue.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(!canCalculateWaterIntake || isPerformingAction)
            .opacity(canCalculateWaterIntake && !isPerformingAction ? 1.0 : 0.6)

            // Sync to HealthKit button
            Button(action: onSyncData) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(.green.opacity(0.15))
                            .frame(width: 32, height: 32)

                        if isSyncing {
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(.green)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.green)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sync to HealthKit")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.primary)

                        Text("Sync all water portions to HealthKit")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.green.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(.green.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(!hasAnySyncPermissions || isPerformingAction)
            .opacity(hasAnySyncPermissions && !isPerformingAction ? 1.0 : 0.6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
