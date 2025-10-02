//
//  HealthKitCard.swift
//  WaterTracker
//
//  Created by Jackson  on 10/09/2025.
//

import SwiftUI
import HealthKit

struct HealthKitCard: View {
    @EnvironmentObject private var healthKitService: HealthKitService
    @State private var isLoading = true
    @State private var healthDataAvailable = false
    @State private var healthData: HealthKitData?
    @State private var showingEnableTutorial = false
    @State private var showingDisableTutorial = false
    @State private var isRefreshing = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header - Clean and minimal
            HStack(spacing: 12) {
                // Health Icon
                ZStack {
                    Circle()
                        .fill(.red.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.red)
                    } else if healthDataAvailable {
                        Image(systemName: "heart.fill")
                            .font(.title3)
                            .foregroundStyle(.red)
                    } else {
                        Image(systemName: "heart.slash")
                            .font(.title3)
                            .foregroundStyle(.orange)
                    }
                }

                // Title and Status
                VStack(alignment: .leading, spacing: 2) {
                    Text("Health & Data")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(healthDataAvailable ? "All HealthKit services connected" : "Connect HealthKit services")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                
                // Status indicator
                if healthDataAvailable {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title3)
                } else if !isLoading {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)
                        .font(.title3)
                }
            }
            .padding()

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
        .padding(.vertical, 20)
        .padding(.horizontal)
    }
    
    // MARK: - Health Data Available View
    
    private var healthDataAvailableView: some View {
        VStack(spacing: 16) {
            Divider()
                .padding(.horizontal)
            
            // Success indicator
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
                Text("All HealthKit services connected")
                    .font(.caption)
                    .foregroundStyle(.green)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(.horizontal)
            
            // Data summary - Compact grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
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
            .padding(.horizontal)
            
            // Action buttons - Simplified
            VStack(spacing: 8) {
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
                    .padding(.vertical, 12)
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isRefreshing)
                
                Button {
                    showingDisableTutorial = true
                } label: {
                    Text("Disable Health Sync")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
    
    // MARK: - Health Data Unavailable View
    
    private var healthDataUnavailableView: some View {
        VStack(spacing: 16) {
            Divider()
                .padding(.horizontal)
            
            VStack(spacing: 12) {
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
                    VStack(spacing: 8) {
                        Text("Missing services:")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .fontWeight(.medium)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 6) {
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
                    .padding(.horizontal)
                }
            }
            .padding(.horizontal)
            
            Button {
                showingEnableTutorial = true
            } label: {
                Text("Connect HealthKit Services")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
    
    // MARK: - Helper Methods
    
    private func fetchHealthData() {
        isLoading = true
        Task {
            do {
                let data = await healthKitService.fetchAllHealthData()
                await MainActor.run {
                    self.healthData = data
                    // Consider health data available only if ALL data fields are not null
                    self.healthDataAvailable = data.height != nil && data.weight != nil && data.age != nil && data.gender != nil && data.averageSleepHours != nil
                    self.isLoading = false
                }
            } catch {
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
            do {
                let data = await healthKitService.fetchAllHealthData()
                await MainActor.run {
                    self.healthData = data
                    self.healthDataAvailable = data.height != nil && data.weight != nil && data.age != nil && data.gender != nil && data.averageSleepHours != nil
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
}

// MARK: - Data Item View

struct DataItemView: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
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
