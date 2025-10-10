//
//  SleepTimeInputView.swift
//  WaterTracker
//
//  Created by Assistant on 10/10/2025.
//

import SwiftUI

/// View to collect manual sleep time input when HealthKit data is not available
struct SleepTimeInputView: View {
    @State private var bedTime: Date = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var wakeTime: Date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    
    var onSubmit: (ManualSleepTime) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerCard
                
                sleepTimeCard
                
                Spacer(minLength: 40)
                
                PrimaryButton(
                    title: String(localized: "Generate Schedule"),
                    systemImage: "wand.and.stars",
                    colors: [.blue, .cyan]
                ) {
                    let sleepTime = ManualSleepTime(bedTime: bedTime, wakeTime: wakeTime)
                    onSubmit(sleepTime)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.blue)
                
                Text("Sleep Schedule")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            
            Text("We couldn't find sleep data from HealthKit. Please enter your typical sleep schedule so we can create an optimized water intake schedule for you.")
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
    
    private var sleepTimeCard: some View {
        VStack(spacing: 20) {
            // Bed Time Picker
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "bed.double.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.blue)
                    
                    Text("Bed Time")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                
                DatePicker(
                    "Bed Time",
                    selection: $bedTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.compact)
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Divider()
            
            // Wake Time Picker
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "sunrise.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.orange)
                    
                    Text("Wake Time")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                
                DatePicker(
                    "Wake Time",
                    selection: $wakeTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.compact)
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Sleep Duration Display
            sleepDurationDisplay
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    private var sleepDurationDisplay: some View {
        VStack(spacing: 8) {
            Divider()
            
            HStack {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.purple)
                
                Text("Sleep Duration")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(calculateSleepDuration())
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
            }
        }
    }
    
    private func calculateSleepDuration() -> String {
        let calendar = Calendar.current
        let bedHour = calendar.component(.hour, from: bedTime)
        let bedMinute = calendar.component(.minute, from: bedTime)
        let wakeHour = calendar.component(.hour, from: wakeTime)
        let wakeMinute = calendar.component(.minute, from: wakeTime)
        
        // Calculate sleep duration in minutes
        var totalMinutes = (wakeHour * 60 + wakeMinute) - (bedHour * 60 + bedMinute)
        
        // If negative, sleep crossed midnight
        if totalMinutes < 0 {
            totalMinutes += 24 * 60
        }
        
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if minutes == 0 {
            return "\(hours)h"
        } else {
            return "\(hours)h \(minutes)m"
        }
    }
}

#Preview {
    SleepTimeInputView { sleepTime in
        print("Sleep time submitted: \(sleepTime)")
    }
}

