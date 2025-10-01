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
    @Published var currentWeather: CurrentWeather?
    @Published var dailyForecast: Forecast<DayWeather>?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var locationName: String?
    
    private let weatherService = WeatherKit.WeatherService.shared
    private let locationManager = CLLocationManager()
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
    
    func fetchWeatherData() async {
        isLoading = true
        errorMessage = nil
        
        // Check location authorization status
        guard locationManager.authorizationStatus == .authorizedWhenInUse || 
              locationManager.authorizationStatus == .authorizedAlways else {
            errorMessage = "Location permission required. Please enable location access in Settings."
            isLoading = false
            return
        }
        
        // Check if location is available
        guard let location = locationManager.location else {
            // If no location, try to start location updates
            locationManager.startUpdatingLocation()
            errorMessage = "Getting your location..."
            isLoading = false
            return
        }
        
        do {
            let (currentWeather, dailyForecast) = try await weatherService.weather(for: location, including: .current, .daily)
            
            self.currentWeather = currentWeather
            self.dailyForecast = dailyForecast
            
            // Fetch location name
            await fetchLocationName(for: location)
        } catch {
            // If WeatherKit fails, provide mock data as fallback
            if error.localizedDescription.contains("WeatherDaemon") || 
               error.localizedDescription.contains("WDSJWTAuthenticator") {
                errorMessage = "WeatherKit not configured. Using sample data for development."
                await loadMockWeatherData()
            } else {
                errorMessage = "Failed to fetch weather data: \(error.localizedDescription)"
                // Still provide mock data as fallback for better UX
                await loadMockWeatherData()
            }
        }
        
        isLoading = false
    }
    
    private func fetchLocationName(for location: CLLocation) async {
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                // Try to get city name first, then locality, then administrative area
                let cityName = placemark.locality ?? placemark.administrativeArea ?? placemark.country ?? "Unknown Location"
                locationName = cityName
            }
        } catch {
            print("Failed to fetch location name: \(error)")
            locationName = "Current Location"
        }
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
        
        // Set mock location name
        self.locationName = "San Francisco, CA"
    }
    
    func getWeatherRecommendation() -> WeatherRecommendation? {
        #if DEBUG
        // In debug mode, always return mock data
        return createMockWeatherRecommendation()
        #endif
        
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
        if errorMessage?.contains("sample data") == true || errorMessage?.contains("mock weather data") == true {
            return createMockWeatherRecommendation()
        }
        
        return nil
    }
    
    private func createMockWeatherRecommendation() -> WeatherRecommendation {
        // Enhanced mock weather data with multiple scenarios for testing
        let scenarios = [
            // Hot sunny day
            (temp: 32.0, maxTemp: 36.0, minTemp: 24.0, humidity: 0.35, uvIndex: 9, condition: WeatherCondition.clear),
            // Warm humid day
            (temp: 28.0, maxTemp: 30.0, minTemp: 22.0, humidity: 0.75, uvIndex: 6, condition: WeatherCondition.partlyCloudy),
            // Cool rainy day
            (temp: 18.0, maxTemp: 20.0, minTemp: 15.0, humidity: 0.85, uvIndex: 2, condition: WeatherCondition.rain),
            // Cold winter day
            (temp: 5.0, maxTemp: 8.0, minTemp: 2.0, humidity: 0.60, uvIndex: 1, condition: WeatherCondition.cloudy),
            // Moderate spring day
            (temp: 22.0, maxTemp: 25.0, minTemp: 18.0, humidity: 0.50, uvIndex: 4, condition: WeatherCondition.partlyCloudy)
        ]
        
        // Randomly select a scenario for variety in testing
        let scenario = scenarios.randomElement() ?? scenarios[0]
        
        // Calculate enhanced recommendation based on weather conditions
        let recommendation = calculateEnhancedWaterRecommendation(
            currentTemp: scenario.temp,
            maxTemp: scenario.maxTemp,
            minTemp: scenario.minTemp,
            humidity: scenario.humidity,
            uvIndex: scenario.uvIndex,
            condition: scenario.condition
        )
        
        return WeatherRecommendation(
            currentTemperature: scenario.temp,
            maxTemperature: scenario.maxTemp,
            minTemperature: scenario.minTemp,
            humidity: scenario.humidity,
            uvIndex: scenario.uvIndex,
            condition: scenario.condition,
            recommendation: recommendation
        )
    }
    
    private func calculateEnhancedWaterRecommendation(
        currentTemp: Double,
        maxTemp: Double,
        minTemp: Double,
        humidity: Double,
        uvIndex: Int,
        condition: WeatherCondition
    ) -> WeatherRecommendationData {
        var baseAdjustment = 0.0
        var factors: [String] = []
        var confidence = 0.5
        
        // Temperature-based adjustments (more nuanced)
        if currentTemp >= 35 {
            baseAdjustment += 600
            factors.append("Extreme heat (+600ml)")
            confidence += 0.2
        } else if currentTemp >= 30 {
            baseAdjustment += 400
            factors.append("Hot temperature (+400ml)")
            confidence += 0.15
        } else if currentTemp >= 25 {
            baseAdjustment += 250
            factors.append("Warm temperature (+250ml)")
            confidence += 0.1
        } else if currentTemp <= 5 {
            baseAdjustment -= 150
            factors.append("Cold weather (-150ml)")
            confidence += 0.1
        } else if currentTemp <= 10 {
            baseAdjustment -= 100
            factors.append("Cool weather (-100ml)")
            confidence += 0.05
        }
        
        // Humidity adjustments (more detailed)
        if humidity < 0.25 {
            baseAdjustment += 300
            factors.append("Very dry air (+300ml)")
            confidence += 0.15
        } else if humidity < 0.40 {
            baseAdjustment += 200
            factors.append("Low humidity (+200ml)")
            confidence += 0.1
        } else if humidity > 0.85 {
            baseAdjustment += 150
            factors.append("High humidity (+150ml)")
            confidence += 0.1
        } else if humidity > 0.70 {
            baseAdjustment += 100
            factors.append("Moderate humidity (+100ml)")
            confidence += 0.05
        }
        
        // UV Index adjustments (more comprehensive)
        if uvIndex >= 10 {
            baseAdjustment += 200
            factors.append("Extreme UV exposure (+200ml)")
            confidence += 0.15
        } else if uvIndex >= 8 {
            baseAdjustment += 150
            factors.append("Very high UV (+150ml)")
            confidence += 0.1
        } else if uvIndex >= 6 {
            baseAdjustment += 100
            factors.append("High UV (+100ml)")
            confidence += 0.05
        } else if uvIndex >= 3 {
            baseAdjustment += 50
            factors.append("Moderate UV (+50ml)")
        }
        
        // Weather condition adjustments
        switch condition {
        case .clear, .mostlyClear:
            baseAdjustment += 100
            factors.append("Clear skies (+100ml)")
            confidence += 0.05
        case .rain, .drizzle:
            baseAdjustment -= 50
            factors.append("Rainy weather (-50ml)")
        case .snow, .blizzard:
            baseAdjustment -= 100
            factors.append("Snowy weather (-100ml)")
        case .thunderstorms, .strongStorms:
            baseAdjustment += 75
            factors.append("Stormy conditions (+75ml)")
        case .foggy, .haze:
            baseAdjustment += 50
            factors.append("Foggy conditions (+50ml)")
        default:
            break
        }
        
        // Daily temperature range consideration
        let tempRange = maxTemp - minTemp
        if tempRange > 15 {
            baseAdjustment += 100
            factors.append("Large temperature swing (+100ml)")
            confidence += 0.05
        }
        
        // Ensure minimum adjustment
        let totalAdjustment = max(0, baseAdjustment)
        
        // Determine priority based on multiple factors
        let priority: WeatherPriority
        if totalAdjustment >= 500 || currentTemp >= 35 || uvIndex >= 10 {
            priority = .high
        } else if totalAdjustment >= 200 || currentTemp >= 25 || uvIndex >= 6 {
            priority = .medium
        } else {
            priority = .low
        }
        
        return WeatherRecommendationData(
            additionalWaterMl: Int(totalAdjustment),
            factors: factors,
            confidence: min(0.95, confidence),
            priority: priority
        )
    }
    
    // MARK: - Cache Management
    
    func createMockWeatherCache(for date: Date, modelContext: ModelContext) {
        let recommendation = createMockWeatherRecommendation()
        let aiComment = generateMockAIComment(for: recommendation)
        
        let cache = WeatherAnalysisCache.fromWeatherRecommendation(recommendation, aiComment: aiComment, locationName: locationName)
        cache.date = date
        
        modelContext.insert(cache)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save mock weather cache: \(error)")
        }
    }
    
    // MARK: - Testing Helper Methods
    
    /// Creates multiple mock weather scenarios for testing different conditions
    func createTestWeatherScenarios(modelContext: ModelContext) {
        let scenarios = [
            // Hot sunny day
            (date: Date(), temp: 35.0, maxTemp: 38.0, minTemp: 28.0, humidity: 0.30, uvIndex: 10, condition: WeatherCondition.clear),
            // Warm humid day
            (date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(), temp: 28.0, maxTemp: 30.0, minTemp: 24.0, humidity: 0.80, uvIndex: 6, condition: WeatherCondition.partlyCloudy),
            // Cool rainy day
            (date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(), temp: 18.0, maxTemp: 20.0, minTemp: 15.0, humidity: 0.90, uvIndex: 2, condition: WeatherCondition.rain),
            // Cold winter day
            (date: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(), temp: 3.0, maxTemp: 6.0, minTemp: -1.0, humidity: 0.65, uvIndex: 1, condition: WeatherCondition.cloudy),
            // Perfect spring day
            (date: Calendar.current.date(byAdding: .day, value: -4, to: Date()) ?? Date(), temp: 22.0, maxTemp: 25.0, minTemp: 18.0, humidity: 0.55, uvIndex: 4, condition: WeatherCondition.partlyCloudy)
        ]
        
        for scenario in scenarios {
            let recommendation = WeatherRecommendation(
                currentTemperature: scenario.temp,
                maxTemperature: scenario.maxTemp,
                minTemperature: scenario.minTemp,
                humidity: scenario.humidity,
                uvIndex: scenario.uvIndex,
                condition: scenario.condition,
                recommendation: calculateEnhancedWaterRecommendation(
                    currentTemp: scenario.temp,
                    maxTemp: scenario.maxTemp,
                    minTemp: scenario.minTemp,
                    humidity: scenario.humidity,
                    uvIndex: scenario.uvIndex,
                    condition: scenario.condition
                )
            )
            
            let aiComment = generateMockAIComment(for: recommendation)
            let cache = WeatherAnalysisCache.fromWeatherRecommendation(recommendation, aiComment: aiComment, locationName: "Test Location \(scenarios.firstIndex(where: { $0.date == scenario.date }) ?? 0 + 1)")
            cache.date = scenario.date
            
            modelContext.insert(cache)
        }
        
        do {
            try modelContext.save()
            print("✅ Created \(scenarios.count) test weather scenarios")
        } catch {
            print("❌ Failed to save test weather scenarios: \(error)")
        }
    }
    
    func generateMockAIComment(for recommendation: WeatherRecommendation) -> String {
        let temp = recommendation.currentTemperature
        let humidity = recommendation.humidity
        let uvIndex = recommendation.uvIndex
        let condition = recommendation.condition
        let additionalWater = recommendation.recommendation.additionalWaterMl
        
        // Generate contextual AI comments based on weather conditions
        if temp >= 35 {
            return "🔥 Extreme heat alert! With temperatures soaring to \(Int(temp))°C, your body is working overtime to cool down. Stay ahead of dehydration by sipping water every 15-20 minutes, even if you don't feel thirsty yet."
        } else if temp >= 30 {
            return "☀️ Hot day ahead! At \(Int(temp))°C with \(Int(humidity * 100))% humidity, you'll need extra hydration to maintain your body's cooling system. Consider adding electrolytes if you're active outdoors."
        } else if temp >= 25 {
            return "🌤️ Warm and pleasant! Perfect weather for staying hydrated. The \(Int(temp))°C temperature means your body will naturally need more fluids, especially if you're spending time outside."
        } else if temp <= 10 {
            return "❄️ Cool weather means less obvious thirst, but your body still needs hydration! The dry air at \(Int(temp))°C can be deceptively dehydrating. Keep sipping water regularly."
        } else if temp <= 5 {
            return "🧊 Cold weather alert! While you might not feel thirsty in \(Int(temp))°C weather, indoor heating and dry air can actually increase your hydration needs. Don't forget to drink water!"
        } else if humidity < 0.3 {
            return "🏜️ Very dry air detected! With only \(Int(humidity * 100))% humidity, your body loses moisture faster through breathing and skin. Increase your water intake to compensate for the dry conditions."
        } else if humidity > 0.8 {
            return "💧 High humidity day! While the air feels moist at \(Int(humidity * 100))% humidity, your body still needs extra water to regulate temperature. The muggy conditions make cooling more challenging."
        } else if uvIndex >= 8 {
            return "⚠️ High UV exposure! With a UV index of \(uvIndex), your skin needs extra protection and your body needs extra hydration. Sun exposure increases fluid loss through sweating and skin damage repair."
        } else if uvIndex >= 6 {
            return "☀️ Moderate UV levels detected. The UV index of \(uvIndex) means some sun protection is needed, and your hydration should account for the increased outdoor activity potential."
        } else if condition == .rain || condition == .drizzle {
            return "🌧️ Rainy day ahead! While the cooler, wet weather might reduce your thirst, don't let it fool you - your body still needs regular hydration. The humidity can actually make you feel more comfortable drinking water."
        } else if condition == .snow || condition == .blizzard {
            return "❄️ Snowy conditions! Cold weather can suppress thirst, but the dry air and indoor heating mean you still need to stay hydrated. Hot beverages count toward your daily intake too!"
        } else if condition == .thunderstorms || condition == .strongStorms {
            return "⛈️ Stormy weather! The atmospheric pressure changes and humidity fluctuations can affect your body's hydration needs. Stay consistent with your water intake despite the dramatic weather."
        } else if additionalWater >= 500 {
            return "🚨 High hydration alert! Your body needs significantly more water today due to the weather conditions. Consider setting more frequent reminders and keep a water bottle close by."
        } else if additionalWater >= 200 {
            return "💡 Moderate hydration boost needed! The current weather conditions suggest drinking extra water today. Your body will thank you for the additional hydration support."
        } else if additionalWater > 0 {
            return "✅ Slight hydration adjustment recommended! The weather suggests a small increase in your daily water intake. Every little bit helps maintain optimal hydration."
        } else {
            return "🌤️ Perfect hydration weather! The current conditions are ideal for maintaining your regular water intake goals. Keep up the great hydration habits!"
        }
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
            
            // Fetch location name
            await fetchLocationName(for: location)
        } catch {
            errorMessage = "Failed to fetch weather data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

// MARK: - Mock Weather Data for Development
// Note: Mock data is now handled through WeatherRecommendation directly
// instead of trying to mock WeatherKit types
