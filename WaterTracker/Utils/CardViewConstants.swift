//
//  CardViewConstants.swift
//  WaterTracker
//
//  Constants for WeatherCardView and SleepCardView
//

import Foundation
import SwiftUI

/// Centralized constants for weather and sleep analysis cards
enum CardViewConstants {
    
    // MARK: - Layout Constants
    
    enum Layout {
        static let cardPadding: CGFloat = 16
        static let cardCornerRadius: CGFloat = 10
        static let innerSpacing: CGFloat = 12
        static let sectionSpacing: CGFloat = 20
        static let iconSize: CGFloat = 20
        static let shadowRadius: CGFloat = 2
        static let shadowOpacity: CGFloat = 0.05
    }
    
    // MARK: - Sleep Analysis Constants
    
    enum Sleep {
        /// Afternoon cutoff time for caffeine tracking (3 PM)
        static let afternoonCaffeineHour = 15
        
        /// Hours to look back from bedtime for evening intake calculation
        static let eveningIntakeWindowHours = 3
        
        /// Default bedtime hour when no sleep data available (10 PM)
        static let defaultBedtimeHour = 22
        
        /// Default daily water target in milliliters when user goal unavailable
        static let fallbackDailyTargetMl: Double = 2000.0
        
        /// Minimum valid water intake to consider for analysis (ml)
        static let minimumValidIntakeMl: Double = 100.0
        
        /// Data completeness thresholds (number of nights)
        static let minimalDataNights = 7
        static let moderateDataNights = 21
        static let goodDataNights = 45
        static let robustDataNights = 60
        
        /// Historical data lookback period (days)
        static let historicalDataLookbackDays = 60
        static let lastWeekDataLookbackDays = 7
        
        // MARK: - Evening Intake Thresholds
        
        /// Optimal evening intake percentage (≤20%)
        static let optimalEveningIntakeThreshold = 0.20
        
        /// Warning evening intake percentage (20-30%)
        static let warningEveningIntakeThreshold = 0.30
        
        /// Critical evening intake percentage (>30%)
        static let criticalEveningIntakeThreshold = 0.30
        
        // MARK: - Hydration Score Thresholds
        
        /// Optimal hydration score (≥80%)
        static let optimalHydrationThreshold = 0.80
        
        /// Warning hydration score (60-80%)
        static let warningHydrationThreshold = 0.60
        
        // MARK: - Nocturia Risk Calculation
        
        /// Risk score thresholds
        static let highNocturiaRiskThreshold = 35
        static let moderateNocturiaRiskThreshold = 20
        
        /// Evening intake risk points
        static let veryHighEveningIntakePercentage = 0.35
        static let highEveningIntakePercentage = 0.25
        static let moderateEveningIntakePercentage = 0.20
        
        static let veryHighEveningRiskPoints = 40
        static let highEveningRiskPoints = 25
        static let moderateEveningRiskPoints = 15
        static let lowEveningRiskPoints = 5
        
        /// Total intake risk points
        static let veryHighTotalIntakeMl = 3000.0
        static let highTotalIntakeMl = 2500.0
        static let veryHighIntakeRiskPoints = 20
        static let highIntakeRiskPoints = 10
        
        /// Caffeine risk points
        static let largeCaffeineAmountMl = 500.0
        static let moderateCaffeineAmountMl = 250.0
        static let largeCaffeineRiskPoints = 15
        static let moderateCaffeineRiskPoints = 10
        static let smallCaffeineRiskPoints = 5
        
        /// Alcohol/other drinks risk
        static let eveningOtherDrinksRiskPoints = 5
        
        // MARK: - Insight Generation
        
        /// Thresholds for insights
        static let excellentHydrationThreshold = 0.85
        static let lowHydrationThreshold = 0.60
        static let greatTimingThreshold = 0.15
        static let poorTimingThreshold = 0.30
    }
    
    // MARK: - Weather Analysis Constants
    
    enum Weather {
        /// Temperature thresholds (Celsius)
        static let hotTemperatureC: Double = 30.0
        static let warmTemperatureC: Double = 25.0
        static let coldTemperatureC: Double = 10.0
        static let veryHotMaxTempC: Double = 35.0
        
        /// Humidity thresholds
        static let lowHumidityThreshold: Double = 0.3
        static let highHumidityThreshold: Double = 0.8
        
        /// UV Index thresholds
        static let veryHighUVIndex: Int = 8
        static let highUVIndex: Int = 6
        
        /// Temperature units
        enum TemperatureUnit: String {
            case celsius = "celsius"
            case fahrenheit = "fahrenheit"
            
            var symbol: String {
                switch self {
                case .celsius: return "°C"
                case .fahrenheit: return "°F"
                }
            }
            
            /// Convert Celsius to the target unit
            func convert(celsius: Double) -> Double {
                switch self {
                case .celsius:
                    return celsius
                case .fahrenheit:
                    return (celsius * 9/5) + 32
                }
            }
            
            /// Convert from this unit to Celsius
            func toCelsius(value: Double) -> Double {
                switch self {
                case .celsius:
                    return value
                case .fahrenheit:
                    return (value - 32) * 5/9
                }
            }
        }
    }
    
    // MARK: - Error Messages
    
    enum ErrorMessages {
        static let noWeatherData = String(localized: "No weather data available")
        static let noSleepData = String(localized: "No sleep data available")
        static let fetchFailed = String(localized: "Failed to fetch data")
        static let aiGenerationFailed = String(localized: "Failed to generate AI insight")
        static let locationPermissionRequired = String(localized: "Location permission required")
    }
    
    // MARK: - Animation
    
    enum Animation {
        static let springResponse: Double = 0.4
        static let springDamping: Double = 0.8
    }
}

/// Temperature formatting helper
struct TemperatureFormatter {
    let unit: CardViewConstants.Weather.TemperatureUnit
    
    func format(_ celsius: Double) -> String {
        let value = unit.convert(celsius: celsius)
        return "\(Int(value))\(unit.symbol)"
    }
    
    func formatWithLabel(_ celsius: Double, label: String) -> String {
        let value = unit.convert(celsius: celsius)
        return "\(label): \(Int(value))\(unit.symbol)"
    }
}

