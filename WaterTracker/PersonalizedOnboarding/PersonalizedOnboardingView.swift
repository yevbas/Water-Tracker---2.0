//
//  PersonalizedOnboardingView.swift
//  PlateAI
//
//  Created by Jackson  on 21/08/2025.
//

import SwiftUI
import SwiftData
import Lottie

struct PersonalizedOnboarding: View {
    @Environment(\.modelContext) private var modelContext
    @State var selectedMetric: MetricView.Configuration?
    @State var answers: [String: MetricView.Answer] = [:]
    @State var selectedAnswer: String?
    @State var selectedUnit: WaterUnit = .millilitres
    @State var planPreview: PlanPreviewModel?
    @State var stage = Stage.welcome
    @StateObject private var healthKitService = HealthKitService.shared
    @State private var hasHealthKitData = false

    enum Stage {
        case welcome
        case unitSelection
        case healthKitPermission
        case healthKitDataConfirmation
        case metricCollection
        case askingForReview
        case calculating
        case planPreview(PlanPreviewModel)
        case convertUser
    }

    var metrics: [MetricView.Configuration] = [
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
            id: "climate",
            title: String(
                localized: "Used for individual plan"
            ),
            question: String(
                localized: "Your climate?"
            ),
            answerType: .strings([
                .init(value: "cool", title: String(localized: "Cool")),
                .init(value: "temperate", title: String(localized: "Temperate")),
                .init(value: "hot", title: String(localized: "Hot"))
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
        )
    ]

    var progress: Float {
        calculateProgress()
    }

    var body: some View {
        switch stage {
        case .welcome:
            WelcomeView {
                stage = .unitSelection
            }
        case .unitSelection:
            UnitSelectionView { unit in
                selectedUnit = unit
                // Save the selected unit to UserDefaults
                UserDefaults.standard.set(unit == .ounces ? "fl_oz" : "ml", forKey: "measurement_units")
                stage = .healthKitPermission
            }
        case .healthKitPermission:
            HealthKitPermissionView {
                // Permission granted - check if we have data and proceed accordingly
                checkHealthKitDataAndProceed()
            } onPermissionDenied: {
                // Permission denied - proceed to metric collection anyway
                stage = .metricCollection
            }
        case .healthKitDataConfirmation:
            HealthKitDataConfirmationView {
                // User confirmed their health data - proceed to metric collection for review/modification
                stage = .metricCollection
            }
        case .metricCollection:
            metricsCollectingView
        case .calculating:
            GeneratingPlanView(
                answers: answers,
                selectedUnit: selectedUnit
            ) { newPlan in
                stage = .planPreview(newPlan)
            }
        case .planPreview(let plantPreview):
            GeneratedPlanReviewView(
                plantPreview: plantPreview
            ) {
                planPreview = plantPreview
                stage = .convertUser
            }
        case .askingForReview:
            RateUsView {
                stage = .calculating
            }
        case .convertUser:
            ConvertUserView(planPreview: planPreview)
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
            // Show HealthKit data notice if applicable
            if hasHealthKitData {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.blue)
                    Text("Your health data from Health app has been pre-filled. You can modify any values below.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            
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
                    .tint(.blue)
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
            healthKitService.setModelContextForOnboarding(modelContext)
            populateAnswersWithHealthKitData()
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
    
    // MARK: - HealthKit Integration
    
    private func checkHealthKitDataAndProceed() {
        // Wait a moment for HealthKit data to be fetched
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if hasCompleteHealthKitData() {
                hasHealthKitData = true
                populateAnswersWithHealthKitData()
                // Show confirmation screen with the retrieved data, then proceed to metric collection
                stage = .healthKitDataConfirmation
            } else {
                // Not enough data, proceed with manual collection
                stage = .metricCollection
            }
        }
    }
    
    private func hasCompleteHealthKitData() -> Bool {
        return healthKitService.userHeight != nil &&
               healthKitService.userWeight != nil &&
               healthKitService.userAge != nil &&
               healthKitService.userGender != nil
    }
    
    private func populateAnswersWithHealthKitData() {
        var defaultAnswers: [String: MetricView.Answer] = [
            "climate": .init(value: "temperate", title: String(localized: "Temperate")),
        ]
        
        // Use HealthKit data if available, otherwise use defaults
        if let height = healthKitService.userHeight {
            let heightCm = Int(height * 100) // Convert meters to cm
            defaultAnswers["height"] = .init(
                value: "\(heightCm) cm",
                title: String(localized: "\(heightCm) cm")
            )
        } else {
            defaultAnswers["height"] = .init(value: "170 cm", title: String(localized: "\(170) cm"))
        }
        
        if let weight = healthKitService.userWeight {
            let weightKg = Int(weight) // Weight is already in kg
            defaultAnswers["weight"] = .init(
                value: "\(weightKg) kg",
                title: String(localized: "\(weightKg) kg")
            )
        } else {
            defaultAnswers["weight"] = .init(value: "70 kg", title: String(localized: "\(70) kg"))
        }
        
        if let age = healthKitService.userAge {
            defaultAnswers["age"] = .init(
                value: "\(age) years",
                title: String(localized: "\(age) years")
            )
        } else {
            defaultAnswers["age"] = .init(value: "25 years", title: String(localized: "\(25) years"))
        }
        
        if let gender = healthKitService.userGender {
            let genderString = gender.stringValue
            let genderTitle = genderString.capitalized
            defaultAnswers["gender"] = .init(
                value: genderString,
                title: genderTitle
            )
        } else {
            defaultAnswers["gender"] = .init(value: "other", title: String(localized: "Other"))
        }
        
        answers = defaultAnswers
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
