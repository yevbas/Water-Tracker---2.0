//
//  StatisticsCard.swift
//  WaterTracker
//
//  Created by Assistant on 02/10/2025.
//

import SwiftUI
import Charts
import RevenueCatUI
import SwiftData

struct StatisticsCard: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("measurement_units") private var measurementUnits: String = "ml"
    @AppStorage("water_goal_ml") private var waterGoalMl: Int = 2500
    @EnvironmentObject private var revenueCatMonitor: RevenueCatMonitor
    @State var isPresentedPaywall = false
    @State var isPresentedStatisticsView = false
    @State private var waterPortions: [WaterPortion] = []
    
    // Cached computed data to avoid recalculation
    @State private var cachedStats: StatisticsData?
    @State private var lastFetchDate: Date?

    var body: some View {
        Button(action: {
            if revenueCatMonitor.userHasFullAccess {
                isPresentedStatisticsView = true
            } else {
                isPresentedPaywall = true
            }
        }) {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(spacing: 12) {
                    // Icon - no background circle, just colored icon
                    Image(systemName: revenueCatMonitor.userHasFullAccess ? "chart.bar.fill" : "lock.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(revenueCatMonitor.userHasFullAccess ? .orange : .gray)
                    
                    // Title
                    Text("Statistics")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.gray)
                }
                
                if revenueCatMonitor.userHasFullAccess {
                    // Hydration breakdown
                    hydrationBreakdownSection
                    
                    // Main content like Apple Health
                    VStack(alignment: .leading, spacing: 16) {
                        // Summary text
                        Text("Over the last 7 days, you averaged \(formatAmount(weeklyAverage)) water intake a day.")
                            .font(.system(size: 15))
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Mini Chart
                        if !last7DaysData.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Average Water Intake")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                                
                                HStack(alignment: .bottom) {
                                    Text("\(formatAmount(weeklyAverage))")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundStyle(.primary)
                                    
                                    Text(measurementUnits == "fl_oz" ? "fl oz" : "ml")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.secondary)
                                        .padding(.bottom, 2)
                                    
                                    Spacer()
                                }
                                
                                Chart(last7DaysData, id: \.dayOfWeek) { data in
                                    BarMark(
                                        x: .value("Day", data.dayOfWeek),
                                        y: .value("Amount", data.amount)
                                    )
                                    .foregroundStyle(.orange)
                                    .cornerRadius(2)
                                }
                                .frame(height: 60)
                                .chartXAxis(.visible)
                                .chartYAxis(.hidden)
                                .chartXAxis {
                                    AxisMarks(values: .automatic) { _ in
                                        AxisValueLabel()
                                            .font(.system(size: 11))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    // Premium locked content
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 10) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.blue)
                                Text("Weekly and monthly trends")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                            }
                            
                            HStack(spacing: 10) {
                                Image(systemName: "drop.circle")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.green)
                                Text("Drink type analysis")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                            }
                            
                            HStack(spacing: 10) {
                                Image(systemName: "target")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.orange)
                                Text("Goal achievement patterns")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        // Unlock Button
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
                                    .fill(.blue)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .navigationDestination(isPresented: $isPresentedStatisticsView) {
            StatisticsView()
        }
        .sheet(isPresented: $isPresentedPaywall) {
            PaywallView()
        }
        .onAppear {
            if cachedStats == nil || lastFetchDate == nil {
                fetchWaterPortions()
            }
        }
        .onChange(of: modelContext) { _, _ in
            // Only refetch if we don't have cached data or it's been more than 5 minutes
            if cachedStats == nil || lastFetchDate == nil || 
               (lastFetchDate != nil && Date().timeIntervalSince(lastFetchDate!) > 300) {
                fetchWaterPortions()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var weeklyAverage: Double {
        cachedStats?.weeklyAverage ?? 0
    }
    
    private var averageDrinkSize: Double {
        cachedStats?.averageDrinkSize ?? 0
    }
    
    private var todayGoalProgress: Double {
        cachedStats?.todayGoalProgress ?? 0
    }
    
    private var last7DaysData: [DayData] {
        cachedStats?.last7DaysData ?? []
    }
    
    // MARK: - Helper Functions
    
    private func convertToMl(amount: Double, unit: WaterUnit) -> Double {
        switch unit {
        case .millilitres:
            return amount
        case .ounces:
            return amount * 29.5735
        }
    }
    
    private var hydrationBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Hydration Breakdown")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)
                Spacer()
            }
            
            HStack(spacing: 12) {
                // Net hydration
                VStack(alignment: .leading, spacing: 4) {
                    Text("Net Hydration")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formatAmount(netHydrationAmount))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.blue)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                .id("net-hydration")
                
                if dehydrationAmount > 0 {
                    // Dehydration
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dehydrated")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("-\(formatAmount(dehydrationAmount))")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.red)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                    .id("dehydration")
                }
            }
            
            // Category breakdown
            if !categoryBreakdown.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("By Category")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    ForEach(categoryBreakdown, id: \.category) { item in
                        HStack {
                            Circle()
                                .fill(item.color)
                                .frame(width: 8, height: 8)
                            Text(item.category.displayName)
                                .font(.caption)
                            Spacer()
                            Text(formatAmount(item.amount))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .id("category-\(item.category.rawValue)")
                    }
                }
            }
        }
        .padding(12)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
    }
    
    private var netHydrationAmount: Double {
        cachedStats?.netHydrationAmount ?? 0
    }
    
    private var dehydrationAmount: Double {
        cachedStats?.dehydrationAmount ?? 0
    }
    
    private var categoryBreakdown: [(category: HydrationCategory, amount: Double, color: Color)] {
        cachedStats?.categoryBreakdown ?? []
    }
    
    private func formatAmount(_ amount: Double) -> String {
        if measurementUnits == "fl_oz" {
            let oz = amount / 29.5735
            return "\(Int(oz.rounded()))"
        } else {
            return "\(Int(amount.rounded()))"
        }
    }
    
    // MARK: - Data Fetching
    
    private func fetchWaterPortions() {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate // Only fetch last 7 days for statistics card
        
        let fetchDescriptor = FetchDescriptor<WaterPortion>(
            predicate: #Predicate<WaterPortion> { portion in
                portion.dayDate >= startDate && portion.dayDate <= endDate
            },
            sortBy: [SortDescriptor(\.createDate, order: .reverse)]
        )
        
        do {
            waterPortions = try modelContext.fetch(fetchDescriptor)
            calculateAndCacheStatistics()
        } catch {
            print("Error fetching water portions for statistics: \(error)")
            waterPortions = []
            cachedStats = nil
        }
    }
    
    private func calculateAndCacheStatistics() {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        
        // Filter to last 7 days
        let weekPortions = waterPortions.filter { portion in
            portion.dayDate >= startDate && portion.dayDate <= endDate
        }
        
        // Calculate weekly average
        let groupedByDay = Dictionary(grouping: weekPortions) { $0.dayDate }
        let dailyTotals = groupedByDay.mapValues { portions in
            portions.reduce(0) { total, portion in
                total + convertToMl(amount: portion.amount, unit: portion.unit)
            }
        }
        
        let weeklyAverage = dailyTotals.isEmpty ? 0 : dailyTotals.values.reduce(0, +) / Double(dailyTotals.count)
        
        // Calculate average drink size
        let averageDrinkSize = weekPortions.isEmpty ? 0 : {
            let totalAmount = weekPortions.reduce(0) { total, portion in
                total + convertToMl(amount: portion.amount, unit: portion.unit)
            }
            return totalAmount / Double(weekPortions.count)
        }()
        
        // Calculate today's goal progress
        let today = Date().rounded()
        let todayPortions = waterPortions.filter { $0.dayDate == today }
        let todayTotal = todayPortions.reduce(0) { total, portion in
            total + convertToMl(amount: portion.amount, unit: portion.unit)
        }
        let todayGoalProgress = (todayTotal / Double(waterGoalMl)) * 100
        
        // Calculate last 7 days chart data
        var last7DaysData: [DayData] = []
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: endDate) else { continue }
            let dayDate = date.rounded()
            
            let dayPortions = waterPortions.filter { $0.dayDate == dayDate }
            let dayTotal = dayPortions.reduce(0) { total, portion in
                total + convertToMl(amount: portion.amount, unit: portion.unit)
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "E"
            let dayOfWeek = formatter.string(from: date)
            
            last7DaysData.append(DayData(dayOfWeek: dayOfWeek, amount: dayTotal))
        }
        last7DaysData = last7DaysData.reversed()
        
        // Calculate hydration amounts
        let netHydrationAmount = waterPortions.reduce(0) { sum, portion in
            let amountInMl = convertToMl(amount: portion.amount, unit: portion.unit)
            return sum + (amountInMl * portion.drink.hydrationFactor)
        }
        
        let dehydrationAmount = waterPortions.reduce(0) { sum, portion in
            let amountInMl = convertToMl(amount: portion.amount, unit: portion.unit)
            if portion.drink.hydrationFactor < 0 {
                return sum + (amountInMl * abs(portion.drink.hydrationFactor))
            }
            return sum
        }
        
        // Calculate category breakdown
        let breakdown = Dictionary(grouping: waterPortions) { $0.drink.hydrationCategory }
        let categoryBreakdown = breakdown.compactMap { category, portions in
            let totalAmount = portions.reduce(0) { sum, portion in
                sum + convertToMl(amount: portion.amount, unit: portion.unit)
            }
            
            let color: Color = switch category {
            case .fullyHydrating: .blue
            case .mildDiuretic: .teal
            case .partiallyHydrating: .orange
            case .dehydrating: .red
            }
            
            return (category: category, amount: totalAmount, color: color)
        }.sorted { $0.amount > $1.amount }
        
        // Cache all calculated data
        cachedStats = StatisticsData(
            weeklyAverage: weeklyAverage,
            averageDrinkSize: averageDrinkSize,
            todayGoalProgress: todayGoalProgress,
            last7DaysData: last7DaysData,
            netHydrationAmount: netHydrationAmount,
            dehydrationAmount: dehydrationAmount,
            categoryBreakdown: categoryBreakdown
        )
        
        lastFetchDate = Date()
    }
}

// MARK: - Supporting Views

struct QuickStatView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Data Models

struct DayData: Identifiable {
    let id = UUID()
    let dayOfWeek: String
    let amount: Double
}

struct StatisticsData {
    let weeklyAverage: Double
    let averageDrinkSize: Double
    let todayGoalProgress: Double
    let last7DaysData: [DayData]
    let netHydrationAmount: Double
    let dehydrationAmount: Double
    let categoryBreakdown: [(category: HydrationCategory, amount: Double, color: Color)]
}

#Preview {
    NavigationStack {
        ScrollView {
            StatisticsCard()
                .environmentObject(RevenueCatMonitor(state: .preview(false)))
                .modelContainer(for: [WaterPortion.self], inMemory: true)
                .padding()
        }
    }
}
