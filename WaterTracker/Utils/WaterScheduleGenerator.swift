//
//  WaterScheduleGenerator.swift
//  WaterTracker
//
//  Created by Assistant on 10/10/2025.
//

import Foundation

/// Utility to generate optimized water intake schedules based on sleep patterns
struct WaterScheduleGenerator {
    
    /// Generate water intake schedule from HealthKit sleep data
    static func generateSchedule(from sleepRecommendation: SleepRecommendation) -> [ScheduleTime] {
        guard let wakeTime = sleepRecommendation.wakeTime,
              let bedTime = sleepRecommendation.bedTime else {
            // Fallback to default schedule if no valid sleep times
            return generateDefaultSchedule()
        }
        
        let calendar = Calendar.current
        let wakeHour = calendar.component(.hour, from: wakeTime)
        let wakeMinute = calendar.component(.minute, from: wakeTime)
        let bedHour = calendar.component(.hour, from: bedTime)
        let bedMinute = calendar.component(.minute, from: bedTime)
        
        return generateOptimizedSchedule(
            wakeHour: wakeHour,
            wakeMinute: wakeMinute,
            bedHour: bedHour,
            bedMinute: bedMinute,
            sleepQuality: sleepRecommendation.sleepQualityScore
        )
    }
    
    /// Generate water intake schedule from manual sleep time input
    static func generateSchedule(from manualSleepTime: ManualSleepTime) -> [ScheduleTime] {
        return generateOptimizedSchedule(
            wakeHour: manualSleepTime.wakeHour,
            wakeMinute: manualSleepTime.wakeMinute,
            bedHour: manualSleepTime.bedHour,
            bedMinute: manualSleepTime.bedMinute,
            sleepQuality: 0.75 // Assume moderate sleep quality for manual input
        )
    }
    
    // MARK: - Private Methods
    
