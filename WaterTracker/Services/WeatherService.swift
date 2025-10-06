//
//  WeatherService.swift
//  WaterTracker
//
//  Created by Jackson on 08/09/2025.
//

import Foundation
import WeatherKit
import CoreLocation
import SwiftData

@MainActor
class WeatherService: NSObject, ObservableObject {
    private let weatherService = WeatherKit.WeatherService.shared
    let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }

    
    func fetchWeatherData() async throws -> WeatherRecommendation {
        // Check location authorization status
        guard locationManager.authorizationStatus == .authorizedWhenInUse || 
              locationManager.authorizationStatus == .authorizedAlways else {
            throw WeatherError.locationPermissionRequired
        }
        
        // Check if location is available
        guard let location = locationManager.location else {
            locationManager.startUpdatingLocation()
            throw WeatherError.locationUnavailable
        }
        
        let (currentWeather, dailyForecast) = try await weatherService.weather(for: location, including: .current, .daily)
        
        guard let daily = dailyForecast.forecast.first else {
            throw WeatherError.noWeatherData
        }
        
        let current = currentWeather
        
        return WeatherRecommendation(
            currentTemperature: current.temperature.value,
            maxTemperature: daily.highTemperature.value,
            minTemperature: daily.lowTemperature.value,
            humidity: current.humidity,
            uvIndex: current.uvIndex.value,
            condition: current.condition,
            recommendation: calculateWaterRecommendation(current: current, daily: daily)
        )
    }
    
    func getLocationName(for location: CLLocation) async -> String {
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                return placemark.locality ?? placemark.administrativeArea ?? placemark.country ?? String(localized: "Unknown Location")
            }
        } catch {
            return String(localized: "Current Location")
        }
        return String(localized: "Current Location")
    }
    
    
    private func calculateWaterRecommendation(current: CurrentWeather, daily: DayWeather) -> WeatherRecommendationData {
        let tempCelsius = current.temperature.value
        let humidity = current.humidity
        let uvIndex = current.uvIndex.value
        let maxTemp = daily.highTemperature.value
        
        var baseAdjustment = 0.0
        var factors: [String] = []
        
        // Temperature-based adjustments
        if tempCelsius > 30 {
            baseAdjustment += 500
            factors.append(String(localized: "High temperature (+500ml)"))
        } else if tempCelsius > 25 {
            baseAdjustment += 300
            factors.append(String(localized: "Warm temperature (+300ml)"))
        } else if tempCelsius < 10 {
            baseAdjustment -= 100
            factors.append(String(localized: "Cold weather (-100ml)"))
        }
        
        // Humidity adjustments
        if humidity < 0.3 {
            baseAdjustment += 200
            factors.append(String(localized: "Low humidity (+200ml)"))
        } else if humidity > 0.8 {
            baseAdjustment += 100
            factors.append(String(localized: "High humidity (+100ml)"))
        }
        
        // UV Index adjustments
        if uvIndex >= 8 {
            baseAdjustment += 150
            factors.append(String(localized: "Very high UV (+150ml)"))
        } else if uvIndex >= 6 {
            baseAdjustment += 100
            factors.append(String(localized: "High UV (+100ml)"))
        }
        
        // Daily max temperature consideration
        if maxTemp > 35 {
            baseAdjustment += 200
            factors.append(String(localized: "Very hot day expected (+200ml)"))
        }
        
        let totalAdjustment = max(0, baseAdjustment)
        
        return WeatherRecommendationData(
            additionalWaterMl: Int(totalAdjustment),
            factors: factors,
            confidence: calculateConfidence(factors: factors),
            priority: determinePriority(adjustment: totalAdjustment)
        )
    }
    
    private func calculateConfidence(factors: [String]) -> Double {
        // More factors = higher confidence
        let factorCount = Double(factors.count)
        return min(0.95, 0.5 + (factorCount * 0.15))
    }
    
    private func determinePriority(adjustment: Double) -> WeatherPriority {
        if adjustment >= 500 {
            return .high
        } else if adjustment >= 200 {
            return .medium
        } else {
            return .low
        }
    }
}

// MARK: - Weather Models

struct WeatherRecommendation {
    let currentTemperature: Double
    let maxTemperature: Double
    let minTemperature: Double
    let humidity: Double
    let uvIndex: Int
    let condition: WeatherCondition
    let recommendation: WeatherRecommendationData
}

struct WeatherRecommendationData: Codable {
    let additionalWaterMl: Int
    let factors: [String]
    let confidence: Double
    let priority: WeatherPriority
}

enum WeatherPriority: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "orange"
        case .high: return "red"
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "checkmark.circle"
        case .medium: return "exclamationmark.triangle"
        case .high: return "exclamationmark.octagon"
        }
    }
}

// MARK: - Weather Error

enum WeatherError: LocalizedError {
    case locationPermissionRequired
    case locationUnavailable
    case noWeatherData
    
    var errorDescription: String? {
        switch self {
        case .locationPermissionRequired:
            return String(localized: "Location permission required. Please enable location access in Settings.")
        case .locationUnavailable:
            return String(localized: "Getting your location...")
        case .noWeatherData:
            return String(localized: "Failed to fetch weather data")
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension WeatherService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Location error handling is now done in the calling code
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // Authorization status changes are handled by the calling code
    }
}
