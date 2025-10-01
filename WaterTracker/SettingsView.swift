//
//  SettingsView.swift
//  WaterTracker
//
//  Created by Jackson  on 10/09/2025.
//

import SwiftUI
import UIKit
import SwiftData
import HealthKit
import HealthKitUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var portions: [WaterPortion]
    @EnvironmentObject private var healthKitService: HealthKitService
    @State private var isConvertingUnits: Bool = false
    @State private var showingHealthKitAlert = false
    @State private var healthKitAlertMessage = ""
    @State private var isRequestingHealthKitPermission = false
    @AppStorage("water_goal_ml") private var waterGoalMl: Int = 2500
    @AppStorage("measurement_units") private var measurementUnitsString: String = "ml" // "ml" or "fl_oz"

    private var measurementUnits: WaterUnit {
        get { WaterUnit.fromString(measurementUnitsString) }
        set { measurementUnitsString = newValue == .ounces ? "fl_oz" : "ml" }
    }

    private var measurementUnitsBinding: Binding<WaterUnit> {
        Binding(
            get: { WaterUnit.fromString(measurementUnitsString) },
            set: { measurementUnitsString = $0 == .ounces ? "fl_oz" : "ml" }
        )
    }
    @AppStorage("app_language") private var appLanguage: String = Locale.current.language.languageCode?.identifier ?? "en"

    private let privacyPolicyURL = URL(string: "https://example.com/privacy")!
    private let termsOfUseURL = URL(string: "https://example.com/terms")!

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                hydrationSettingsCard
                healthKitCard
                generalSettingsCard
                aboutCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 30)
        }
        .navigationTitle("Settings")
        .alert("HealthKit", isPresented: $showingHealthKitAlert) {
            Button("OK") { }
        } message: {
            Text(healthKitAlertMessage)
        }
        .overlay {
            if isConvertingUnits {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Recalculating saved portions…")
                            .foregroundStyle(.white)
                            .font(.headline)
                    }
                    .padding(24)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray6)))
                    .padding(32)
                }
                .transition(.opacity)
            }
        }
        .healthDataAccessRequest(
            store: healthKitService.healthStore,
            readTypes: healthKitService.healthKitTypes,
            trigger: isRequestingHealthKitPermission
        ) { result in
            handleHealthKitPermissionResult(result)
        }
    }

    // MARK: - UI Components

    private var hydrationSettingsCard: some View {
        VStack(spacing: 12) {
            hydrationCardHeader

            VStack(spacing: 20) {
                dailyGoalSection

                Divider()
                    .background(.blue.opacity(0.2))

                measurementUnitsSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .blue.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }

    private var hydrationCardHeader: some View {
        HStack {
            Image(systemName: "drop.fill")
                .foregroundStyle(.white)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("Hydration Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                Text("Customize your daily water goals")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    private var dailyGoalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    Image(systemName: "target")
                        .foregroundStyle(.blue)
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 20, height: 20)
                    Text("Daily Goal")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
                Spacer()
                Text(goalDisplay)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }

            VStack(spacing: 8) {
                Slider(value: Binding(
                    get: { Double(waterGoalMl) },
                    set: { waterGoalMl = Int($0) }
                ), in: 1000...6000, step: 50)
                .tint(.blue)

                HStack {
                    Text("1000 ml")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("6000 ml")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var measurementUnitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "ruler")
                    .foregroundStyle(.blue)
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 20, height: 20)
                Text("Measurement Units")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }

            Picker("Units", selection: measurementUnitsBinding) {
                ForEach(WaterUnit.allCases, id: \.self) { unit in
                    Text(unit.displayName).tag(unit)
                }
            }
            .pickerStyle(.segmented)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.blue.opacity(0.05))
            )
            .onChange(of: measurementUnits) { oldValue, newValue in
                convertAllPortions(from: oldValue, to: newValue)
                NotificationsManager.shared.registerCategories()
            }
        }
    }

    private var healthKitCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.white)
                    .font(.title2)
                    .frame(width: 40, height: 40)
                    .background(
                        LinearGradient(
                            colors: [.red, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Health & Data")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    Text("Connect with HealthKit")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            VStack(spacing: 16) {
                Button {
                    isRequestingHealthKitPermission = true
                } label: {
                    HStack {
                        Image(systemName: "heart.text.square")
                            .foregroundStyle(.white)
                            .font(.system(size: 16))
                        Text("Request HealthKit Access")
                            .foregroundStyle(.white)
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.red, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Text("Grant HealthKit permission to get personalized hydration recommendations based on your health data.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .red.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .healthDataAccessRequest(
            store: healthKitService.healthStore,
            readTypes: healthKitService.healthKitTypes,
            trigger: isRequestingHealthKitPermission
        ) { result in
            handleHealthKitPermissionResult(result)
        }
    }


    private var generalSettingsCard: some View {
        VStack(spacing: 16) {
            generalCardHeader

            VStack(spacing: 12) {
                SettingsButton(
                    title: "Change Language",
                    subtitle: "System Settings",
                    icon: "globe",
                    iconColor: .blue,
                    action: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                )

                SettingsButton(
                    title: "Rate Us",
                    subtitle: "Help us improve",
                    icon: "star.fill",
                    iconColor: .yellow,
                    action: {
                        WaterTrackerApp.requestReview()
                    }
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .gray.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }

    private var generalCardHeader: some View {
        HStack {
            Image(systemName: "gearshape.fill")
                .foregroundStyle(.white)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(
                    LinearGradient(
                        colors: [.gray, .secondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("General")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                Text("App preferences")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    private var aboutCard: some View {
        VStack(spacing: 16) {
            aboutCardHeader

            VStack(spacing: 12) {
                SettingsButton(
                    title: "Privacy Policy",
                    subtitle: "How we protect your data",
                    icon: "hand.raised.fill",
                    iconColor: .green,
                    action: {
                        UIApplication.shared.open(privacyPolicyURL)
                    }
                )

                SettingsButton(
                    title: "Terms of Service",
                    subtitle: "App terms and conditions",
                    icon: "text.document.fill",
                    iconColor: .orange,
                    action: {
                        UIApplication.shared.open(termsOfUseURL)
                    }
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .purple.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }

    private var aboutCardHeader: some View {
        HStack {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.white)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("About")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                Text("Legal information")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    // MARK: - Helper Methods

    private var goalDisplay: String {
        switch measurementUnits {
        case .ounces:
            let oz = Double(waterGoalMl) / 29.5735
            return "\(Int(oz.rounded())) fl oz"
        case .millilitres:
            return "\(waterGoalMl) ml"
        }
    }

    private func convertAllPortions(from old: WaterUnit, to new: WaterUnit) {
        guard old != new else { return }
        isConvertingUnits = true
        // Perform on main actor to keep SwiftData context safe
        Task { @MainActor in
            for portion in portions {
                if portion.unit == old {
                    portion.amount = old.convertTo(new, amount: portion.amount)
                    portion.unit = new
                }
            }
            try? modelContext.save()
            isConvertingUnits = false
        }
    }

    private func handleHealthKitPermissionResult(_ result: Result<Bool, Error>) {
        isRequestingHealthKitPermission = false
        
        switch result {
        case .success:
            healthKitAlertMessage = "HealthKit access granted. Your health data can now be used for personalized hydration recommendations."
        case .failure(let error):
            healthKitAlertMessage = "Failed to access HealthKit: \(error.localizedDescription)"
        }
        showingHealthKitAlert = true
    }
}

// MARK: - Custom Components

struct HealthDataItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 20, height: 20)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            HStack {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.15), lineWidth: 0.5)
                )
        )
    }
}

struct SettingsButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: icon)
                    .foregroundStyle(.white)
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(iconColor)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.secondary.opacity(0.1), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WaterPortion.self, configurations: config)

    return NavigationStack {
        SettingsView()
            .modelContainer(container)
            .environmentObject(HealthKitService())
    }
}

