//
//  WaterScheduleFromSleepDataGeneratorScreen.swift
//  WaterTracker
//
//  Created by Assistant on 10/10/2025.
//

import SwiftUI
import HealthKit

/// Main coordinator view for automatic water schedule generation based on sleep time
struct WaterScheduleFromSleepDataGeneratorScreen: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var sleepService = SleepService()
    @State private var currentStep: GenerationStep = .loading
    @State private var sleepData: SleepRecommendation?
    @State private var manualSleepTime: ManualSleepTime?
    @State private var generatedSchedule: [ScheduleTime] = []
    
    enum GenerationStep {
        case loading
        case manualInput
        case generating
        case preview
        case error(String)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack {
                    switch currentStep {
                    case .loading:
                        loadingView
                    case .manualInput:
                        SleepTimeInputView(onSubmit: { sleepTime in
                            manualSleepTime = sleepTime
                            generateSchedule()
                        })
                    case .generating:
                        generatingView
                    case .preview:
                        GeneratedScheduleView(
                            schedule: generatedSchedule,
                            sleepData: sleepData,
                            manualSleepTime: manualSleepTime,
                            onApply: { selectedTimes in
                                applySchedule(selectedTimes)
                            }
                        )
                    case .error(let message):
                        errorView(message: message)
                    }
                }
            }
            .navigationTitle("Smart Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadSleepData()
            }
        }
    }
    
    // MARK: - Views
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Checking for sleep data...")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding()
    }
    
    private var generatingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Generating optimal schedule...")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding()
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48, weight: .medium))
                .foregroundStyle(.orange)
            
            Text("Something went wrong")
                .font(.system(size: 20, weight: .semibold))
            
            Text(message)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            PrimaryButton(
                title: String(localized: "Try Again"),
                systemImage: "arrow.clockwise",
                colors: [.blue, .cyan]
            ) {
                Task { await loadSleepData() }
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    // MARK: - Data Loading
    
    private func loadSleepData() async {
        currentStep = .loading
        
        // Try to fetch sleep data from HealthKit
        if let sleepRecommendation = await sleepService.fetchSleepData(for: Date()) {
            sleepData = sleepRecommendation
            generateSchedule()
        } else {
            // No sleep data available, ask for manual input
            await MainActor.run {
                currentStep = .manualInput
            }
        }
    }
    
    private func generateSchedule() {
        currentStep = .generating
        
        Task {
            // Generate schedule based on sleep data or manual input
            let schedule: [ScheduleTime]
            
            if let sleepData = sleepData {
                schedule = WaterScheduleGenerator.generateSchedule(from: sleepData)
            } else if let manualSleepTime = manualSleepTime {
                schedule = WaterScheduleGenerator.generateSchedule(from: manualSleepTime)
            } else {
                await MainActor.run {
                    currentStep = .error("No sleep data available")
                }
                return
            }
            
            await MainActor.run {
                generatedSchedule = schedule
                currentStep = .preview
            }
        }
    }
    
    private func applySchedule(_ selectedTimes: [ScheduleTime]) {
        dismiss()
        
        // Post notification to parent view to add the selected reminders
        NotificationCenter.default.post(
            name: .applyGeneratedSchedule,
            object: nil,
            userInfo: ["times": selectedTimes]
        )
    }
}

// MARK: - Supporting Types

struct ScheduleTime: Identifiable, Equatable, Hashable {
    let id = UUID()
    let hour: Int
    let minute: Int
    let reason: String
    let icon: String
    var isSelected: Bool = true
    
    var timeString: String {
        let calendar = Calendar.current
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let date = calendar.date(from: components) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }
}

struct ManualSleepTime {
    let bedTime: Date
    let wakeTime: Date
    
    var bedHour: Int {
        Calendar.current.component(.hour, from: bedTime)
    }
    
    var bedMinute: Int {
        Calendar.current.component(.minute, from: bedTime)
    }
    
    var wakeHour: Int {
        Calendar.current.component(.hour, from: wakeTime)
    }
    
    var wakeMinute: Int {
        Calendar.current.component(.minute, from: wakeTime)
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let applyGeneratedSchedule = Notification.Name("applyGeneratedSchedule")
}

#Preview {
    WaterScheduleFromSleepDataGeneratorScreen()
}

