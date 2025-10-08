//
//  SettingsView.swift
//  WaterTracker
//
//  Created by Jackson  on 10/09/2025.
//

import SwiftUI
import UIKit
import SwiftData
import RevenueCatUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var portions: [WaterPortion]
    @EnvironmentObject private var revenueCatMonitor: RevenueCatMonitor
    @State private var isConvertingUnits: Bool = false
    @State private var isPresentedPaywall = false
    @AppStorage("water_goal_ml") private var waterGoalMl: Int = 2500
    @AppStorage("measurement_units") private var measurementUnitsString: String = "ml" // "ml" or "fl_oz"
    @AppStorage("show_weather_card") private var showWeatherCard: Bool = true
    @AppStorage("show_sleep_card") private var showSleepCard: Bool = true
    @AppStorage("show_statistics_card") private var showStatisticsCard: Bool = true

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

    private let privacyPolicyURL = URL(string: "https://sites.google.com/view/aquioapp/privacy-policy")!
    private let termsOfUseURL = URL(string: "https://sites.google.com/view/aquioapp/terms-conditions")!

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if !revenueCatMonitor.userHasFullAccess {
                    unlockFullAccessCard
                }
                hydrationSettingsCard
                dashboardSettingsCard
                HealthKitCard()
                TutorialSettingsCard()
                generalSettingsCard
                aboutCard
                #if DEBUG
                DebugSettingsCard()
                #endif
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 30)
        }
//        .navigationTitle("Settings")
        .overlay {
            if isConvertingUnits {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Recalculating saved portions...")
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
        .sheet(isPresented: $isPresentedPaywall) {
            PaywallView()
        }
    }

    // MARK: - UI Components

    private var unlockFullAccessCard: some View {
        VStack(spacing: 16) {
            unlockFullAccessHeader
            
            VStack(spacing: 16) {
                unlockFeaturesList
                
                Divider()
                    .background(.purple.opacity(0.2))
                
                unlockActionButton
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [.purple.opacity(0.3), .pink.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .purple.opacity(0.15), radius: 15, x: 0, y: 8)
        )
    }
    
    private var unlockFullAccessHeader: some View {
        HStack {
            Image(systemName: "crown.fill")
                .foregroundStyle(.white)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Unlock Full Access")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                Text("Get premium features")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "sparkles")
                .foregroundStyle(.purple)
                .font(.title3)
                .symbolEffect(.pulse)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var unlockFeaturesList: some View {
        VStack(spacing: 12) {
            UnlockFeatureRow(
                icon: "xmark.circle.fill",
                title: String(localized: "Remove Ads"),
                description: String(localized: "Enjoy an ad-free experience with full access")
            )
            
            UnlockFeatureRow(
                icon: "cloud.sun.fill",
                title: String(localized: "Weather Insights"),
                description: String(localized: "Get hydration recommendations based on weather conditions")
            )
            
            UnlockFeatureRow(
                icon: "moon.fill",
                title: String(localized: "Sleep Analysis"),
                description: String(localized: "Track how hydration affects your sleep quality")
            )
            
            UnlockFeatureRow(
                icon: "chart.bar.fill",
                title: String(localized: "Advanced Statistics"),
                description: String(localized: "View detailed analytics and weekly trends")
            )
            
            UnlockFeatureRow(
                icon: "drop.triangle.fill",
                title: String(localized: "All Drink Types"),
                description: String(localized: "Track coffee, tea, juice, and other beverages")
            )
        }
    }
    
    private var unlockActionButton: some View {
        Button(action: {
            isPresentedPaywall = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 16, weight: .semibold))
                
                Text("Unlock Full Access")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [.purple, .pink],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }

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

    private var dashboardSettingsCard: some View {
        VStack(spacing: 12) {
            dashboardCardHeader

            VStack(spacing: 20) {
                weatherCardToggleSection
                
                Divider()
                    .background(.green.opacity(0.2))
                
                sleepCardToggleSection
                
                Divider()
                    .background(.green.opacity(0.2))
                
                statisticsCardToggleSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .green.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }

    private var dashboardCardHeader: some View {
        HStack {
            Image(systemName: "square.grid.2x2.fill")
                .foregroundStyle(.white)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(
                    LinearGradient(
                        colors: [.green, .mint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("Dashboard Components")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                Text("Control card visibility")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    private var weatherCardToggleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    Image(systemName: "cloud.sun.fill")
                        .foregroundStyle(.green)
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 20, height: 20)
                    Text("Weather Card")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
                Spacer()
                Toggle("", isOn: $showWeatherCard)
                    .toggleStyle(SwitchToggleStyle(tint: .green))
            }
            
            Text("Shows weather conditions and hydration recommendations")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var sleepCardToggleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    Image(systemName: "moon.fill")
                        .foregroundStyle(.green)
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 20, height: 20)
                    Text("Sleep Card")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
                Spacer()
                Toggle("", isOn: $showSleepCard)
                    .toggleStyle(SwitchToggleStyle(tint: .green))
            }
            
            Text("Shows sleep analysis and hydration insights")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var statisticsCardToggleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(.green)
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 20, height: 20)
                    Text("Statistics Card")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
                Spacer()
                Toggle("", isOn: $showStatisticsCard)
                    .toggleStyle(SwitchToggleStyle(tint: .green))
            }
            
            Text("Shows weekly trends and detailed analytics")
                .font(.caption)
                .foregroundStyle(.secondary)
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
                    title: String(localized: "Rate Us"),
                    subtitle: String(localized: "Help us improve"),
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
                    title: String(localized: "Privacy Policy"),
                    subtitle: String(localized: "How we protect your data"),
                    icon: "hand.raised.fill",
                    iconColor: .green,
                    action: {
                        UIApplication.shared.open(privacyPolicyURL)
                    }
                )

                SettingsButton(
                    title: String(localized: "Terms of Service"),
                    subtitle: String(localized: "App terms and conditions"),
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
            let oz = WaterUnit.ounces.fromMilliliters(Double(waterGoalMl))
            return String(localized: "\(Int(oz.rounded())) fl oz")
        case .millilitres:
            return String(localized: "\(waterGoalMl) ml")
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

struct UnlockFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.purple)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.purple.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.purple.opacity(0.1), lineWidth: 0.5)
                )
        )
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
    }
}

