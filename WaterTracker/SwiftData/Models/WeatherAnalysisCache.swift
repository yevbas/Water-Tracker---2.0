//
//  WeatherAnalysisCache.swift
//  WaterTracker
//
//  Created by Jackson on 08/09/2025.
//

import Foundation
import SwiftData
import WeatherKit

@Model
final class WeatherAnalysisCache {
    var date: Date
    var aiComment: String
    var weatherRecommendation: Data?
    var temperature: Double
    var humidity: Double
    var uvIndex: Int
    var condition: String
    var additionalWaterMl: Int
    var factors: [String]
    var priority: String
    var confidence: Double
    
    init(
        date: Date = Date(),
        aiComment: String,
        weatherRecommendation: Data? = nil,
        temperature: Double,
        humidity: Double,
        uvIndex: Int,
        condition: String,
        additionalWaterMl: Int,
        factors: [String],
        priority: String,
        confidence: Double
    ) {
        self.date = date
        self.aiComment = aiComment
        self.weatherRecommendation = weatherRecommendation
        self.temperature = temperature
        self.humidity = humidity
        self.uvIndex = uvIndex
        self.condition = condition
        self.additionalWaterMl = additionalWaterMl
        self.factors = factors
        self.priority = priority
        self.confidence = confidence
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    func toWeatherRecommendation() -> WeatherRecommendation? {
        guard let weatherData = weatherRecommendation,
              let recommendation = try? JSONDecoder().decode(WeatherRecommendationData.self, from: weatherData) else {
            return nil
        }
        
        return WeatherRecommendation(
            currentTemperature: temperature,
            maxTemperature: temperature + 3, // Approximate
            minTemperature: temperature - 3, // Approximate
            humidity: humidity,
            uvIndex: uvIndex,
            condition: WeatherCondition(rawValue: condition) ?? .clear,
            recommendation: recommendation
        )
    }
    
    static func fromWeatherRecommendation(_ recommendation: WeatherRecommendation, aiComment: String) -> WeatherAnalysisCache {
        let recommendationData = try? JSONEncoder().encode(recommendation.recommendation)
        
        return WeatherAnalysisCache(
            aiComment: aiComment,
            weatherRecommendation: recommendationData,
            temperature: recommendation.currentTemperature,
            humidity: recommendation.humidity,
            uvIndex: recommendation.uvIndex,
            condition: recommendation.condition.rawValue,
            additionalWaterMl: recommendation.recommendation.additionalWaterMl,
            factors: recommendation.recommendation.factors,
            priority: recommendation.recommendation.priority.rawValue,
            confidence: recommendation.recommendation.confidence
        )
    }
}
