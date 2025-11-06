//
//  HealthKitDataConfirmationView.swift
//  WaterTracker
//
//  Created by Assistant on 29/09/2025.
//

import SwiftUI
import HealthKit

struct HealthKitDataConfirmationView: View {
    let onContinue: () -> Void
    let userHeight: Double?
    let userWeight: Double?
    let userAge: Int?
    let userGender: HKBiologicalSex?
    let averageSleepHours: Double?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Header Section
                VStack(spacing: 16) {
                    // Success Icon with gradient background
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.green.opacity(0.1), .mint.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    VStack(spacing: 12) {
                        Text("Health Data Retrieved")
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)

                        Text("We've retrieved your health information from the Health app. You can review and modify these values in the next step.")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 16)

                // Data Summary Cards
                VStack(spacing: 16) {
                    Text("Your Health Information")
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 12) {
                        if let height = userHeight {
                            HealthDataCard(
                                icon: "ruler.fill",
                                title: String(localized: "Height"),
                                value: String(localized: "\(Int(height * 100)) cm"),
                                gradientColors: [.red.opacity(0.1), .orange.opacity(0.1)]
                            )
                        }

                        if let weight = userWeight {
                            HealthDataCard(
                                icon: "scalemass.fill",
                                title: String(localized: "Weight"),
                                value: String(localized: "\(Int(weight)) kg"),
                                gradientColors: [.pink.opacity(0.1), .purple.opacity(0.1)]
                            )
                        }

                        if let age = userAge {
                            HealthDataCard(
                                icon: "calendar.circle.fill",
                                title: String(localized: "Age"),
                                value: String(localized: "\(age) years"),
                                gradientColors: [.purple.opacity(0.1), .blue.opacity(0.1)]
                            )
                        }

                        if let gender = userGender {
                            HealthDataCard(
                                icon: "person.circle.fill",
                                title: String(localized: "Gender"),
                                value: gender.stringValue.capitalized,
                                gradientColors: [.blue.opacity(0.1), .cyan.opacity(0.1)]
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .safeAreaInset(edge: .bottom, content: {
            // Action Button
            PrimaryButton(
                title: String(localized: "Review & Continue"),
                systemImage: "arrow.right.circle.fill",
                colors: [.green, .mint],
                action: onContinue
            )
            .padding(.horizontal, 24)
        })
        .background(
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemBackground).opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

struct HealthDataCard: View {
    let icon: String
    let title: String
    let value: String
    let gradientColors: [Color]
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon with gradient background
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
                
                Text(value)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.quaternary, lineWidth: 0.5)
                )
        )
    }
}

#Preview {
    HealthKitDataConfirmationView(
        onContinue: {
            print("Continue tapped")
        },
        userHeight: 1.75,
        userWeight: 70.0,
        userAge: 25,
        userGender: .male,
        averageSleepHours: 8.0
    )
}
