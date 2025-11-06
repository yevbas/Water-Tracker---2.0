//
//  GeneratedPlanReviewView.swift
//  PlateAI
//
//  Created by Jackson  on 21/08/2025.
//

import SwiftUI

struct GeneratedPlanReviewView: View {
    var plantPreview: PlanPreviewModel
    var onContinue: () -> Void = { }
    
    @State private var isAnimating = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 32) {
                // Header Section
                VStack(spacing: 20) {
                    // Success Icon
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.blue.opacity(0.1), .cyan.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 100, height: 100)
                            .scaleEffect(isAnimating ? 1.0 : 0.8)
                            .animation(.easeOut(duration: 0.6), value: isAnimating)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .scaleEffect(isAnimating ? 1.0 : 0.8)
                            .animation(.easeOut(duration: 0.6).delay(0.1), value: isAnimating)
                    }
                    
                    // Title
                    VStack(spacing: 8) {
                        Text("Your hydration plan is ready!")
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.primary)
                        
                        Text("We've calculated your personalized daily water goal based on your preferences")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .opacity(isAnimating ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.8).delay(0.3), value: isAnimating)
                    }
                }
                .padding(.top, 20)
                
                // Goals Card
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Daily Water Goal")
                            .font(.system(.title2, design: .rounded, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        Text("You can adjust this anytime in settings")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Water Goals Display
                    HStack(spacing: 20) {
                        WaterCircleView(
                            title: "Water",
                            emoji: "💧",
                            color: .blue,
                            value: Int(plantPreview.waterAmount.rounded()),
                            unit: plantPreview.waterUnit.shortName
                        )
                        
                        WaterCircleView(
                            title: "Cups",
                            emoji: "🥤",
                            color: .teal,
                            value: plantPreview.cups,
                            unit: "cups"
                        )
                    }
                }
                .padding(24)
                .background {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                }
                .opacity(isAnimating ? 1.0 : 0.0)
                .offset(y: isAnimating ? 0 : 20)
                .animation(.easeOut(duration: 0.8).delay(0.5), value: isAnimating)
            }
            .padding(.horizontal, 20)
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(
                title: String(localized: "Let's start!"),
                colors: [.blue, .cyan]
            ) {
                onContinue()
            }
            .padding(.horizontal, 20)
            .opacity(isAnimating ? 1.0 : 0.0)
            .offset(y: isAnimating ? 0 : 20)
            .animation(.easeOut(duration: 0.8).delay(0.7), value: isAnimating)
        }
        .onAppear {
            isAnimating = true
        }
    }

    struct WaterCircleView: View {
        var title: String
        var emoji: String
        var color: Color
        var value: Int
        var unit: String
        
        @State private var progress: Double = 0.0

        var body: some View {
            VStack(spacing: 16) {
                // Title with emoji
                HStack(spacing: 6) {
                    Text(emoji)
                        .font(.title2)
                    Text(title)
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                
                // Circular Progress
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(color.opacity(0.2), lineWidth: 8)
                        .frame(width: 100, height: 100)
                    
                    // Progress circle
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 100, height: 100)
                        .animation(.easeOut(duration: 1.2), value: progress)
                    
                    // Value text
                    VStack(spacing: 2) {
                        Text("\(value)")
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .foregroundStyle(.primary)
                        Text(unit)
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .onAppear {
                withAnimation(.easeOut(duration: 1.2).delay(0.8)) {
                    progress = 0.7 // 70% progress for visual appeal
                }
            }
        }
    }

}

#Preview {
    GeneratedPlanReviewView(
        plantPreview: .init(
            waterMl: 2600,
            waterUnit: .millilitres,
            cups: 11,
            expectedDate: Date()
        )
    )
}
