//
//  SleepTutorialView.swift
//  WaterTracker
//
//  Created by Assistant on 02/10/2025.
//

import SwiftUI

struct SleepTutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0

    private let pages = [
        TutorialPage(
            title: "Sleep & Hydration Analysis",
            subtitle: "Optimize Your Rest Quality",
            description: "The Sleep card analyzes how your hydration patterns affect sleep quality and provides recommendations to improve both your water intake timing and sleep.",
            icon: "moon.stars.fill",
            iconColor: .cyan,
            benefits: [
                "Track sleep duration and quality from HealthKit",
                "Analyze hydration timing impact on sleep",
                "Get personalized bedtime hydration advice",
                "Reduce nighttime awakenings from overhydration"
            ]
        ),
        TutorialPage(
            title: "The Science of Sleep Hydration",
            subtitle: "Research-Based Insights",
            description: "Scientific research shows that hydration timing significantly affects sleep quality. Drinking too much before bed can disrupt sleep, while dehydration can cause early awakening.",
            icon: "brain.head.profile",
            iconColor: .purple,
            benefits: [
                "Evening intake >25% of daily total disrupts sleep",
                "Dehydration reduces sleep duration by 15-20%",
                "Optimal timing: 80% before 6 PM, 20% after",
                "Caffeine after 3 PM doubles sleep disruption risk"
            ]
        ),
        TutorialPage(
            title: "Sleep Card Features",
            subtitle: "Comprehensive Analysis",
            description: "The sleep card shows your sleep duration, quality score, and detailed hydration impact analysis with personalized recommendations.",
            icon: "chart.bar.fill",
            iconColor: .green,
            benefits: [
                "Sleep duration and quality percentage",
                "Evening hydration percentage analysis",
                "Nocturia (nighttime awakening) risk assessment",
                "AI-powered insights and recommendations"
            ]
        ),
        TutorialPage(
            title: "Improving Sleep Through Hydration",
            subtitle: "Actionable Recommendations",
            description: "Follow the sleep card's recommendations to optimize your hydration timing for better sleep quality and fewer nighttime disruptions.",
            icon: "target",
            iconColor: .orange,
            benefits: [
                "Shift more hydration to morning and afternoon",
                "Limit evening intake to <200ml 2-3 hours before bed",
                "Avoid caffeine after 3 PM for better sleep",
                "Track patterns over 21+ days for best insights"
            ]
        )
    ]

    var body: some View {
        VStack(spacing: 0) {

            // Page Content
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    SleepTutorialPageView(page: pages[index], currentPage: $currentPage)
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
                            .fill(index == currentPage ? .cyan : .gray.opacity(0.3))
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
                        .foregroundStyle(.cyan)
                        } else {
                            Button("Done") {
                                dismiss()
                            }
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(.cyan)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        .navigationTitle("Sleep Tutorial")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SleepTutorialPageView: View {
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

                // Sleep Card Example (for first page)
                if currentPage == 0 {
                    sleepCardExample
                }

                // Hydration Impact Example (for third page)
                if currentPage == 2 {
                    hydrationImpactExample
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

    private var sleepCardExample: some View {
        VStack(spacing: 0) {
            // Mock sleep card header
            HStack(spacing: 12) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.cyan)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Sleep")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text("Time Asleep")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.gray)
            }
            .padding(16)

            // Sleep duration display
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .bottom) {
                    HStack(alignment: .bottom, spacing: 2) {
                        Text("7")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(.primary)
                        Text("hr")
                            .font(.system(size: 16))
                            .foregroundStyle(.primary)
                            .padding(.bottom, 4)
                        Text("23")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(.primary)
                        Text("min")
                            .font(.system(size: 16))
                            .foregroundStyle(.primary)
                            .padding(.bottom, 4)
                    }

                    Spacer()

                    RoundedRectangle(cornerRadius: 2)
                        .fill(.cyan)
                        .frame(width: 60, height: 4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.cyan.opacity(0.2), lineWidth: 1)
        )
    }

    private var hydrationImpactExample: some View {
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
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)

                    Text("Good")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(.green.opacity(0.1))
                        .overlay(
                            Capsule()
                                .stroke(.green.opacity(0.3), lineWidth: 0.5)
                        )
                )
            }

            // Quick snapshot metrics
            HStack(spacing: 8) {
                metricItemExample(
                    label: "Evening Intake",
                    value: "18%",
                    color: .green,
                    icon: "moon.circle.fill"
                )

                metricItemExample(
                    label: "Daily Hydration",
                    value: "87%",
                    color: .green,
                    icon: "drop.circle.fill"
                )

                metricItemExample(
                    label: "Sleep Risk",
                    value: "Low",
                    color: .green,
                    icon: "bed.double.circle.fill"
                )
            }

            // Impact insights
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)

                    Text("Great hydration timing! Your steady intake throughout the day supports better sleep quality.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, 4)
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

    private func metricItemExample(label: String, value: String, color: Color, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.1))
        )
    }
}

#Preview {
    SleepTutorialView()
}
