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
    var selectedUnit: WaterUnit = .millilitres

    var onSubmit: (PlanPreviewModel) -> Void = { _ in }

    @State var progress: CGFloat = 0.0

    @State var isBaseCalcCompleted: Bool = false
    @State var isActivityApplied: Bool = false
    @State var isClimateApplied: Bool = false
    @State var isGoalReady: Bool = false

    @State var isMainButtonEnabled: Bool = false

    var body:some View {
        VStack {
            if isGoalReady {
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
                    Text(isGoalReady ? "Goal is ready!" : "Creating goal...")
                        .foregroundStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation {
                                    isBaseCalcCompleted = true
                                }
                            }
                        }
                    if !isGoalReady {
                        ProgressView()
                    }
                }
                if isBaseCalcCompleted {
                    GroupBox {
                        VStack(alignment: .leading, spacing: 16) {
                            if isBaseCalcCompleted {
                                Label("Calculating base intake", systemImage: "checkmark.circle.fill")
                                    .onAppear {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                            withAnimation {
                                                isActivityApplied = true
                                            }
                                        }
                                    }
                            }
                            if isActivityApplied {
                                Label("Applying activity adjustments", systemImage: "checkmark.circle.fill")
                                    .onAppear {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                            withAnimation {
                                                isClimateApplied = true
                                            }
                                        }
                                    }
                            }
                            if isClimateApplied {
                                Label("Applying climate adjustments", systemImage: "checkmark.circle.fill")
                                    .onAppear {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                            withAnimation {
                                                isGoalReady = true
                                            }
                                        }
                                    }
                            }
                            if isGoalReady {
                                Label("Daily water goal ready", systemImage: "checkmark.circle.fill")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .offset(y: isGoalReady ? -64 : 0)
            if isGoalReady {
                Spacer()
                PrimaryButton(
                    title: String(localized: "See your goal"),
                    colors: [.blue, .cyan],
                    isDisabled: !isMainButtonEnabled
                ) {
                    print("🔍 GeneratingPlanView: Button pressed")
                    print("🔍 GeneratingPlanView: answers = \(answers)")
                    print("🔍 GeneratingPlanView: selectedUnit = \(selectedUnit)")
                    
                    if let dailyTargets = dailyWaterTargets(
                        from: answers
                    ) {
                        print("✅ GeneratingPlanView: dailyTargets created successfully = \(dailyTargets)")
                        onSubmit(dailyTargets)
                    } else {
                        print("❌ GeneratingPlanView: Failed to create dailyTargets")
                    }
                }
                .shimmer()
                .animation(.smooth, value: isMainButtonEnabled)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Convenience: Build plan directly from your UI answers

    func dailyWaterTargets(from answers: [String: MetricView.Answer]) -> PlanPreviewModel? {
        guard let m = UserMetrics(answers: answers) else { return nil }
        return WaterPlanner.plan(for: m, unit: selectedUnit)
    }

}

#Preview {
    GeneratingPlanView()
}
