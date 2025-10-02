//
//  SleepCardView.swift
//  WaterTracker
//
//  Created by AI Assistant
//

import SwiftUI
import SwiftData

struct SleepCardView: View {
    let selectedDate: Date
    let isLoading: Bool

    @Environment(\.modelContext) var modelContext
    @AppStorage("measurement_units") private var measurementUnits: String = "ml"
    @EnvironmentObject private var aiClient: AIDrinkAnalysisClient
    @StateObject private var sleepService = SleepService()

    @Query private var allSleepAnalyses: [SleepAnalysisCache]
    @Query private var allWaterPortions: [WaterPortion]

    @State private var isExpanded = false
    @State private var isGeneratingAIComment = false
    @State private var isRefreshingSleep = false
    @State private var currentAIComment = ""

    private var cachedAnalysis: SleepAnalysisCache? {
        let startOfDay = Calendar.current.startOfDay(for: selectedDate)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        return allSleepAnalyses.first { analysis in
            analysis.date >= startOfDay && analysis.date < endOfDay
        }
    }

    private var hasCachedData: Bool {
        cachedAnalysis != nil
    }

    private var sleepRecommendation: SleepRecommendation? {
        cachedAnalysis?.toSleepRecommendation()
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

    // Get water data for the last week to compare with sleep
    private var lastWeekWaterData: [WaterPortion] {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: selectedDate) ?? selectedDate
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        
        return allWaterPortions.filter { portion in
            portion.createDate >= weekAgo && portion.createDate <= endOfDay
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header - Always Visible
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
                
                // Generate AI comment when expanding if we have sleep data but no AI comment
                if isExpanded && sleepRecommendation != nil && aiComment.isEmpty {
                    generateAIComment()
                }
            }) {
                HStack(spacing: 12) {
                    // Sleep Icon
                    sleepIconView

                    // Sleep Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sleep Analysis")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if isLoading || isRefreshingSleep {
                            Text(isRefreshingSleep ? "Refreshing..." : "Analyzing...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else if let recommendation = sleepRecommendation {
                            Text(formatSleepDuration(recommendation.sleepDurationHours))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else if sleepService.errorMessage != nil {
                            Text("Sleep data unavailable")
                                .font(.subheadline)
                                .foregroundStyle(.red)
                        } else {
                            Text("Tap to analyze sleep")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    // Refresh Button
                    Button(action: {
                        refreshSleepData()
                    }) {
                        if isRefreshingSleep {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.subheadline)
                                .foregroundStyle(.purple)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isRefreshingSleep)

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
                .stroke(.purple.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Sleep Icon

    private var sleepIconView: some View {
        ZStack {
            Circle()
                .fill(.purple.opacity(0.1))
                .frame(width: 44, height: 44)

            if isLoading || isRefreshingSleep {
                ProgressView()
                    .scaleEffect(0.8)
            } else if let recommendation = sleepRecommendation {
                Image(systemName: sleepIcon(for: recommendation.sleepQualityScore))
                    .font(.title3)
                    .foregroundStyle(.purple)
            } else if sleepService.errorMessage != nil {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundStyle(.red)
            } else {
                Image(systemName: "moon.fill")
                    .font(.title3)
                    .foregroundStyle(.purple)
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
            } else if let recommendation = sleepRecommendation {
                sleepDetailsView(recommendation)
                    .padding(.horizontal)
                    .padding(.bottom)
            } else if sleepService.errorMessage != nil {
                noDataView
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

            Text("Analyzing sleep patterns...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - No Data View

    private var noDataView: some View {
        VStack(spacing: 12) {
            Image(systemName: "moon.zzz")
                .font(.title2)
                .foregroundStyle(.purple.opacity(0.6))

            Text("No sleep data available")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Sleep analysis helps optimize your hydration schedule. Please check your Health app settings to enable sleep tracking.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Sleep Details

    private func sleepDetailsView(_ recommendation: SleepRecommendation) -> some View {
        VStack(spacing: 16) {
            // AI Insight (if available)
            if !aiComment.isEmpty {
                aiInsightCard
            }

            // Sleep Stats
            sleepStatsGrid(recommendation)

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
                        .foregroundStyle(.purple)
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
                            .foregroundStyle(.purple)
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
                    .foregroundStyle(.purple)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.purple.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.purple.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private func sleepStatsGrid(_ recommendation: SleepRecommendation) -> some View {
        HStack(spacing: 12) {
            sleepStatItem(
                icon: "moon.fill",
                label: "Duration",
                value: formatSleepDuration(recommendation.sleepDurationHours)
            )

            sleepStatItem(
                icon: "star.fill",
                label: "Quality",
                value: "\(Int(recommendation.sleepQualityScore * 100))%"
            )

            sleepStatItem(
                icon: "brain.head.profile",
                label: "Deep Sleep",
                value: "\(recommendation.deepSleepMinutes)min"
            )
        }
    }

    private func sleepStatItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.purple)

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
                .fill(.purple.opacity(0.05))
        )
    }

    private func recommendationCard(_ recommendation: SleepRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: recommendation.recommendation.priority.icon)
                    .font(.subheadline)
                    .foregroundStyle(colorForPriority(recommendation.recommendation.priority))

                Text("Hydration Recommendation")
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
                                .foregroundStyle(.purple)

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

    private func sleepIcon(for qualityScore: Double) -> String {
        switch qualityScore {
        case 0.8...1.0:
            return "moon.stars.fill"
        case 0.6..<0.8:
            return "moon.fill"
        case 0.4..<0.6:
            return "moon.circle.fill"
        default:
            return "moon.zzz.fill"
        }
    }

    private func colorForPriority(_ priority: SleepPriority) -> Color {
        switch priority {
        case .low:
            return .green
        case .medium:
            return .orange
        case .high:
            return .red
        }
    }

    private func formatSleepDuration(_ hours: Double) -> String {
        let hoursInt = Int(hours)
        let minutes = Int((hours - Double(hoursInt)) * 60)
        
        if hoursInt > 0 {
            return "\(hoursInt)h \(minutes)m"
        } else {
            return "\(minutes)m"
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
    
    // MARK: - Sleep Data Refresh
    
    private func refreshSleepData() {
        isRefreshingSleep = true
        
        Task {
            // Fetch fresh sleep data
            if let recommendation = await sleepService.fetchSleepData(for: selectedDate) {
                // Generate AI comment
                let aiComment = generateMockAIComment(for: recommendation)
                
                // Create new cache entry with fresh data
                let cache = SleepAnalysisCache.fromSleepRecommendation(recommendation, aiComment: aiComment)
                cache.date = selectedDate
                
                // Remove old cache for this date
                removeOldCacheForDate(selectedDate)
                
                // Insert new cache
                modelContext.insert(cache)
                
                do {
                    try modelContext.save()
                } catch {
                    print("Failed to save refreshed sleep data: \(error)")
                }
            }
            
            await MainActor.run {
                isRefreshingSleep = false
                // Clear current AI comment to trigger regeneration
                currentAIComment = ""
            }
        }
    }
    
    private func removeOldCacheForDate(_ date: Date) {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let descriptor = FetchDescriptor<SleepAnalysisCache>(
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
        guard let recommendation = sleepRecommendation else { return }
        
        isGeneratingAIComment = true
        
        Task {
            do {
                let aiComment = try await aiClient.analyzeSleepForHydration(sleepData: recommendation, waterData: lastWeekWaterData)
                
                await MainActor.run {
                    currentAIComment = aiComment
                    isGeneratingAIComment = false
                    
                    // Cache the AI comment for future use
                    cacheAIComment(aiComment)
                }
            } catch {
                await MainActor.run {
                    // Fallback to mock comment if AI fails
                    currentAIComment = generateMockAIComment(for: recommendation)
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
    
    // MARK: - Mock AI Comment Generation
    
    private func generateMockAIComment(for recommendation: SleepRecommendation) -> String {
        let duration = recommendation.sleepDurationHours
        let quality = recommendation.sleepQualityScore
        let deepSleep = recommendation.deepSleepMinutes
        let remSleep = recommendation.remSleepMinutes
        let additionalWater = recommendation.recommendation.additionalWaterMl
        
        // Generate contextual AI comments based on sleep data and scientific research
        if duration < 5.5 {
            return "⚠️ Severe sleep deprivation detected! With only \(formatSleepDuration(duration)) of sleep, your body's antidiuretic hormone (vasopressin) production is significantly reduced, increasing dehydration risk by up to 59%. Prioritize both sleep and hydration recovery today."
        } else if duration < 6.5 {
            return "😴 Sleep deficit alert! \(formatSleepDuration(duration)) falls below the recommended 7-9 hours. Research shows this increases dehydration odds by 16-59%. Your body needs extra hydration to compensate for reduced vasopressin release during inadequate sleep."
        } else if duration >= 7.0 && duration <= 9.0 && quality >= 0.8 {
            return "✨ Excellent sleep quality! Your \(formatSleepDuration(duration)) of restorative sleep with \(Int(quality * 100))% quality score supports optimal hydration regulation. Your body's natural fluid balance mechanisms are functioning well."
        } else if quality < 0.5 {
            return "🌙 Poor sleep quality detected! With a \(Int(quality * 100))% quality score, elevated cortisol levels are affecting your kidney function and fluid retention. Focus on sleep hygiene and increase morning hydration to support recovery."
        } else if deepSleep < 60 {
            return "🧠 Insufficient deep sleep! Only \(deepSleep) minutes of deep sleep means reduced physical restoration. Deep sleep is crucial for metabolic recovery - consider earlier bedtime and limit evening screen time to improve sleep architecture."
        } else if remSleep < 90 {
            return "💭 Low REM sleep detected! \(remSleep) minutes of REM sleep affects cognitive function and stress regulation. REM sleep increases metabolic activity by 20-30%, requiring extra hydration. Consider stress management techniques."
        } else if additionalWater >= 300 {
            return "💧 High hydration needs today! Your sleep pattern suggests significant overnight water loss (\(additionalWater)ml additional needed). The combination of sleep duration, quality, and metabolic demands requires focused hydration attention."
        } else if additionalWater >= 150 {
            return "🌅 Moderate hydration boost recommended! Based on your sleep analysis, your body needs \(additionalWater)ml extra water today. Sleep patterns affect fluid balance through hormonal regulation and metabolic processes."
        } else if additionalWater > 0 {
            return "✅ Slight hydration adjustment! Your sleep data suggests a small increase (\(additionalWater)ml) in daily water intake. Even minor sleep variations can impact your body's fluid regulation systems."
        } else {
            return "🌟 Optimal sleep-hydration balance! Your sleep quality and duration support excellent fluid regulation. Keep maintaining these healthy sleep patterns for continued hydration optimization."
        }
    }
}

#Preview {
    SleepCardView(selectedDate: Date(), isLoading: false)
        .modelContainer(for: [SleepAnalysisCache.self, WaterPortion.self], inMemory: true)
        .padding()
}
