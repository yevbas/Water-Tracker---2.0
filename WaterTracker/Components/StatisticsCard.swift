//
//  StatisticsCard.swift
//  WaterTracker
//
//  Created by Assistant on 02/10/2025.
//

import SwiftUI
import Charts

struct StatisticsCard: View {
    let waterPortions: [WaterPortion]
    @AppStorage("measurement_units") private var measurementUnits: String = "ml"
    @AppStorage("water_goal_ml") private var waterGoalMl: Int = 2500
    
    var body: some View {
        NavigationLink(destination: StatisticsView()) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Statistics")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("View detailed analytics")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chart.bar.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                // Quick Stats
                HStack(spacing: 20) {
                    QuickStatView(
                        title: "7-Day Avg",
                        value: formatAmount(weeklyAverage),
                        icon: "drop.fill",
                        color: .blue
                    )
                    
                    QuickStatView(
                        title: "Avg Size",
                        value: formatAmount(averageDrinkSize),
                        icon: "cup.and.saucer.fill",
                        color: .green
                    )
                    
                    QuickStatView(
                        title: "Today's Goal",
                        value: "\(Int(todayGoalProgress))%",
                        icon: "target",
                        color: todayGoalProgress >= 100 ? .green : .orange
                    )
                }
                
                // Mini Chart
                if !last7DaysData.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Last 7 Days")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Chart(last7DaysData) { data in
                            BarMark(
                                x: .value("Day", data.dayOfWeek),
                                y: .value("Amount", data.amount)
                            )
                            .foregroundStyle(.blue.gradient)
                            .cornerRadius(2)
                        }
                        .frame(height: 60)
                        .chartXAxis(.hidden)
                        .chartYAxis(.hidden)
                    }
                }
                
                // View More Button
                HStack {
                    Spacer()
                    Text("View Detailed Statistics")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    Image(systemName: "arrow.right")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Computed Properties
    
    private var weeklyAverage: Double {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        
        let weekPortions = waterPortions.filter { portion in
            portion.dayDate >= startDate && portion.dayDate <= endDate
        }
        
        let groupedByDay = Dictionary(grouping: weekPortions) { $0.dayDate }
        let dailyTotals = groupedByDay.mapValues { portions in
            portions.reduce(0) { total, portion in
                total + convertToMl(amount: portion.amount, unit: portion.unit)
            }
        }
        
        guard !dailyTotals.isEmpty else { return 0 }
        return dailyTotals.values.reduce(0, +) / Double(dailyTotals.count)
    }
    
    private var averageDrinkSize: Double {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        
        let weekPortions = waterPortions.filter { portion in
            portion.dayDate >= startDate && portion.dayDate <= endDate
        }
        
        guard !weekPortions.isEmpty else { return 0 }
        let totalAmount = weekPortions.reduce(0) { total, portion in
            total + convertToMl(amount: portion.amount, unit: portion.unit)
        }
        return totalAmount / Double(weekPortions.count)
    }
    
    private var todayGoalProgress: Double {
        let today = Date().rounded()
        let todayPortions = waterPortions.filter { $0.dayDate == today }
        
        let todayTotal = todayPortions.reduce(0) { total, portion in
            total + convertToMl(amount: portion.amount, unit: portion.unit)
        }
        
        return (todayTotal / Double(waterGoalMl)) * 100
    }
    
    private var last7DaysData: [DayData] {
        let calendar = Calendar.current
        let today = Date()
        var data: [DayData] = []
        
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let dayDate = date.rounded()
            
            let dayPortions = waterPortions.filter { $0.dayDate == dayDate }
            let dayTotal = dayPortions.reduce(0) { total, portion in
                total + convertToMl(amount: portion.amount, unit: portion.unit)
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "E"
            let dayOfWeek = formatter.string(from: date)
            
            data.append(DayData(dayOfWeek: dayOfWeek, amount: dayTotal))
        }
        
        return data.reversed()
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
            return "\(Int(oz.rounded()))"
        } else {
            return "\(Int(amount.rounded()))"
        }
    }
}

// MARK: - Supporting Views

struct QuickStatView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Data Models

struct DayData: Identifiable {
    let id = UUID()
    let dayOfWeek: String
    let amount: Double
}

#Preview {
    NavigationStack {
        ScrollView {
            StatisticsCard(waterPortions: [])
                .padding()
        }
    }
}
