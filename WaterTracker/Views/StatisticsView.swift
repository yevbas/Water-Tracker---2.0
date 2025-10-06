//
//  StatisticsView.swift
//  WaterTracker
//
//  Created by Assistant on 02/10/2025.
//

import SwiftUI
import Charts
import SwiftData
import Foundation

struct StatisticsView: View {
    @Environment(\.modelContext) var modelContext
    @AppStorage("measurement_units") private var measurementUnits: String = "ml"
    @AppStorage("water_goal_ml") private var waterGoalMl: Int = 2500
    
    @State private var waterPortions: [WaterPortion] = []
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedStatistic: StatisticType = .dailyAverage
    
    // Cached computed data to avoid recalculation
    @State private var cachedStatistics: DetailedStatisticsData?
    @State private var lastFetchDate: Date?
    @State private var lastTimeRange: TimeRange = .week
    
    enum TimeRange: String, CaseIterable {
        case week = "7 Days"
        case month = "30 Days"
        case threeMonths = "3 Months"
        case year = "1 Year"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            case .year: return 365
            }
        }
    }
    
    enum StatisticType: String, CaseIterable {
        case dailyAverage = "Daily Average"
        case drinkTypes = "Drink Types"
        case weeklyTrend = "Weekly Trend"
        case goalProgress = "Goal Progress"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Time Range Picker
                timeRangePicker
                
                // Statistics Cards
                statisticsCards
                
                // Chart Section
                chartSection
                
                // Detailed Statistics
                detailedStatistics
                
                Spacer(minLength: 100)
            }
            .padding()
        }
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if cachedStatistics == nil || lastFetchDate == nil {
                fetchWaterPortions()
            }
        }
        .onChange(of: selectedTimeRange) { _, newRange in
            if newRange != lastTimeRange {
                fetchWaterPortions()
            }
        }
        .toolbar(.hidden, for: .tabBar)
    }
    
    private var timeRangePicker: some View {
        Picker("Time Range", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
    }
    
    private var statisticsCards: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(
                title: String(localized: "Average Daily"),
                value: formatAmount(averageDailyIntake),
                subtitle: String(localized: "per day"),
                icon: "drop.fill",
                color: .blue
            )
            
            StatCard(
                title: String(localized: "Average Size"),
                value: formatAmount(averageDrinkSize),
                subtitle: String(localized: "per drink"),
                icon: "cup.and.saucer.fill",
                color: .green
            )
            
            StatCard(
                title: String(localized: "Total Drinks"),
                value: "\(totalDrinks)",
                subtitle: String(localized: "drinks"),
                icon: "number",
                color: .orange
            )
            
            StatCard(
                title: String(localized: "Goal Achievement"),
                value: "\(Int(goalAchievementRate))%",
                subtitle: String(localized: "of days"),
                icon: "target",
                color: .purple
            )
        }
    }
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Charts")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Picker("Chart Type", selection: $selectedStatistic) {
                    ForEach(StatisticType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            chartView
                .frame(height: 250)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private var chartView: some View {
        switch selectedStatistic {
        case .dailyAverage:
            dailyIntakeChart
        case .drinkTypes:
            drinkTypesChart
        case .weeklyTrend:
            weeklyTrendChart
        case .goalProgress:
            goalProgressChart
        }
    }
    
    private var dailyIntakeChart: some View {
        Chart(dailyIntakeData) { data in
            BarMark(
                x: .value("Date", data.date, unit: .day),
                y: .value("Amount", data.amount)
            )
            .foregroundStyle(.blue.gradient)
            .cornerRadius(4)
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(formatAmount(amount))
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: max(1, selectedTimeRange.days / 7))) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
    }
    
    private var drinkTypesChart: some View {
        Chart(drinkTypeData) { data in
            SectorMark(
                angle: .value("Amount", data.amount),
                innerRadius: .ratio(0.5),
                angularInset: 2
            )
            .foregroundStyle(by: .value("Drink", data.drink.title))
            .cornerRadius(4)
        }
        .chartLegend(position: .bottom, alignment: .center)
        .chartBackground { chartProxy in
            GeometryReader { geometry in
                if let plotFrame = chartProxy.plotFrame {
                    let frame = geometry[plotFrame]
                    VStack {
                        Text("Drink Types")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        Text(formatAmount(totalIntakeInRange))
                            .font(.title2.bold())
                            .foregroundColor(.primary)
                    }
                    .position(x: frame.midX, y: frame.midY)
                }
            }
        }
    }
    
    private var weeklyTrendChart: some View {
        Chart(weeklyTrendData) { data in
            LineMark(
                x: .value("Week", data.week),
                y: .value("Average", data.averageIntake)
            )
            .foregroundStyle(.green)
            .lineStyle(StrokeStyle(lineWidth: 3))
            
            PointMark(
                x: .value("Week", data.week),
                y: .value("Average", data.averageIntake)
            )
            .foregroundStyle(.green)
            .symbolSize(50)
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(formatAmount(amount))
                    }
                }
            }
        }
    }
    
    private var goalProgressChart: some View {
        Chart(goalProgressData) { data in
            BarMark(
                x: .value("Date", data.date, unit: .day),
                y: .value("Progress", data.progressPercentage)
            )
            .foregroundStyle(data.progressPercentage >= 100 ? .green : .orange)
            .cornerRadius(4)
            
            RuleMark(y: .value("Goal", 100))
                .foregroundStyle(.red)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let percentage = value.as(Double.self) {
                        Text("\(Int(percentage))%")
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: max(1, selectedTimeRange.days / 7))) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
    }
    
    private var detailedStatistics: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detailed Statistics")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                DetailRow(
                    title: String(localized: "Most Active Day"),
                    value: mostActiveDayString
                )
                DetailRow(
                    title: String(localized: "Least Active Day"),
                    value: leastActiveDayString
                )
                DetailRow(
                    title: String(localized: "Favorite Drink"),
                    value: favoriteDrink
                )
                DetailRow(
                    title: String(localized: "Best Streak"),
                    value: String(localized: "\(bestStreak) days")
                )
                DetailRow(
                    title: String(localized: "Current Streak"),
                    value: String(localized: "\(currentStreak) days")
                )
                DetailRow(
                    title: String(localized: "Total Volume"),
                    value: formatAmount(totalIntakeInRange)
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Data Calculations
    
    private var filteredPortions: [WaterPortion] {
        cachedStatistics?.filteredPortions ?? []
    }
    
    private var averageDailyIntake: Double {
        cachedStatistics?.averageDailyIntake ?? 0
    }
    
    private var averageDrinkSize: Double {
        cachedStatistics?.averageDrinkSize ?? 0
    }
    
    private var totalDrinks: Int {
        cachedStatistics?.totalDrinks ?? 0
    }
    
    private var goalAchievementRate: Double {
        cachedStatistics?.goalAchievementRate ?? 0
    }
    
    private var totalIntakeInRange: Double {
        cachedStatistics?.totalIntakeInRange ?? 0
    }
    
    private var dailyIntakeData: [DailyIntakeData] {
        cachedStatistics?.dailyIntakeData ?? []
    }
    
    private var drinkTypeData: [DrinkTypeData] {
        cachedStatistics?.drinkTypeData ?? []
    }
    
    private var weeklyTrendData: [WeeklyTrendData] {
        cachedStatistics?.weeklyTrendData ?? []
    }
    
    private var goalProgressData: [GoalProgressData] {
        cachedStatistics?.goalProgressData ?? []
    }
    
    private var mostActiveDayString: String {
        cachedStatistics?.mostActiveDayString ?? String(localized: "No data")
    }
    
    private var leastActiveDayString: String {
        cachedStatistics?.leastActiveDayString ?? String(localized: "No data")
    }
    
    private var favoriteDrink: String {
        cachedStatistics?.favoriteDrink ?? String(localized: "No data")
    }
    
    private var bestStreak: Int {
        cachedStatistics?.bestStreak ?? 0
    }
    
    private var currentStreak: Int {
        cachedStatistics?.currentStreak ?? 0
    }
    
    // MARK: - Helper Functions
    
    private func convertToMl(amount: Double, unit: WaterUnit) -> Double {
        switch unit {
        case .millilitres:
            return amount
        case .ounces:
            return unit.toMilliliters(amount)
        }
    }

    private func formatAmount(_ amount: Double) -> String {
        if measurementUnits == "fl_oz" {
            let oz = WaterUnit.ounces.fromMilliliters(amount)
            return String(localized: "\(Int(oz.rounded())) fl oz")
        } else {
            return String(localized: "\(Int(amount.rounded())) ml")
        }
    }
    
    private func fetchWaterPortions() {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -selectedTimeRange.days, to: endDate) ?? endDate
        
        let fetchDescriptor = FetchDescriptor<WaterPortion>(
            predicate: #Predicate { $0.dayDate >= startDate && $0.dayDate <= endDate },
            sortBy: [.init(\WaterPortion.createDate, order: .reverse)]
        )
        
        do {
            waterPortions = try modelContext.fetch(fetchDescriptor)
            calculateAndCacheStatistics()
        } catch {
            print("Error fetching water portions: \(error)")
            waterPortions = []
            cachedStatistics = nil
        }
    }
    
    private func calculateAndCacheStatistics() {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -selectedTimeRange.days, to: endDate) ?? endDate
        
        // Filter portions to selected time range
        let filteredPortions = waterPortions.filter { portion in
            portion.dayDate >= startDate && portion.dayDate <= endDate
        }
        
        // Calculate basic statistics
        let groupedByDay = Dictionary(grouping: filteredPortions) { $0.dayDate }
        let dailyTotals = groupedByDay.mapValues { portions in
            portions.reduce(0) { total, portion in
                total + convertToMl(amount: portion.amount, unit: portion.unit)
            }
        }
        
        let averageDailyIntake = dailyTotals.isEmpty ? 0 : dailyTotals.values.reduce(0, +) / Double(dailyTotals.count)
        
        let averageDrinkSize = filteredPortions.isEmpty ? 0 : {
            let totalAmount = filteredPortions.reduce(0) { total, portion in
                total + convertToMl(amount: portion.amount, unit: portion.unit)
            }
            return totalAmount / Double(filteredPortions.count)
        }()
        
        let totalDrinks = filteredPortions.count
        
        let goalAchievementRate = {
            guard !dailyTotals.isEmpty else { return 0.0 }
            let daysReachedGoal = dailyTotals.values.filter { $0 >= Double(waterGoalMl) }.count
            return (Double(daysReachedGoal) / Double(dailyTotals.count)) * 100
        }()
        
        let totalIntakeInRange = filteredPortions.reduce(0) { total, portion in
            total + convertToMl(amount: portion.amount, unit: portion.unit)
        }
        
        // Calculate chart data
        let dailyIntakeData = groupedByDay.map { date, portions in
            let totalAmount = portions.reduce(0) { total, portion in
                total + convertToMl(amount: portion.amount, unit: portion.unit)
            }
            return DailyIntakeData(date: date, amount: totalAmount)
        }.sorted { $0.date < $1.date }
        
        let drinkTypeData = {
            let groupedByDrink = Dictionary(grouping: filteredPortions) { $0.drink }
            return groupedByDrink.map { drink, portions in
                let totalAmount = portions.reduce(0) { total, portion in
                    total + convertToMl(amount: portion.amount, unit: portion.unit)
                }
                return DrinkTypeData(drink: drink, amount: totalAmount)
            }.sorted { $0.amount > $1.amount }
        }()
        
        let weeklyTrendData = {
            let calendar = Calendar.current
            var weeklyData: [WeeklyTrendData] = []
            var currentDate = startDate
            var weekNumber = 1
            
            while currentDate <= endDate {
                let weekEnd = min(calendar.date(byAdding: .day, value: 6, to: currentDate) ?? currentDate, endDate)
                
                let weekPortions = filteredPortions.filter { portion in
                    portion.dayDate >= currentDate && portion.dayDate <= weekEnd
                }
                
                let weekGroupedByDay = Dictionary(grouping: weekPortions) { $0.dayDate }
                let weekDailyTotals = weekGroupedByDay.mapValues { portions in
                    portions.reduce(0) { total, portion in
                        total + convertToMl(amount: portion.amount, unit: portion.unit)
                    }
                }
                
                let averageIntake = weekDailyTotals.isEmpty ? 0 : weekDailyTotals.values.reduce(0, +) / Double(weekDailyTotals.count)
                
                weeklyData.append(WeeklyTrendData(week: weekNumber, averageIntake: averageIntake))
                
                currentDate = calendar.date(byAdding: .day, value: 7, to: currentDate) ?? currentDate
                weekNumber += 1
            }
            
            return weeklyData
        }()
        
        let goalProgressData = groupedByDay.map { date, portions in
            let totalAmount = portions.reduce(0) { total, portion in
                total + convertToMl(amount: portion.amount, unit: portion.unit)
            }
            let progressPercentage = (totalAmount / Double(waterGoalMl)) * 100
            return GoalProgressData(date: date, progressPercentage: min(progressPercentage, 150))
        }.sorted { $0.date < $1.date }
        
        // Calculate detailed statistics
        let mostActiveDayString = {
            guard let maxDay = dailyTotals.max(by: { $0.value < $1.value }) else {
                return String(localized: "No data")
            }
            
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "\(formatter.string(from: maxDay.key)) (\(formatAmount(maxDay.value)))"
        }()
        
        let leastActiveDayString = {
            guard let minDay = dailyTotals.min(by: { $0.value < $1.value }) else {
                return String(localized: "No data")
            }
            
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "\(formatter.string(from: minDay.key)) (\(formatAmount(minDay.value)))"
        }()
        
        let favoriteDrink = {
            let groupedByDrink = Dictionary(grouping: filteredPortions) { $0.drink }
            let drinkCounts = groupedByDrink.mapValues { $0.count }
            
            guard let favorite = drinkCounts.max(by: { $0.value < $1.value }) else {
                return String(localized: "No data")
            }
            
            return String(localized: "\(favorite.key.title) (\(favorite.value) drinks)")
        }()
        
        let bestStreak = {
            let allGroupedByDay = Dictionary(grouping: waterPortions) { $0.dayDate }
            let allDailyTotals = allGroupedByDay.mapValues { portions in
                portions.reduce(0) { total, portion in
                    total + convertToMl(amount: portion.amount, unit: portion.unit)
                }
            }
            
            let sortedDays = allDailyTotals.keys.sorted()
            var maxStreak = 0
            var currentStreak = 0
            
            for day in sortedDays {
                if let total = allDailyTotals[day], total >= Double(waterGoalMl) {
                    currentStreak += 1
                    maxStreak = max(maxStreak, currentStreak)
                } else {
                    currentStreak = 0
                }
            }
            
            return maxStreak
        }()
        
        let currentStreak = {
            let calendar = Calendar.current
            let today = Date().rounded()
            var streak = 0
            var checkDate = today
            
            let allGroupedByDay = Dictionary(grouping: waterPortions) { $0.dayDate }
            
            while let dayTotal = allGroupedByDay[checkDate]?.reduce(0, { total, portion in
                total + convertToMl(amount: portion.amount, unit: portion.unit)
            }), dayTotal >= Double(waterGoalMl) {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            }
            
            return streak
        }()
        
        // Cache all calculated data
        cachedStatistics = DetailedStatisticsData(
            filteredPortions: filteredPortions,
            averageDailyIntake: averageDailyIntake,
            averageDrinkSize: averageDrinkSize,
            totalDrinks: totalDrinks,
            goalAchievementRate: goalAchievementRate,
            totalIntakeInRange: totalIntakeInRange,
            dailyIntakeData: dailyIntakeData,
            drinkTypeData: drinkTypeData,
            weeklyTrendData: weeklyTrendData,
            goalProgressData: goalProgressData,
            mostActiveDayString: mostActiveDayString,
            leastActiveDayString: leastActiveDayString,
            favoriteDrink: favoriteDrink,
            bestStreak: bestStreak,
            currentStreak: currentStreak
        )
        
        lastFetchDate = Date()
        lastTimeRange = selectedTimeRange
    }
}

// MARK: - Data Models

struct DailyIntakeData: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
}

struct DrinkTypeData: Identifiable {
    let id = UUID()
    let drink: Drink
    let amount: Double
}

struct WeeklyTrendData: Identifiable {
    let id = UUID()
    let week: Int
    let averageIntake: Double
}

struct GoalProgressData: Identifiable {
    let id = UUID()
    let date: Date
    let progressPercentage: Double
}

struct DetailedStatisticsData {
    let filteredPortions: [WaterPortion]
    let averageDailyIntake: Double
    let averageDrinkSize: Double
    let totalDrinks: Int
    let goalAchievementRate: Double
    let totalIntakeInRange: Double
    let dailyIntakeData: [DailyIntakeData]
    let drinkTypeData: [DrinkTypeData]
    let weeklyTrendData: [WeeklyTrendData]
    let goalProgressData: [GoalProgressData]
    let mostActiveDayString: String
    let leastActiveDayString: String
    let favoriteDrink: String
    let bestStreak: Int
    let currentStreak: Int
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}


#Preview {
    NavigationStack {
        StatisticsView()
            .modelContainer(for: [WaterPortion.self], inMemory: true)
    }
}
