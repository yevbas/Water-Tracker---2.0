//
//  WeatherCardView.swift
//  WaterTracker
//
//  Created by AI Assistant
//

import SwiftUI
import WeatherKit
import SwiftData
import RevenueCatUI

struct WeatherCardView: View {
    // Current date rounded for saving
    let selectedDate: Date = Date().rounded()

    @State var isLoading: Bool = false

    @Environment(\.modelContext) var modelContext
    @AppStorage("measurement_units") private var measurementUnits: String = "ml"
    @EnvironmentObject private var aiClient: AIDrinkAnalysisClient
    @EnvironmentObject private var weatherService: WeatherService
    @EnvironmentObject private var revenueCatMonitor: RevenueCatMonitor

    @Query private var allWeatherAnalyses: [WeatherAnalysisCache]

    @State private var isExpanded = false
    @State private var isGeneratingAIComment = false
    @State private var isRefreshingWeather = false
    @State private var currentAIComment = ""
    @State private var errorMessage: String?

    @State private var isPresentedPaywall = false

    private var cachedAnalysis: WeatherAnalysisCache? {
        // Use rounded date for identification
        let roundedDate = selectedDate.rounded()
        
        return allWeatherAnalyses.first { analysis in
            // Compare dates by checking if they're within the same day
            Calendar.current.isDate(analysis.date, inSameDayAs: roundedDate)
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
                // Only allow expansion if user has full access
                guard revenueCatMonitor.userHasFullAccess else {
                    isPresentedPaywall = true
                    return
                }

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
                        if let locationName = cachedAnalysis?.locationName {
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
                            Text(revenueCatMonitor.userHasFullAccess ? "Tap to analyze weather" : "Premium feature")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    // Premium Lock Icon or Refresh Button
                    if !revenueCatMonitor.userHasFullAccess {
                        Image(systemName: "lock.fill")
                            .font(.subheadline)
                            .foregroundStyle(.blue.opacity(0.6))
                    } else {
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
                    }

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
                if revenueCatMonitor.userHasFullAccess {
                    expandedContentView
                        .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    premiumLockedContentView
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
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
        .sheet(isPresented: $isPresentedPaywall) {
            PaywallView()
        }
    }

    // MARK: - Premium Locked Content

    private var premiumLockedContentView: some View {
        VStack(spacing: 16) {
            Divider()
                .padding(.horizontal)

            VStack(spacing: 16) {
                Image(systemName: "lock.fill")
                    .font(.title2)
                    .foregroundStyle(.blue.opacity(0.6))

                Text("Premium Feature")
                    .font(.headline)
                    .fontWeight(.semibold)

                Text("Unlock detailed weather analysis with AI-powered hydration recommendations based on current conditions.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button(action: {
                    // TODO: Handle premium upgrade
                    print("Upgrade to Premium tapped")
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.subheadline)
                        Text("Unlock Premium")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.blue.gradient)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
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
                if let errorMessage = errorMessage {
                    errorView(errorMessage)
                        .padding(.horizontal)
                        .padding(.bottom)
                } else {
                    noDataView
                        .padding(.horizontal)
                        .padding(.bottom)
                }
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

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundStyle(.orange)

            Text("Weather Error")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
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
        errorMessage = nil
        
        Task {
            do {
                // Fetch fresh weather data using the new service pattern
                let recommendation = try await weatherService.fetchWeatherData()

                isGeneratingAIComment = true

                let aiComment = try await aiClient.analyzeWeatherForHydration(
                    weatherData: recommendation
                )

                isGeneratingAIComment = false

                // Get location name if available
                var locationName: String?

                if let location = weatherService.locationManager.location {
                    locationName = await weatherService.getLocationName(for: location)
                }

                // Create new cache entry with fresh data
                let cache = WeatherAnalysisCache.fromWeatherRecommendation(
                    recommendation,
                    aiComment: aiComment,
                    locationName: locationName
                )
                cache.date = selectedDate.rounded()
                
                // Remove old cache for this date and clean up old data
                await cleanOldWeatherData()
                
                // Insert new cache
                modelContext.insert(cache)

                try? modelContext.save()
            } catch let weatherError as WeatherError {
                errorMessage = weatherError.localizedDescription
            } catch let error {
                errorMessage = "Failed to fetch weather data: \(error.localizedDescription)"
            }
            isRefreshingWeather = false
            currentAIComment = ""
        }
    }
    
    private func cleanOldWeatherData() async {
        let currentRoundedDate = Date().rounded()
        
        // Fetch all weather analyses and filter manually since we can't use rounded() in predicate
        let descriptor = FetchDescriptor<WeatherAnalysisCache>()
        
        do {
            let allCaches = try modelContext.fetch(descriptor)
            let oldCaches = allCaches.filter { analysis in
                !Calendar.current.isDate(analysis.date, inSameDayAs: currentRoundedDate)
            }
            
            for cache in oldCaches {
                modelContext.delete(cache)
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to clean old weather data"
            }
        }
    }
    
    // MARK: - AI Comment Generation
    
    private func generateAIComment() {
        guard let recommendation = weatherRecommendation else { return }
        
        isGeneratingAIComment = true
        
        Task {
            do {
                let aiComment = try await aiClient.analyzeWeatherForHydration(
                    weatherData: recommendation
                )

                await MainActor.run {
                    currentAIComment = aiComment
                    isGeneratingAIComment = false
                    
                    // Cache the AI comment for future use
                    cacheAIComment(aiComment)
                }
            } catch {
                await MainActor.run {
                    isGeneratingAIComment = false
                    errorMessage = "Failed to generate AI insight"
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
    WeatherCardView()
        .modelContainer(for: WeatherAnalysisCache.self, inMemory: true)
        .environmentObject(WeatherService())
        .environmentObject(AIDrinkAnalysisClient())
        .environmentObject(RevenueCatMonitor(state: .preview(false)))
        .padding()
}

