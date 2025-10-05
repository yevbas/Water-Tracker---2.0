//
//  HealthKitSharedViews.swift
//  WaterTracker
//
//  Shared view components for HealthKit card and related views
//  Created by Claude Code
//

import SwiftUI

// MARK: - Data Item View

struct DataItemView: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            // Enhanced icon with background
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(color)
            }

            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Sync Toggle Row

struct SyncToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Enhanced icon with better styling
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(color)
            }

            // Text content with improved typography
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            // Enhanced toggle with better styling
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: color))
                .scaleEffect(0.9)
                .onChange(of: isOn) { _, newValue in
                    // Save to UserDefaults immediately
                    let key: String
                    switch title {
                    case "Water Intake":
                        key = "healthkit_sync_water"
                    case "Caffeine":
                        key = "healthkit_sync_caffeine"
                    case "Alcohol":
                        key = "healthkit_sync_alcohol"
                    default:
                        key = "healthkit_sync_\(title.lowercased().replacingOccurrences(of: " ", with: "_"))"
                    }
                    UserDefaults.standard.set(newValue, forKey: key)
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Missing Service View

struct MissingServiceView: View {
    let title: String
    let isMissing: Bool
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(isMissing ? .orange : .green)

            Text(title)
                .font(.caption2)
                .foregroundStyle(isMissing ? .orange : .green)
                .fontWeight(.medium)

            if isMissing {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isMissing ? .orange.opacity(0.1) : .green.opacity(0.1))
        )
    }
}
