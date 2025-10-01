//
//  WeatherTestView.swift
//  WaterTracker
//
//  Created by AI Assistant for testing weather card functionality
//

import SwiftUI
import SwiftData

struct WeatherTestView: View {
    @Environment(\.modelContext) var modelContext
    @State private var weatherService = WeatherService()
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Weather Card Test")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Test different weather scenarios and AI recommendations")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                // Weather Card
                WeatherCardView(
                    selectedDate: selectedDate,
                    isLoading: false
                )
                
                // Test Controls
                VStack(spacing: 16) {
                    Button("Generate Test Scenarios") {
                        weatherService.createTestWeatherScenarios(modelContext: modelContext)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Create Today's Mock Data") {
                        weatherService.createMockWeatherCache(for: Date(), modelContext: modelContext)
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Clear All Weather Data") {
                        clearWeatherData()
                    }
                    .buttonStyle(.bordered)
                    .foregroundStyle(.red)
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    private func clearWeatherData() {
        do {
            let descriptor = FetchDescriptor<WeatherAnalysisCache>()
            let allWeatherData = try modelContext.fetch(descriptor)
            
            for weatherData in allWeatherData {
                modelContext.delete(weatherData)
            }
            
            try modelContext.save()
        } catch {
            print("Failed to clear weather data: \(error)")
        }
    }
}

#Preview {
    WeatherTestView()
        .modelContainer(for: WeatherAnalysisCache.self, inMemory: true)
}
