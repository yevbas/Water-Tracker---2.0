//
//  WeatherCardView.swift
//  WaterTracker
//
//  Created by AI Assistant
//

import SwiftUI
import WeatherKit
import SwiftData

struct WeatherCardView: View {
    let selectedDate: Date
    let isLoading: Bool

    @Environment(\.modelContext) var modelContext
    @AppStorage("measurement_units") private var measurementUnits: String = "ml"
    @StateObject private var aiClient = AIDrinkAnalysisClient.shared

    @Query private var allWeatherAnalyses: [WeatherAnalysisCache]

    @State private var isExpanded = false
    @State private var isGeneratingAIComment = false
    @State private var isRefreshingWeather = false
    @State private var currentAIComment = ""
    @State private var weatherService = WeatherService()

    private var cachedAnalysis: WeatherAnalysisCache? {
        let startOfDay = Calendar.current.startOfDay(for: selectedDate)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        return allWeatherAnalyses.first { analysis in
            analysis.date >= startOfDay && analysis.date < endOfDay
        }
    }

    private var hasCachedData: Bool {
        cachedAnalysis != nil
    }

    private var weatherRecommendation: WeatherRecommendation? {
        cachedAnalysis?.toWeatherRecommendation()
    }

    private var aiComment: String {
        if !currentAIComment.isEmpty {
            return currentAIComment
        }
        return cachedAnalysis?.aiComment ?? ""
    }

