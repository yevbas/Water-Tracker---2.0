//
//  SleepAnalysisCache.swift
//  WaterTracker
//
//  Created by AI Assistant
//

import Foundation
import SwiftData

@Model
final class SleepAnalysisCache {
    var date: Date
    var aiComment: String
    var sleepRecommendation: Data?
    var sleepDurationHours: Double
    var sleepQualityScore: Double
    var bedTime: Date?
    var wakeTime: Date?
    var deepSleepMinutes: Int
    var remSleepMinutes: Int
    var additionalWaterMl: Int
    var factors: [String]
    var priority: String
    var confidence: Double
    
    init(
        date: Date = Date().rounded(),
        aiComment: String,
        sleepRecommendation: Data? = nil,
        sleepDurationHours: Double,
        sleepQualityScore: Double,
        bedTime: Date? = nil,
        wakeTime: Date? = nil,
        deepSleepMinutes: Int,
        remSleepMinutes: Int,
        additionalWaterMl: Int,
        factors: [String],
        priority: String,
        confidence: Double
    ) {
        self.date = date.rounded()
        self.aiComment = aiComment
        self.sleepRecommendation = sleepRecommendation
        self.sleepDurationHours = sleepDurationHours
        self.sleepQualityScore = sleepQualityScore
        self.bedTime = bedTime
        self.wakeTime = wakeTime
        self.deepSleepMinutes = deepSleepMinutes
        self.remSleepMinutes = remSleepMinutes
        self.additionalWaterMl = additionalWaterMl
        self.factors = factors
        self.priority = priority
        self.confidence = confidence
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    func toSleepRecommendation() -> SleepRecommendation? {
        guard let sleepData = sleepRecommendation,
              let recommendation = try? JSONDecoder().decode(SleepRecommendationData.self, from: sleepData) else {
            return nil
        }
        
        return SleepRecommendation(
            sleepDurationHours: sleepDurationHours,
            sleepQualityScore: sleepQualityScore,
            bedTime: bedTime,
            wakeTime: wakeTime,
            deepSleepMinutes: deepSleepMinutes,
            remSleepMinutes: remSleepMinutes,
            recommendation: recommendation,
            actualSleepDate: nil // Cache doesn't store this, will be nil for cached data
        )
    }
    
    static func fromSleepRecommendation(_ recommendation: SleepRecommendation, aiComment: String) -> SleepAnalysisCache {
        let recommendationData = try? JSONEncoder().encode(recommendation.recommendation)
        
        return SleepAnalysisCache(
            aiComment: aiComment,
            sleepRecommendation: recommendationData,
            sleepDurationHours: recommendation.sleepDurationHours,
            sleepQualityScore: recommendation.sleepQualityScore,
            bedTime: recommendation.bedTime,
            wakeTime: recommendation.wakeTime,
            deepSleepMinutes: recommendation.deepSleepMinutes,
            remSleepMinutes: recommendation.remSleepMinutes,
            additionalWaterMl: recommendation.recommendation.additionalWaterMl,
            factors: recommendation.recommendation.factors,
            priority: recommendation.recommendation.priority.rawValue,
            confidence: recommendation.recommendation.confidence
        )
    }
    
    /// Removes all sleep data except for the current date
    /// This keeps only the most recent sleep analysis to avoid storing unnecessary historical data
    static func cleanupOldData(modelContext: ModelContext, keepingCurrentDate currentDate: Date = Date().rounded()) {
        let descriptor = FetchDescriptor<SleepAnalysisCache>()
        
        do {
            let allCaches = try modelContext.fetch(descriptor)
            let currentRoundedDate = currentDate.rounded()
            
            for cache in allCaches {
                // Remove all sleep data that's not for the current date
                if cache.date.rounded() != currentRoundedDate {
                    modelContext.delete(cache)
                }
            }
            
            try modelContext.save()
        } catch {
            print("Failed to cleanup old sleep data: \(error)")
        }
    }
}
