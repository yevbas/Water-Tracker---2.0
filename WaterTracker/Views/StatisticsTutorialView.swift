//
//  StatisticsTutorialView.swift
//  WaterTracker
//
//  Created by Assistant on 02/10/2025.
//

import SwiftUI
import Charts

struct StatisticsTutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0

    private let pages = [
        TutorialPage(
            title: "Comprehensive Analytics",
            subtitle: "Track Your Hydration Journey",
            description: "The Statistics view provides detailed insights into your hydration patterns with interactive charts, trends analysis, and achievement tracking.",
            icon: "chart.bar.fill",
            iconColor: .green,
            benefits: [
                "Daily, weekly, monthly, and yearly views",
                "Interactive charts with multiple data types",
                "Goal achievement tracking and streaks",
                "Drink type distribution analysis"
            ]
        ),
        TutorialPage(
            title: "Key Metrics & Insights",
            subtitle: "Understand Your Patterns",
            description: "Monitor essential hydration metrics including daily averages, drink sizes, total intake, and goal achievement rates over different time periods.",
            icon: "target",
            iconColor: .blue,
            benefits: [
                "Average daily intake and drink size",
                "Total drinks consumed over time",
                "Goal achievement percentage",
                "Best and current streaks"
            ]
        ),
        TutorialPage(
            title: "Interactive Charts",
            subtitle: "Visualize Your Progress",
            description: "Switch between different chart types to analyze your data: daily intake bars, drink type pie charts, weekly trends, and goal progress tracking.",
            icon: "chart.line.uptrend.xyaxis",
            iconColor: .purple,
            benefits: [
                "Daily intake bar charts with goal lines",
                "Drink type distribution pie charts",
                "Weekly trend lines showing patterns",
                "Goal progress visualization over time"
            ]
        ),
        TutorialPage(
            title: "Using Statistics Effectively",
            subtitle: "Improve Your Habits",
            description: "Use the statistics to identify patterns, set realistic goals, and maintain consistent hydration habits. Look for trends and adjust your routine accordingly.",
            icon: "lightbulb.fill",
            iconColor: .orange,
            benefits: [
                "Identify your most and least active days",
                "Find your favorite drink types and patterns",
                "Track improvement over different time periods",
                "Use insights to maintain healthy habits"
            ]
        )
    ]

    var body: some View {
        VStack(spacing: 0) {

            // Page Content
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    StatisticsTutorialPageView(page: pages[index], currentPage: $currentPage)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

            // Bottom Navigation
            VStack(spacing: 20) {
                // Page Indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? .green : .gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                    }
                }

                // Navigation Buttons
                HStack(spacing: 16) {
                    if currentPage > 0 {
                        Button("Previous") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPage -= 1
                            }
                        }
                        .foregroundStyle(.secondary)
                    } else {
                        Spacer()
                    }

                    Spacer()

                    if currentPage < pages.count - 1 {
                        Button("Next") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPage += 1
                            }
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                        } else {
                            Button("Done") {
                                dismiss()
                            }
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(.green)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        .navigationTitle("Statistics Tutorial")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StatisticsTutorialPageView: View {
    let page: TutorialPage
    @Binding var currentPage: Int

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Icon and Title
                VStack(spacing: 20) {
                    Image(systemName: page.icon)
                        .font(.system(size: 60, weight: .medium))
                        .foregroundStyle(page.iconColor)
                        .frame(width: 100, height: 100)
                        .background(
                            Circle()
                                .fill(page.iconColor.opacity(0.1))
                        )

                    VStack(spacing: 8) {
                        Text(page.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text(page.subtitle)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }

                // Description
                Text(page.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                // Statistics Cards Example (for first page)
                if currentPage == 0 {
                    statisticsCardsExample
                }

                // Chart Example (for third page)
                if currentPage == 2 {
                    chartExample
                }

                // Benefits List
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(page.benefits, id: \.self) { benefit in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(page.iconColor)
                                .font(.system(size: 16))
                                .frame(width: 20, height: 20)

                            Text(benefit)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(page.iconColor.opacity(0.2), lineWidth: 1)
                        )
                )

                Spacer(minLength: 50)
            }
            .padding(.horizontal, 24)
        }
    }

    private var statisticsCardsExample: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCardExample(
                title: "Average Daily",
                value: "2,340 ml",
                subtitle: "per day",
                icon: "drop.fill",
                color: .blue
            )

            StatCardExample(
                title: "Average Size",
                value: "285 ml",
                subtitle: "per drink",
                icon: "cup.and.saucer.fill",
                color: .green
            )

            StatCardExample(
                title: "Total Drinks",
                value: "156",
                subtitle: "drinks",
                icon: "number",
                color: .orange
            )

            StatCardExample(
                title: "Goal Achievement",
                value: "78%",
                subtitle: "of days",
                icon: "target",
                color: .purple
            )
        }
    }

    private var chartExample: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Daily Intake Chart")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            // Mock chart
            Chart(sampleData) { data in
                BarMark(
                    x: .value("Day", data.day),
                    y: .value("Amount", data.amount)
                )
                .foregroundStyle(.blue.gradient)
                .cornerRadius(4)
            }
            .frame(height: 150)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text("\(Int(amount)) ml")
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let day = value.as(String.self) {
                            Text(day)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private let sampleData = [
        ChartDataPoint(day: "Mon", amount: 2100),
        ChartDataPoint(day: "Tue", amount: 2450),
        ChartDataPoint(day: "Wed", amount: 2200),
        ChartDataPoint(day: "Thu", amount: 2600),
        ChartDataPoint(day: "Fri", amount: 2300),
        ChartDataPoint(day: "Sat", amount: 2800),
        ChartDataPoint(day: "Sun", amount: 2400)
    ]
}

struct StatCardExample: View {
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

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let day: String
    let amount: Double
}

#Preview {
    NavigationStack {
        StatisticsTutorialView()
    }
}
