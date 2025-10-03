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
    @State private var hasWritePermissions = false
    @State private var hasWaterWritePermission = false
    @State private var hasCaffeineWritePermission = false
    @State private var hasAlcoholWritePermission = false
    @State private var syncWater = UserDefaults.standard.bool(forKey: "healthkit_sync_water")
    @State private var syncCaffeine = UserDefaults.standard.bool(forKey: "healthkit_sync_caffeine")
    @State private var syncAlcohol = UserDefaults.standard.bool(forKey: "healthkit_sync_alcohol")
    
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
            // Header - Enhanced with better spacing and alignment
            HStack(spacing: 16) {
                // Health Icon with improved styling
                ZStack {
                    Circle()
                        .fill(.red.opacity(0.12))
                        .frame(width: 44, height: 44)
                    
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.red)
                    } else if healthDataAvailable {
                        Image(systemName: isPartiallyConnected ? "heart.text.square" : "heart.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(isPartiallyConnected ? .orange : .red)
                    } else {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.orange)
                    }
                }

                // Title and Status with improved typography
                VStack(alignment: .leading, spacing: 3) {
                    Text("Health & Data")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    Text(connectionStatusText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()
                
                // Status indicator with better visual feedback
                if healthDataAvailable {
                    if isPartiallyConnected {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .font(.system(size: 14, weight: .medium))
                            Text("Partial")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.orange)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.orange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.system(size: 14, weight: .medium))
                            Text("Connected")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.green)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.green.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                } else if !isLoading {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.orange)
                            .font(.system(size: 14, weight: .medium))
                        Text("Not Connected")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.orange)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)

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
            checkWritePermissions()
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
            
            // Data summary - Enhanced grid with better spacing
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
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
            .padding(.horizontal, 20)
            
            // Action buttons - Enhanced with better spacing and hierarchy
            VStack(spacing: 12) {
                // Primary action - Refresh Data
                Button {
                    refreshHealthData()
                } label: {
                    HStack(spacing: 10) {
                        if isRefreshing {
                            ProgressView()
                                .scaleEffect(0.9)
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        Text(isRefreshing ? "Refreshing..." : "Refresh Data")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .disabled(isRefreshing)
                
                // Water intake calculation button
                if canCalculateWaterIntake {
                    Button {
                        calculateWaterIntake()
                    } label: {
                        HStack(spacing: 10) {
                            if isCalculatingWaterIntake {
                                ProgressView()
                                    .scaleEffect(0.9)
                                    .tint(.white)
                            } else {
                                Image(systemName: "drop.circle")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            Text(isCalculatingWaterIntake ? "Calculating..." : "Calculate Water Intake")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [.green, .green.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .green.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .disabled(isCalculatingWaterIntake || isRefreshing)
                }
                
                // Sync all data button
                Button {
                    syncAllDataToHealthKit()
                } label: {
                    HStack(spacing: 10) {
                        if isSyncing {
                            ProgressView()
                                .scaleEffect(0.9)
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.up.circle")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        VStack(spacing: 2) {
                            Text(isSyncing ? "Syncing to Health..." : "Sync All Data to Health")
                                .font(.system(size: 16, weight: .semibold))
                            if isSyncing && syncProgress > 0 {
                                Text("\(Int(syncProgress * 100))% complete")
                                    .font(.system(size: 12, weight: .medium))
                                    .opacity(0.9)
                            }
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.purple, .purple.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .purple.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .disabled(isSyncing || isRefreshing || isCalculatingWaterIntake)
                
                // Sync toggles - only show if any write permissions exist
                if hasWaterWritePermission || hasCaffeineWritePermission || hasAlcoholWritePermission {
                    VStack(spacing: 16) {
                        // Enhanced divider with better spacing
                        HStack {
                            Rectangle()
                                .fill(.secondary.opacity(0.3))
                                .frame(height: 1)
                            Text("Sync Settings")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 12)
                            Rectangle()
                                .fill(.secondary.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 20)
                        
                        VStack(spacing: 10) {
                            // Water toggle - only show if water write permission exists
                            if hasWaterWritePermission {
                                SyncToggleRow(
                                    title: "Water Intake",
                                    subtitle: "Sync hydration data",
                                    icon: "drop.fill",
                                    color: .blue,
                                    isOn: $syncWater
                                )
                            }
                            
                            // Caffeine toggle - only show if caffeine write permission exists
                            if hasCaffeineWritePermission {
                                SyncToggleRow(
                                    title: "Caffeine",
                                    subtitle: "Sync caffeine consumption",
                                    icon: "cup.and.saucer.fill",
                                    color: .brown,
                                    isOn: $syncCaffeine
                                )
                            }
                            
                            // Alcohol toggle - only show if alcohol write permission exists
                            if hasAlcoholWritePermission {
                                SyncToggleRow(
                                    title: "Alcohol",
                                    subtitle: "Sync alcohol consumption",
                                    icon: "wineglass.fill",
                                    color: .purple,
                                    isOn: $syncAlcohol
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                // Secondary actions with better spacing
                VStack(spacing: 8) {
                    if isPartiallyConnected {
                        Button {
                            showingEnableTutorial = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Connect More Services")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [.orange, .orange.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(color: .orange.opacity(0.3), radius: 3, x: 0, y: 1)
                        }
                    }
                    
                    Button {
                        showingDisableTutorial = true
                    } label: {
                        Text("Disable Health Sync")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 4)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
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
    
    private func checkWritePermissions() {
        Task {
            let hasWrite = await healthKitService.checkHealthKitWritePermissions()
            let hasWater = await healthKitService.checkWaterWritePermission()
            let hasCaffeine = await healthKitService.checkCaffeineWritePermission()
            let hasAlcohol = await healthKitService.checkAlcoholWritePermission()
            
            await MainActor.run {
                self.hasWritePermissions = hasWrite
                self.hasWaterWritePermission = hasWater
                self.hasCaffeineWritePermission = hasCaffeine
                self.hasAlcoholWritePermission = hasAlcohol
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
                let hasWrite = await healthKitService.checkHealthKitWritePermissions()
                let hasWater = await healthKitService.checkWaterWritePermission()
                let hasCaffeine = await healthKitService.checkCaffeineWritePermission()
                let hasAlcohol = await healthKitService.checkAlcoholWritePermission()
                
                await MainActor.run {
                    self.healthData = data
                    self.healthDataAvailable = data.height != nil || data.weight != nil || data.age != nil || data.gender != nil || data.averageSleepHours != nil
                    self.hasWritePermissions = hasWrite
                    self.hasWaterWritePermission = hasWater
                    self.hasCaffeineWritePermission = hasCaffeine
                    self.hasAlcoholWritePermission = hasAlcohol
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
                
                let result = await healthKitService.syncAllHistoricalData(
                    from: portionsForSync,
                    syncWater: syncWater,
                    syncCaffeine: syncCaffeine,
                    syncAlcohol: syncAlcohol
                )
                
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
        VStack(spacing: 8) {
            // Enhanced icon with background
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(color)
            }
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
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

// MARK: - Sync Toggle Row

struct SyncToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Enhanced icon with better styling
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(color)
            }
            
            // Text content with improved typography
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Enhanced toggle with better styling
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: color))
                .scaleEffect(0.9)
                .onChange(of: isOn) { _, newValue in
                    // Save to UserDefaults immediately
                    let key: String
                    switch title {
                    case "Water Intake":
                        key = "healthkit_sync_water"
                    case "Caffeine":
                        key = "healthkit_sync_caffeine"
                    case "Alcohol":
                        key = "healthkit_sync_alcohol"
                    default:
                        key = "healthkit_sync_\(title.lowercased().replacingOccurrences(of: " ", with: "_"))"
                    }
                    UserDefaults.standard.set(newValue, forKey: key)
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    HealthKitCard()
        .environmentObject(HealthKitService())
        .padding()
}
