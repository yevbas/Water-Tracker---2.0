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
                    title: "Height",
                    value: "\(Int(height * 100)) cm",
                    color: .blue
                )
            }

            if let weight = healthData?.weight {
                DataItemView(
                    icon: "scalemass",
                    title: "Weight",
                    value: "\(Int(weight)) kg",
                    color: .green
                )
            }

            if let age = healthData?.age {
                DataItemView(
                    icon: "calendar",
                    title: "Age",
                    value: "\(age) years",
                    color: .orange
                )
            }

            if let gender = healthData?.gender {
                let genderText: String = {
                    switch gender {
                    case .male:
                        return "Male"
                    case .female:
                        return "Female"
                    case .other:
                        return "Other"
                    case .notSet:
                        return "Not Set"
                    @unknown default:
                        return "Unknown"
                    }
                }()

                DataItemView(
                    icon: "person",
                    title: "Gender",
                    value: genderText,
                    color: .purple
                )
            }

            if let sleepHours = healthData?.averageSleepHours {
                DataItemView(
                    icon: "bed.double",
                    title: "Avg Sleep",
                    value: String(format: "%.1f hrs", sleepHours),
                    color: .indigo
                 )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// DataItemView is defined in HealthKitSharedViews.swift
