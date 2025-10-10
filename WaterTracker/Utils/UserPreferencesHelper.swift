//
//  UserPreferencesHelper.swift
//  WaterTracker
//
//  Helper utilities for accessing user preferences
//

import Foundation
import SwiftUI

/// Helper for accessing user preferences consistently across the app
struct UserPreferencesHelper {
    
    // MARK: - Water Goal
    
    /// Gets the user's daily water goal in milliliters
    /// Falls back to default if not set
    static func getDailyWaterGoalMl() -> Double {
        let goalMl = UserDefaults.standard.integer(forKey: "water_goal_ml")
        
        // If not set (returns 0), use default
        if goalMl <= 0 {
            return CardViewConstants.Sleep.fallbackDailyTargetMl
        }
        
        return Double(goalMl)
    }
    
    // MARK: - Temperature Unit
    
    /// Gets the user's preferred temperature unit
    static func getTemperatureUnit() -> CardViewConstants.Weather.TemperatureUnit {
        let unitString = UserDefaults.standard.string(forKey: "temperature_unit") ?? "celsius"
        return CardViewConstants.Weather.TemperatureUnit(rawValue: unitString) ?? .celsius
    }
    
    /// Sets the user's preferred temperature unit
    static func setTemperatureUnit(_ unit: CardViewConstants.Weather.TemperatureUnit) {
        UserDefaults.standard.set(unit.rawValue, forKey: "temperature_unit")
    }
    
    // MARK: - Measurement Units
    
    /// Gets the user's preferred measurement unit for water
    static func getMeasurementUnit() -> WaterUnit {
        let unitString = UserDefaults.standard.string(forKey: "measurement_units") ?? "ml"
        return WaterUnit.fromString(unitString)
    }
}

/// View extension for easy access to preferences
extension View {
    /// Formats water amount according to user's measurement unit preference
    func formatWaterAmount(_ ml: Int) -> String {
        let unit = UserPreferencesHelper.getMeasurementUnit()
        
        switch unit {
        case .ounces:
            let oz = unit.fromMilliliters(Double(ml))
            return String(localized: "\(Int(oz.rounded())) fl oz")
        case .millilitres:
            return String(localized: "\(ml) ml")
        }
    }
    
    /// Formats temperature according to user's temperature unit preference
    func formatTemperature(_ celsius: Double) -> String {
        let unit = UserPreferencesHelper.getTemperatureUnit()
        let value = unit.convert(celsius: celsius)
        return "\(Int(value))\(unit.symbol)"
    }
}

