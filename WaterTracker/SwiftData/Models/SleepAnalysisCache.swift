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
        date: Date = Date(),
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
        self.date = date
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
            recommendation: recommendation
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
}
