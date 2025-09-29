//
//  GeneratingPlanView.swift
//  PlateAI
//
//  Created by Jackson  on 21/08/2025.
//

import SwiftUI
import Lottie

struct GeneratingPlanView: View {

    var answers: [String: MetricView.Answer] = [:]

    var onSubmit: (PlanPreviewModel) -> Void = { _ in }

    @State var progress: CGFloat = 0.0

    @State var isBMRAnalysisCompleted: Bool = false
    @State var isProteinsCalculated: Bool = false
    @State var isCarbohydratesCalculated: Bool = false
    @State var isFatsCalculated: Bool = false

    @State var isMainButtonEnabled: Bool = false

    var body:some View {
        VStack {
            if isFatsCalculated {
                LottieView(animation: .named("succeess"))
                    .playing(.fromProgress(0.0, toProgress: 1.0, loopMode: .playOnce))
                    .animationSpeed(2)
                    .animationDidFinish({ _ in
                        isMainButtonEnabled = true
                    })
                    .frame(height: 400)
            }
            VStack {
                HStack {
                    Text(isFatsCalculated ? "Plan is ready!" : "Creating plan...")
                        .foregroundStyle(LinearGradient(colors: [.yellow, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation {
                                    isBMRAnalysisCompleted = true
                                }
                            }
                        }
                    if !isFatsCalculated {
                        ProgressView()
                    }
                }
                if isBMRAnalysisCompleted {
                    GroupBox {
                        VStack(alignment: .leading, spacing: 16) {
                            if isBMRAnalysisCompleted {
                                Label("Applying BMR analysis", systemImage: "checkmark.circle.fill")
                                    .onAppear {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                            withAnimation {
                                                isProteinsCalculated = true
                                            }
                                        }
                                    }
                            }
                            if isProteinsCalculated {
                                Label("Completed Protein Analysis", systemImage: "checkmark.circle.fill")
                                    .onAppear {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                            withAnimation {
                                                isCarbohydratesCalculated = true
                                            }
                                        }
                                    }
                            }
                            if isCarbohydratesCalculated {
                                Label("Completed Carbohydrate Analysis", systemImage: "checkmark.circle.fill")
                                    .onAppear {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                            withAnimation {
                                                isFatsCalculated = true
                                            }
                                        }
                                    }
                            }
                            if isFatsCalculated {
                                Label("Completed Fat Analysis", systemImage: "checkmark.circle.fill")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .offset(y: isFatsCalculated ? -64 : 0)
            if isFatsCalculated {
                Spacer()
                PrimaryButton(
                    title: String(localized: "Check out your plan"),
                    colors: [.yellow, .pink],
                    isDisabled: !isMainButtonEnabled
                ) {
                    if let dailyTargets = dailyNutritionTargets(
                        from: answers
                    ) {
                        onSubmit(dailyTargets)
                    }
                }
                .shimmer()
                .animation(.smooth, value: isMainButtonEnabled)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Convenience: Build plan directly from your UI answers

    func dailyNutritionTargets(from answers: [String: MetricView.Answer]) -> PlanPreviewModel? {
        guard let m = UserMetrics(answers: answers) else { return nil }
        return NutritionPlanner.plan(for: m)
    }

}

#Preview {
    GeneratingPlanView()
}
