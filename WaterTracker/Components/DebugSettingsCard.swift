//
//  DebugSettingsCard.swift
//  WaterTracker
//
//  Created by Jackson on 01/10/2025.
//

import SwiftUI
import SwiftData
import HealthKit

#if DEBUG
struct DebugSettingsCard: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var portions: [WaterPortion]
    @Query private var weatherAnalysisCache: [WeatherAnalysisCache]

    @EnvironmentObject private var healthKitService: HealthKitService

    @AppStorage("water_goal_ml") private var waterGoalMl: Int = 2500
    @AppStorage("measurement_units") private var measurementUnitsString: String = "ml"

    @State private var isGeneratingTestData = false
    @State private var isGeneratingHealthData = false
    @State private var isGeneratingSleepData = false
    @State private var showingDebugAlert = false
    @State private var debugAlertMessage = ""
    @State private var showingClearDataConfirmation = false
    
    @AppStorage("UseMockSleepData") private var useMockSleepData: Bool = false

    private var measurementUnits: WaterUnit {
        WaterUnit.fromString(measurementUnitsString)
    }

    var body: some View {
        VStack(spacing: 16) {
            debugCardHeader

            VStack(spacing: 12) {
                SettingsButton(
                    title: "Simulate Crash",
                    subtitle: "Test crash reporting",
                    icon: "exclamationmark.triangle.fill",
                    iconColor: .red,
                    action: {
                        simulateCrash()
                    }
                )

                SettingsButton(
                    title: "Generate 4 Months Data",
                    subtitle: "Create random test data",
                    icon: "chart.bar.fill",
                    iconColor: .blue,
                    action: {
                        generate4MonthsTestData()
                    }
                )

                SettingsButton(
                    title: "Generate Sample Health Data",
                    subtitle: "Height, weight & 30 days of sleep",
                    icon: "heart.text.square.fill",
                    iconColor: .pink,
                    action: {
                        generateSampleHealthData()
                    }
                )

                SettingsButton(
                    title: "Add Today's Sleep Data",
                    subtitle: "Generate realistic sleep for today",
                    icon: "bed.double.fill",
                    iconColor: .purple,
                    action: {
                        generateTodaySleepData()
                    }
                )
                
                // Mock Sleep Data Toggle
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: "moon.zzz.fill")
                                .font(.title3)
                                .foregroundStyle(.orange)
                            
                            Text("Use Mock Sleep Data")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        Text("Enable when no real sleep data available")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $useMockSleepData)
                        .labelsHidden()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.quaternary, lineWidth: 0.5)
                        )
                )

                SettingsButton(
                    title: "Clear Sleep Data",
                    subtitle: "Remove all sleep samples from Health",
                    icon: "moon.zzz.fill",
                    iconColor: .indigo,
                    action: {
                        clearSleepData()
                    }
                )

                SettingsButton(
                    title: "Clear All Data",
                    subtitle: "Delete all water portions & cache",
                    icon: "trash.fill",
                    iconColor: .red,
                    action: {
                        showingClearDataConfirmation = true
                    }
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .orange.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .alert("Debug", isPresented: $showingDebugAlert) {
            Button("OK") { }
        } message: {
            Text(debugAlertMessage)
        }
        .alert("Clear All Data", isPresented: $showingClearDataConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("Are you sure you want to delete all water portions, health profiles, and cached data? This action cannot be undone.")
        }
        .overlay {
            if isGeneratingTestData || isGeneratingHealthData || isGeneratingSleepData {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                        Text(loadingMessage)
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

    private var loadingMessage: String {
        if isGeneratingTestData {
            return "Generating test data…"
        } else if isGeneratingHealthData {
            return "Generating health data…"
        } else if isGeneratingSleepData {
            return "Generating sleep data…"
        }
        return "Processing…"
    }

    private var debugCardHeader: some View {
        HStack {
            Image(systemName: "ladybug.fill")
                .foregroundStyle(.white)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("Debug Tools")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                Text("Development mode only")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    // MARK: - Debug Methods

    private func simulateCrash() {
        print("🔥 Simulating crash...")
        fatalError("Debug crash triggered by user")
    }

    private func generate4MonthsTestData() {
        isGeneratingTestData = true

        Task { @MainActor in
            let calendar = Calendar.current
            let endDate = Date()
            guard let startDate = calendar.date(byAdding: .month, value: -4, to: endDate) else {
                isGeneratingTestData = false
                return
            }

            var totalPortionsCreated = 0
            var currentDate = startDate

            // Available drinks for random selection
            let drinks = Drink.allCases

            // Generate data for each day
            while currentDate <= endDate {
                // Random number of drinks per day (3-8)
                let drinksPerDay = Int.random(in: 3...8)

                for _ in 0..<drinksPerDay {
                    // Random time during the day (6 AM to 11 PM)
                    let randomHour = Int.random(in: 6...23)
                    let randomMinute = Int.random(in: 0...59)

                    guard let drinkTime = calendar.date(
                        bySettingHour: randomHour,
                        minute: randomMinute,
                        second: 0,
                        of: currentDate
                    ) else { continue }

                    // Random amount based on current goal (between 10% and 40% of daily goal)
                    let minAmount = Double(waterGoalMl) * 0.10
                    let maxAmount = Double(waterGoalMl) * 0.40
                    let randomAmount = Double.random(in: minAmount...maxAmount).rounded()

                    // Random drink type
                    let randomDrink = drinks.randomElement() ?? .water

                    // Create the water portion
                    let portion = WaterPortion(
                        amount: randomAmount,
                        unit: measurementUnits,
                        drink: randomDrink,
                        createDate: drinkTime,
                        dayDate: drinkTime.rounded()
                    )

                    modelContext.insert(portion)
                    totalPortionsCreated += 1
                }

                // Move to next day
                guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                    break
                }
                currentDate = nextDay
            }

            // Save all changes
            do {
                try modelContext.save()
                isGeneratingTestData = false
                debugAlertMessage = "Successfully generated \(totalPortionsCreated) water portions across 4 months!"
                showingDebugAlert = true
                print("✅ Debug: Generated \(totalPortionsCreated) test portions")
            } catch {
                isGeneratingTestData = false
                debugAlertMessage = "Failed to generate test data: \(error.localizedDescription)"
                showingDebugAlert = true
                print("❌ Debug: Failed to generate test data - \(error)")
            }
        }
    }

    private func generateSampleHealthData() {
        guard HKHealthStore.isHealthDataAvailable() else {
            debugAlertMessage = "HealthKit is not available on this device."
            showingDebugAlert = true
            return
        }

        // HealthKit data is fetched directly when needed - no need to check availability

        isGeneratingHealthData = true

        Task { @MainActor in
            let healthStore = healthKitService.healthStore
            var samplesCreated = 0

            do {
                // 1. Generate Height (170-185 cm)
                let heightValue = Double.random(in: 170...185)
                let heightQuantity = HKQuantity(unit: HKUnit.meterUnit(with: .centi), doubleValue: heightValue)
                let heightSample = HKQuantitySample(
                    type: HKQuantityType(.height),
                    quantity: heightQuantity,
                    start: Date(),
                    end: Date()
                )
                try await healthStore.save(heightSample)
                samplesCreated += 1
                print("✅ Debug: Created height sample - \(heightValue) cm")

                // 2. Generate Weight (60-90 kg)
                let weightValue = Double.random(in: 60...90)
                let weightQuantity = HKQuantity(unit: HKUnit.gramUnit(with: .kilo), doubleValue: weightValue)
                let weightSample = HKQuantitySample(
                    type: HKQuantityType(.bodyMass),
                    quantity: weightQuantity,
                    start: Date(),
                    end: Date()
                )
                try await healthStore.save(weightSample)
                samplesCreated += 1
                print("✅ Debug: Created weight sample - \(weightValue) kg")

                // 3. Generate Sleep Data for the last 30 days
                let calendar = Calendar.current
                let endDate = Date()
                guard let startDate = calendar.date(byAdding: .day, value: -30, to: endDate) else {
                    throw NSError(domain: "DebugError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to calculate date range"])
                }

                var currentDate = startDate
                var sleepSamplesCreated = 0

                while currentDate <= endDate {
                    // Generate sleep for each night (6-9 hours)
                    let sleepHours = Double.random(in: 6.0...9.0)

                    // Sleep start time: 10 PM to midnight
                    let sleepStartHour = Int.random(in: 22...23)
                    guard let sleepStart = calendar.date(
                        bySettingHour: sleepStartHour,
                        minute: Int.random(in: 0...59),
                        second: 0,
                        of: currentDate
                    ) else { continue }

                    let sleepEnd = sleepStart.addingTimeInterval(sleepHours * 3600)

                    // Create sleep sample
                    let sleepSample = HKCategorySample(
                        type: HKCategoryType(.sleepAnalysis),
                        value: HKCategoryValueSleepAnalysis.inBed.rawValue,
                        start: sleepStart,
                        end: sleepEnd
                    )

                    try await healthStore.save(sleepSample)
                    sleepSamplesCreated += 1

                    // Move to next day
                    guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                        break
                    }
                    currentDate = nextDay
                }

                samplesCreated += sleepSamplesCreated
                print("✅ Debug: Created \(sleepSamplesCreated) sleep samples")

                // Success
                isGeneratingHealthData = false
                debugAlertMessage = "Successfully generated \(samplesCreated) health samples:\n• Height\n• Weight\n• \(sleepSamplesCreated) sleep records (30 days)\n\nNote: Age/Date of Birth must be set manually in the Health app.\n\nTap 'Refresh Health Data' in Settings to sync."
                showingDebugAlert = true
                print("✅ Debug: Generated \(samplesCreated) health samples total")

            } catch {
                isGeneratingHealthData = false
                debugAlertMessage = "Failed to generate health data: \(error.localizedDescription)\n\nMake sure HealthKit permissions are granted."
                showingDebugAlert = true
                print("❌ Debug: Failed to generate health data - \(error)")
            }
        }
    }

    private func generateTodaySleepData() {
        guard HKHealthStore.isHealthDataAvailable() else {
            debugAlertMessage = "HealthKit is not available on this device."
            showingDebugAlert = true
            return
        }

        // HealthKit data is fetched directly when needed - no need to check availability

        isGeneratingSleepData = true

        Task { @MainActor in
            let healthStore = healthKitService.healthStore
            let calendar = Calendar.current

            do {
                // Generate sleep for last night (ending this morning)
                let now = Date()
                let today = calendar.startOfDay(for: now)

                // Sleep duration: 6.5 - 8.5 hours
                let sleepHours = Double.random(in: 6.5...8.5)
                let sleepSeconds = sleepHours * 3600

                // Wake time: 6 AM - 9 AM this morning
                let wakeHour = Int.random(in: 6...9)
                let wakeMinute = Int.random(in: 0...59)
                guard let wakeTime = calendar.date(bySettingHour: wakeHour, minute: wakeMinute, second: 0, of: today) else {
                    throw NSError(domain: "DebugError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to calculate wake time"])
                }

                let bedTime = wakeTime.addingTimeInterval(-sleepSeconds)

                print("🛏️ Debug: Generating sleep from \(bedTime) to \(wakeTime) (\(String(format: "%.1f", sleepHours))h)")

                // Create main "in bed" sample
                let inBedSample = HKCategorySample(
                    type: HKCategoryType(.sleepAnalysis),
                    value: HKCategoryValueSleepAnalysis.inBed.rawValue,
                    start: bedTime,
                    end: wakeTime
                )
                try await healthStore.save(inBedSample)

                // Generate realistic sleep stages
                var currentTime = bedTime
                var samplesCreated = 1

                // Sleep stages distribution (roughly realistic)
                // Light/Core: 50-60%, Deep: 15-20%, REM: 20-25%

                while currentTime < wakeTime {
                    let remainingTime = wakeTime.timeIntervalSince(currentTime)
                    if remainingTime <= 0 { break }

                    // Randomize stage duration (15-90 minutes)
                    let stageDuration = min(Double.random(in: 900...5400), remainingTime)
                    let stageEnd = currentTime.addingTimeInterval(stageDuration)

                    // Select sleep stage based on time of night
                    let sleepProgress = currentTime.timeIntervalSince(bedTime) / sleepSeconds
                    let stageValue: HKCategoryValueSleepAnalysis

                    if sleepProgress < 0.25 {
                        // Early sleep - more deep sleep
                        stageValue = Bool.random() ? .asleepDeep : .asleepCore
                    } else if sleepProgress < 0.5 {
                        // Middle sleep - mix of stages
                        stageValue = [.asleepCore, .asleepREM, .asleepDeep].randomElement()!
                    } else {
                        // Late sleep - more REM
                        stageValue = Bool.random() ? .asleepREM : .asleepCore
                    }

                    let stageSample = HKCategorySample(
                        type: HKCategoryType(.sleepAnalysis),
                        value: stageValue.rawValue,
                        start: currentTime,
                        end: stageEnd
                    )

                    try await healthStore.save(stageSample)
                    samplesCreated += 1
                    currentTime = stageEnd
                }

                isGeneratingSleepData = false
                debugAlertMessage = "Successfully generated today's sleep data:\n• \(String(format: "%.1f", sleepHours)) hours\n• Bedtime: \(formatTime(bedTime))\n• Wake: \(formatTime(wakeTime))\n• \(samplesCreated) sleep stages\n\nGo to Dashboard and tap 'Analyze Sleep Data'!"
                showingDebugAlert = true
                print("✅ Debug: Generated \(samplesCreated) sleep samples for today")

            } catch {
                isGeneratingSleepData = false
                debugAlertMessage = "Failed to generate sleep data: \(error.localizedDescription)\n\nMake sure HealthKit permissions are granted."
                showingDebugAlert = true
                print("❌ Debug: Failed to generate sleep data - \(error)")
            }
        }
    }

    private func clearSleepData() {
        guard HKHealthStore.isHealthDataAvailable() else {
            debugAlertMessage = "HealthKit is not available on this device."
            showingDebugAlert = true
            return
        }

        // HealthKit data is fetched directly when needed - no need to check availability

        isGeneratingSleepData = true

        Task { @MainActor in
            let healthStore = healthKitService.healthStore

            do {
                // Query all sleep samples
                let sleepType = HKCategoryType(.sleepAnalysis)

                // Get samples from the past year
                let calendar = Calendar.current
                let endDate = Date()
                guard let startDate = calendar.date(byAdding: .year, value: -1, to: endDate) else {
                    throw NSError(domain: "DebugError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to calculate date range"])
                }

                let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

                return await withCheckedContinuation { continuation in
                    let query = HKSampleQuery(
                        sampleType: sleepType,
                        predicate: predicate,
                        limit: HKObjectQueryNoLimit,
                        sortDescriptors: nil
                    ) { _, samples, error in
                        Task { @MainActor in
                            if let error = error {
                                self.isGeneratingSleepData = false
                                self.debugAlertMessage = "Failed to fetch sleep data: \(error.localizedDescription)"
                                self.showingDebugAlert = true
                                print("❌ Debug: Failed to fetch sleep data - \(error)")
                                continuation.resume()
                                return
                            }

                            guard let sleepSamples = samples, !sleepSamples.isEmpty else {
                                self.isGeneratingSleepData = false
                                self.debugAlertMessage = "No sleep data found in HealthKit."
                                self.showingDebugAlert = true
                                print("⚠️ Debug: No sleep samples to delete")
                                continuation.resume()
                                return
                            }

                            print("🗑️ Debug: Found \(sleepSamples.count) sleep samples to delete")

                            // Delete all samples
                            do {
                                try await healthStore.delete(sleepSamples)

                                self.isGeneratingSleepData = false
                                self.debugAlertMessage = "Successfully deleted \(sleepSamples.count) sleep samples from HealthKit!"
                                self.showingDebugAlert = true
                                print("✅ Debug: Deleted \(sleepSamples.count) sleep samples")
                            } catch {
                                self.isGeneratingSleepData = false
                                self.debugAlertMessage = "Failed to delete sleep data: \(error.localizedDescription)"
                                self.showingDebugAlert = true
                                print("❌ Debug: Failed to delete sleep samples - \(error)")
                            }

                            continuation.resume()
                        }
                    }

                    healthStore.execute(query)
                }
            } catch {
                isGeneratingSleepData = false
                debugAlertMessage = "Failed to clear sleep data: \(error.localizedDescription)"
                showingDebugAlert = true
                print("❌ Debug: Failed to clear sleep data - \(error)")
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func clearAllData() {
        Task { @MainActor in
            do {
                var deletedCount = 0

                // Fetch and delete all water portions
                let portionDescriptor = FetchDescriptor<WaterPortion>()
                let allPortions = try modelContext.fetch(portionDescriptor)
                for portion in allPortions {
                    modelContext.delete(portion)
                    deletedCount += 1
                }


                // Sleep analysis cache was removed - data is fetched directly from HealthKit

                // Fetch and delete all weather analysis cache
                let weatherDescriptor = FetchDescriptor<WeatherAnalysisCache>()
                let allWeatherCache = try modelContext.fetch(weatherDescriptor)
                for cache in allWeatherCache {
                    modelContext.delete(cache)
                }

                // Save changes
                try modelContext.save()

                debugAlertMessage = "Successfully deleted \(deletedCount) water portions and all cached data!"
                showingDebugAlert = true
                print("✅ Debug: Cleared all data - \(deletedCount) portions deleted")
            } catch {
                debugAlertMessage = "Failed to clear data: \(error.localizedDescription)"
                showingDebugAlert = true
                print("❌ Debug: Failed to clear data - \(error)")
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WaterPortion.self, WeatherAnalysisCache.self, configurations: config)
    
    return DebugSettingsCard()
        .modelContainer(container)
        .environmentObject(HealthKitService())
}
#endif

