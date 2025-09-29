//
//  PersonalizedOnboardingView.swift
//  PlateAI
//
//  Created by Jackson  on 21/08/2025.
//

import SwiftUI
import Lottie

struct PersonalizedOnboarding: View {
    @State var selectedMetric: MetricView.Configuration?
    @State var answers: [String: MetricView.Answer] = [:]
    @State var selectedAnswer: String?
    @State var stage = Stage.welcome

    enum Stage {
        case welcome
        case metricCollection
        case askingForReview
        case calculating
        case planPreview(PlanPreviewModel)
        case convertUser
    }

    var metrics: [MetricView.Configuration] = [
        .init(
            id: "goal",
            title: String(
                localized: "Used for individual plan"
            ),
            question: String(
                localized: "What's your goal?"
            ),
            answerType: .strings([
                .init(
                    value: Goal.lose.rawValue,
                    title: String(localized: "Lose weight")
                ),
                .init(
                    value: Goal.maintain.rawValue,
                    title: String(localized: "Maintain")
                ),
                .init(
                    value: Goal.gain.rawValue,
                    title: String(localized: "Gain weight")
                )
            ])
        ),
        .init(
            id: "activity-factor",
            title: String(
                localized: "Used for individual plan"
            ),
            question: String(
                localized: "What's your activity?"
            ),
            answerType: .strings([
                .init(
                    value: "Sedentary (little or no exercise)",
                    title: String(localized: "Sedentary (little or no exercise)")
                ),
                .init(
                    value: "Light (1–3 days/week)",
                    title: String(localized: "Light (1–3 days/week)")
                ),
                .init(
                    value: "Moderate (3–5 days/week)",
                    title: String(localized: "Moderate (3–5 days/week)")
                ),
                .init(
                    value: "Very (6–7 days/week)",
                    title: String(localized: "Very (6–7 days/week)")
                ),
                .init(
                    value: "Extra (physical job + training)",
                    title: String(localized: "Extra (physical job + training)")
                )
            ])
        ),
        .init(
            id: "gender",
            title: String(
                localized: "Used for individual plan"
            ),
            question: String(
                localized: "Gender"
            ),
            answerType: .strings([
                .init(
                    value: Gender.male.rawValue,
                    title: String(localized: "Male")
                ),
                .init(
                    value: Gender.female.rawValue,
                    title: String(localized: "Female")
                ),
                .init(
                    value: Gender.other.rawValue,
                    title: String(localized: "Other")
                )
            ])
        ),
        .init(
            id: "height",
            title: String(
                localized: "Used for individual plan"
            ),
            question: String(
                localized: "Your height (cm)?"
            ),
            answerType: .selection(
                (100..<250).map {
                    .init(
                        value: "\($0) cm",
                        title: String(localized: "\($0) cm")
                    )
                }
            )
        ),
        .init(
            id: "weight",
            title: String(
                localized: "Used for individual plan"
            ),
            question: String(
                localized: "Your weight (kg)?"
            ),
            answerType: .selection(
                (30..<250).map {
                    .init(
                        value: "\($0) kg",
                        title: String(localized: "\($0) kg")
                    )
                }
            )
        ),
        .init(
            id: "age",
            title: String(
                localized: "Used for individual plan"
            ),
            question: String(
                localized: "What's your age?"
            ),
            answerType: .selection(
                (10..<125).map {
                    .init(
                        value: "\($0) years",
                        title: String(localized: "\($0) years")
                    )
                }
            )
        ),
        .init(
            id: "expected-weight-change",
            title: String(
                localized: "Used for individual plan"
            ),
            question: String(
                localized: "Expected change per week (kg)"
            ),
            answerType: .selection(
                stride(from: 0.1, to: 1.4, by: 0.1)
                    .map {
                        .init(
                            value: "\($0.formatted(.number.precision(.fractionLength(1)))) kg",
                            title: String(localized: "\($0.formatted(.number.precision(.fractionLength(1)))) kg")
                        )
                    }
            )
        )
    ]

    var progress: Float {
        calculateProgress()
    }

    var body: some View {
        switch stage {
        case .welcome:
            WelcomeView {
                stage = .metricCollection
            }
        case .metricCollection:
            metricsCollectingView
        case .calculating:
            GeneratingPlanView(
                answers: answers
            ) { newPlan in
                stage = .planPreview(newPlan)
            }
        case .planPreview(let plantPreview):
            PlanReviewView(
                plantPreview: plantPreview
            ) {
                stage = .convertUser
            }
        case .askingForReview:
            RateUsView {
                stage = .calculating
            }
        case .convertUser:
            ConvertUserView()
        }
    }

    var calculatingView: some View {
        VStack {
            LottieView(
                animation: .named("liquid-loader")
            )
            .looping()
        }
    }

    var metricsCollectingView: some View {
        VStack {
            HStack(spacing: 16) {
                Button {
                    previousMetric()
                } label: {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title)
                        .foregroundStyle(.secondary)
                        .tint(.gray)
                }
                .disabled(progress == 0.0)

                ProgressView(value: progress)
                    .tint(.black)
                    .progressViewStyle(.linear)
//                    .animation(.linear, value: selectedMetric)
            }
            .padding()
            if let selectedMetric {
                MetricView(
                    selectedAnswer: answers[selectedMetric.id],
                    configuration: selectedMetric
                ) { submittedAnswer in

                    answers.updateValue(
                        submittedAnswer!,
                        forKey: selectedMetric.id
                    )

                    nextMetric()
                }
                .id(selectedMetric.id)
            }
        }
        .onAppear {
            selectedMetric = metrics.first

            // default values
            answers = [
                "height": .init(value: "170 cm", title: String(localized: "\(170) cm")),
                "weight": .init(value: "70 kg", title: String(localized: "\(70) kg")),
                "age": .init(value: "25 years", title: String(localized: "\(25) years")),
                "expected-weight-change": .init(value: "0,1 kg", title: String(localized: "\(0.1) kg")),
            ]
        }
    }

    func nextMetric() {
        guard let selectedMetric,
              let index = metrics.firstIndex(of: selectedMetric) else {
            return
        }
        guard let nextMetric = metrics[safe: Int(index) + 1] else {
            stage = .askingForReview
            return
        }
        self.selectedMetric = nextMetric
    }

    func previousMetric() {
        guard let selectedMetric,
              let index = metrics.firstIndex(of: selectedMetric) else {
            return
        }

        self.selectedMetric = metrics[safe: Int(index) - 1]
    }

    func calculateProgress() -> Float {
        guard let selectedMetric,
              let index = metrics.firstIndex(of: selectedMetric) else {
            return 0.0
        }
        return Float(index) / Float(metrics.count)
    }

}

#Preview {
    PersonalizedOnboarding()
}

extension Array {
    public subscript(safe index: Int) -> Element? {
        guard index >= 0 && index < count else {
            return nil
        }
        return self[index]
    }
}
