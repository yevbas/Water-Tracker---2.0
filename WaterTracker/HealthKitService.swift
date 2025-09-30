import Foundation
import HealthKit
import SwiftData

class HealthKitService: ObservableObject {
    let healthStore = HKHealthStore()
    private var modelContext: ModelContext?
    private var userHealthProfile: UserHealthProfile?
    
    private let healthKitTypes: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .height)!,
        HKObjectType.quantityType(forIdentifier: .bodyMass)!,
        HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!,
        HKObjectType.characteristicType(forIdentifier: .biologicalSex)!,
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    ]
    
    init() {
        // Note: loadUserHealthProfile() will be called when modelContext is set
    }
    
    // MARK: - Model Context Management
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadUserHealthProfile()
    }
    
    func setModelContextForOnboarding(_ context: ModelContext) {
        self.modelContext = context
        // Don't load existing profile during onboarding - we'll create a new one
    }
    
    // MARK: - Permission Management
    
    func isAuthorized() -> Bool {
        return healthKitTypes.allSatisfy { healthStore.authorizationStatus(for: $0) == .sharingAuthorized }
    }
    
    func requestPermission(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, NSError(domain: "HealthKitError", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device"]))
            return
        }
        
        healthStore.requestAuthorization(toShare: nil, read: healthKitTypes) { success, error in
            DispatchQueue.main.async {
                if success {
                    // Permission granted - the view will handle data fetching and saving
                    completion(true, nil)
                } else {
                    completion(false, error)
                }
            }
        }
    }
    
    // MARK: - Status Management
    
    func isHealthKitEnabled() -> Bool {
        return userHealthProfile?.isHealthKitEnabled ?? false
    }
    
    func enableHealthKit() {
        userHealthProfile?.enableHealthKit()
        saveProfile()
    }
    
    func disableHealthKit() {
        userHealthProfile?.disableHealthKit()
        saveProfile()
    }
    
    func refreshHealthKitStatus() {
        loadUserHealthProfile()
    }
    
    // MARK: - Data Refresh (for Settings)
    
    func refreshHealthData() {
        print("🔄 HealthKit data refresh requested from Settings")
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
                self.updateProfileWithHeight(heightInMeters)
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
                self.updateProfileWithWeight(weightInKg)
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchUserAge() {
        do {
            let birthDateComponents = try healthStore.dateOfBirthComponents()
            let calendar = Calendar.current
            
            // Convert DateComponents to Date
            guard let birthDate = calendar.date(from: birthDateComponents) else {
                print("❌ Could not convert birth date components to Date")
                return
            }
            
            let age = calendar.dateComponents([.year], from: birthDate, to: Date()).year
            print("✅ Age fetched: \(age ?? 0) years")
            
            DispatchQueue.main.async {
                self.updateProfileWithAge(age)
            }
        } catch {
            print("❌ Error fetching age: \(error)")
        }
    }
    
    private func fetchUserGender() {
        do {
            let biologicalSex = try healthStore.biologicalSex()
            print("✅ Gender fetched: \(biologicalSex.biologicalSex.rawValue)")
            
            DispatchQueue.main.async {
                self.updateProfileWithGender(biologicalSex.biologicalSex)
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
        
        print("🔍 Fetching sleep data...")
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
                self.updateProfileWithSleep(sleepHours)
            }
        }
        
        healthStore.execute(query)
    }
    
    private func calculateAverageSleepHours(from samples: [HKSample]) -> Double? {
        let sleepSamples = samples.compactMap { $0 as? HKCategorySample }
        let inBedSamples = sleepSamples.filter { $0.value == HKCategoryValueSleepAnalysis.inBed.rawValue }
        
        guard !inBedSamples.isEmpty else { return nil }
        
        let totalHours = inBedSamples.reduce(0.0) { total, sample in
            let duration = sample.endDate.timeIntervalSince(sample.startDate)
            return total + duration / 3600.0 // Convert to hours
        }
        
        return totalHours / Double(inBedSamples.count)
    }
    
    private func updateProfileWithHeight(_ height: Double) {
        userHealthProfile?.height = height
        saveProfile()
    }
    
    private func updateProfileWithWeight(_ weight: Double) {
        userHealthProfile?.weight = weight
        saveProfile()
    }
    
    private func updateProfileWithAge(_ age: Int?) {
        userHealthProfile?.age = age
        saveProfile()
    }
    
    private func updateProfileWithGender(_ gender: HKBiologicalSex) {
        userHealthProfile?.gender = gender.stringValue
        saveProfile()
    }
    
    private func updateProfileWithSleep(_ sleepHours: Double?) {
        userHealthProfile?.averageSleepHours = sleepHours
        saveProfile()
    }
    
    // MARK: - Private Methods
    
    private func loadUserHealthProfile() {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<UserHealthProfile>()
        do {
            let profiles = try modelContext.fetch(descriptor)
            self.userHealthProfile = profiles.first
        } catch {
            print("❌ Error loading user health profile: \(error)")
        }
    }
    
    private func saveProfile() {
        guard let modelContext = modelContext else { return }
        
        do {
            try modelContext.save()
        } catch {
            print("❌ Error saving profile: \(error)")
        }
    }
}

// MARK: - Extensions
// Note: HKBiologicalSex.stringValue extension is defined in UserHealthProfile.swift