//
//  UserHealthProfile.swift
//  WaterTracker
//
//  Created by Assistant on 29/09/2025.
//

import Foundation
import SwiftData
import HealthKit

@Model
final class UserHealthProfile {
    var height: Double? // in meters
    var weight: Double? // in kg
    var age: Int?
    var gender: String? // "male", "female", "other", "notSet"
    var lastUpdated: Date
    var isHealthKitEnabled: Bool
    var averageSleepHours: Double?
    var lastSleepDataUpdate: Date?
    
    init(
        height: Double? = nil,
        weight: Double? = nil,
        age: Int? = nil,
        gender: String? = nil,
        lastUpdated: Date = Date(),
        isHealthKitEnabled: Bool = false,
        averageSleepHours: Double? = nil,
        lastSleepDataUpdate: Date? = nil
    ) {
        self.height = height
        self.weight = weight
        self.age = age
        self.gender = gender
        self.lastUpdated = lastUpdated
        self.isHealthKitEnabled = isHealthKitEnabled
        self.averageSleepHours = averageSleepHours
        self.lastSleepDataUpdate = lastSleepDataUpdate
    }
    
    // MARK: - Computed Properties
    
    var heightInCm: Int? {
        guard let height = height else { return nil }
        return Int(height * 100)
    }
    
    var weightInKg: Int? {
        guard let weight = weight else { return nil }
        return Int(weight)
    }
    
    var genderEnum: HKBiologicalSex? {
        guard let gender = gender else { return nil }
        switch gender {
        case "male":
            return .male
        case "female":
            return .female
        case "other":
            return .other
        case "notSet":
            return .notSet
        default:
            return nil
        }
    }
    
    var isDataComplete: Bool {
        return height != nil && weight != nil && age != nil && gender != nil
    }
    
    var sleepQualityDescription: String {
        guard let averageHours = averageSleepHours else { return "Unknown" }
        
        switch averageHours {
        case 0..<6:
            return "Poor (less than 6 hours)"
        case 6..<7:
            return "Fair (6-7 hours)"
        case 7..<8:
            return "Good (7-8 hours)"
        case 8..<9:
            return "Very Good (8-9 hours)"
        default:
            return "Excellent (9+ hours)"
        }
    }
    
    var sleepRecommendation: String {
        guard let averageHours = averageSleepHours else { return "Aim for 7-9 hours of sleep for optimal hydration" }
        
        if averageHours < 7 {
            return "Poor sleep can increase dehydration. Consider improving sleep quality and increasing water intake."
        } else if averageHours > 9 {
            return "Good sleep quality! Maintain your current hydration routine."
        } else {
            return "Good sleep pattern. Your hydration needs are well-balanced."
        }
    }
    
    // MARK: - Update Methods
    
    func updateFromHealthKit(
        height: Double?,
        weight: Double?,
        age: Int?,
        gender: HKBiologicalSex?,
        averageSleepHours: Double?
    ) {
        self.height = height
        self.weight = weight
        self.age = age
        self.gender = gender?.stringValue
        self.averageSleepHours = averageSleepHours
        self.lastUpdated = Date()
        if averageSleepHours != nil {
            self.lastSleepDataUpdate = Date()
        }
    }
    
    func enableHealthKit() {
        self.isHealthKitEnabled = true
        self.lastUpdated = Date()
    }
    
    func disableHealthKit() {
        self.isHealthKitEnabled = false
        self.lastUpdated = Date()
    }
}

// MARK: - HKBiologicalSex Extension

extension HKBiologicalSex {
    var stringValue: String {
        switch self {
        case .male:
            return "male"
        case .female:
            return "female"
        case .other:
            return "other"
        case .notSet:
            return "notSet"
        @unknown default:
            return "notSet"
        }
    }
}
