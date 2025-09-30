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
        // This method is called from Settings to refresh data
        // The actual data fetching is now handled by the views
        print("🔄 HealthKit data refresh requested from Settings")
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