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
    @EnvironmentObject private var sleepService: SleepService

    @Query private var allSleepAnalyses: [SleepAnalysisCache]
    @Query private var allWaterPortions: [WaterPortion]

    @State private var isExpanded = false
    @State private var isGeneratingAIComment = false
    @State private var isRefreshingSleep = false
    @State private var currentAIComment = ""

    private var cachedAnalysis: SleepAnalysisCache? {
        let selectedRoundedDate = selectedDate.rounded()
        
        return allSleepAnalyses.first { analysis in
            analysis.date.rounded() == selectedRoundedDate
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

    // Get water data for the selected day
    private var dayWaterData: [WaterPortion] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? selectedDate
        
        return allWaterPortions.filter { portion in
            portion.createDate >= startOfDay && portion.createDate < endOfDay
        }.sorted { $0.createDate < $1.createDate }
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
    
    // Calculate hydration metrics based on research
    private var hydrationMetrics: HydrationMetrics {
        calculateHydrationMetrics()
    }
    
    // Get historical sleep data for confidence calculation
    private var historicalSleepData: [SleepAnalysisCache] {
        let calendar = Calendar.current
        let monthAgo = calendar.date(byAdding: .day, value: -60, to: selectedDate) ?? selectedDate
        
        return allSleepAnalyses.filter { analysis in
            analysis.date >= monthAgo && analysis.date <= selectedDate
        }.sorted { $0.date < $1.date }
    }
    
    // Data completeness assessment
    private var dataCompleteness: DataCompleteness {
        let validNights = historicalSleepData.count
        
        if validNights >= 45 {
            return .robust
        } else if validNights >= 21 {
            return .good
        } else if validNights >= 7 {
            return .moderate
        } else {
            return .minimal
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
                            VStack(alignment: .leading, spacing: 2) {
                                Text(formatSleepDuration(recommendation.sleepDurationHours))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                // Show date if using latest available data
                                if let actualDate = recommendation.actualSleepDate,
                                   !Calendar.current.isDate(actualDate, inSameDayAs: selectedDate) {
                                    Text("from \(actualDate.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                }
                            }
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
        VStack(spacing: 16) {
            // Different messages based on data availability
            if dayWaterData.isEmpty && historicalSleepData.isEmpty {
                // No data at all
                completeNoDataView
            } else if historicalSleepData.isEmpty {
                // Have hydration data but no sleep data
                noSleepDataView
            } else if dayWaterData.isEmpty {
                // Have sleep data but no hydration data for today
                noHydrationDataView
            } else {
                // Have some data but analysis failed
                analysisFailedView
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private var completeNoDataView: some View {
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
    }
    
    private var noSleepDataView: some View {
        VStack(spacing: 12) {
            Image(systemName: "bed.double")
                .font(.title2)
                .foregroundStyle(.purple.opacity(0.6))

            Text("Sleep tracking needed")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                Text("We can see your hydration data (\(dayWaterData.count) drinks today), but need sleep data to provide timing recommendations.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                
                Text("Enable sleep tracking in the Health app to unlock personalized insights.")
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var noHydrationDataView: some View {
        VStack(spacing: 12) {
            Image(systemName: "drop.circle")
                .font(.title2)
                .foregroundStyle(.blue.opacity(0.6))

            Text("No hydration data today")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                Text("We have your sleep data (\(historicalSleepData.count) nights tracked), but no water intake recorded for today.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                
                Text("Log your drinks to see how hydration timing affects your sleep quality.")
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var analysisFailedView: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundStyle(.orange.opacity(0.6))

            Text("Analysis temporarily unavailable")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                Text("We have your data (\(dayWaterData.count) drinks, \(historicalSleepData.count) nights) but analysis failed.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                
                Text("Tap refresh to try again.")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Sleep Details

    private func sleepDetailsView(_ recommendation: SleepRecommendation) -> some View {
        VStack(spacing: 16) {
            // AI Insight (if available)
            if !aiComment.isEmpty {
                aiInsightCard
            }

            // Hydration Impact Metrics (new research-based section)
            hydrationImpactSection(recommendation)
            
            // Sleep Stats
            sleepStatsGrid(recommendation)

            // Recommendation
            recommendationCard(recommendation)

            // Sleep Data Info
            VStack(spacing: 4) {
                // Show actual sleep date if different from selected date
                if let actualDate = recommendation.actualSleepDate,
                   !Calendar.current.isDate(actualDate, inSameDayAs: selectedDate) {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.caption2)
                            .foregroundStyle(.orange)

                        Text("Sleep data from \(actualDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .fontWeight(.medium)

                        Spacer()
                    }
                }
                
                // Last analysis update
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
        VStack(spacing: 12) {
            // Primary sleep metrics
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

    // MARK: - Hydration Impact Section (Research-Based)
    
    private func hydrationImpactSection(_ recommendation: SleepRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "drop.fill")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                
                Text("Hydration Impact Analysis")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Data confidence indicator
                confidenceBadge
            }
            
            // Quick snapshot metrics
            hydrationMetricsGrid
            
            // Impact insights
            if !hydrationMetrics.insights.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(hydrationMetrics.insights.prefix(2), id: \.self) { insight in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                            
                            Text(insight)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
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
                .fill(.blue.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private var hydrationMetricsGrid: some View {
        HStack(spacing: 8) {
            // Evening intake percentage
            metricItem(
                label: "Evening Intake",
                value: "\(Int(hydrationMetrics.eveningIntakePercentage * 100))%",
                status: hydrationMetrics.eveningIntakeStatus,
                icon: "moon.circle.fill"
            )
            
            // Hydration score
            metricItem(
                label: "Daily Hydration",
                value: "\(Int(hydrationMetrics.dailyHydrationScore * 100))%",
                status: hydrationMetrics.hydrationStatus,
                icon: "drop.circle.fill"
            )
            
            // Nocturia risk
            metricItem(
                label: "Sleep Risk",
                value: hydrationMetrics.nocturiaRisk.displayText,
                status: hydrationMetrics.nocturiaRisk.status,
                icon: "bed.double.circle.fill"
            )
        }
    }
    
    private func metricItem(label: String, value: String, status: MetricStatus, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(status.color)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(status.color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(status.color.opacity(0.1))
        )
    }
    
    private var confidenceBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: dataCompleteness.icon)
                .font(.caption2)
                .foregroundStyle(dataCompleteness.color)
            
            Text(dataCompleteness.label)
                .font(.caption2)
                .foregroundStyle(dataCompleteness.color)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(dataCompleteness.color.opacity(0.1))
                .overlay(
                    Capsule()
                        .stroke(dataCompleteness.color.opacity(0.3), lineWidth: 0.5)
                )
        )
    }
    
    // MARK: - Hydration Calculations (Evidence-Based)
    
    private func calculateHydrationMetrics() -> HydrationMetrics {
        // Handle edge case: no hydration data
        guard !dayWaterData.isEmpty else {
            return HydrationMetrics(
                eveningIntakePercentage: 0,
                eveningIntakeStatus: .optimal,
                dailyHydrationScore: 0,
                hydrationStatus: .critical,
                nocturiaRisk: .low,
                insights: ["No hydration data available for today. Start logging your water intake to see personalized sleep insights."]
            )
        }
        
        let totalDailyIntake = dayWaterData.reduce(0) { total, portion in
            total + (portion.amount * portion.unit.conversionFactor) // Convert to ml
        }
        
        // Handle edge case: minimal water intake
        guard totalDailyIntake >= 100 else { // Less than 100ml seems like incomplete data
            return HydrationMetrics(
                eveningIntakePercentage: 0,
                eveningIntakeStatus: .optimal,
                dailyHydrationScore: 0,
                hydrationStatus: .critical,
                nocturiaRisk: .low,
                insights: ["Very low water intake recorded (\(Int(totalDailyIntake))ml). Make sure to log all your drinks for accurate analysis."]
            )
        }
        
        // Calculate evening intake (last 3-4 hours before bedtime)
        let eveningIntake = calculateEveningIntake()
        let eveningPercentage = totalDailyIntake > 0 ? eveningIntake / totalDailyIntake : 0
        
        // Calculate hydration score (based on personalized target)
        let dailyTarget = calculatePersonalizedTarget()
        let hydrationScore = min(1.0, totalDailyIntake / dailyTarget)
        
        // Calculate nocturia risk
        let nocturiaRisk = calculateNocturiaRisk(eveningPercentage: eveningPercentage, totalIntake: totalDailyIntake)
        
        // Generate insights based on research and data completeness
        let insights = generateHydrationInsights(
            eveningPercentage: eveningPercentage,
            hydrationScore: hydrationScore,
            nocturiaRisk: nocturiaRisk,
            totalIntake: totalDailyIntake
        )
        
        return HydrationMetrics(
            eveningIntakePercentage: eveningPercentage,
            eveningIntakeStatus: getEveningIntakeStatus(eveningPercentage),
            dailyHydrationScore: hydrationScore,
            hydrationStatus: getHydrationStatus(hydrationScore),
            nocturiaRisk: nocturiaRisk,
            insights: insights
        )
    }
    
    private func calculateEveningIntake() -> Double {
        guard let bedTime = sleepRecommendation?.bedTime else {
            // Fallback: assume bedtime is 22:00 if no sleep data
            let calendar = Calendar.current
            let assumedBedtime = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: selectedDate) ?? selectedDate
            return calculateEveningIntakeForBedtime(assumedBedtime)
        }
        
        return calculateEveningIntakeForBedtime(bedTime)
    }
    
    private func calculateEveningIntakeForBedtime(_ bedTime: Date) -> Double {
        let calendar = Calendar.current
        let eveningStart = calendar.date(byAdding: .hour, value: -3, to: bedTime) ?? bedTime
        
        return dayWaterData.filter { portion in
            portion.createDate >= eveningStart && portion.createDate <= bedTime
        }.reduce(0) { total, portion in
            total + (portion.amount * portion.unit.conversionFactor)
        }
    }
    
    private func calculatePersonalizedTarget() -> Double {
        // This should ideally come from user settings or HealthKit data
        // For now, use a standard 2000ml target, but this should be personalized
        return 2000.0
    }
    
    private func calculateNocturiaRisk(eveningPercentage: Double, totalIntake: Double) -> NocturiaRisk {
        // Based on research: evening intake >20-25% of daily total increases nocturia risk
        var riskScore = 0
        
        // Evening intake percentage (0-40 points)
        if eveningPercentage >= 0.35 {
            riskScore += 40 // Very high evening intake
        } else if eveningPercentage >= 0.25 {
            riskScore += 25 // High evening intake
        } else if eveningPercentage >= 0.20 {
            riskScore += 15 // Moderate evening intake
        } else {
            riskScore += 5 // Low evening intake
        }
        
        // Total daily intake (0-20 points)
        if totalIntake > 3000 {
            riskScore += 20 // Very high total intake
        } else if totalIntake > 2500 {
            riskScore += 10 // High total intake
        }
        
        // Caffeine factors (0-15 points)
        let caffeineRisk = calculateCaffeineRisk()
        riskScore += caffeineRisk
        
        // Alcohol factors (0-10 points) 
        // Note: Alcohol is diuretic but also sedating, complex relationship
        // For now, any alcohol increases risk slightly
        let alcoholRisk = calculateAlcoholRisk()
        riskScore += alcoholRisk
        
        // Age factor (if available from HealthKit)
        // Age >= 55: +10 points - would need HealthKit integration
        
        if riskScore >= 35 {
            return .high
        } else if riskScore >= 20 {
            return .moderate
        } else {
            return .low
        }
    }
    
    private func calculateCaffeineRisk() -> Int {
        let calendar = Calendar.current
        let afternoon = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        
        // Find coffee/tea intake after 3 PM
        let lateCaffeineIntake = dayWaterData.filter { portion in
            (portion.drink == .coffee || portion.drink == .tea) && portion.createDate >= afternoon
        }
        
        if !lateCaffeineIntake.isEmpty {
            let lateCaffeineAmount = lateCaffeineIntake.reduce(0) { total, portion in
                total + (portion.amount * portion.unit.conversionFactor)
            }
            
            // More caffeine = higher risk
            if lateCaffeineAmount >= 500 { // Large amounts
                return 15
            } else if lateCaffeineAmount >= 250 { // Moderate amounts
                return 10
            } else {
                return 5 // Small amounts
            }
        }
        
        return 0
    }
    
    private func calculateAlcoholRisk() -> Int {
        // Check for any drinks that might indicate alcohol
        // Note: Current system doesn't explicitly track alcohol, but "other" might be used
        let suspectedAlcohol = dayWaterData.filter { portion in
            portion.drink == .other || portion.drink == .soda // Soda could be mixed drinks
        }
        
        // Conservative approach: if there are "other" drinks in evening, slight risk increase
        if !suspectedAlcohol.isEmpty {
            let eveningOtherDrinks = suspectedAlcohol.filter { portion in
                guard let bedTime = sleepRecommendation?.bedTime else { return false }
                let calendar = Calendar.current
                let eveningStart = calendar.date(byAdding: .hour, value: -4, to: bedTime) ?? bedTime
                return portion.createDate >= eveningStart && portion.createDate <= bedTime
            }
            
            if !eveningOtherDrinks.isEmpty {
                return 5 // Small risk increase for evening "other" drinks
            }
        }
        
        return 0
    }
    
    private func getEveningIntakeStatus(_ percentage: Double) -> MetricStatus {
        if percentage <= 0.20 {
            return .optimal
        } else if percentage <= 0.30 {
            return .warning
        } else {
            return .critical
        }
    }
    
    private func getHydrationStatus(_ score: Double) -> MetricStatus {
        if score >= 0.80 {
            return .optimal
        } else if score >= 0.60 {
            return .warning
        } else {
            return .critical
        }
    }
    
    private func generateHydrationInsights(
        eveningPercentage: Double,
        hydrationScore: Double,
        nocturiaRisk: NocturiaRisk,
        totalIntake: Double
    ) -> [String] {
        var insights: [String] = []
        
        // Add data completeness context to insights
        let confidencePrefix = getConfidencePrefix()
        
        // Evening timing insights
        if eveningPercentage >= 0.30 {
            insights.append("\(confidencePrefix)You drank \(Int(eveningPercentage * 100))% of your fluids in the evening, which may disrupt sleep. Try shifting intake earlier.")
        } else if eveningPercentage <= 0.15 && hydrationScore >= 0.70 {
            insights.append("\(confidencePrefix)Great hydration timing! Your steady intake throughout the day supports better sleep quality.")
        }
        
        // Hydration level insights
        if hydrationScore < 0.60 {
            insights.append("Low daily hydration (\(Int(totalIntake))ml) may increase risk of shorter sleep duration and morning fatigue.")
        } else if hydrationScore >= 0.85 {
            insights.append("Excellent hydration (\(Int(totalIntake))ml) supports optimal melatonin production and sleep regulation.")
        }
        
        // Nocturia risk insights with research context
        let caffeineInsight = generateCaffeineInsight()
        
        switch nocturiaRisk {
        case .high:
            var highRiskInsight = "High risk of sleep interruptions. Research shows >25% evening intake can cause 2-3 nighttime awakenings. Limit fluids 2-3 hours before bed to <200ml."
            if !caffeineInsight.isEmpty {
                highRiskInsight += " " + caffeineInsight
            }
            insights.append(highRiskInsight)
        case .moderate:
            var moderateRiskInsight = "Moderate risk of nighttime awakenings. Consider shifting more hydration to earlier in the day."
            if !caffeineInsight.isEmpty {
                moderateRiskInsight += " " + caffeineInsight
            }
            insights.append(moderateRiskInsight)
        case .low:
            if eveningPercentage <= 0.20 {
                insights.append("Optimal hydration timing reduces sleep disruption risk. Your pattern aligns with research recommendations.")
            } else {
                insights.append("Low risk of sleep disruption from current hydration patterns.")
            }
            
            // Add caffeine insight even for low risk if relevant
            if !caffeineInsight.isEmpty {
                insights.append(caffeineInsight)
            }
        }
        
        // Add data completeness guidance
        if dataCompleteness == .minimal {
            insights.append("💡 Track for 7+ days to unlock personalized patterns and more accurate recommendations.")
        } else if dataCompleteness == .moderate {
            insights.append("📈 Great progress! 21+ days of data will enable even more precise sleep-hydration insights.")
        }
        
        return insights
    }
    
    private func getConfidencePrefix() -> String {
        switch dataCompleteness {
        case .minimal:
            return "Early pattern: "
        case .moderate:
            return "Emerging trend: "
        case .good:
            return "Reliable pattern: "
        case .robust:
            return ""  // No prefix needed for high confidence
        }
    }
    
    private func generateCaffeineInsight() -> String {
        let calendar = Calendar.current
        let afternoon = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        
        // Check for late caffeine intake
        let lateCaffeineIntake = dayWaterData.filter { portion in
            (portion.drink == .coffee || portion.drink == .tea) && portion.createDate >= afternoon
        }
        
        if !lateCaffeineIntake.isEmpty {
            let lateCaffeineAmount = lateCaffeineIntake.reduce(0) { total, portion in
                total + (portion.amount * portion.unit.conversionFactor)
            }
            
            let latestCaffeineTime = lateCaffeineIntake.map { $0.createDate }.max()
            let timeString = latestCaffeineTime?.formatted(date: .omitted, time: .shortened) ?? ""
            
            if lateCaffeineAmount >= 500 {
                return "⚠️ High caffeine intake (\(Int(lateCaffeineAmount))ml) after 3 PM (last: \(timeString)) significantly increases sleep disruption risk."
            } else if lateCaffeineAmount >= 250 {
                return "☕️ Moderate caffeine after 3 PM (last: \(timeString)) may affect sleep quality. Consider earlier timing."
            } else {
                return "☕️ Small amount of caffeine after 3 PM noted. Monitor impact on sleep quality."
            }
        }
        
        // Check for good caffeine timing
        let morningCaffeine = dayWaterData.filter { portion in
            (portion.drink == .coffee || portion.drink == .tea) && portion.createDate < afternoon
        }
        
        if !morningCaffeine.isEmpty && lateCaffeineIntake.isEmpty {
            return "✅ Good caffeine timing! All coffee/tea before 3 PM supports better sleep quality."
        }
        
        return ""
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
            // Clean up old sleep data first, keeping only current date
            SleepAnalysisCache.cleanupOldData(modelContext: modelContext, keepingCurrentDate: selectedDate)
            
            // Fetch fresh sleep data
            if let recommendation = await sleepService.fetchSleepData(for: selectedDate) {
                // Generate AI comment
                let aiComment = generateMockAIComment(for: recommendation)
                
                // Create new cache entry with fresh data
                let cache = SleepAnalysisCache.fromSleepRecommendation(recommendation, aiComment: aiComment)
                cache.date = selectedDate.rounded()
                
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
    
    
    // MARK: - AI Comment Generation
    
    private func generateAIComment() {
        guard let recommendation = sleepRecommendation else { return }
        
        isGeneratingAIComment = true
        
        Task {
            do {
                // Use original AI analysis function
                let aiComment = try await aiClient.analyzeSleepForHydration(
                    sleepData: recommendation, 
                    waterData: lastWeekWaterData
                )
                
                await MainActor.run {
                    currentAIComment = aiComment
                    isGeneratingAIComment = false
                    
                    // Cache the AI comment for future use
                    cacheAIComment(aiComment)
                }
            } catch {
                await MainActor.run {
                    // Fallback to enhanced mock comment if AI fails
                    currentAIComment = generateEnhancedMockAIComment(for: recommendation)
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
    
    // MARK: - Enhanced AI Comment Generation
    
    private func generateEnhancedMockAIComment(for recommendation: SleepRecommendation) -> String {
        let duration = recommendation.sleepDurationHours
        let quality = recommendation.sleepQualityScore
        let metrics = hydrationMetrics
        let completeness = dataCompleteness
        
        // Include data completeness context
        var comment = ""
        
        // Add confidence context based on data completeness
        switch completeness {
        case .minimal:
            comment += "📊 Early analysis (\\(historicalSleepData.count) nights): "
        case .moderate:
            comment += "📈 Building patterns (\\(historicalSleepData.count) nights): "
        case .good:
            comment += "✅ Reliable analysis (\\(historicalSleepData.count) nights): "
        case .robust:
            comment += "🎯 Comprehensive analysis (\\(historicalSleepData.count)+ nights): "
        }
        
        // Prioritize hydration timing insights
        if metrics.eveningIntakePercentage >= 0.30 {
            comment += "Your evening hydration (\\(Int(metrics.eveningIntakePercentage * 100))%) significantly increases nocturia risk. Research shows this can fragment sleep by 2-3 awakenings per night."
        } else if metrics.dailyHydrationScore < 0.60 {
            comment += "Low daily hydration (\\(Int(metrics.dailyHydrationScore * 100))% of target) may have shortened your sleep by 10-20 minutes. Dehydration reduces vasopressin production."
        } else if duration < 6.5 && metrics.dailyHydrationScore >= 0.80 {
            comment += "Despite good hydration, your \\(formatSleepDuration(duration)) sleep increases dehydration risk by 16-59%. Focus on sleep duration recovery alongside hydration."
        } else if metrics.eveningIntakePercentage <= 0.15 && quality >= 0.75 {
            comment += "Excellent hydration timing! Your steady daytime intake and minimal evening fluids support optimal sleep architecture and melatonin production."
        } else {
            // Fallback to original sleep-focused comments
            return generateMockAIComment(for: recommendation)
        }
        
        return comment
    }
    
    // MARK: - Original Mock AI Comment Generation
    
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

// MARK: - Supporting Data Structures

struct HydrationMetrics {
    let eveningIntakePercentage: Double
    let eveningIntakeStatus: MetricStatus
    let dailyHydrationScore: Double
    let hydrationStatus: MetricStatus
    let nocturiaRisk: NocturiaRisk
    let insights: [String]
}

enum MetricStatus {
    case optimal
    case warning
    case critical
    
    var color: Color {
        switch self {
        case .optimal: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }
}

enum NocturiaRisk {
    case low
    case moderate
    case high
    
    var displayText: String {
        switch self {
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        }
    }
    
    var status: MetricStatus {
        switch self {
        case .low: return .optimal
        case .moderate: return .warning
        case .high: return .critical
        }
    }
}

enum DataCompleteness {
    case minimal    // <7 nights
    case moderate   // 7-20 nights
    case good       // 21-44 nights
    case robust     // 45+ nights
    
    var label: String {
        switch self {
        case .minimal: return "Early"
        case .moderate: return "Moderate"
        case .good: return "Good"
        case .robust: return "Robust"
        }
    }
    
    var icon: String {
        switch self {
        case .minimal: return "chart.line.uptrend.xyaxis"
        case .moderate: return "chart.bar.fill"
        case .good: return "checkmark.circle.fill"
        case .robust: return "star.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .minimal: return .orange
        case .moderate: return .blue
        case .good: return .green
        case .robust: return .purple
        }
    }
}

#Preview {
    SleepCardView(selectedDate: Date(), isLoading: false)
        .modelContainer(for: [SleepAnalysisCache.self, WaterPortion.self], inMemory: true)
        .padding()
}
