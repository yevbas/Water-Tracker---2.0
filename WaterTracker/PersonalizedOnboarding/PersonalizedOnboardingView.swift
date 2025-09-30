//
//  PersonalizedOnboardingView.swift
//  PlateAI
//
//  Created by Jackson  on 21/08/2025.
//

import SwiftUI
import SwiftData
import Lottie
import HealthKit

struct PersonalizedOnboarding: View {
    @Environment(\.modelContext) private var modelContext
    @State var selectedMetric: MetricView.Configuration?
    @State var answers: [String: MetricView.Answer] = [:]
    @State var selectedAnswer: String?
    @State var selectedUnit: WaterUnit = .millilitres
    @State var planPreview: PlanPreviewModel?
    @State var stage = Stage.welcome
    @EnvironmentObject private var healthKitService: HealthKitService
    @State private var hasHealthKitData = false
    
    // HealthKit data properties
    @State private var userHeight: Double?
    @State private var userWeight: Double?
    @State private var userAge: Int?
    @State private var userGender: HKBiologicalSex?
    @State private var averageSleepHours: Double?

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
            HealthKitDataConfirmationView(
                onContinue: {
                    // User confirmed their health data - proceed to metric collection for review/modification
                    stage = .metricCollection
                },
                userHeight: userHeight,
                userWeight: userWeight,
                userAge: userAge,
                userGender: userGender,
                averageSleepHours: averageSleepHours
            )
        case .metricCollection:
            metricsCollectingView
        case .calculating:
            GeneratingPlanView(
                answers: answers,
                selectedUnit: selectedUnit
            ) { newPlan in
                print("🔍 PersonalizedOnboardingView: onSubmit called with newPlan = \(newPlan)")
                print("🔍 PersonalizedOnboardingView: Current stage = \(stage)")
                stage = .planPreview(newPlan)
                print("🔍 PersonalizedOnboardingView: New stage = \(stage)")
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
        // Start fetching HealthKit data directly from the view
        fetchHealthKitData()
        
        // Wait a moment for HealthKit data to be fetched
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
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
        return userHeight != nil &&
               userWeight != nil &&
               userAge != nil &&
               userGender != nil
    }
    
    private func populateAnswersWithHealthKitData() {
        var defaultAnswers: [String: MetricView.Answer] = [
            "climate": .init(value: "temperate", title: String(localized: "Temperate")),
        ]
        
        // Use HealthKit data if available, otherwise use defaults
        if let height = userHeight {
            let heightCm = Int(height * 100) // Convert meters to cm
            defaultAnswers["height"] = .init(
                value: "\(heightCm) cm",
                title: String(localized: "\(heightCm) cm")
            )
        } else {
            defaultAnswers["height"] = .init(value: "170 cm", title: String(localized: "\(170) cm"))
        }
        
        if let weight = userWeight {
            let weightKg = Int(weight) // Weight is already in kg
            defaultAnswers["weight"] = .init(
                value: "\(weightKg) kg",
                title: String(localized: "\(weightKg) kg")
            )
        } else {
            defaultAnswers["weight"] = .init(value: "70 kg", title: String(localized: "\(70) kg"))
        }
        
        if let age = userAge {
            defaultAnswers["age"] = .init(
                value: "\(age) years",
                title: String(localized: "\(age) years")
            )
        } else {
            defaultAnswers["age"] = .init(value: "25 years", title: String(localized: "\(25) years"))
        }
        
        if let gender = userGender {
            let genderString = gender.stringValue
            let genderTitle = genderString.capitalized
            
            // Only populate if the gender value is one of the expected values (exclude "notSet")
            if genderString == "male" || genderString == "female" || genderString == "other" {
                defaultAnswers["gender"] = .init(
                    value: genderString,
                    title: genderTitle
                )
            }
        }
        // Don't set default gender - let user select it
        
        answers = defaultAnswers
    }
    
    // MARK: - HealthKit Data Fetching
    
    private func fetchHealthKitData() {
        print("🚀 Starting HealthKit data fetch from view...")
        fetchUserHeight()
        fetchUserWeight()
        fetchUserAge()
        fetchUserGender()
        fetchRecentSleepData()
    }
    
    private func fetchUserHeight() {
        guard let heightType = HKQuantityType.quantityType(forIdentifier: .height) else { 
            print("❌ Height type not available")
            return 
        }
        
        print("🔍 Fetching height data...")
        let query = HKSampleQuery(
            sampleType: heightType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
        ) { _, samples, error in
            if let error = error {
                print("❌ Error fetching height: \(error)")
                return
            }
            
            guard let sample = samples?.first as? HKQuantitySample else { 
                print("❌ No height samples found")
                return 
            }
            
            let heightInMeters = sample.quantity.doubleValue(for: HKUnit.meter())
            print("✅ Height fetched: \(heightInMeters) meters")
            
            DispatchQueue.main.async {
                self.userHeight = heightInMeters
                self.saveHealthDataIfReady()
            }
        }
        
        healthKitService.healthStore.execute(query)
    }
    