    private var lastAnalysisDate: Date? {
        cachedAnalysis?.date
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header - Always Visible
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
                
                // Generate AI comment when expanding if we have weather data but no AI comment
                if isExpanded && weatherRecommendation != nil && aiComment.isEmpty {
                    generateAIComment()
                }
            }) {
                HStack(spacing: 12) {
                    // Weather Icon
                    weatherIconView

                    // Weather Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Weather Analysis")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        // Location name
                        if let locationName = cachedAnalysis?.locationName ?? weatherService.locationName {
                            Text(locationName)
                                .font(.caption)
                                .foregroundStyle(.blue)
                                .fontWeight(.medium)
                        }

                        if isLoading || isRefreshingWeather {
                            Text(isRefreshingWeather ? "Refreshing..." : "Analyzing...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else if let recommendation = weatherRecommendation {
                            Text("\(Int(recommendation.currentTemperature))°C • \(recommendation.condition.description)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Tap to analyze weather")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    // Refresh Button
                    Button(action: {
                        refreshWeatherData()
                    }) {
                        if isRefreshingWeather {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isRefreshingWeather)

                    // Expand/Collapse Icon
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 0 : 0))
                }
                .padding()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded Content
            if isExpanded {
                expandedContentView
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.blue.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Weather Icon

    private var weatherIconView: some View {
        ZStack {
            Circle()
                .fill(.blue.opacity(0.1))
                .frame(width: 44, height: 44)

            if isLoading || isRefreshingWeather {
                ProgressView()
                    .scaleEffect(0.8)
            } else if let recommendation = weatherRecommendation {
                Image(systemName: weatherIcon(for: recommendation.condition))
                    .font(.title3)
                    .foregroundStyle(.blue)
            } else {
                Image(systemName: "cloud.sun.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)
            }
        }
    }

    // MARK: - Expanded Content

    @ViewBuilder
    private var expandedContentView: some View {
        VStack(spacing: 16) {
            Divider()
                .padding(.horizontal)

            if isLoading {
                loadingView
                    .padding(.horizontal)
                    .padding(.bottom)
            } else if let recommendation = weatherRecommendation {
                weatherDetailsView(recommendation)
                    .padding(.horizontal)
                    .padding(.bottom)
            } else {
                noDataView
                    .padding(.horizontal)
                    .padding(.bottom)
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.1)

            Text("Analyzing weather conditions...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - No Data View

    private var noDataView: some View {
        VStack(spacing: 12) {
            Image(systemName: "cloud.sun")
                .font(.title2)
                .foregroundStyle(.blue.opacity(0.6))

            Text("No weather data available")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Weather analysis will help optimize your hydration goals based on current conditions.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Weather Details

    private func weatherDetailsView(_ recommendation: WeatherRecommendation) -> some View {
        VStack(spacing: 16) {
            // AI Insight (if available)
            if !aiComment.isEmpty {
                aiInsightCard
            }

            // Weather Stats
            weatherStatsGrid(recommendation)

            // Recommendation
            recommendationCard(recommendation)

            // Last Update
            if let lastDate = lastAnalysisDate {
                HStack {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    Text("Analyzed \(lastDate, style: .relative)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    Spacer()
                }
            }
        }
    }

    private var aiInsightCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                if isGeneratingAIComment {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "sparkles")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }

                Text("AI Insight")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Regenerate button
                if !aiComment.isEmpty && !isGeneratingAIComment {
                    Button(action: {
                        generateAIComment()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }

            if isGeneratingAIComment {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Generating personalized insight...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if !aiComment.isEmpty {
                Text(aiComment)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Button(action: {
                    generateAIComment()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                        Text("Generate AI insight")
                            .font(.caption)
                    }
                    .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.blue.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private func weatherStatsGrid(_ recommendation: WeatherRecommendation) -> some View {
        HStack(spacing: 12) {
            weatherStatItem(
                icon: "thermometer",
                label: "High",
                value: "\(Int(recommendation.maxTemperature))°C"
            )

            weatherStatItem(
                icon: "drop.fill",
                label: "Humidity",
                value: "\(Int(recommendation.humidity * 100))%"
            )

            weatherStatItem(
                icon: "sun.max.fill",
                label: "UV Index",
                value: "\(recommendation.uvIndex)"
            )
        }
    }

    private func weatherStatItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.blue)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.blue.opacity(0.05))
        )
    }

    private func recommendationCard(_ recommendation: WeatherRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: recommendation.recommendation.priority.icon)
                    .font(.subheadline)
                    .foregroundStyle(colorForPriority(recommendation.recommendation.priority))

                Text("Recommendation")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            if recommendation.recommendation.additionalWaterMl > 0 {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("Drink extra")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(formatWaterAmount(recommendation.recommendation.additionalWaterMl))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(colorForPriority(recommendation.recommendation.priority))

                    Text("today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)

                    Text("Current goal is sufficient")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Factors
            if !recommendation.recommendation.factors.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(recommendation.recommendation.factors.prefix(3), id: \.self) { factor in
                        HStack(spacing: 4) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 4))
                                .foregroundStyle(.blue)

                            Text(factor)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Helper Methods

    private func weatherIcon(for condition: WeatherCondition) -> String {
        switch condition {
        case .clear:
            return "sun.max.fill"
        case .cloudy:
            return "cloud.fill"
        case .partlyCloudy:
            return "cloud.sun.fill"
        case .rain:
            return "cloud.rain.fill"
        case .snow:
            return "cloud.snow.fill"
        case .thunderstorms:
            return "cloud.bolt.fill"
        case .foggy:
            return "cloud.fog.fill"
        case .haze:
            return "sun.haze.fill"
        case .smoky:
            return "smoke.fill"
        case .breezy:
            return "wind"
        case .windy:
            return "wind"
        case .frigid:
            return "thermometer.snowflake"
        case .hot:
            return "thermometer.sun.fill"
        case .sunShowers:
            return "cloud.sun.rain.fill"
        case .blowingDust:
            return "cloud.dust.fill"
        case .blowingSnow:
            return "cloud.snow.fill"
        case .freezingDrizzle:
            return "cloud.drizzle.fill"
        case .freezingRain:
            return "cloud.rain.fill"
        case .heavyRain:
            return "cloud.heavyrain.fill"
        case .flurries:
            return "cloud.snow.fill"
        case .heavySnow:
            return "cloud.snow.fill"
        case .sleet:
            return "cloud.sleet.fill"
        case .sunFlurries:
            return "cloud.snow.fill"
        case .tropicalStorm:
            return "cloud.bolt.rain.fill"
        case .hurricane:
            return "hurricane"
        case .wintryMix:
            return "cloud.sleet.fill"
        case .blizzard:
            return "cloud.snow.fill"
        case .drizzle:
            return "cloud.drizzle.fill"
        case .hail:
            return "cloud.hail.fill"
        case .isolatedThunderstorms:
            return "cloud.bolt.fill"
        case .mostlyClear:
            return "sun.min.fill"
        case .mostlyCloudy:
            return "cloud.fill"
        case .scatteredThunderstorms:
            return "cloud.bolt.fill"
        case .strongStorms:
            return "cloud.bolt.rain.fill"
        @unknown default:
            return "cloud.fill"
        }
    }

    private func colorForPriority(_ priority: WeatherPriority) -> Color {
        switch priority {
        case .low:
            return .green
        case .medium:
            return .orange
        case .high:
            return .red
        }
    }

    private func formatWaterAmount(_ ml: Int) -> String {
        if measurementUnits == "fl_oz" {
            let oz = Double(ml) / 29.5735
            return "\(Int(oz.rounded())) fl oz"
        } else {
            return "\(ml) ml"
        }
    }
    
    // MARK: - Weather Data Refresh
    
    private func refreshWeatherData() {
        isRefreshingWeather = true
        
        Task {
            // Fetch fresh weather data
            await weatherService.fetchWeatherData()
            
            // Get the latest recommendation
            if let recommendation = weatherService.getWeatherRecommendation() {
                // Create new cache entry with fresh data
                let aiComment = weatherService.generateMockAIComment(for: recommendation)
                let cache = WeatherAnalysisCache.fromWeatherRecommendation(recommendation, aiComment: aiComment, locationName: weatherService.locationName)
                cache.date = selectedDate
                
                // Remove old cache for this date
                removeOldCacheForDate(selectedDate)
                
                // Insert new cache
                modelContext.insert(cache)
                
                do {
                    try modelContext.save()
                } catch {
                    print("Failed to save refreshed weather data: \(error)")
                }
            }
            
            await MainActor.run {
                isRefreshingWeather = false
                // Clear current AI comment to trigger regeneration
                currentAIComment = ""
            }
        }
    }
    
    private func removeOldCacheForDate(_ date: Date) {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let descriptor = FetchDescriptor<WeatherAnalysisCache>(
            predicate: #Predicate { analysis in
                analysis.date >= startOfDay && analysis.date < endOfDay
            }
        )
        
        do {
            let oldCaches = try modelContext.fetch(descriptor)
            for cache in oldCaches {
                modelContext.delete(cache)
            }
        } catch {
            print("Failed to remove old cache: \(error)")
        }
    }
    
    // MARK: - AI Comment Generation
    
    private func generateAIComment() {
        guard let recommendation = weatherRecommendation else { return }
        
        isGeneratingAIComment = true
        
        Task {
            do {
                let aiComment = try await aiClient.analyzeWeatherForHydration(weatherData: recommendation)
                
                await MainActor.run {
                    currentAIComment = aiComment
                    isGeneratingAIComment = false
                    
                    // Cache the AI comment for future use
                    cacheAIComment(aiComment)
                }
            } catch {
                await MainActor.run {
                    // Fallback to mock comment if AI fails
                    currentAIComment = weatherService.generateMockAIComment(for: recommendation)
                    isGeneratingAIComment = false
                }
            }
        }
    }
    
    private func cacheAIComment(_ comment: String) {
        // Update the cached analysis with the new AI comment
        if let analysis = cachedAnalysis {
            analysis.aiComment = comment
            
            do {
                try modelContext.save()
            } catch {
                print("Failed to save AI comment: \(error)")
            }
        }
    }
}

#Preview {
    WeatherCardView(selectedDate: Date(), isLoading: false)
        .modelContainer(for: WeatherAnalysisCache.self, inMemory: true)
        .padding()
}

