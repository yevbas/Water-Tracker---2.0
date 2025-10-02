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
            fetchWaterPortions()
        }
        .onChange(of: selectedTimeRange) { _, _ in
            fetchWaterPortions()
        }
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
                title: "Average Daily",
                value: formatAmount(averageDailyIntake),
                subtitle: "per day",
                icon: "drop.fill",
                color: .blue
            )
            
            StatCard(
                title: "Average Size",
                value: formatAmount(averageDrinkSize),
                subtitle: "per drink",
                icon: "cup.and.saucer.fill",
                color: .green
            )
            
            StatCard(
                title: "Total Drinks",
                value: "\(totalDrinks)",
                subtitle: "drinks",
                icon: "number",
                color: .orange
            )
            
            StatCard(
                title: "Goal Achievement",
                value: "\(Int(goalAchievementRate))%",
                subtitle: "of days",
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
                DetailRow(title: "Most Active Day", value: mostActiveDayString)
                DetailRow(title: "Least Active Day", value: leastActiveDayString)
                DetailRow(title: "Favorite Drink", value: favoriteDrink)
                DetailRow(title: "Best Streak", value: "\(bestStreak) days")
                DetailRow(title: "Current Streak", value: "\(currentStreak) days")
                DetailRow(title: "Total Volume", value: formatAmount(totalIntakeInRange))
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Data Calculations
    
    private var filteredPortions: [WaterPortion] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -selectedTimeRange.days, to: endDate) ?? endDate
        
        return waterPortions.filter { portion in
            portion.dayDate >= startDate && portion.dayDate <= endDate
        }
    }
    
    private var averageDailyIntake: Double {
        let groupedByDay = Dictionary(grouping: filteredPortions) { $0.dayDate }
        let dailyTotals = groupedByDay.mapValues { portions in
            portions.reduce(0) { total, portion in
                total + convertToMl(amount: portion.amount, unit: portion.unit)
            }
        }
        
        guard !dailyTotals.isEmpty else { return 0 }
        return dailyTotals.values.reduce(0, +) / Double(dailyTotals.count)
    }
    
    private var averageDrinkSize: Double {
        guard !filteredPortions.isEmpty else { return 0 }
        let totalAmount = filteredPortions.reduce(0) { total, portion in
            total + convertToMl(amount: portion.amount, unit: portion.unit)
        }
        return totalAmount / Double(filteredPortions.count)
    }
    
    private var totalDrinks: Int {
        filteredPortions.count
    }
    
    private var goalAchievementRate: Double {
        let groupedByDay = Dictionary(grouping: filteredPortions) { $0.dayDate }
        let dailyTotals = groupedByDay.mapValues { portions in
            portions.reduce(0) { total, portion in
                total + convertToMl(amount: portion.amount, unit: portion.unit)
            }
        }
        
        guard !dailyTotals.isEmpty else { return 0 }
        let daysReachedGoal = dailyTotals.values.filter { $0 >= Double(waterGoalMl) }.count
        return (Double(daysReachedGoal) / Double(dailyTotals.count)) * 100
    }
    
    private var totalIntakeInRange: Double {
        filteredPortions.reduce(0) { total, portion in
            total + convertToMl(amount: portion.amount, unit: portion.unit)
        }
    }
    
    private var dailyIntakeData: [DailyIntakeData] {
        let groupedByDay = Dictionary(grouping: filteredPortions) { $0.dayDate }
        return groupedByDay.map { date, portions in
            let totalAmount = portions.reduce(0) { total, portion in
                total + convertToMl(amount: portion.amount, unit: portion.unit)
            }
            return DailyIntakeData(date: date, amount: totalAmount)
        }.sorted { $0.date < $1.date }
    }
    
    private var drinkTypeData: [DrinkTypeData] {
        let groupedByDrink = Dictionary(grouping: filteredPortions) { $0.drink }
        return groupedByDrink.map { drink, portions in
            let totalAmount = portions.reduce(0) { total, portion in
                total + convertToMl(amount: portion.amount, unit: portion.unit)
            }
            return DrinkTypeData(drink: drink, amount: totalAmount)
        }.sorted { $0.amount > $1.amount }
    }
    
    private var weeklyTrendData: [WeeklyTrendData] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -selectedTimeRange.days, to: endDate) ?? endDate
        
        var weeklyData: [WeeklyTrendData] = []
        var currentDate = startDate
        var weekNumber = 1
        
        while currentDate <= endDate {
            let weekEnd = min(calendar.date(byAdding: .day, value: 6, to: currentDate) ?? currentDate, endDate)
            
            let weekPortions = filteredPortions.filter { portion in
                portion.dayDate >= currentDate && portion.dayDate <= weekEnd
            }
            
            let groupedByDay = Dictionary(grouping: weekPortions) { $0.dayDate }
            let dailyTotals = groupedByDay.mapValues { portions in
                portions.reduce(0) { total, portion in
                    total + convertToMl(amount: portion.amount, unit: portion.unit)
                }
            }
            
            let averageIntake = dailyTotals.isEmpty ? 0 : dailyTotals.values.reduce(0, +) / Double(dailyTotals.count)
            
            weeklyData.append(WeeklyTrendData(week: weekNumber, averageIntake: averageIntake))
            
            currentDate = calendar.date(byAdding: .day, value: 7, to: currentDate) ?? currentDate
            weekNumber += 1
        }
        
        return weeklyData
    }
    
    private var goalProgressData: [GoalProgressData] {
        let groupedByDay = Dictionary(grouping: filteredPortions) { $0.dayDate }
        return groupedByDay.map { date, portions in
            let totalAmount = portions.reduce(0) { total, portion in
                total + convertToMl(amount: portion.amount, unit: portion.unit)
            }
            let progressPercentage = (totalAmount / Double(waterGoalMl)) * 100
            return GoalProgressData(date: date, progressPercentage: min(progressPercentage, 150)) // Cap at 150% for better visualization
        }.sorted { $0.date < $1.date }
    }
    
    private var mostActiveDayString: String {
        let groupedByDay = Dictionary(grouping: filteredPortions) { $0.dayDate }
        let dailyTotals = groupedByDay.mapValues { portions in
            portions.reduce(0) { total, portion in
                total + convertToMl(amount: portion.amount, unit: portion.unit)
            }
        }
        
        guard let maxDay = dailyTotals.max(by: { $0.value < $1.value }) else {
            return "No data"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: maxDay.key)) (\(formatAmount(maxDay.value)))"
    }
    
    private var leastActiveDayString: String {
        let groupedByDay = Dictionary(grouping: filteredPortions) { $0.dayDate }
        let dailyTotals = groupedByDay.mapValues { portions in
            portions.reduce(0) { total, portion in
                total + convertToMl(amount: portion.amount, unit: portion.unit)
            }
        }
        
        guard let minDay = dailyTotals.min(by: { $0.value < $1.value }) else {
            return "No data"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: minDay.key)) (\(formatAmount(minDay.value)))"
    }
    
    private var favoriteDrink: String {
        let groupedByDrink = Dictionary(grouping: filteredPortions) { $0.drink }
        let drinkCounts = groupedByDrink.mapValues { $0.count }
        
        guard let favorite = drinkCounts.max(by: { $0.value < $1.value }) else {
            return "No data"
        }
        
        return "\(favorite.key.title) (\(favorite.value) drinks)"
    }
    
    private var bestStreak: Int {
        // Calculate the longest streak of days meeting the goal
        let groupedByDay = Dictionary(grouping: waterPortions) { $0.dayDate }
        let dailyTotals = groupedByDay.mapValues { portions in
            portions.reduce(0) { total, portion in
                total + convertToMl(amount: portion.amount, unit: portion.unit)
            }
        }
        
        let sortedDays = dailyTotals.keys.sorted()
        var maxStreak = 0
        var currentStreak = 0
        
        for day in sortedDays {
            if let total = dailyTotals[day], total >= Double(waterGoalMl) {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }
        
        return maxStreak
    }
    
    private var currentStreak: Int {
        // Calculate current streak from today backwards
        let calendar = Calendar.current
        let today = Date().rounded()
        var streak = 0
        var checkDate = today
        
        let groupedByDay = Dictionary(grouping: waterPortions) { $0.dayDate }
        
        while let dayTotal = groupedByDay[checkDate]?.reduce(0, { total, portion in
            total + convertToMl(amount: portion.amount, unit: portion.unit)
        }), dayTotal >= Double(waterGoalMl) {
            streak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        
        return streak
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
    
    private func formatAmount(_ amount: Double) -> String {
        if measurementUnits == "fl_oz" {
            let oz = amount / 29.5735
            return "\(Int(oz.rounded())) fl oz"
        } else {
            return "\(Int(amount.rounded())) ml"
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
        } catch {
            print("Error fetching water portions: \(error)")
            waterPortions = []
        }
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
