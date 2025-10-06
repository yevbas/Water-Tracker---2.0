//
//  EnableHealthKitTutorialView.swift
//  WaterTracker
//
//  Created by Jackson  on 10/09/2025.
//

import SwiftUI
import HealthKit

struct EnableHealthKitTutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var healthKitService: HealthKitService
    @State private var isRequestingPermission = false
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 20) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.red, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .red.opacity(0.3), radius: 20, x: 0, y: 10)

                    VStack(spacing: 12) {
                        Text("Enable Health Sync")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)

                        Text("Connect with HealthKit to get personalized hydration recommendations")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 40)

                // Benefits section
                VStack(spacing: 24) {
                    Text("What you'll get:")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    VStack(spacing: 16) {
                        BenefitRowView(
                            icon: "person.fill",
                            title: String(localized: "Personalized Goals"),
                            description: String(localized: "Hydration targets based on your body weight and activity level")
                        )

                        BenefitRowView(
                            icon: "moon.fill",
                            title: String(localized: "Sleep Integration"),
                            description: String(localized: "Adjustments based on your sleep patterns and recovery needs")
                        )

                        BenefitRowView(
                            icon: "chart.line.uptrend.xyaxis",
                            title: String(localized: "Health Insights"),
                            description: String(localized: "Track how hydration affects your overall health metrics")
                        )

                        BenefitRowView(
                            icon: "bell.fill",
                            title: String(localized: "Smart Reminders"),
                            description: String(localized: "Intelligent notifications based on your daily routine")
                        )
                    }
                }
                .padding(.horizontal, 24)

                // Privacy section
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .font(.title2)
                            .foregroundStyle(.green)
                        Text("Your Privacy is Protected")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }

                    Text("We only read the health data we need for hydration recommendations. Your data stays on your device and is never shared with third parties.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.green.opacity(0.1))
                )
                .padding(.horizontal, 24)

                // Action buttons
                VStack(spacing: 16) {
                    Button {
                        requestHealthKitPermission()
                    } label: {
                        HStack {
                            if isRequestingPermission {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            } else {
                                Image(systemName: "heart.text.square")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            Text(isRequestingPermission ? "Requesting Access..." : "Enable Health Sync")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [.red, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(isRequestingPermission)

                    Button {
                        dismiss()
                    } label: {
                        Text("Maybe Later")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Health Sync")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Close") {
                    dismiss()
                }
            }
        }
        .healthDataAccessRequest(
            store: healthKitService.healthStore,
            shareTypes: healthKitService.healthKitWriteTypes,
            readTypes: healthKitService.healthKitTypes,
            trigger: isRequestingPermission
        ) { result in
            handlePermissionResult(result)
        }
        .alert("HealthKit Access", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Helper Methods

    private func requestHealthKitPermission() {
        isRequestingPermission = true
    }

    private func handlePermissionResult(_ result: Result<Bool, Error>) {
        isRequestingPermission = false

        switch result {
        case .success:
            alertMessage = String(localized: "HealthKit access granted! Your health data can now be used for personalized hydration recommendations.")
            showingAlert = true
            // Dismiss after successful permission
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        case .failure(let error):
            alertMessage = String(localized: "Failed to access HealthKit: \(error.localizedDescription)")
            showingAlert = true
        }
    }
}

// MARK: - Benefit Row View

struct BenefitRowView: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(.blue.opacity(0.1))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.quaternary.opacity(0.3))
        )
    }
}

#Preview {
    EnableHealthKitTutorialView()
        .environmentObject(HealthKitService())
}
