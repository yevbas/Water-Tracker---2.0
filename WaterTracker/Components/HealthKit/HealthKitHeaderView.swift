//
//  HealthKitHeaderView.swift
//  WaterTracker
//
//  Created by Claude Code
//

import SwiftUI

struct HealthKitHeaderView: View {
    let isLoading: Bool
    let healthDataAvailable: Bool
    let isPartiallyConnected: Bool
    let connectionStatusText: String
    let onRefresh: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Health Icon with improved styling
            ZStack {
                Circle()
                    .fill(.red.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.red)
            }

            // Title and status with better hierarchy
            VStack(alignment: .leading, spacing: 4) {
                Text("HealthKit")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.primary)

                HStack(spacing: 6) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(width: 14, height: 14)
                    } else {
                        Image(systemName: healthDataAvailable ? (isPartiallyConnected ? "exclamationmark.circle.fill" : "checkmark.circle.fill") : "xmark.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(healthDataAvailable ? (isPartiallyConnected ? .orange : .green) : .secondary)
                    }

                    Text(connectionStatusText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Refresh button
            Button(action: onRefresh) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(.secondary.opacity(0.1))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
    }
}
