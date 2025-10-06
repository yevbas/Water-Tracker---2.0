//
//  WeatherTutorialView.swift
//  WaterTracker
//
//  Created by Assistant on 02/10/2025.
//

import SwiftUI

struct WeatherTutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0

    private let pages = [
        TutorialPage(
            title: String(localized: "Smart Weather Analysis"),
            subtitle: String(localized: "Hydration Based on Conditions"),
            description: String(localized: "The Weather card automatically adjusts your hydration recommendations based on current weather conditions, temperature, humidity, and UV index."),
            icon: "cloud.sun.fill",
            iconColor: .blue,
            benefits: [
                String(localized: "Real-time weather data from your location"),
                String(localized: "Temperature-based hydration adjustments"),
                String(localized: "Humidity and UV index considerations"),
                String(localized: "AI-powered personalized recommendations")
            ]
        ),
        TutorialPage(
            title: String(localized: "How Weather Affects Hydration"),
            subtitle: String(localized: "Science Behind the Recommendations"),
            description: String(localized: "Your body loses more water in hot, humid, or sunny conditions. Our algorithm calculates additional water needs based on environmental factors."),
            icon: "thermometer.sun.fill",
            iconColor: .orange,
            benefits: [
                String(localized: "Hot weather increases sweat and water loss"),
                String(localized: "High humidity makes cooling less efficient"),
                String(localized: "UV exposure accelerates dehydration"),
                String(localized: "Wind and dry air increase fluid needs")
            ]
        ),
        TutorialPage(
            title: String(localized: "Weather Card Features"),
            subtitle: String(localized: "What You'll See"),
            description: String(localized: "The weather card shows current conditions, temperature, and provides specific hydration recommendations with AI-generated insights."),
            icon: "sparkles",
            iconColor: .purple,
            benefits: [
                String(localized: "Current temperature and weather condition"),
                String(localized: "Humidity percentage and UV index"),
                String(localized: "Additional water intake recommendations"),
                String(localized: "AI insights explaining the reasoning")
            ]
        ),
        TutorialPage(
            title: String(localized: "Using Weather Insights"),
            subtitle: String(localized: "Make Informed Decisions"),
            description: String(localized: "Tap the weather card to expand and see detailed analysis. Use the refresh button to get updated conditions and recommendations."),
            icon: "lightbulb.fill",
            iconColor: .yellow,
            benefits: [
                String(localized: "Tap the card to expand for full details"),
                String(localized: "Refresh for updated weather conditions"),
                String(localized: "Follow AI recommendations for optimal hydration"),
                String(localized: "Adjust your daily routine based on weather")
            ]
        )
    ]

    var body: some View {
        VStack(spacing: 0) {

            // Page Content
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    WeatherTutorialPageView(page: pages[index])
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
                            .fill(index == currentPage ? .blue : .gray.opacity(0.3))
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
                        .foregroundStyle(.blue)
                        } else {
                            Button("Done") {
                                dismiss()
                            }
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        .navigationTitle("Weather Tutorial")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WeatherTutorialPageView: View {
    let page: TutorialPage

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

                // Weather Card Example (for first page)
                if currentPage == 0 {
                    weatherCardExample
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

    @State private var currentPage = 0

    private var weatherCardExample: some View {
        VStack(spacing: 0) {
            // Mock weather card header
            HStack(spacing: 12) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Weather")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text("28°C • Clear")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.gray)
            }
            .padding(16)

            // Mock expanded content
            VStack(spacing: 16) {
                Divider()

                // Mock weather stats
                HStack(spacing: 12) {
                    weatherStatExample(
                        icon: "thermometer",
                        label: String(localized: "High"),
                        value: "32°C"
                    )
                    weatherStatExample(
                        icon: "drop.fill",
                        label: String(localized: "Humidity"),
                        value: "65%"
                    )
                    weatherStatExample(
                        icon: "sun.max.fill",
                        label: String(localized: "UV Index"),
                        value: "8"
                    )
                }

                // Mock recommendation
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.orange)

                        Text("Recommendation")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("Drink extra")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("500 ml")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.orange)

                        Text("today")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.ultraThinMaterial)
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.blue.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func weatherStatExample(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.blue)

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
}

#Preview {
    WeatherTutorialView()
}
