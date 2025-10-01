import Foundation
import HealthKit

// MARK: - Helper Struct for Data Collection
struct HealthKitData {
    var height: Double?
    var weight: Double?
    var age: Int?
    var gender: HKBiologicalSex?
    var averageSleepHours: Double?
}

class HealthKitService: ObservableObject {
    let healthStore = HKHealthStore()
    
    // HealthKit types for reference
    let healthKitTypes: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .height)!,
        HKObjectType.quantityType(forIdentifier: .bodyMass)!,
        HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!,
        HKObjectType.characteristicType(forIdentifier: .biologicalSex)!,
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    ]

    init() {}
    
    // MARK: - Unified HealthKit Data Fetching
    
    func fetchAllHealthData() async -> HealthKitData {
        print("🚀 Starting unified HealthKit data fetch...")
        
        async let height = fetchUserHeight()
        async let weight = fetchUserWeight()
        async let age = fetchUserAge()
        async let gender = fetchUserGender()
        async let sleepHours = fetchRecentSleepData()
        
        let (fetchedHeight, fetchedWeight, fetchedAge, fetchedGender, fetchedSleepHours) = await (height, weight, age, gender, sleepHours)
        
        print("✅ All HealthKit data fetched - height: \(fetchedHeight != nil), weight: \(fetchedWeight != nil), age: \(fetchedAge != nil), gender: \(fetchedGender != nil), sleep: \(fetchedSleepHours != nil)")
        
        return HealthKitData(
            height: fetchedHeight,
            weight: fetchedWeight,
            age: fetchedAge,
            gender: fetchedGender,
            averageSleepHours: fetchedSleepHours
        )
    }
    
    // MARK: - Individual Fetch Methods
    
    func fetchUserHeight() async -> Double? {
        guard let heightType = HKQuantityType.quantityType(forIdentifier: .height) else {
            print("❌ Height type not available")
            return nil
        }
        
        print("🔍 Fetching height data...")
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heightType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    print("❌ Error fetching height: \(error)")
                    continuation.resume(returning: nil)
                    return
                }
                
                guard let sample = samples?.first as? HKQuantitySample else {
                    print("❌ No height samples found")
                    continuation.resume(returning: nil)
                    return
                }
                
                let heightInMeters = sample.quantity.doubleValue(for: HKUnit.meter())
                print("✅ Height fetched: \(heightInMeters) meters")
                continuation.resume(returning: heightInMeters)
            }
            
            healthStore.execute(query)
        }
    }
    
    func fetchUserWeight() async -> Double? {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            print("❌ Weight type not available")
            return nil
        }
        
        print("🔍 Fetching weight data...")
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    print("❌ Error fetching weight: \(error)")
                    continuation.resume(returning: nil)
                    return
                }
                
                guard let sample = samples?.first as? HKQuantitySample else {
                    print("❌ No weight samples found")
                    continuation.resume(returning: nil)
                    return
                }
                
                let weightInKg = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                print("✅ Weight fetched: \(weightInKg) kg")
                continuation.resume(returning: weightInKg)
            }
            
            healthStore.execute(query)
        }
    }
    
    func fetchUserAge() async -> Int? {
        do {
            let birthDateComponents = try healthStore.dateOfBirthComponents()
            let calendar = Calendar.current
            
            // Convert DateComponents to Date
            guard let birthDate = calendar.date(from: birthDateComponents) else {
                print("❌ Could not convert birth date components to Date")
                return nil
            }
            
            let age = calendar.dateComponents([.year], from: birthDate, to: Date()).year
            print("✅ Age fetched: \(age ?? 0) years")
            return age
        } catch {
            print("❌ Error fetching age: \(error)")
            return nil
        }
    }
    
    func fetchUserGender() async -> HKBiologicalSex? {
        do {
            let biologicalSex = try healthStore.biologicalSex()
            print("✅ Gender fetched: \(biologicalSex.biologicalSex.rawValue)")
            return biologicalSex.biologicalSex
        } catch {
            print("❌ Error fetching gender: \(error)")
            return nil
        }
    }
    
    func fetchRecentSleepData() async -> Double? {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            print("❌ Sleep type not available")
            return nil
        }
        
        print("🔍 Fetching sleep data...")
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    print("❌ Error fetching sleep data: \(error)")
                    continuation.resume(returning: nil)
                    return
                }
                
                guard let samples = samples else {
                    print("❌ No sleep samples found")
                    continuation.resume(returning: nil)
                    return
                }
                
                let sleepHours = self.calculateAverageSleepHours(from: samples)
                print("✅ Sleep data fetched: \(sleepHours ?? 0) hours average")
                continuation.resume(returning: sleepHours)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Private Helper Methods
    
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
}

// MARK: - Extensions

extension HKBiologicalSex {
    var stringValue: String {
        switch self {
        case .male:
            return "male"
        case .female:
            return "female"
        case .other:
            return "other"
        case .notSet:
            return "notSet"
        @unknown default:
            return "notSet"
        }
    }
    
    static func from(string: String?) -> HKBiologicalSex? {
        guard let string = string else { return nil }
        switch string {
        case "female":
            return .female
        case "male":
            return .male
        case "other":
            return .other
        default:
            return .notSet
        }
    }
}
