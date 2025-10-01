//
//  DisableHealthKitTutorialView.swift
//  WaterTracker
//
//  Created by Jackson  on 10/09/2025.
//

import SwiftUI
import HealthKit

struct DisableHealthKitTutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 20) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 80))
                            .foregroundStyle(.orange)
                            .shadow(color: .orange.opacity(0.3), radius: 20, x: 0, y: 10)
                        
                        VStack(spacing: 12) {
                            Text("Disable Health Sync")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                            
                            Text("Learn how to turn off HealthKit integration")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 40)
                    
                    // What happens section
                    VStack(spacing: 24) {
                        Text("What happens when you disable:")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        
                        VStack(spacing: 16) {
                            ImpactRowView(
                                icon: "target",
                                title: "Generic Goals",
                                description: "You'll use default hydration targets instead of personalized ones",
                                isNegative: true
                            )
                            
                            ImpactRowView(
                                icon: "moon.zzz",
                                title: "No Sleep Integration",
                                description: "Sleep patterns won't be considered for hydration recommendations",
                                isNegative: true
                            )
                            
                            ImpactRowView(
                                icon: "chart.bar",
                                title: "Limited Insights",
                                description: "Health-based analytics and trends will be unavailable",
                                isNegative: true
                            )
                            
                            ImpactRowView(
                                icon: "bell.slash",
                                title: "Basic Reminders",
                                description: "You'll only get simple time-based notifications",
                                isNegative: true
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // How to disable section
                    VStack(spacing: 20) {
                        Text("How to disable HealthKit:")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        
                        VStack(spacing: 16) {
                            StepView(
                                stepNumber: 1,
                                title: "Open Settings",
                                description: "Go to your iPhone's Settings app"
                            )
                            
                            StepView(
                                stepNumber: 2,
                                title: "Find Privacy & Security",
                                description: "Scroll down and tap on 'Privacy & Security'"
                            )
                            
                            StepView(
                                stepNumber: 3,
                                title: "Select Health",
                                description: "Tap on 'Health' in the list of privacy settings"
                            )
            
                            StepView(
                                stepNumber: 4,
                                title: "Find WaterTracker",
                                description: "Look for 'WaterTracker' in the list of apps"
                            )
                            
                            StepView(
                                stepNumber: 5,
                                title: "Turn Off All",
                                description: "Toggle off all the switches for data types"
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Warning section
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title2)
                                .foregroundStyle(.orange)
                            Text("Important Note")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        Text("Disabling HealthKit will remove all personalized features. You can always re-enable it later by going through the same steps and turning the switches back on.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.orange.opacity(0.1))
                    )
                    .padding(.horizontal, 24)
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        Button {
                            showingConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: "gear")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Open Settings")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        
                        Button {
                            dismiss()
                        } label: {
                            Text("Keep Health Sync Enabled")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Disable Health Sync")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .confirmationDialog("Open Settings", isPresented: $showingConfirmation) {
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will open your iPhone's Settings app where you can disable HealthKit access for WaterTracker.")
        }
    }
}

// MARK: - Impact Row View

struct ImpactRowView: View {
    let icon: String
    let title: String
    let description: String
    let isNegative: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(isNegative ? .red : .green)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill((isNegative ? Color.red : Color.green).opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.quaternary.opacity(0.3))
        )
    }
}

// MARK: - Step View

struct StepView: View {
    let stepNumber: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Text("\(stepNumber)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(.blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.quaternary.opacity(0.3))
        )
    }
}

#Preview {
    DisableHealthKitTutorialView()
}
