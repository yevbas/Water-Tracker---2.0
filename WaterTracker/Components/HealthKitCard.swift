//
//  HealthKitCard.swift
//  WaterTracker
//
//  Created by Jackson  on 10/09/2025.
//

import SwiftUI
import HealthKit
import SwiftData

struct HealthKitCard: View {
    @EnvironmentObject private var healthKitService: HealthKitService
    @Environment(\.modelContext) private var modelContext
    @State private var isLoading = true
    @State private var healthDataAvailable = false
    @State private var healthData: HealthKitData?
    @State private var showingEnableTutorial = false
    @State private var showingDisableTutorial = false
    @State private var isRefreshing = false
    @State private var isCalculatingWaterIntake = false
    @State private var showingCalculationResult = false
    @State private var calculatedWaterGoal: Int?
    @State private var isSyncing = false
    @State private var syncProgress: Double = 0.0
    @State private var showingSyncResult = false
    @State private var syncResult: (success: Int, failed: Int, total: Int)?
    
    // Computed properties for connection state
    private var availableDataCount: Int {
        guard let data = healthData else { return 0 }
        var count = 0
        if data.height != nil { count += 1 }
        if data.weight != nil { count += 1 }
        if data.age != nil { count += 1 }
        if data.gender != nil { count += 1 }
        if data.averageSleepHours != nil { count += 1 }
        return count
    }
    
