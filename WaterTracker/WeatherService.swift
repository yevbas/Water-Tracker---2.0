//
//  WeatherService.swift
//  WaterTracker
//
//  Created by Jackson on 08/09/2025.
//

import Foundation
import WeatherKit
import CoreLocation

@MainActor
class WeatherService: NSObject, ObservableObject {
    @Published var currentWeather: CurrentWeather?
    @Published var dailyForecast: Forecast<DayWeather>?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let weatherService = WeatherKit.WeatherService.shared
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    func fetchWeatherData() async {
        // Check location authorization status
        guard locationManager.authorizationStatus == .authorizedWhenInUse || 
              locationManager.authorizationStatus == .authorizedAlways else {
            errorMessage = "Location permission required. Please enable location access in Settings."
            return
        }
        
        // Check if location is available
        guard let location = locationManager.location else {
            // If no location, try to start location updates
            locationManager.startUpdatingLocation()
            errorMessage = "Getting your location..."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let (currentWeather, dailyForecast) = try await weatherService.weather(for: location, including: .current, .daily)
            
            self.currentWeather = currentWeather
            self.dailyForecast = dailyForecast
        } catch {
            // If WeatherKit fails, provide mock data for development
            if error.localizedDescription.contains("WeatherDaemon") || 
               error.localizedDescription.contains("WDSJWTAuthenticator") {
                errorMessage = "WeatherKit not configured. Using sample data for development."
                await loadMockWeatherData()
            } else {
                errorMessage = "Failed to fetch weather data: \(error.localizedDescription)"
            }
        }
        
        isLoading = false
    }
    
    private func loadMockWeatherData() async {
        // Create mock weather data for development
        // This will be replaced with real WeatherKit data once configured
        // For now, we'll create a simple mock that provides the data we need
        // without trying to conform to WeatherKit protocols
        
        // We'll set a flag to indicate we're using mock data
        // and handle the weather recommendation calculation differently
        self.currentWeather = nil
        self.dailyForecast = nil
    }
    
    func getWeatherRecommendation() -> WeatherRecommendation? {
        // If we have real weather data, use it
        if let current = currentWeather,
           let daily = dailyForecast?.forecast.first {
            return WeatherRecommendation(
                currentTemperature: current.temperature.value,
                maxTemperature: daily.highTemperature.value,
                minTemperature: daily.lowTemperature.value,
                humidity: current.humidity,
                uvIndex: current.uvIndex.value,
                condition: current.condition,
                recommendation: calculateWaterRecommendation(
                    current: current,
                    daily: daily
                )
            )
        }
        
        // If we're using mock data (WeatherKit not configured), return mock recommendation
        if errorMessage?.contains("sample data") == true {
            return createMockWeatherRecommendation()
        }
        
        return nil
    }
    
    private func createMockWeatherRecommendation() -> WeatherRecommendation {
        // Mock weather data for development
        let mockTemperature = 25.0
        let mockMaxTemp = 28.0
        let mockMinTemp = 18.0
        let mockHumidity = 0.65
        let mockUVIndex = 6
        let mockCondition = WeatherCondition.partlyCloudy
        
        // Create mock recommendation data
        let mockRecommendation = WeatherRecommendationData(
            additionalWaterMl: 300, // +300ml for warm weather
            factors: ["Warm temperature (+300ml)", "Moderate humidity (+100ml)"],
            confidence: 0.85,
            priority: .medium
        )
        
        return WeatherRecommendation(
            currentTemperature: mockTemperature,
            maxTemperature: mockMaxTemp,
            minTemperature: mockMinTemp,
            humidity: mockHumidity,
            uvIndex: mockUVIndex,
            condition: mockCondition,
            recommendation: mockRecommendation
        )
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
            factors.append("High temperature (+500ml)")
        } else if tempCelsius > 25 {
            baseAdjustment += 300
            factors.append("Warm temperature (+300ml)")
        } else if tempCelsius < 10 {
            baseAdjustment -= 100
            factors.append("Cold weather (-100ml)")
        }
        
        // Humidity adjustments
        if humidity < 0.3 {
            baseAdjustment += 200
            factors.append("Low humidity (+200ml)")
        } else if humidity > 0.8 {
            baseAdjustment += 100
            factors.append("High humidity (+100ml)")
        }
        
        // UV Index adjustments
        if uvIndex >= 8 {
            baseAdjustment += 150
            factors.append("Very high UV (+150ml)")
        } else if uvIndex >= 6 {
            baseAdjustment += 100
            factors.append("High UV (+100ml)")
        }
        
        // Daily max temperature consideration
        if maxTemp > 35 {
            baseAdjustment += 200
            factors.append("Very hot day expected (+200ml)")
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

// MARK: - CLLocationManagerDelegate

extension WeatherService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Stop location updates once we have a location
        locationManager.stopUpdatingLocation()
        
        // Fetch weather data with the new location
        Task {
            await fetchWeatherDataWithLocation(location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "Location error: \(error.localizedDescription)"
        isLoading = false
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            // Permission granted, try to fetch weather data
            Task {
                await fetchWeatherData()
            }
        case .denied, .restricted:
            errorMessage = "Location permission denied. Please enable location access in Settings."
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
    
    private func fetchWeatherDataWithLocation(_ location: CLLocation) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let (currentWeather, dailyForecast) = try await weatherService.weather(for: location, including: .current, .daily)
            
            self.currentWeather = currentWeather
            self.dailyForecast = dailyForecast
        } catch {
            errorMessage = "Failed to fetch weather data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

// MARK: - Mock Weather Data for Development
// Note: Mock data is now handled through WeatherRecommendation directly
// instead of trying to mock WeatherKit types