    /// Generate optimized schedule based on wake and bed times
    private static func generateOptimizedSchedule(
        wakeHour: Int,
        wakeMinute: Int,
        bedHour: Int,
        bedMinute: Int,
        sleepQuality: Double
    ) -> [ScheduleTime] {
        var schedule: [ScheduleTime] = []
        
        // Calculate total awake time in minutes
        let wakeTimeMinutes = wakeHour * 60 + wakeMinute
        var bedTimeMinutes = bedHour * 60 + bedMinute
        
        // If bed time is earlier in the day than wake time, it's next day
        if bedTimeMinutes < wakeTimeMinutes {
            bedTimeMinutes += 24 * 60
        }
        
        let awakeTimeMinutes = bedTimeMinutes - wakeTimeMinutes
        let awakeHours = Double(awakeTimeMinutes) / 60.0
        
        // Pre-bed buffer: 60-90 minutes before bed (shorter for late sleepers)
        let preBedBufferMinutes = min(90, max(60, Int(awakeTimeMinutes / 10)))
        
        // Usable time for reminders (excluding pre-bed buffer)
        let usableAwakeMinutes = awakeTimeMinutes - preBedBufferMinutes
        
        // 1. FIRST REMINDER - 20-30 minutes after waking (people need time to wake up!)
        let firstReminderDelay = 25 // 25 minutes after waking
        let firstReminderMinutes = wakeTimeMinutes + firstReminderDelay
        let firstReminder = minutesToHourMinute(firstReminderMinutes)
        schedule.append(ScheduleTime(
            hour: firstReminder.hour,
            minute: firstReminder.minute,
            reason: "Morning hydration after waking up",
            icon: "sunrise.fill"
        ))
        
        // Calculate optimal number of reminders based on awake time
        // Aim for reminder every 2-3 hours, with minimum of 4 and maximum of 8 total reminders
        let optimalReminderCount = min(8, max(4, Int(awakeHours / 2.5)))
        
        // Calculate interval between reminders
        let reminderInterval = usableAwakeMinutes / optimalReminderCount
        
        // 2. Generate evenly spaced reminders throughout the day
        for i in 1..<(optimalReminderCount - 1) {
            let reminderMinutes = wakeTimeMinutes + firstReminderDelay + (reminderInterval * i)
            
            // Only add if it's before the pre-bed buffer
            if reminderMinutes < bedTimeMinutes - preBedBufferMinutes {
                let reminder = minutesToHourMinute(Int(reminderMinutes))
                
                // Determine icon and reason based on time of day
                let hoursSinceWake = Double(Int(reminderMinutes) - wakeTimeMinutes) / 60.0
                let icon: String
                let reason: String
                
                if hoursSinceWake < 2.5 {
                    icon = "cup.and.saucer.fill"
                    reason = "Morning hydration boost"
                } else if hoursSinceWake < 5.5 {
                    icon = "sun.min.fill"
                    reason = "Mid-morning refresh"
                } else if hoursSinceWake < 8 {
                    icon = "fork.knife"
                    reason = "Afternoon hydration"
                } else if hoursSinceWake < 12 {
                    icon = "sun.max.fill"
                    reason = "Late afternoon boost"
                } else if hoursSinceWake < 15 {
                    icon = "sunset.fill"
                    reason = "Evening hydration"
                } else {
                    icon = "moon.stars.fill"
                    reason = "Late evening hydration"
                }
                
                schedule.append(ScheduleTime(
                    hour: reminder.hour,
                    minute: reminder.minute,
                    reason: reason,
                    icon: icon
                ))
            }
        }
        
        // 3. PRE-BED REMINDER - Calculated buffer before bed
        let preBedMinutes = bedTimeMinutes - preBedBufferMinutes
        if preBedMinutes > wakeTimeMinutes + 60 { // At least 1 hour after waking
            let preBed = minutesToHourMinute(preBedMinutes)
            schedule.append(ScheduleTime(
                hour: preBed.hour,
                minute: preBed.minute,
                reason: "Last hydration before bed (\(preBedBufferMinutes)min buffer)",
                icon: "moon.fill",
                isSelected: true // Include by default since it's now better timed
            ))
        }
        
        // 4. If poor sleep quality, add an extra mid-day reminder for recovery
        if sleepQuality < 0.6 && awakeTimeMinutes > 900 { // If awake > 15 hours and poor sleep
            let midDayMinutes = wakeTimeMinutes + (awakeTimeMinutes / 2)
            
            // Check if this time doesn't conflict with existing reminders
            let hasConflict = schedule.contains { scheduleTime in
                let scheduleMinutes = scheduleTime.hour * 60 + scheduleTime.minute
                return abs(scheduleMinutes - midDayMinutes) < 60
            }
            
            if !hasConflict && midDayMinutes < bedTimeMinutes - preBedBufferMinutes {
                let extra = minutesToHourMinute(midDayMinutes)
                schedule.append(ScheduleTime(
                    hour: extra.hour,
                    minute: extra.minute,
                    reason: "Extra hydration for sleep recovery",
                    icon: "plus.circle.fill"
                ))
            }
        }
        
        // Sort schedule by time
        schedule.sort { first, second in
            let firstMinutes = first.hour * 60 + first.minute
            let secondMinutes = second.hour * 60 + second.minute
            return firstMinutes < secondMinutes
        }
        
        return schedule
    }
    
    /// Generate a default schedule for 7 AM - 11 PM
    private static func generateDefaultSchedule() -> [ScheduleTime] {
        return [
            ScheduleTime(hour: 7, minute: 30, reason: "Morning hydration after waking up", icon: "sunrise.fill"),
            ScheduleTime(hour: 9, minute: 30, reason: "Mid-morning boost", icon: "cup.and.saucer.fill"),
            ScheduleTime(hour: 12, minute: 0, reason: "Lunchtime hydration", icon: "fork.knife"),
            ScheduleTime(hour: 15, minute: 0, reason: "Afternoon refresh", icon: "sun.max.fill"),
            ScheduleTime(hour: 18, minute: 0, reason: "Evening hydration", icon: "sunset.fill"),
            ScheduleTime(hour: 21, minute: 30, reason: "Last hydration before bed (90min buffer)", icon: "moon.fill")
        ]
    }
    
    /// Round time to nearest 15 minutes for cleaner schedule
    private static func roundToNearest15Minutes(hour: Int, minute: Int) -> (hour: Int, minute: Int) {
        let totalMinutes = hour * 60 + minute
        let rounded = ((totalMinutes + 7) / 15) * 15 // Round to nearest 15
        let newHour = (rounded / 60) % 24
        let newMinute = rounded % 60
        return (newHour, newMinute)
    }
    
    /// Convert minutes since midnight to hour and minute
    private static func minutesToHourMinute(_ totalMinutes: Int) -> (hour: Int, minute: Int) {
        let adjustedMinutes = totalMinutes % (24 * 60) // Handle day overflow
        let hour = adjustedMinutes / 60
        let minute = adjustedMinutes % 60
        
        // Round to nearest 15 minutes for cleaner schedule
        return roundToNearest15Minutes(hour: hour, minute: minute)
    }
}