    private var connectionStatusText: String {
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
    
    private var isPartiallyConnected: Bool {
        healthDataAvailable && availableDataCount < 5
    }
    
    private var canCalculateWaterIntake: Bool {
        guard let data = healthData else { return false }
        return data.height != nil && data.weight != nil && data.age != nil && data.gender != nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header - Clean and minimal
            HStack(spacing: 12) {
                // Health Icon
                ZStack {
                    Circle()
                        .fill(.red.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(.red)
                    } else if healthDataAvailable {
                        Image(systemName: isPartiallyConnected ? "heart.text.square" : "heart.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(isPartiallyConnected ? .orange : .red)
                    } else {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.orange)
                    }
                }

                // Title and Status
                VStack(alignment: .leading, spacing: 1) {
                    Text("Health & Data")
                        .font(.system(size: 17, weight: .semibold))
                    
                    Text(connectionStatusText)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }

                Spacer()
                
                // Status indicator
                if healthDataAvailable {
                    if isPartiallyConnected {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.system(size: 16))
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.system(size: 16))
                    }
                } else if !isLoading {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)
                        .font(.system(size: 16))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            // Content based on state
            if isLoading {
                loadingView
            } else if healthDataAvailable {
                healthDataAvailableView
            } else {
                healthDataUnavailableView
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.red.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            fetchHealthData()
        }
        .sheet(isPresented: $showingEnableTutorial) {
            EnableHealthKitTutorialView()
        }
        .sheet(isPresented: $showingDisableTutorial) {
            DisableHealthKitTutorialView()
        }
        .alert("Water Intake Calculated", isPresented: $showingCalculationResult) {
            Button("Update Goal") {
                if let waterGoal = calculatedWaterGoal {
                    UserDefaults.standard.set(waterGoal, forKey: "water_goal_ml")
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            if let waterGoal = calculatedWaterGoal {
                Text("Based on your health data, your recommended daily water intake is \(waterGoal) ml. Would you like to update your current goal?")
            }
        }
        .alert("Sync Complete", isPresented: $showingSyncResult) {
            Button("OK") { }
        } message: {
            if let result = syncResult {
                if result.failed == 0 {
                    Text("Successfully synced all \(result.success) drink entries to the Health app! 🎉")
                } else {
                    Text("Synced \(result.success) of \(result.total) entries successfully. \(result.failed) entries failed to sync.")
                }
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.1)
                .tint(.red)
            
            Text("Checking HealthKit availability...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Health Data Available View
    
    private var healthDataAvailableView: some View {
        VStack(spacing: 12) {
            Divider()
                .padding(.horizontal, 16)
            
            // Success indicator
            HStack {
                Image(systemName: isPartiallyConnected ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .foregroundStyle(isPartiallyConnected ? .orange : .green)
                    .font(.system(size: 12))
                Text(connectionStatusText)
                    .font(.system(size: 12))
                    .foregroundStyle(isPartiallyConnected ? .orange : .green)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(.horizontal, 16)
            
            // Data summary - Compact grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                if let height = healthData?.height {
                    DataItemView(
                        icon: "ruler",
                        title: "Height",
                        value: String(format: "%.1f m", height),
                        color: .blue
                    )
                }
                
                if let weight = healthData?.weight {
                    DataItemView(
                        icon: "scalemass",
                        title: "Weight",
                        value: String(format: "%.1f kg", weight),
                        color: .green
                    )
                }
                
                if let age = healthData?.age {
                    DataItemView(
                        icon: "calendar",
                        title: "Age",
                        value: "\(age) years",
                        color: .purple
                    )
                }
                
                if let sleep = healthData?.averageSleepHours {
                    DataItemView(
                        icon: "moon",
                        title: "Sleep",
                        value: String(format: "%.1f hrs", sleep),
                        color: .indigo
                    )
                }
            }
            .padding(.horizontal, 16)
            
            // Action buttons - Simplified
            VStack(spacing: 6) {
                Button {
                    refreshHealthData()
                } label: {
                    HStack(spacing: 8) {
                        if isRefreshing {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 16, weight: .medium))
                        }
                        Text(isRefreshing ? "Refreshing..." : "Refresh Data")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(isRefreshing)
                
                // Water intake calculation button
                if canCalculateWaterIntake {
                    Button {
                        calculateWaterIntake()
                    } label: {
                        HStack(spacing: 8) {
                            if isCalculatingWaterIntake {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            } else {
                                Image(systemName: "drop.circle")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            Text(isCalculatingWaterIntake ? "Calculating..." : "Calculate Water Intake")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(.green)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(isCalculatingWaterIntake || isRefreshing)
                }
                
                // Sync all data button
                Button {
                    syncAllDataToHealthKit()
                } label: {
                    HStack(spacing: 8) {
                        if isSyncing {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.up.circle")
                                .font(.system(size: 16, weight: .medium))
                        }
                        VStack(spacing: 2) {
                            Text(isSyncing ? "Syncing to Health..." : "Sync All Data to Health")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            if isSyncing && syncProgress > 0 {
                                Text("\(Int(syncProgress * 100))% complete")
                                    .font(.caption2)
                                    .opacity(0.8)
                            }
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(.purple)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(isSyncing || isRefreshing || isCalculatingWaterIntake)
                
                if isPartiallyConnected {
                    Button {
                        showingEnableTutorial = true
                    } label: {
                        Text("Connect More Services")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                
                Button {
                    showingDisableTutorial = true
                } label: {
                    Text("Disable Health Sync")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
    
    // MARK: - Health Data Unavailable View
    
    private var healthDataUnavailableView: some View {
        VStack(spacing: 12) {
            Divider()
                .padding(.horizontal, 16)
            
            VStack(spacing: 10) {
                Image(systemName: "heart.slash")
                    .font(.title2)
                    .foregroundStyle(.orange)
                
                Text("HealthKit Services Not Connected")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Connect all HealthKit services for personalized recommendations")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                // Show which specific services are missing
                if let data = healthData {
                    VStack(spacing: 6) {
                        Text("Missing services:")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .fontWeight(.medium)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 4) {
                            MissingServiceView(
                                title: "Height",
                                isMissing: data.height == nil,
                                icon: "ruler"
                            )
                            MissingServiceView(
                                title: "Weight",
                                isMissing: data.weight == nil,
                                icon: "scalemass"
                            )
                            MissingServiceView(
                                title: "Age",
                                isMissing: data.age == nil,
                                icon: "calendar"
                            )
                            MissingServiceView(
                                title: "Gender",
                                isMissing: data.gender == nil,
                                icon: "person"
                            )
                            MissingServiceView(
                                title: "Sleep",
                                isMissing: data.averageSleepHours == nil,
                                icon: "moon"
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.horizontal, 16)
            
            Button {
                requestHealthKitPermissions()
            } label: {
                Text("Enable HealthKit")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
    
    // MARK: - Helper Methods
    
    private func fetchHealthData() {
        print("🔍 Starting fetchHealthData...")
        isLoading = true
        Task {
            // Directly fetch health data - if we have no permissions, HealthKit will return empty data
            print("🔍 Attempting to fetch health data...")
            do {
                let data = await healthKitService.fetchAllHealthData()
                print("📊 Health data fetched: height=\(data.height != nil), weight=\(data.weight != nil), age=\(data.age != nil), gender=\(data.gender != nil), sleep=\(data.averageSleepHours != nil)")
                
                await MainActor.run {
                    self.healthData = data
                    // Consider health data available if we have ANY data (not all)
                    let hasAnyData = data.height != nil || data.weight != nil || data.age != nil || data.gender != nil || data.averageSleepHours != nil
                    print("📊 Has any data (permissions granted): \(hasAnyData)")
                    self.healthDataAvailable = hasAnyData
                    self.isLoading = false
                }
            } catch {
                print("❌ Error fetching health data: \(error)")
                await MainActor.run {
                    self.healthData = nil
                    self.healthDataAvailable = false
                    self.isLoading = false
                }
            }
        }
    }
    
    private func refreshHealthData() {
        isRefreshing = true
        Task {
            // Request permissions again in case they were denied
            let granted = await healthKitService.requestHealthKitPermissions()
            if !granted {
                await MainActor.run {
                    self.healthData = nil
                    self.healthDataAvailable = false
                    self.isRefreshing = false
                }
                return
            }
            
            do {
                let data = await healthKitService.fetchAllHealthData()
                await MainActor.run {
                    self.healthData = data
                    self.healthDataAvailable = data.height != nil || data.weight != nil || data.age != nil || data.gender != nil || data.averageSleepHours != nil
                    self.isRefreshing = false
                }
            } catch {
                await MainActor.run {
                    self.healthData = nil
                    self.healthDataAvailable = false
                    self.isRefreshing = false
                }
            }
        }
    }
    
    private func requestHealthKitPermissions() {
        Task {
            print("🔐 Requesting HealthKit permissions...")
            let granted = await healthKitService.requestHealthKitPermissions()
            print("🔐 Permissions granted: \(granted)")
            if granted {
                print("✅ Permissions granted, fetching health data...")
                // Refresh the health data after permissions are granted
                await MainActor.run {
                    fetchHealthData()
                }
            } else {
                print("❌ Permissions denied")
            }
        }
    }
    
    private func calculateWaterIntake() {
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
                await MainActor.run {
                    self.isCalculatingWaterIntake = false
                    print("❌ Failed to create UserMetrics from HealthKit data")
                }
                return
            }
            
            // Calculate water intake using WaterPlanner
            let plan = WaterPlanner.plan(for: userMetrics)
            
            await MainActor.run {
                self.calculatedWaterGoal = plan.waterMl
                self.isCalculatingWaterIntake = false
                self.showingCalculationResult = true
                print("✅ Water intake calculated: \(plan.waterMl) ml")
            }
        }
    }
    
    private func syncAllDataToHealthKit() {
        isSyncing = true
        syncProgress = 0.0
        
        Task {
            do {
                // Fetch all water portions from the model context with a more robust approach
                let fetchDescriptor = FetchDescriptor<WaterPortion>(
                    sortBy: [SortDescriptor(\.createDate, order: .forward)]
                )
                
                // Perform the fetch on the main actor to avoid threading issues
                let allPortions = try await MainActor.run {
                    try modelContext.fetch(fetchDescriptor)
                }
                
                guard !allPortions.isEmpty else {
                    await MainActor.run {
                        self.isSyncing = false
                        print("❌ No data to sync")
                    }
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
                
                let result = await healthKitService.syncAllHistoricalData(from: portionsForSync)
                
                await MainActor.run {
                    self.syncResult = result
                    self.isSyncing = false
                    self.syncProgress = 1.0
                    self.showingSyncResult = true
                    
                    print("✅ Sync completed: \(result.success) success, \(result.failed) failed")
                }
            } catch {
                await MainActor.run {
                    self.isSyncing = false
                    print("❌ Failed to fetch water portions: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Data Item View

struct DataItemView: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
            
            VStack(spacing: 1) {
                Text(title)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                
                Text(value)
                    .font(.system(size: 12, weight: .semibold))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.05))
        )
    }
}

// MARK: - Missing Service View

struct MissingServiceView: View {
    let title: String
    let isMissing: Bool
    let icon: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(isMissing ? .orange : .green)
            
            Text(title)
                .font(.caption2)
                .foregroundStyle(isMissing ? .orange : .green)
                .fontWeight(.medium)
            
            if isMissing {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isMissing ? .orange.opacity(0.1) : .green.opacity(0.1))
        )
    }
}

#Preview {
    HealthKitCard()
        .environmentObject(HealthKitService())
        .padding()
}
