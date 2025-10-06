//
//  SleepCardView.swift
//  WaterTracker
//
//  Created by AI Assistant
//

import SwiftUI
import SwiftData
import RevenueCatUI

struct SleepCardView: View {
    let selectedDate: Date = Date().rounded()
    let isLoading: Bool

    @Environment(\.modelContext) var modelContext
    @AppStorage("measurement_units") private var measurementUnits: String = "ml"
    @EnvironmentObject private var aiClient: AIDrinkAnalysisClient
    @EnvironmentObject private var sleepService: SleepService
    @EnvironmentObject private var revenueCatMonitor: RevenueCatMonitor

    @Query private var allSleepAnalyses: [SleepAnalysisCache]
    @State private var allWaterPortions: [WaterPortion] = []

    @State private var isExpanded = false
    @State private var isGeneratingAIComment = false
    @State private var isRefreshingSleep = false
    @State private var currentAIComment = ""
    @State private var isPresentedPaywall = false

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
        return fetchLastWeekWaterPortions()
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
                // Only allow expansion if user has full access
                guard revenueCatMonitor.userHasFullAccess else {
                    isPresentedPaywall = true
                    return
                }

                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
                
                // Generate AI comment when expanding if we have sleep data but no AI comment
                if isExpanded && sleepRecommendation != nil && aiComment.isEmpty {
                    generateAIComment()
                }
            }) {
                HStack(spacing: 12) {
                    // Sleep Icon - no background circle, just colored icon like Apple Health
                    if isLoading || isRefreshingSleep {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else if let recommendation = sleepRecommendation {
                        Image(systemName: sleepIcon(for: recommendation.sleepQualityScore))
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.cyan)
                    } else if sleepService.errorMessage != nil {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.red)
                    } else {
                        Image(systemName: revenueCatMonitor.userHasFullAccess ? "bed.double.fill" : "lock.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(revenueCatMonitor.userHasFullAccess ? .cyan : .gray)
                    }

                    // Sleep Info
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("Sleep")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.primary)
                            
                            if let actualDate = sleepRecommendation?.actualSleepDate,
                               !Calendar.current.isDate(actualDate, inSameDayAs: selectedDate) {
                                Text("Yesterday")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        if isLoading || isRefreshingSleep {
                            Text(isRefreshingSleep ? "Refreshing..." : "Analyzing...")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        } else if let recommendation = sleepRecommendation {
                            Text("Time Asleep")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        } else if sleepService.errorMessage != nil {
                            Text("No Data")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        } else {
                            Text(revenueCatMonitor.userHasFullAccess ? "No Data" : "Premium feature")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    // Action buttons
                    HStack(spacing: 8) {
                        // Premium Lock Icon or Refresh Button
                        if !revenueCatMonitor.userHasFullAccess {
                            // No extra lock icon needed, already shown in main icon
                        } else {
                            // Refresh Button
                            Button(action: {
                                refreshSleepData()
                            }) {
                                if isRefreshingSleep {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(.gray)
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(isRefreshingSleep)
                        }

                        // Expand/Collapse Icon
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.gray)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    }
                }
                .padding(16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Sleep duration display (always visible when we have data, like Apple Health)
            if let recommendation = sleepRecommendation, revenueCatMonitor.userHasFullAccess {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .bottom) {
                        let hours = Int(recommendation.sleepDurationHours)
                        let minutes = Int((recommendation.sleepDurationHours - Double(hours)) * 60)
                        
                        HStack(alignment: .bottom, spacing: 2) {
                            Text("\(hours)")
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundStyle(.primary)
                            Text("hr")
                                .font(.system(size: 16))
                                .foregroundStyle(.primary)
                                .padding(.bottom, 4)
                            Text("\(minutes)")
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundStyle(.primary)
                            Text("min")
                                .font(.system(size: 16))
                                .foregroundStyle(.primary)
                                .padding(.bottom, 4)
                        }
                        
                        Spacer()
                        
                        // Simple progress bar like Apple Health
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.cyan)
                            .frame(width: 60, height: 4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, isExpanded ? 0 : 16)
            }
            
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
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .onAppear {
            fetchWaterPortions()
        }
        .onChange(of: selectedDate) { _, _ in
            fetchWaterPortions()
        }
        .sheet(isPresented: $isPresentedPaywall) {
            PaywallView()
        }
    }

    // MARK: - Premium Locked Content

    private var premiumLockedContentView: some View {
        VStack(spacing: 20) {
            Divider()
                .padding(.horizontal, 16)

            VStack(spacing: 20) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.purple.opacity(0.6))

                VStack(spacing: 8) {
                    Text("Premium Feature")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text("Unlock comprehensive sleep analysis with AI-powered hydration recommendations based on your sleep patterns and quality.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Button(action: {
                    isPresentedPaywall = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 13, weight: .medium))
                        Text("Unlock Premium")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.purple)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Sleep Icon

    private var sleepIconView: some View {
        ZStack {
            Circle()
                .fill(.purple.opacity(0.1))
                .frame(width: 40, height: 40)

            if isLoading || isRefreshingSleep {
                ProgressView()
                    .scaleEffect(0.7)
            } else if let recommendation = sleepRecommendation {
                Image(systemName: sleepIcon(for: recommendation.sleepQualityScore))
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.purple)
            } else if sleepService.errorMessage != nil {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.red)
            } else {
                Image(systemName: "moon.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.purple)
            }
        }
    }

    // MARK: - Expanded Content

    @ViewBuilder
    private var expandedContentView: some View {
        VStack(spacing: 20) {
            Divider()
                .padding(.horizontal, 16)

            if isLoading {
                loadingView
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            } else if let recommendation = sleepRecommendation {
                sleepDetailsView(recommendation)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            } else if sleepService.errorMessage != nil {
                noDataView
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            } else {
                noDataView
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
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
                    label: String(localized: "Duration"),
                    value: formatSleepDuration(recommendation.sleepDurationHours)
                )

                sleepStatItem(
                    icon: "star.fill",
                    label: String(localized: "Quality"),
                    value: "\(Int(recommendation.sleepQualityScore * 100))%"
                )

                sleepStatItem(
                    icon: "brain.head.profile",
                    label: String(localized: "Deep Sleep"),
                    value: String(localized: "\(recommendation.deepSleepMinutes)min")
                )
            }
        }
    }

    private func sleepStatItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.purple)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
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
                label: String(localized: "Evening Intake"),
                value: "\(Int(hydrationMetrics.eveningIntakePercentage * 100))%",
                status: hydrationMetrics.eveningIntakeStatus,
                icon: "moon.circle.fill"
            )
            
            // Hydration score
            metricItem(
                label: String(localized: "Daily Hydration"),
                value: "\(Int(hydrationMetrics.dailyHydrationScore * 100))%",
                status: hydrationMetrics.hydrationStatus,
                icon: "drop.circle.fill"
            )
            
            // Nocturia risk
            metricItem(
                label: String(localized: "Sleep Risk"),
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
                insights: [String(localized: "No hydration data available for today. Start logging your water intake to see personalized sleep insights.")]
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
            insights.append(String(localized: "\(confidencePrefix)You drank \(Int(eveningPercentage * 100))% of your fluids in the evening, which may disrupt sleep. Try shifting intake earlier."))
        } else if eveningPercentage <= 0.15 && hydrationScore >= 0.70 {
            insights.append(String(localized: "\(confidencePrefix)Great hydration timing! Your steady intake throughout the day supports better sleep quality."))
        }
        
        // Hydration level insights
        if hydrationScore < 0.60 {
            insights.append(String(localized: "Low daily hydration (\(Int(totalIntake))ml) may increase risk of shorter sleep duration and morning fatigue."))
        } else if hydrationScore >= 0.85 {
            insights.append(String(localized: "Excellent hydration (\(Int(totalIntake))ml) supports optimal melatonin production and sleep regulation."))
        }
        
        // Nocturia risk insights with research context
        let caffeineInsight = generateCaffeineInsight()
        
        switch nocturiaRisk {
        case .high:
            var highRiskInsight = String(localized: "High risk of sleep interruptions. Research shows >25% evening intake can cause 2-3 nighttime awakenings. Limit fluids 2-3 hours before bed to <200ml.")
            if !caffeineInsight.isEmpty {
                highRiskInsight += " " + caffeineInsight
            }
            insights.append(highRiskInsight)
        case .moderate:
            var moderateRiskInsight = String(localized: "Moderate risk of nighttime awakenings. Consider shifting more hydration to earlier in the day.")
            if !caffeineInsight.isEmpty {
                moderateRiskInsight += " " + caffeineInsight
            }
            insights.append(moderateRiskInsight)
        case .low:
            if eveningPercentage <= 0.20 {
                insights.append(String(localized: "Optimal hydration timing reduces sleep disruption risk. Your pattern aligns with research recommendations."))
            } else {
                insights.append(String(localized: "Low risk of sleep disruption from current hydration patterns."))
            }
            
            // Add caffeine insight even for low risk if relevant
            if !caffeineInsight.isEmpty {
                insights.append(caffeineInsight)
            }
        }
        
        // Add data completeness guidance
        if dataCompleteness == .minimal {
            insights.append(String(localized: "💡 Track for 7+ days to unlock personalized patterns and more accurate recommendations."))
        } else if dataCompleteness == .moderate {
            insights.append(String(localized: "📈 Great progress! 21+ days of data will enable even more precise sleep-hydration insights."))
        }
        
        return insights
    }
    
    private func getConfidencePrefix() -> String {
        switch dataCompleteness {
        case .minimal:
            return String(localized: "Early pattern: ")
        case .moderate:
            return String(localized: "Emerging trend: ")
        case .good:
            return String(localized: "Reliable pattern: ")
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
                return String(localized: "⚠️ High caffeine intake (\(Int(lateCaffeineAmount))ml) after 3 PM (last: \(timeString)) significantly increases sleep disruption risk.")
            } else if lateCaffeineAmount >= 250 {
                return String(localized: "☕️ Moderate caffeine after 3 PM (last: \(timeString)) may affect sleep quality. Consider earlier timing.")
            } else {
                return String(localized: "☕️ Small amount of caffeine after 3 PM noted. Monitor impact on sleep quality.")
            }
        }
        
        // Check for good caffeine timing
        let morningCaffeine = dayWaterData.filter { portion in
            (portion.drink == .coffee || portion.drink == .tea) && portion.createDate < afternoon
        }
        
        if !morningCaffeine.isEmpty && lateCaffeineIntake.isEmpty {
            return String(localized: "✅ Good caffeine timing! All coffee/tea before 3 PM supports better sleep quality.")
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
            let oz = WaterUnit.ounces.fromMilliliters(Double(ml))
            return String(localized: "\(Int(oz.rounded())) fl oz")
        } else {
            return String(localized: "\(ml) ml")
        }
    }
    
    // MARK: - Sleep Data Refresh
    
    private func refreshSleepData() {
        isRefreshingSleep = true
        
        Task {
            // Clean up old sleep data first, keeping only current date
            SleepAnalysisCache.cleanupOldData(
                modelContext: modelContext,
                keepingCurrentDate: selectedDate
            )

            // Fetch fresh sleep data
            if let recommendation = await sleepService.fetchSleepData(for: selectedDate) {
                // Create new cache entry with fresh data (no AI comment initially)
                let cache = SleepAnalysisCache.fromSleepRecommendation(recommendation, aiComment: "")
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
                // Refresh water portions data
                fetchWaterPortions()
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
                    // If AI generation fails, leave comment empty
                    currentAIComment = ""
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
    
    // MARK: - Water Portion Fetching
    
    private func fetchWaterPortions() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? selectedDate
        
        let fetchDescriptor = FetchDescriptor<WaterPortion>(
            predicate: #Predicate { portion in
                portion.createDate >= startOfDay && portion.createDate < endOfDay
            },
            sortBy: [.init(\WaterPortion.createDate, order: .forward)]
        )
        
        do {
            allWaterPortions = try modelContext.fetch(fetchDescriptor)
        } catch {
            print("Failed to fetch water portions: \(error)")
            allWaterPortions = []
        }
    }
    
    private func fetchLastWeekWaterPortions() -> [WaterPortion] {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: selectedDate) ?? selectedDate
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        
        let fetchDescriptor = FetchDescriptor<WaterPortion>(
            predicate: #Predicate { portion in
                portion.createDate >= weekAgo && portion.createDate <= endOfDay
            },
            sortBy: [.init(\WaterPortion.createDate, order: .forward)]
        )
        
        do {
            return try modelContext.fetch(fetchDescriptor)
        } catch {
            print("Failed to fetch last week water portions: \(error)")
            return []
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
        case .low: return String(localized: "Low")
        case .moderate: return String(localized: "Moderate")
        case .high: return String(localized: "High")
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
        case .minimal: return String(localized: "Early")
        case .moderate: return String(localized:  "Moderate")
        case .good: return String(localized: "Good")
        case .robust: return String(localized: "Robust")
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
    SleepCardView(isLoading: false)
        .modelContainer(for: [SleepAnalysisCache.self, WaterPortion.self], inMemory: true)
        .environmentObject(RevenueCatMonitor(state: .preview(false)))
        .environmentObject(AIDrinkAnalysisClient())
        .environmentObject(SleepService())
        .padding()
}
