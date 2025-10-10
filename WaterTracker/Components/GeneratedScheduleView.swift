//
//  GeneratedScheduleView.swift
//  WaterTracker
//
//  Created by Assistant on 10/10/2025.
//

import SwiftUI

/// View to display and customize the generated water intake schedule
struct GeneratedScheduleView: View {
    @State var schedule: [ScheduleTime]
    let sleepData: SleepRecommendation?
    let manualSleepTime: ManualSleepTime?
    var onApply: ([ScheduleTime]) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerCard
                
                if sleepData != nil || manualSleepTime != nil {
                    sleepInfoCard
                }
                
                scheduleCard
                
                Spacer(minLength: 20)
                
                applyButton
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Header Card
    
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.blue)
                
                Text("Your Optimal Schedule")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            
            Text("We've created a personalized water intake schedule based on your sleep pattern. Tap any reminder to toggle it on or off.")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    // MARK: - Sleep Info Card
    
    private var sleepInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.purple)
                
                Text("Sleep Schedule")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            
            HStack(spacing: 16) {
                // Bed Time
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bed Time")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    
                    Text(bedTimeString)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                // Wake Time
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Wake Time")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    
                    Text(wakeTimeString)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    // MARK: - Schedule Card
    
    private var scheduleCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.blue)
                
                Text("Reminders")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text("\(selectedCount) selected")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 12) {
                ForEach($schedule) { $time in
                    scheduleTimeRow(time: $time)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    private func scheduleTimeRow(time: Binding<ScheduleTime>) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                time.wrappedValue.isSelected.toggle()
            }
        } label: {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: time.wrappedValue.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(time.wrappedValue.isSelected ? .blue : .gray)
                    .frame(width: 24)
                
                // Time and Reason
                VStack(alignment: .leading, spacing: 2) {
                    Text(time.wrappedValue.timeString)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(time.wrappedValue.isSelected ? .primary : .secondary)
                    
                    Text(time.wrappedValue.reason)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Selection indicator
                Image(systemName: time.wrappedValue.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(time.wrappedValue.isSelected ? .blue : .gray.opacity(0.3))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(time.wrappedValue.isSelected ? Color.blue.opacity(0.05) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(time.wrappedValue.isSelected ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Apply Button
    
    private var applyButton: some View {
        VStack(spacing: 12) {
            PrimaryButton(
                title: String(localized: "Apply Schedule"),
                systemImage: "checkmark.circle.fill",
                colors: [.blue, .cyan],
                isDisabled: selectedCount == 0
            ) {
                let selectedTimes = schedule.filter { $0.isSelected }
                onApply(selectedTimes)
            }
            .padding(.horizontal)
            
            if selectedCount == 0 {
                Text("Select at least one reminder to continue")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var selectedCount: Int {
        schedule.filter { $0.isSelected }.count
    }
    
    private var bedTimeString: String {
        if let sleepData = sleepData, let bedTime = sleepData.bedTime {
            return bedTime.formatted(date: .omitted, time: .shortened)
        } else if let manualSleepTime = manualSleepTime {
            return manualSleepTime.bedTime.formatted(date: .omitted, time: .shortened)
        }
        return "N/A"
    }
    
    private var wakeTimeString: String {
        if let sleepData = sleepData, let wakeTime = sleepData.wakeTime {
            return wakeTime.formatted(date: .omitted, time: .shortened)
        } else if let manualSleepTime = manualSleepTime {
            return manualSleepTime.wakeTime.formatted(date: .omitted, time: .shortened)
        }
        return "N/A"
    }
}

#Preview {
    let sampleSchedule = [
        ScheduleTime(hour: 7, minute: 0, reason: "Morning wake-up hydration", icon: "sunrise.fill", isSelected: true),
        ScheduleTime(hour: 9, minute: 0, reason: "Mid-morning boost", icon: "cup.and.saucer.fill", isSelected: true),
        ScheduleTime(hour: 12, minute: 0, reason: "Lunchtime hydration", icon: "fork.knife", isSelected: true),
        ScheduleTime(hour: 15, minute: 0, reason: "Afternoon refresh", icon: "sun.max.fill", isSelected: true),
        ScheduleTime(hour: 18, minute: 0, reason: "Evening hydration", icon: "sunset.fill", isSelected: true),
        ScheduleTime(hour: 20, minute: 0, reason: "Pre-bed hydration", icon: "moon.fill", isSelected: false)
    ]
    
    return GeneratedScheduleView(
        schedule: sampleSchedule,
        sleepData: nil,
        manualSleepTime: ManualSleepTime(
            bedTime: Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date()) ?? Date(),
            wakeTime: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
        )
    ) { times in
        print("Applied \(times.count) reminders")
    }
}

