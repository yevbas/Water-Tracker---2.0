//
//  HealthKitService.swift
//  WaterTracker
//
//  Created by Assistant on 29/09/2025.
//

import Foundation
import HealthKit
import SwiftData

class HealthKitService: ObservableObject {
    static let shared = HealthKitService()
    
    private let healthStore = HKHealthStore()
    private var modelContext: ModelContext?
    
    // Health data that we'll prefetch
    @Published var userHeight: Double?
    @Published var userWeight: Double?
    @Published var userAge: Int?
    @Published var userGender: HKBiologicalSex?
    @Published var recentActivityData: [HKQuantitySample] = []
    @Published var recentSleepData: [HKCategorySample] = []
    @Published var userHealthProfile: UserHealthProfile?
    
    private init() {}
    
    // MARK: - Model Context Setup
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadUserHealthProfile()
    }
    
    func setModelContextForOnboarding(_ context: ModelContext) {
        self.modelContext = context
        // Don't load existing profile during onboarding - we'll create a new one
    }
    
    private func loadUserHealthProfile() {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<UserHealthProfile>()
        do {
            let profiles = try modelContext.fetch(descriptor)
            if let profile = profiles.first {
                self.userHealthProfile = profile
                // Update published properties from stored data
                self.userHeight = profile.height
                self.userWeight = profile.weight
                self.userAge = profile.age
                self.userGender = profile.genderEnum
            } else {
                // Create new profile if none exists
                let newProfile = UserHealthProfile()
                self.userHealthProfile = newProfile
                modelContext.insert(newProfile)
                try? modelContext.save()
            }
        } catch {
            print("Error loading user health profile: \(error)")
        }
    }
    
    // MARK: - Permission Request
    
    func requestPermission(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, HealthKitError.healthDataNotAvailable)
            return
        }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .height)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!,
            HKObjectType.characteristicType(forIdentifier: .biologicalSex)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, error in
            if success {
                // Prefetch user data after permission is granted
                self?.prefetchUserData()
                
                // Wait for data to be fetched before calling completion
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    completion(success, error)
                }
            } else {
                completion(success, error)
            }
        }
    }
    
    // MARK: - Data Prefetching
    
    private func prefetchUserData() {
        print("🚀 Starting HealthKit data prefetch...")
        fetchUserHeight()
        fetchUserWeight()
        fetchUserAge()
        fetchUserGender()
        fetchRecentActivityData()
        fetchRecentSleepData()
        
        // Save data to SwiftData after a delay to allow all data to be fetched
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.saveHealthDataToSwiftData()
        }
    }
    
    private func saveHealthDataToSwiftData() {
        guard let modelContext = modelContext else { return }
        
        let averageSleepHours = getAverageSleepHours()
        
        if let profile = userHealthProfile {
            profile.updateFromHealthKit(
                height: userHeight,
                weight: userWeight,
                age: userAge,
                gender: userGender,
                averageSleepHours: averageSleepHours
            )
            profile.enableHealthKit()
        } else {
            let newProfile = UserHealthProfile(
                height: userHeight,
                weight: userWeight,
                age: userAge,
                gender: userGender?.stringValue,
                isHealthKitEnabled: true,
                averageSleepHours: averageSleepHours
            )
            userHealthProfile = newProfile
            modelContext.insert(newProfile)
        }
        
        do {
            try modelContext.save()
            print("✅ Health data saved to SwiftData")
        } catch {
            print("❌ Error saving health data to SwiftData: \(error)")
        }
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
        ) { [weak self] _, samples, error in
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
                self?.userHeight = heightInMeters
            }
        }
        
        healthStore.execute(query)
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
        ) { [weak self] _, samples, error in
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
                self?.userWeight = weightInKg
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchUserAge() {
        do {
            let dateOfBirthComponents = try healthStore.dateOfBirthComponents()
            let calendar = Calendar.current
            
            // Convert DateComponents to Date
            guard let dateOfBirth = calendar.date(from: dateOfBirthComponents) else {
                print("Error: Could not convert date of birth components to date")
                return
            }
            
            let age = calendar.dateComponents([.year], from: dateOfBirth, to: Date()).year
            
            DispatchQueue.main.async {
                self.userAge = age
            }
        } catch {
            print("Error fetching age: \(error)")
        }
    }
    
    private func fetchUserGender() {
        do {
            let biologicalSex = try healthStore.biologicalSex()
            
            DispatchQueue.main.async {
                self.userGender = biologicalSex.biologicalSex
            }
        } catch {
            print("Error fetching gender: \(error)")
        }
    }
    
    private func fetchRecentActivityData() {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        
        let query = HKSampleQuery(
            sampleType: energyType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
        ) { [weak self] _, samples, _ in
            guard let samples = samples as? [HKQuantitySample] else { return }
            
            DispatchQueue.main.async {
                self?.recentActivityData = samples
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchRecentSleepData() {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        
        let query = HKSampleQuery(
            sampleType: sleepType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
        ) { [weak self] _, samples, _ in
            guard let samples = samples as? [HKCategorySample] else { return }
            
            DispatchQueue.main.async {
                self?.recentSleepData = samples
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Helper Methods
    
    func getActivityLevel() -> String {
        guard !recentActivityData.isEmpty else { return "Sedentary (little or no exercise)" }
        
        let totalEnergy = recentActivityData.reduce(0.0) { total, sample in
            total + sample.quantity.doubleValue(for: HKUnit.kilocalorie())
        }
        
        let averageDailyEnergy = totalEnergy / 7.0
        
        switch averageDailyEnergy {
        case 0..<200:
            return "Sedentary (little or no exercise)"
        case 200..<400:
            return "Light (1–3 days/week)"
        case 400..<600:
            return "Moderate (3–5 days/week)"
        case 600..<800:
            return "Very (6–7 days/week)"
        default:
            return "Extra (physical job + training)"
        }
    }
    
    func getHeightInCm() -> Int? {
        guard let height = userHeight else { return nil }
        return Int(height * 100) // Convert meters to cm
    }
    
    func getWeightInKg() -> Int? {
        guard let weight = userWeight else { return nil }
        return Int(weight)
    }
    
    func getGenderString() -> String? {
        guard let gender = userGender else { return nil }
        
        switch gender {
        case .male:
            return "Male"
        case .female:
            return "Female"
        case .other:
            return "Other"
        case .notSet:
            return nil
        @unknown default:
            return nil
        }
    }
    
    func getAverageSleepHours() -> Double? {
        guard !recentSleepData.isEmpty else { return nil }
        
        let totalSleepDuration = recentSleepData.reduce(0.0) { total, sample in
            let duration = sample.endDate.timeIntervalSince(sample.startDate)
            return total + duration
        }
        
        let averageHours = totalSleepDuration / (7.0 * 3600.0) // Convert to hours over 7 days
        return averageHours
    }
    
    func getSleepQuality() -> String {
        guard let averageHours = getAverageSleepHours() else { return "Unknown" }
        
        switch averageHours {
        case 0..<6:
            return "Poor (less than 6 hours)"
        case 6..<7:
            return "Fair (6-7 hours)"
        case 7..<8:
            return "Good (7-8 hours)"
        case 8..<9:
            return "Very Good (8-9 hours)"
        default:
            return "Excellent (9+ hours)"
        }
    }
    
    func getSleepRecommendation() -> String {
        guard let averageHours = getAverageSleepHours() else { return "Aim for 7-9 hours of sleep for optimal hydration" }
        
        if averageHours < 7 {
            return "Poor sleep can increase dehydration. Consider improving sleep quality and increasing water intake."
        } else if averageHours > 9 {
            return "Good sleep quality! Maintain your current hydration routine."
        } else {
            return "Good sleep pattern. Your hydration needs are well-balanced."
        }
    }
    
    // MARK: - Data Refresh
    
    func refreshHealthData() {
        guard isAuthorized() else { return }
        prefetchUserData()
    }
    
    func disableHealthKit() {
        guard let modelContext = modelContext else { return }
        
        if let profile = userHealthProfile {
            profile.disableHealthKit()
            do {
                try modelContext.save()
                print("✅ HealthKit disabled")
            } catch {
                print("❌ Error disabling HealthKit: \(error)")
            }
        }
    }
    
    func enableHealthKit() {
        guard let modelContext = modelContext else { return }
        
        if let profile = userHealthProfile {
            profile.enableHealthKit()
            do {
                try modelContext.save()
                print("✅ HealthKit enabled")
            } catch {
                print("❌ Error enabling HealthKit: \(error)")
            }
        }
    }
    
    // MARK: - Permission Status
    
    func isAuthorized() -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        
        let typesToCheck: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .height)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!
        ]
        
        for type in typesToCheck {
            let status = healthStore.authorizationStatus(for: type)
            if status != .sharingAuthorized {
                return false
            }
        }
        
        return true
    }
    
    func isHealthKitEnabled() -> Bool {
        return userHealthProfile?.isHealthKitEnabled ?? false
    }
}

// MARK: - Error Types

enum HealthKitError: LocalizedError {
    case healthDataNotAvailable
    case permissionDenied
    case dataNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .healthDataNotAvailable:
            return "Health data is not available on this device"
        case .permissionDenied:
            return "HealthKit permission was denied"
        case .dataNotAvailable:
            return "Requested health data is not available"
        }
    }
}
