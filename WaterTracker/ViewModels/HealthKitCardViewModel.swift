//
//  HealthKitCardViewModel.swift
//  WaterTracker
//
//  Created by Claude Code
//

import SwiftUI
import HealthKit
import SwiftData

@MainActor
class HealthKitCardViewModel: ObservableObject {
    // MARK: - Dependencies
    private let healthKitService: HealthKitService
    private let modelContext: ModelContext

    // MARK: - Published State: Loading & Data
    @Published var isLoading = true
    @Published var healthDataAvailable = false
    @Published var healthData: HealthKitData?

    // MARK: - Published State: Actions
    @Published var isRefreshing = false
    @Published var isCalculatingWaterIntake = false
    @Published var isSyncing = false
    @Published var syncProgress: Double = 0.0

    // MARK: - Published State: Permissions
    @Published var hasWritePermissions = false
    @Published var hasWaterWritePermission = false
    @Published var hasCaffeineWritePermission = false
    @Published var hasAlcoholWritePermission = false

    // MARK: - Published State: UI & Navigation
    @Published var showingEnableTutorial = false
    @Published var showingDisableTutorial = false
    @Published var showingCalculationResult = false
    @Published var calculatedWaterGoal: Int?
    @Published var showingSyncResult = false
    @Published var syncResult: (success: Int, failed: Int, total: Int)?

    // MARK: - Published State: Sync Settings
    @Published var syncWater: Bool
    @Published var syncCaffeine: Bool
    @Published var syncAlcohol: Bool

    // MARK: - Computed Properties

    var availableDataCount: Int {
        guard let data = healthData else { return 0 }
        var count = 0
        if data.height != nil { count += 1 }
        if data.weight != nil { count += 1 }
        if data.age != nil { count += 1 }
        if data.gender != nil { count += 1 }
        if data.averageSleepHours != nil { count += 1 }
        return count
    }

    var connectionStatusText: String {
        if !healthDataAvailable {
            return "Connect HealthKit services"
        }
        let total = 5 // height, weight, age, gender, sleep
        if availableDataCount == total {
            return "All HealthKit services connected"
        } else {
            return "\(availableDataCount) of \(total) HealthKit services connected"
        }
    }

    var isPartiallyConnected: Bool {
        healthDataAvailable && availableDataCount < 5
    }

    var canCalculateWaterIntake: Bool {
        guard let data = healthData else { return false }
        return data.height != nil && data.weight != nil && data.age != nil && data.gender != nil
    }

    var hasAnySyncPermissions: Bool {
        hasWaterWritePermission || hasCaffeineWritePermission || hasAlcoholWritePermission
    }

    var isPerformingAction: Bool {
        isRefreshing || isCalculatingWaterIntake || isSyncing
    }

    // MARK: - Initialization

    init(healthKitService: HealthKitService, modelContext: ModelContext) {
        self.healthKitService = healthKitService
        self.modelContext = modelContext

        // Initialize sync settings from UserDefaults
        self.syncWater = UserDefaults.standard.bool(forKey: "healthkit_sync_water")
        self.syncCaffeine = UserDefaults.standard.bool(forKey: "healthkit_sync_caffeine")
        self.syncAlcohol = UserDefaults.standard.bool(forKey: "healthkit_sync_alcohol")
    }

    // MARK: - Data Fetching

    func fetchHealthData() {
        print("🔍 Starting fetchHealthData...")
        isLoading = true
        Task {
            print("🔍 Attempting to fetch health data...")
            let data = await healthKitService.fetchAllHealthData()
            print("📊 Health data fetched: height=\(data.height != nil), weight=\(data.weight != nil), age=\(data.age != nil), gender=\(data.gender != nil), sleep=\(data.averageSleepHours != nil)")

            self.healthData = data
            // Consider health data available if we have ANY data (not all)
            let hasAnyData = data.height != nil || data.weight != nil || data.age != nil || data.gender != nil || data.averageSleepHours != nil
            print("📊 Has any data (permissions granted): \(hasAnyData)")
            self.healthDataAvailable = hasAnyData
            self.isLoading = false
        }
    }

    // MARK: - Permissions

    func checkWritePermissions() {
        Task {
            let hasWrite = await healthKitService.checkHealthKitWritePermissions()
            let hasWater = await healthKitService.checkWaterWritePermission()
            let hasCaffeine = await healthKitService.checkCaffeineWritePermission()
            let hasAlcohol = await healthKitService.checkAlcoholWritePermission()

            self.hasWritePermissions = hasWrite
            self.hasWaterWritePermission = hasWater
            self.hasCaffeineWritePermission = hasCaffeine
            self.hasAlcoholWritePermission = hasAlcohol
        }
    }

    func requestHealthKitPermissions() {
        Task {
            print("🔐 Requesting HealthKit permissions...")
            let granted = await healthKitService.requestHealthKitPermissions()
            print("🔐 Permissions granted: \(granted)")
            if granted {
                print("✅ Permissions granted, fetching health data...")
                fetchHealthData()
            } else {
                print("❌ Permissions denied")
            }
        }
    }

    // MARK: - Data Refresh