    private func fetchUserWeight() {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { 
            print("❌ Weight type not available")
            return 
        }
        
        print("🔍 Fetching weight data...")
        let query = HKSampleQuery(
            sampleType: weightType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
        ) { _, samples, error in
            if let error = error {
                print("❌ Error fetching weight: \(error)")
                return
            }
            
            guard let sample = samples?.first as? HKQuantitySample else { 
                print("❌ No weight samples found")
                return 
            }
            
            let weightInKg = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
            print("✅ Weight fetched: \(weightInKg) kg")
            
            DispatchQueue.main.async {
                self.userWeight = weightInKg
                self.saveHealthDataIfReady()
            }
        }
        
        healthKitService.healthStore.execute(query)
    }
    
    private func fetchUserAge() {
        do {
            let dateOfBirthComponents = try healthKitService.healthStore.dateOfBirthComponents()
            let calendar = Calendar.current
            let now = Date()
            
            // Convert DateComponents to Date
            if let dateOfBirth = calendar.date(from: dateOfBirthComponents) {
                let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: now)
                if let age = ageComponents.year {
                    print("✅ Age fetched: \(age) years")
                    DispatchQueue.main.async {
                        self.userAge = age
                        self.saveHealthDataIfReady()
                    }
                }
            }
        } catch {
            print("❌ Error fetching age: \(error)")
        }
    }
    
    private func fetchUserGender() {
        do {
            let biologicalSex = try healthKitService.healthStore.biologicalSex()
            print("✅ Gender fetched: \(biologicalSex.biologicalSex.stringValue)")
            DispatchQueue.main.async {
                self.userGender = biologicalSex.biologicalSex
                self.saveHealthDataIfReady()
            }
        } catch {
            print("❌ Error fetching gender: \(error)")
        }
    }
    
    private func fetchRecentSleepData() {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            print("❌ Sleep type not available")
            return
        }
        
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKSampleQuery(
            sampleType: sleepType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
        ) { _, samples, error in
            if let error = error {
                print("❌ Error fetching sleep data: \(error)")
                return
            }
            
            guard let samples = samples else {
                print("❌ No sleep samples found")
                return
            }
            
            let sleepHours = self.calculateAverageSleepHours(from: samples)
            print("✅ Sleep data fetched: \(sleepHours) hours average")
            
            DispatchQueue.main.async {
                self.averageSleepHours = sleepHours
                self.saveHealthDataIfReady()
            }
        }
        
        healthKitService.healthStore.execute(query)
    }
    
    private func calculateAverageSleepHours(from samples: [HKSample]) -> Double {
        var totalSleepHours: Double = 0
        var sleepDays: Int = 0
        
        for sample in samples {
            if let sleepSample = sample as? HKCategorySample,
               sleepSample.value == HKCategoryValueSleepAnalysis.inBed.rawValue {
                let duration = sample.endDate.timeIntervalSince(sample.startDate)
                let hours = duration / 3600
                totalSleepHours += hours
                sleepDays += 1
            }
        }
        
        return sleepDays > 0 ? totalSleepHours / Double(sleepDays) : 0
    }
    
    private func saveHealthDataIfReady() {
        guard userHeight != nil && userWeight != nil else {
            print("📱 Waiting for essential data (height: \(userHeight != nil), weight: \(userWeight != nil))")
            return
        }
        
        print("📱 Essential data available, saving to SwiftData...")
        saveHealthDataToSwiftData()
    }
    
    private func saveHealthDataToSwiftData() {
        print("📱 Saving health data to SwiftData from view...")
        print("📱 Current data - height: \(userHeight ?? 0), weight: \(userWeight ?? 0), age: \(userAge ?? 0)")
        
        let averageSleepHours = self.averageSleepHours ?? 0
        
        let newProfile = UserHealthProfile(
            height: userHeight,
            weight: userWeight,
            age: userAge,
            gender: userGender?.stringValue,
            isHealthKitEnabled: true,
            averageSleepHours: averageSleepHours
        )
        
        modelContext.insert(newProfile)
        
        do {
            try modelContext.save()
            print("✅ Health data saved to SwiftData with HealthKit enabled")
            
            // Verify the profile was saved
            let descriptor = FetchDescriptor<UserHealthProfile>()
            let profiles = try modelContext.fetch(descriptor)
            print("📱 Verification: Found \(profiles.count) profiles after save")
            if let savedProfile = profiles.first {
                print("📱 Saved profile - enabled: \(savedProfile.isHealthKitEnabled), height: \(savedProfile.height ?? 0)")
            }
        } catch {
            print("❌ Error saving health data to SwiftData: \(error)")
        }
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
