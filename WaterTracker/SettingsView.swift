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
    @State private var isConvertingUnits: Bool = false
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
