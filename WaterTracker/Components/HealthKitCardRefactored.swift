//
//  HealthKitCardRefactored.swift
//  WaterTracker
//
//  Created by Claude Code
//

import SwiftUI
import HealthKit
import SwiftData

struct HealthKitCardRefactored: View {
    // MARK: - Environment
    @EnvironmentObject private var healthKitService: HealthKitService
    @Environment(\.modelContext) private var modelContext

    // MARK: - ViewModel
    @StateObject private var viewModel: HealthKitCardViewModel

    // MARK: - Initialization
    init() {
        // Note: We'll properly initialize viewModel in onAppear since we need environment objects
        _viewModel = StateObject(wrappedValue: HealthKitCardViewModel(
            healthKitService: HealthKitService(),
            modelContext: ModelContext(try! ModelContainer(for: WaterPortion.self))
        ))
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HealthKitHeaderView(
                isLoading: viewModel.isLoading,
                healthDataAvailable: viewModel.healthDataAvailable,
                isPartiallyConnected: viewModel.isPartiallyConnected,
                connectionStatusText: viewModel.connectionStatusText,
                onRefresh: {
                    viewModel.refreshHealthData()
                }
            )

            // Content based on state
            if viewModel.isLoading {
                loadingView
            } else if viewModel.healthDataAvailable {
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
            // Re-initialize viewModel with proper dependencies from environment
            let newViewModel = HealthKitCardViewModel(
                healthKitService: healthKitService,
                modelContext: modelContext
            )
            viewModel.fetchHealthData()
            viewModel.checkWritePermissions()
        }
        .sheet(isPresented: $viewModel.showingEnableTutorial) {
            EnableHealthKitTutorialScreen()
        }
        .sheet(isPresented: $viewModel.showingDisableTutorial) {
            DisableHealthKitTutorialScreen()
        }
        .alert("Water Intake Calculated", isPresented: $viewModel.showingCalculationResult) {
            Button("Update Goal") {
                if let waterGoal = viewModel.calculatedWaterGoal {
                    UserDefaults.standard.set(waterGoal, forKey: "water_goal_ml")
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            if let waterGoal = viewModel.calculatedWaterGoal {
                Text("Based on your health data, your recommended daily water intake is \(waterGoal) ml. Would you like to update your current goal?")
            }
        }
        .alert("Sync Complete", isPresented: $viewModel.showingSyncResult) {
            Button("OK") { }
        } message: {
            if let result = viewModel.syncResult {
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

            // Data Grid
            HealthKitDataGridView(healthData: viewModel.healthData)

            // Action Buttons
            HealthKitActionsView(
                canCalculateWaterIntake: viewModel.canCalculateWaterIntake,
                hasAnySyncPermissions: viewModel.hasAnySyncPermissions,
                isCalculatingWaterIntake: viewModel.isCalculatingWaterIntake,
                isSyncing: viewModel.isSyncing,
                isPerformingAction: viewModel.isPerformingAction,
                onCalculateWaterIntake: {
                    viewModel.calculateWaterIntake()
                },
                onSyncData: {
                    viewModel.syncAllDataToHealthKit()
                }
            )

            // Sync Settings
            if viewModel.hasAnySyncPermissions {
                Divider()
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                HealthKitSyncSettingsView(
                    syncWater: $viewModel.syncWater,
                    syncCaffeine: $viewModel.syncCaffeine,
                    syncAlcohol: $viewModel.syncAlcohol,
                    hasWaterWritePermission: viewModel.hasWaterWritePermission,
                    hasCaffeineWritePermission: viewModel.hasCaffeineWritePermission,
                    hasAlcoholWritePermission: viewModel.hasAlcoholWritePermission
                )
            }

            // Missing Services Indicator
            if viewModel.isPartiallyConnected {
                missingServicesView
            }
        }
    }

    // MARK: - Health Data Unavailable View

    private var healthDataUnavailableView: some View {
        VStack(spacing: 16) {
            Divider()
                .padding(.horizontal, 16)

            // Info message
            VStack(spacing: 12) {
                Image(systemName: "heart.text.square")
                    .font(.system(size: 50, weight: .thin))
                    .foregroundStyle(.red.opacity(0.5))

                Text("HealthKit Not Connected")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)

                Text("Connect to HealthKit to access your health data and sync water intake.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            // Enable button
            Button(action: {
                viewModel.requestHealthKitPermissions()
            }) {
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

    // MARK: - Missing Services View

    private var missingServicesView: some View {
        VStack(spacing: 12) {
            Divider()
                .padding(.horizontal, 16)

            HStack {
                Text("Missing Data")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 8) {
                if viewModel.healthData?.height == nil {
                    MissingServiceView(title: "Height", isMissing: true, icon: "figure.stand")
                }
                if viewModel.healthData?.weight == nil {
                    MissingServiceView(title: "Weight", isMissing: true, icon: "scalemass")
                }
                if viewModel.healthData?.age == nil {
                    MissingServiceView(title: "Age", isMissing: true, icon: "calendar")
                }
                if viewModel.healthData?.gender == nil {
                    MissingServiceView(title: "Gender", isMissing: true, icon: "person")
                }
                if viewModel.healthData?.averageSleepHours == nil {
                    MissingServiceView(title: "Sleep", isMissing: true, icon: "bed.double")
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }
}

// MissingServiceView is defined in HealthKitSharedViews.swift

#Preview {
    HealthKitCardRefactored()
        .environmentObject(HealthKitService())
        .padding()
}
