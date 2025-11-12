//
//  TutorialSettingsCard.swift
//  WaterTracker
//
//  Created by Assistant on 02/10/2025.
//

import SwiftUI

struct TutorialSettingsCard: View {
    
    var body: some View {
        VStack(spacing: 16) {
            tutorialCardHeader
            
            VStack(spacing: 12) {
                NavigationLink(destination: HealthKitTutorialView()) {
                    TutorialButtonContent(
                        title: String(localized: "HealthKit Integration"),
                        subtitle: String(localized: "Sync health data & personalize goals"),
                        icon: "heart.fill",
                        iconColor: .red
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink(destination: WeatherTutorialView()) {
                    TutorialButtonContent(
                        title: String(localized: "Weather Analysis"),
                        subtitle: String(localized: "Smart hydration based on conditions"),
                        icon: "cloud.sun.fill",
                        iconColor: .blue
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink(destination: SleepTutorialView()) {
                    TutorialButtonContent(
                        title: String(localized: "Sleep Insights"),
                        subtitle: String(localized: "Optimize hydration for better sleep"),
                        icon: "moon.fill",
                        iconColor: .cyan
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink(destination: StatisticsTutorialView()) {
                    TutorialButtonContent(
                        title: String(localized: "Statistics & Analytics"),
                        subtitle: String(localized: "Track progress with detailed charts"),
                        icon: "chart.bar.fill",
                        iconColor: .green
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [.indigo.opacity(0.3), .purple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .indigo.opacity(0.15), radius: 15, x: 0, y: 8)
        )
    }
    
    private var tutorialCardHeader: some View {
        HStack {
            Image(systemName: "graduationcap.fill")
                .foregroundStyle(.white)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(
                    LinearGradient(
                        colors: [.indigo, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text("App Tutorial")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                Text("Learn to use WaterTracker features")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(.indigo)
                .font(.title3)
                .symbolEffect(.pulse)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
}

struct TutorialButtonContent: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(.white)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(iconColor)
                )
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
                .font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.secondary.opacity(0.1), lineWidth: 0.5)
                )
        )
    }
}

#Preview {
    NavigationStack {
        TutorialSettingsCard()
            .padding()
    }
}