    func refreshHealthData() {
        isRefreshing = true
        Task {
            // Request permissions again in case they were denied
            let granted = await healthKitService.requestHealthKitPermissions()
            if !granted {
                self.healthData = nil
                self.healthDataAvailable = false
                self.isRefreshing = false
                return
            }

            let data = await healthKitService.fetchAllHealthData()
            let hasWrite = await healthKitService.checkHealthKitWritePermissions()
            let hasWater = await healthKitService.checkWaterWritePermission()
            let hasCaffeine = await healthKitService.checkCaffeineWritePermission()
            let hasAlcohol = await healthKitService.checkAlcoholWritePermission()

            self.healthData = data
            self.healthDataAvailable = data.height != nil || data.weight != nil || data.age != nil || data.gender != nil || data.averageSleepHours != nil
            self.hasWritePermissions = hasWrite
            self.hasWaterWritePermission = hasWater
            self.hasCaffeineWritePermission = hasCaffeine
            self.hasAlcoholWritePermission = hasAlcohol
            self.isRefreshing = false
        }
    }

    // MARK: - Water Intake Calculation

    func calculateWaterIntake() {
        guard let data = healthData,
              let height = data.height,
              let weight = data.weight,
              let age = data.age,
              let gender = data.gender else {
            print("❌ Missing required health data for water intake calculation")
            return
        }

        isCalculatingWaterIntake = true

        Task {
            // Convert HealthKit data to UserMetrics format
            let heightCm = height * 100 // Convert meters to cm
            let weightKg = weight // Already in kg
            let ageYears = age

            // Convert HKBiologicalSex to Gender enum
            let genderString: String
            switch gender {
            case .male:
                genderString = "male"
            case .female:
                genderString = "female"
            case .other:
                genderString = "other"
            case .notSet:
                genderString = "other"
            @unknown default:
                genderString = "other"
            }

            // Create UserMetrics using the answers format that the initializer expects
            let answers: [String: MetricView.Answer] = [
                "gender": MetricView.Answer(value: genderString, title: genderString.capitalized),
                "height": MetricView.Answer(value: "\(Int(heightCm)) cm", title: "\(Int(heightCm)) cm"),
                "weight": MetricView.Answer(value: "\(Int(weightKg)) kg", title: "\(Int(weightKg)) kg"),
                "age": MetricView.Answer(value: "\(ageYears) years", title: "\(ageYears) years"),
                "activity-factor": MetricView.Answer(value: "Moderate (3–5 days/week)", title: "Moderate (3–5 days/week)"),
                "climate": MetricView.Answer(value: "temperate", title: "Temperate")
            ]

            guard let userMetrics = UserMetrics(answers: answers) else {
                self.isCalculatingWaterIntake = false
                print("❌ Failed to create UserMetrics from HealthKit data")
                return
            }

            // Calculate water intake using WaterPlanner
            let plan = WaterPlanner.plan(for: userMetrics)

            self.calculatedWaterGoal = plan.waterMl
            self.isCalculatingWaterIntake = false
            self.showingCalculationResult = true
            print("✅ Water intake calculated: \(plan.waterMl) ml")
        }
    }

    // MARK: - Data Sync

    func syncAllDataToHealthKit() {
        isSyncing = true
        syncProgress = 0.0

        Task {
            do {
                // Fetch all water portions from the model context
                let fetchDescriptor = FetchDescriptor<WaterPortion>(
                    sortBy: [SortDescriptor(\.createDate, order: .forward)]
                )

                let allPortions = try modelContext.fetch(fetchDescriptor)

                guard !allPortions.isEmpty else {
                    self.isSyncing = false
                    print("❌ No data to sync")
                    return
                }

                print("🔄 Starting sync of \(allPortions.count) portions to HealthKit...")

                // Create a simple array of data to avoid SwiftData reference issues
                let portionData = allPortions.map { portion in
                    (
                        amount: portion.amount,
                        unit: portion.unit,
                        drink: portion.drink,
                        createDate: portion.createDate
                    )
                }

                // Convert back to WaterPortion objects for the sync
                let portionsForSync = portionData.map { data in
                    WaterPortion(
                        amount: data.amount,
                        unit: data.unit,
                        drink: data.drink,
                        createDate: data.createDate,
                        dayDate: data.createDate.rounded()
                    )
                }

                let result = await healthKitService.syncAllHistoricalData(
                    from: portionsForSync,
                    syncWater: syncWater,
                    syncCaffeine: syncCaffeine,
                    syncAlcohol: syncAlcohol
                )

                self.syncResult = result
                self.isSyncing = false
                self.syncProgress = 1.0
                self.showingSyncResult = true

                print("✅ Sync completed: \(result.success) success, \(result.failed) failed")
            } catch {
                self.isSyncing = false
                print("❌ Failed to fetch water portions: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Sync Settings

    func updateSyncSettings(water: Bool? = nil, caffeine: Bool? = nil, alcohol: Bool? = nil) {
        if let water = water {
            syncWater = water
            UserDefaults.standard.set(water, forKey: "healthkit_sync_water")
        }
        if let caffeine = caffeine {
            syncCaffeine = caffeine
            UserDefaults.standard.set(caffeine, forKey: "healthkit_sync_caffeine")
        }
        if let alcohol = alcohol {
            syncAlcohol = alcohol
            UserDefaults.standard.set(alcohol, forKey: "healthkit_sync_alcohol")
        }
    }
}
