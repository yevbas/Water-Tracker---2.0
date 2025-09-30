//
//  SettingsView.swift
//  WaterTracker
//
//  Created by Jackson  on 10/09/2025.
//

import SwiftUI
import UIKit
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var portions: [WaterPortion]
    @Query private var healthProfiles: [UserHealthProfile]
    @EnvironmentObject private var healthKitService: HealthKitService
    @State private var isConvertingUnits: Bool = false
    @State private var showingHealthKitAlert = false
    @State private var healthKitAlertMessage = ""
    @State private var showingRecalculateAlert = false
    @State private var hasMetricsChanged = false
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
            List {
                Section("Hydration") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Daily goal", systemImage: "drop.fill")
                                .foregroundStyle(.blue)
                            Spacer()
                            Text(goalDisplay)
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: Binding(
                            get: { Double(waterGoalMl) },
                            set: { waterGoalMl = Int($0) }
                        ), in: 1000...6000, step: 50)
                        .tint(.blue)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Measurement units", systemImage: "ruler")
                            .foregroundStyle(.blue)
                        Picker("Units", selection: measurementUnitsBinding) {
                            ForEach(WaterUnit.allCases, id: \.self) { unit in
                                Text(unit.displayName).tag(unit)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: measurementUnits) { oldValue, newValue in
                            convertAllPortions(from: oldValue, to: newValue)
                            NotificationsManager.shared.registerCategories()
                        }
                    }
                }

                Section("Health & Data") {
                    Toggle(isOn: Binding(
                        get: { healthKitService.isHealthKitEnabled() },
                        set: { isEnabled in
                            if isEnabled {
                                enableHealthKit()
                            } else {
                                disableHealthKit()
                            }
                        }
                    )) {
                        Label("HealthKit Integration", systemImage: "heart.fill")
                            .foregroundStyle(.blue)
                    }
                    
                    if healthKitService.isHealthKitEnabled() {
                        Button {
                            refreshHealthData()
                        } label: {
                            Label("Refresh Health Data", systemImage: "arrow.clockwise")
                        }
                        .foregroundStyle(.blue)
                        
                        if let profile = healthProfiles.first, profile.isDataComplete {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Health Data", systemImage: "person.crop.circle")
                                    .foregroundStyle(.blue)
                                
                                HStack {
                                    Text("Height:")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    if let height = profile.heightInCm {
                                        Text("\(height) cm")
                                            .foregroundStyle(.primary)
                                    }
                                }
                                
                                HStack {
                                    Text("Weight:")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    if let weight = profile.weightInKg {
                                        Text("\(weight) kg")
                                            .foregroundStyle(.primary)
                                    }
                                }
                                
                                HStack {
                                    Text("Age:")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    if let age = profile.age {
                                        Text("\(age) years")
                                            .foregroundStyle(.primary)
                                    }
                                }
                                
                                if let sleepHours = profile.averageSleepHours {
                                    HStack {
                                        Text("Avg Sleep:")
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text("\(String(format: "%.1f", sleepHours)) hours")
                                            .foregroundStyle(.primary)
                                    }
                                }
                            }
                            .font(.caption)
                            .padding(.vertical, 4)
                        }
                        
                        // Re-calculate button if metrics have changed
                        if hasMetricsChanged {
                            Button {
                                showingRecalculateAlert = true
                            } label: {
                                Label("Re-calculate Water Amount", systemImage: "arrow.triangle.2.circlepath")
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }

                Section("General") {
                    Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                        Label("Change language", systemImage: "globe")
                    }
                    .foregroundStyle(.blue)
                    Button {
                        WaterTrackerApp.requestReview()
                    } label: {
                        Label("Rate us", systemImage: "star.fill")
                    }
                    .foregroundStyle(.blue)
                }

                Section("About") {
                    Link(destination: privacyPolicyURL) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }
                    .foregroundStyle(.blue)
                    Link(destination: termsOfUseURL) {
                        Label("Terms of Service", systemImage: "text.document.fill")
                    }
                    .foregroundStyle(.blue)
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                print("⚙️ Settings view appeared")
                healthKitService.setModelContext(modelContext)
                // Refresh HealthKit status first
                healthKitService.refreshHealthKitStatus()
                // Fetch fresh HealthKit data on every app launch
                if healthKitService.isHealthKitEnabled() {
                    print("⚙️ HealthKit is enabled, refreshing data")
                    healthKitService.refreshHealthData()
                } else {
                    print("⚙️ HealthKit is disabled")
                }
                // Check for changes after a brief delay to allow data fetching
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    checkForMetricChanges()
                }
            }
            // Note: Metric change detection temporarily disabled since we're not storing
            // HealthKit data in the service anymore. This could be re-implemented if needed.
            .alert("HealthKit", isPresented: $showingHealthKitAlert) {
                Button("OK") { }
            } message: {
                Text(healthKitAlertMessage)
            }
            .alert("Re-calculate Water Amount", isPresented: $showingRecalculateAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Re-calculate") {
                    recalculateWaterAmount()
                }
            } message: {
                Text("Your health metrics have changed. Would you like to re-calculate your daily water goal based on your updated health data?")
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
    }

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
    
    private func enableHealthKit() {
        // Always request permission when enabling HealthKit to show the native permission window
        healthKitService.requestPermission { success, error in
            DispatchQueue.main.async {
                if success {
                    healthKitService.enableHealthKit()
                    healthKitService.refreshHealthData()
                    healthKitAlertMessage = "HealthKit integration enabled. Your health data will be used to provide personalized hydration recommendations."
                } else {
                    healthKitAlertMessage = "Failed to enable HealthKit integration. Please check your Health app permissions."
                }
                showingHealthKitAlert = true
            }
        }
    }
    
    private func disableHealthKit() {
        healthKitService.disableHealthKit()
        healthKitAlertMessage = "HealthKit integration disabled. You can re-enable it anytime in settings."
        showingHealthKitAlert = true
    }
    
    private func refreshHealthData() {
        if healthKitService.isAuthorized() {
            healthKitService.refreshHealthData()
            healthKitAlertMessage = "Health data refreshed successfully."
            showingHealthKitAlert = true
        } else {
            healthKitAlertMessage = "HealthKit permission required. Please enable HealthKit integration first."
            showingHealthKitAlert = true
        }
    }
    
    private func checkForMetricChanges() {
        // For now, we'll disable the metric change detection since we're not storing
        // HealthKit data in the service anymore. This could be re-implemented by
        // fetching fresh data and comparing with stored profile if needed.
        hasMetricsChanged = false
    }
    
    private func recalculateWaterAmount() {
        guard let profile = healthProfiles.first else { return }
        
        // Use profile's stored data for recalculation
        if let height = profile.height,
           let weight = profile.weight,
           let age = profile.age,
           let gender = profile.genderEnum {
            
            // Convert stored data to answers format for UserMetrics
            let heightCm = height * 100 // Convert meters to cm
            let answers: [String: MetricView.Answer] = [
                "gender": MetricView.Answer(value: gender.stringValue, title: gender.stringValue.capitalized),
                "height": MetricView.Answer(value: "\(Int(heightCm)) cm", title: "\(Int(heightCm)) cm"),
                "weight": MetricView.Answer(value: "\(Int(weight)) kg", title: "\(Int(weight)) kg"),
                "age": MetricView.Answer(value: "\(age) years", title: "\(age) years"),
                "activity-factor": MetricView.Answer(value: "moderate", title: "Moderate (3–5 days/week)"),
                "climate": MetricView.Answer(value: "temperate", title: "Temperate")
            ]
            
            guard let userMetrics = UserMetrics(answers: answers) else {
                healthKitAlertMessage = "Failed to create user metrics from health data."
                showingHealthKitAlert = true
                return
            }
            
            // Use the same WaterPlanner logic as onboarding
            let plan = WaterPlanner.plan(for: userMetrics, unit: measurementUnits)
            
            // Update the water goal
            waterGoalMl = plan.waterMl
            
            // Save changes
            do {
                try modelContext.save()
                hasMetricsChanged = false
                healthKitAlertMessage = "Water goal updated to \(waterGoalMl)ml based on your health data."
                showingHealthKitAlert = true
            } catch {
                healthKitAlertMessage = "Failed to save updated water goal. Please try again."
                showingHealthKitAlert = true
            }
        }
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
