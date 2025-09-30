//
//  WeatherAnalysisView.swift
//  WaterTracker
//
//  Created by Jackson on 08/09/2025.
//

import SwiftUI
import WeatherKit
import SwiftData

struct WeatherAnalysisView: View {
    @Environment(\.modelContext) var modelContext
    @StateObject private var weatherService = WeatherService()
    @StateObject private var aiClient = AIDrinkAnalysisClient.shared
    @EnvironmentObject var revenueCatMonitor: RevenueCatMonitor
    @AppStorage("measurement_units") private var measurementUnits: String = "ml"
    
    @State private var weatherRecommendation: WeatherRecommendation?
    @State private var aiComment: String = ""
    @State private var lastAnalysisDate: Date?
    @State private var isAnalyzing = false
    @State private var showSubscriptionPrompt = false
    @State private var cachedAnalysis: WeatherAnalysisCache?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Title
                VStack(spacing: 8) {
                    Text("Weather Analysis")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Get personalized hydration recommendations based on current weather conditions")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                if !revenueCatMonitor.userHasFullAccess {
                    subscriptionPrompt
                } else {
                    // AI Comment Card
                    if let recommendation = weatherRecommendation {
                        aiCommentCard(recommendation)
                    }
                    
                    weatherAnalysisContent
                }
            }
            .padding()
        }
        .onAppear {
            if revenueCatMonitor.userHasFullAccess {
                loadTodaysAnalysis()
            }
        }
        .sheet(isPresented: $showSubscriptionPrompt) {
            // Add your subscription view here
            Text("Subscription Required")
                .padding()
        }
    }

    private var subscriptionPrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "cloud.sun.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            Text("Premium Feature")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Weather-based hydration recommendations are available with a premium subscription.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            Button("Upgrade to Premium") {
                showSubscriptionPrompt = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var weatherAnalysisContent: some View {
        VStack(spacing: 20) {
            if weatherService.isLoading || isAnalyzing {
                loadingView
            } else if let recommendation = weatherRecommendation {
                VStack(spacing: 16) {
                    // Show mock data warning if applicable
                    if let error = weatherService.errorMessage, error.contains("sample data") {
                        mockDataWarning
                    }
                    
                    weatherRecommendationView(recommendation)
                }
            } else if let error = weatherService.errorMessage {
                errorView(error)
            } else {
                emptyStateView
            }
            
            if let lastDate = lastAnalysisDate {
                lastAnalysisInfo(lastDate)
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Analyzing weather conditions...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private func weatherRecommendationView(_ recommendation: WeatherRecommendation) -> some View {
        VStack(spacing: 20) {
            // Current Weather Header
            currentWeatherHeader(recommendation)
            
            // Recommendation Card
            recommendationCard(recommendation)
            
            // Weather Factors
            weatherFactorsCard(recommendation)
            
            // Action Button
            analyzeAgainButton
        }
    }
    
    private func currentWeatherHeader(_ recommendation: WeatherRecommendation) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: weatherIcon(for: recommendation.condition))
                    .font(.system(size: 40))
                    .foregroundStyle(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Int(recommendation.currentTemperature))°C")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(recommendation.condition.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            HStack(spacing: 20) {
                weatherDetailItem(
                    icon: "thermometer",
                    title: "High",
                    value: "\(Int(recommendation.maxTemperature))°C"
                )
                
                weatherDetailItem(
                    icon: "drop",
                    title: "Humidity",
                    value: "\(Int(recommendation.humidity * 100))%"
                )
                
                weatherDetailItem(
                    icon: "sun.max",
                    title: "UV Index",
                    value: "\(recommendation.uvIndex)"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.blue.opacity(0.1))
        )
    }
    
    private func weatherDetailItem(icon: String, title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
        }
    }
    
    private func recommendationCard(_ recommendation: WeatherRecommendation) -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: recommendation.recommendation.priority.icon)
                    .foregroundStyle(colorForPriority(recommendation.recommendation.priority))
                
                Text("Hydration Recommendation")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                if recommendation.recommendation.additionalWaterMl > 0 {
                    HStack {
                        Text("Additional water needed:")
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text(formatWaterAmount(recommendation.recommendation.additionalWaterMl))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(colorForPriority(recommendation.recommendation.priority))
                    }
                } else {
                    HStack {
                        Text("Your current water goal is sufficient for today's weather")
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
                
                if recommendation.recommendation.confidence > 0.7 {
                    HStack {
                        Text("Confidence: \(Int(recommendation.recommendation.confidence * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        ProgressView(value: recommendation.recommendation.confidence)
                            .frame(width: 60)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private func weatherFactorsCard(_ recommendation: WeatherRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet")
                    .foregroundStyle(.blue)
                
                Text("Weather Factors")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(recommendation.recommendation.factors, id: \.self) { factor in
                    HStack {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(.blue)
                        
                        Text(factor)
                            .font(.subheadline)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var analyzeAgainButton: some View {
        Button(action: {
            // Clear today's cache and perform fresh analysis
            clearTodaysCache()
            performAnalysis()
        }) {
            HStack {
                Image(systemName: "arrow.clockwise")
                Text("Analyze Again")
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.blue)
            )
        }
        .disabled(isAnalyzing)
    }
    
    private func clearTodaysCache() {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let predicate = #Predicate<WeatherAnalysisCache> { analysis in
            analysis.date >= today && analysis.date < tomorrow
        }
        
        let descriptor = FetchDescriptor<WeatherAnalysisCache>(predicate: predicate)
        
        do {
            let todaysAnalyses = try modelContext.fetch(descriptor)
            for analysis in todaysAnalyses {
                modelContext.delete(analysis)
            }
            try modelContext.save()
        } catch {
            print("Failed to clear today's cache: \(error)")
        }
    }
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: error.contains("permission") ? "location.slash" : "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(error.contains("permission") ? .red : .orange)
            
            Text("Weather Analysis Failed")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(error)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            if error.contains("permission") {
                Button("Open Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Try Again") {
                    performAnalysis()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "cloud.sun")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            Text("No Weather Analysis")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Tap the button below to analyze current weather conditions and get personalized hydration recommendations.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            Button("Start Analysis") {
                performAnalysis()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var mockDataWarning: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Development Mode")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Text("Using sample weather data. Configure WeatherKit for real data.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.orange.opacity(0.1))
        )
    }
    
    private func aiCommentCard(_ recommendation: WeatherRecommendation) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.blue)
                    .font(.title2)
                
                Text("AI Insight")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            Text(aiComment.isEmpty ? "Analyzing weather data..." : aiComment)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.blue.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    
    private func lastAnalysisInfo(_ date: Date) -> some View {
        HStack {
            Image(systemName: "clock")
                .foregroundStyle(.secondary)
            
            Text("Last analyzed: \(date, style: .relative)")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    // MARK: - Helper Methods
    
    private func loadTodaysAnalysis() {
        // Check if we have analysis for today
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let predicate = #Predicate<WeatherAnalysisCache> { analysis in
            analysis.date >= today && analysis.date < tomorrow
        }
        
        let descriptor = FetchDescriptor<WeatherAnalysisCache>(predicate: predicate)
        
        do {
            let todaysAnalyses = try modelContext.fetch(descriptor)
            
            if let analysis = todaysAnalyses.first {
                // Load cached analysis for today
                cachedAnalysis = analysis
                aiComment = analysis.aiComment
                lastAnalysisDate = analysis.date
                weatherRecommendation = analysis.toWeatherRecommendation()
            } else {
                // No analysis for today, perform fresh analysis
                performAnalysis()
            }
        } catch {
            // Error fetching data, perform fresh analysis
            performAnalysis()
        }
    }
    
    private func performAnalysis() {
        isAnalyzing = true
        lastAnalysisDate = Date()
        aiComment = ""
        
        Task {
            await weatherService.fetchWeatherData()
            
            if let recommendation = weatherService.getWeatherRecommendation() {
                weatherRecommendation = recommendation
                
                // Generate AI analysis
                do {
                    let aiAnalysis = try await aiClient.analyzeWeatherForHydration(weatherData: recommendation)
                    await MainActor.run {
                        aiComment = aiAnalysis
                        
                        // Save to SwiftData
                        saveAnalysisToCache(recommendation: recommendation, aiComment: aiAnalysis)
                    }
                } catch {
                    await MainActor.run {
                        aiComment = "Unable to generate AI analysis. Please try again."
                    }
                }
            }
            
            isAnalyzing = false
        }
    }
    
    private func saveAnalysisToCache(recommendation: WeatherRecommendation, aiComment: String) {
        // Remove any existing analysis for today
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let predicate = #Predicate<WeatherAnalysisCache> { analysis in
            analysis.date >= today && analysis.date < tomorrow
        }
        
        let descriptor = FetchDescriptor<WeatherAnalysisCache>(predicate: predicate)
        
        do {
            let todaysAnalyses = try modelContext.fetch(descriptor)
            for analysis in todaysAnalyses {
                modelContext.delete(analysis)
            }
        } catch {
            // Continue with saving new analysis
        }
        
        // Create new analysis cache
        let newAnalysis = WeatherAnalysisCache.fromWeatherRecommendation(recommendation, aiComment: aiComment)
        newAnalysis.date = lastAnalysisDate ?? Date()
        
        modelContext.insert(newAnalysis)
        cachedAnalysis = newAnalysis
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save weather analysis cache: \(error)")
        }
    }
    
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
}

#Preview {
    WeatherAnalysisView()
        .environmentObject(RevenueCatMonitor(state: .preview(true)))
}
