//
//  PlanReviewView.swift
//  PlateAI
//
//  Created by Jackson  on 21/08/2025.
//

import SwiftUI

struct PlanReviewView: View {
    var plantPreview: PlanPreviewModel

    var onContinue: () -> Void = { }

    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 52, weight: .bold))
                        .foregroundStyle(LinearGradient(colors: [.yellow, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                    if #available(iOS 17.0, *) {
                        (Text("Congratulations, ") + Text("your individual plan is ready!").foregroundStyle(LinearGradient(colors: [.yellow, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)))
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                    } else {
                        Text("Congratulations, your individual plan is ready!")
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                    }
                }
                Text("You will achieve your goal about at \(plantPreview.expectedDate.formatted(date: .long, time: .omitted))")
                    .font(.title3.weight(.medium))
                GroupBox {
                    VStack(alignment: .leading) {
                        Group {
                            Text("Recommendations per day")
                                .font(.headline)
                            Text("You can modify it any time")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        LazyVGrid(columns: [.init(), .init()]) {
                            NutrientCircleView(
                                title:  "🔥" + String(localized: "Calories"),
                                color: .blue,
                                value: plantPreview.calories
                            )
                            NutrientCircleView(
                                title: "🥩" + String(localized: "Proteins"),
                                color: .green,
                                value: plantPreview.proteinG
                            )
                            NutrientCircleView(
                                title: "🥖" + String(localized: "Carbs"),
                                color: .orange,
                                value: plantPreview.carbsG
                            )
                            NutrientCircleView(
                                title: "🥑" + String(localized: "Fats"),
                                color: .red,
                                value: plantPreview.fatG
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(
                title: String(localized: "Let's start!"),
                colors: [.yellow, .pink]
            ) {
//                UserDefaults.standard.dailyCaloriesGoal = Double(plantPreview.calories)
//                UserDefaults.standard.dailyProteinsGoal = Double(plantPreview.proteinG)
//                UserDefaults.standard.dailyFatsGoal = Double(plantPreview.fatG)
//                UserDefaults.standard.dailyCarbsGoal = Double(plantPreview.carbsG)
                onContinue()
            }
            .padding(.horizontal, 16)
            .shimmer()
        }
    }

    struct NutrientCircleView: View {
        var title: String
        var color: Color
        var value: Int

        var body: some View {
            GroupBox {
                VStack {
                    Text(title)
                        .font(.headline)
                    ZStack {
                        Text("\(value)g")
                        Circle()
                            .stroke(lineWidth: 6)
                            .rotation(.degrees(-90))
                            .frame(minHeight: 84)
                            .foregroundStyle(.ultraThinMaterial)
                        Circle()
                            .trim(from: 0.0, to: 0.5)
                            .stroke(lineWidth: 6)
                            .rotation(.degrees(-90))
                            .frame(minHeight: 84)
                            .foregroundStyle(color)
                    }
                }
            }
        }
    }

}

#Preview {
    PlanReviewView(
        plantPreview: .init(
            calories: 1700,
            proteinG: 120,
            fatG: 40,
            carbsG: 240,
            expectedDate: Date()
        )
    )
}
