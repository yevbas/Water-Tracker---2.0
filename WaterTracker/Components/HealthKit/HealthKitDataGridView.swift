//
//  HealthKitDataGridView.swift
//  WaterTracker
//
//  Created by Claude Code
//

import SwiftUI
import HealthKit

struct HealthKitDataGridView: View {
    let healthData: HealthKitData?

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            if let height = healthData?.height {
                DataItemView(
                    icon: "figure.stand",
                    title: String(localized: "Height"),
                    value: String(localized: "\(Int(height * 100)) cm"),
                    color: .blue
                )
            }

            if let weight = healthData?.weight {
                DataItemView(
                    icon: "scalemass",
                    title: String(localized: "Weight"),
                    value: String(localized: "\(Int(weight)) kg"),
                    color: .green
                )
            }

            if let age = healthData?.age {
                DataItemView(
                    icon: "calendar",
                    title: String(localized: "Age"),
                    value: String(localized: "\(age) years"),
                    color: .orange
                )
            }

            if let gender = healthData?.gender {
                let genderText: String = {
                    switch gender {
                    case .male:
                        return String(localized: "Male")
                    case .female:
                        return String(localized: "Female")
                    case .other:
                        return String(localized: "Other")
                    case .notSet:
                        return String(localized: "Not Set")
                    @unknown default:
                        return String(localized: "Unknown")
                    }
                }()

                DataItemView(
                    icon: "person",
                    title: String(localized: "Gender"),
                    value: genderText,
                    color: .purple
                )
            }

            if let sleepHours = healthData?.averageSleepHours {
                DataItemView(
                    icon: "bed.double",
                    title: String(localized: "Avg Sleep"),
                    value: String(localized: "\(sleepHours, specifier: "%.1f") hrs"),
                    color: .indigo
                 )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// DataItemView is defined in HealthKitSharedViews.swift
