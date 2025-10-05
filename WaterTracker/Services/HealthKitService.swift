import Foundation
import HealthKit

class HealthKitService: ObservableObject {
    let healthStore = HKHealthStore()
    
    // HealthKit types for reference
    let healthKitTypes: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .height)!,
        HKObjectType.quantityType(forIdentifier: .bodyMass)!,
        HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!,
        HKObjectType.characteristicType(forIdentifier: .biologicalSex)!,
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
        HKObjectType.quantityType(forIdentifier: .dietaryWater)!
    ]
    
    // HealthKit types we want to write to
    let healthKitWriteTypes: Set<HKSampleType> = [
        HKObjectType.quantityType(forIdentifier: .dietaryWater)!,
        HKObjectType.quantityType(forIdentifier: .dietaryCaffeine)!,
        HKObjectType.quantityType(forIdentifier: .numberOfAlcoholicBeverages)!
    ]

    init() {
        // Initialize default sync settings if they don't exist
        initializeSyncSettings()
    }
    
    private func initializeSyncSettings() {
        // Set default values for sync toggles if they haven't been set yet
        if UserDefaults.standard.object(forKey: "healthkit_sync_water") == nil {
            UserDefaults.standard.set(true, forKey: "healthkit_sync_water")
        }
        if UserDefaults.standard.object(forKey: "healthkit_sync_caffeine") == nil {
            UserDefaults.standard.set(true, forKey: "healthkit_sync_caffeine")
        }
        if UserDefaults.standard.object(forKey: "healthkit_sync_alcohol") == nil {
            UserDefaults.standard.set(true, forKey: "healthkit_sync_alcohol")
        }
    }
    
    // MARK: - HealthKit Authorization
    
    func requestHealthKitPermissions() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("❌ HealthKit is not available on this device")
            return false
        }
        
        print("🔐 Requesting HealthKit permissions...")
        
        do {
            try await healthStore.requestAuthorization(toShare: healthKitWriteTypes, read: healthKitTypes)
            print("✅ HealthKit permissions granted")
            return true
        } catch {
            print("❌ Failed to request HealthKit permissions: \(error)")
            return false
        }
    }
    
    func checkHealthKitPermissions() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("❌ HealthKit not available on device")
            return false
        }
        
        print("🔍 Checking HealthKit permissions by attempting to fetch data...")
        
        // Try to fetch actual data to determine if we have permissions
        // HealthKit will return empty results if permission was denied
        let data = await fetchAllHealthData()
        
        // Check if we can fetch any data at all
        let hasAnyData = data.height != nil || data.weight != nil || data.age != nil || data.gender != nil || data.averageSleepHours != nil
        
        print("🔍 Permission check result - has any data: \(hasAnyData)")
        return hasAnyData
    }
    
    func checkHealthKitWritePermissions() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("❌ HealthKit not available on device")
            return false
        }
        
        print("🔍 Checking HealthKit write permissions...")
        
        // Check authorization status for each write type
        for writeType in healthKitWriteTypes {
            let status = healthStore.authorizationStatus(for: writeType)
            print("🔍 Write permission for \(writeType.identifier): \(status.rawValue)")
            
            // If any write permission is denied or not determined, we don't have full write access
            if status != .sharingAuthorized {
                print("❌ Write permissions not fully granted")
                return false
            }
        }
        
        print("✅ All write permissions granted")
        return true
    }
    
    func checkWaterWritePermission() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            return false
        }
        
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else {
            return false
        }
        
        let status = healthStore.authorizationStatus(for: waterType)
        print("🔍 Water write permission: \(status.rawValue)")
        return status == .sharingAuthorized
    }
    
    func checkCaffeineWritePermission() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            return false
        }
        
        guard let caffeineType = HKQuantityType.quantityType(forIdentifier: .dietaryCaffeine) else {
            return false
        }
        
        let status = healthStore.authorizationStatus(for: caffeineType)
        print("🔍 Caffeine write permission: \(status.rawValue)")
        return status == .sharingAuthorized
    }
    
    func checkAlcoholWritePermission() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            return false
        }
        
        guard let alcoholType = HKQuantityType.quantityType(forIdentifier: .numberOfAlcoholicBeverages) else {
            return false
        }
        
        let status = healthStore.authorizationStatus(for: alcoholType)
        print("🔍 Alcohol write permission: \(status.rawValue)")
        return status == .sharingAuthorized
    }
    
    // MARK: - Unified HealthKit Data Fetching
    
    func fetchAllHealthData() async -> HealthKitData {
        print("🚀 Starting unified HealthKit data fetch...")
        
        async let height = fetchUserHeight()
        async let weight = fetchUserWeight()
        async let age = fetchUserAge()
        async let gender = fetchUserGender()
        async let sleepHours = fetchRecentSleepData()
        
        let (fetchedHeight, fetchedWeight, fetchedAge, fetchedGender, fetchedSleepHours) = await (height, weight, age, gender, sleepHours)
        
        // Validate sleep data - treat 0.0 or very low values as no meaningful data
        let validSleepHours = (fetchedSleepHours != nil && fetchedSleepHours! > 0.5) ? fetchedSleepHours : nil
        
        print("✅ All HealthKit data fetched - height: \(fetchedHeight != nil), weight: \(fetchedWeight != nil), age: \(fetchedAge != nil), gender: \(fetchedGender != nil), sleep: \(validSleepHours != nil)")
        
        return HealthKitData(
            height: fetchedHeight,
            weight: fetchedWeight,
            age: fetchedAge,
            gender: fetchedGender,
            averageSleepHours: validSleepHours
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
    
    // MARK: - Water Intake Saving
    
    func saveWaterIntake(amount: Double, unit: WaterUnit, date: Date = Date()) async -> Bool {
        // Check if water sync is enabled
        guard UserDefaults.standard.bool(forKey: "healthkit_sync_water") else {
            print("💧 Water sync is disabled, skipping HealthKit save")
            return true // Return true since this is intentional, not an error
        }
        
        guard HKHealthStore.isHealthDataAvailable() else {
            print("❌ HealthKit not available on device")
            return false
        }
        
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else {
            print("❌ Water type not available")
            return false
        }
        
        // Convert amount to milliliters for HealthKit
        let amountInMl = unit.toMilliliters(amount)
        let quantity = HKQuantity(unit: HKUnit.literUnit(with: .milli), doubleValue: amountInMl)

        let sample = HKQuantitySample(
            type: waterType,
            quantity: quantity,
            start: date,
            end: date
        )
        
        print("💧 Saving \(amountInMl) ml of water to HealthKit...")
        
        return await withCheckedContinuation { continuation in
            healthStore.save(sample) { success, error in
                if let error = error {
                    print("❌ Failed to save water intake to HealthKit: \(error)")
                    continuation.resume(returning: false)
                } else {
                    print("✅ Water intake saved to HealthKit successfully")
                    continuation.resume(returning: true)
                }
            }
        }
    }
    
    func saveCaffeineIntake(amount: Double, unit: WaterUnit, date: Date = Date()) async -> Bool {
        // Check if caffeine sync is enabled
        guard UserDefaults.standard.bool(forKey: "healthkit_sync_caffeine") else {
            print("☕️ Caffeine sync is disabled, skipping HealthKit save")
            return true // Return true since this is intentional, not an error
        }
        
        guard HKHealthStore.isHealthDataAvailable() else {
            print("❌ HealthKit not available on device")
            return false
        }
        
        guard let caffeineType = HKQuantityType.quantityType(forIdentifier: .dietaryCaffeine) else {
            print("❌ Caffeine type not available")
            return false
        }
        
        // Convert amount to milliliters for HealthKit, then estimate caffeine content
        let amountInMl = unit.toMilliliters(amount)

        // Estimate caffeine content: ~95mg per 240ml (8 fl oz) of coffee
        let caffeinePerMl = 95.0 / 240.0 // mg per ml
        let caffeineAmount = amountInMl * caffeinePerMl
        
        let quantity = HKQuantity(unit: HKUnit.gramUnit(with: .milli), doubleValue: caffeineAmount)
        
        let sample = HKQuantitySample(
            type: caffeineType,
            quantity: quantity,
            start: date,
            end: date
        )
        
        print("☕️ Saving \(caffeineAmount) mg of caffeine to HealthKit...")
        
        return await withCheckedContinuation { continuation in
            healthStore.save(sample) { success, error in
                if let error = error {
                    print("❌ Failed to save caffeine intake to HealthKit: \(error)")
                    continuation.resume(returning: false)
                } else {
                    print("✅ Caffeine intake saved to HealthKit successfully")
                    continuation.resume(returning: true)
                }
            }
        }
    }
    
    func saveAlcoholIntake(amount: Double, unit: WaterUnit, alcoholType: Drink, date: Date = Date()) async -> Bool {
        // Check if alcohol sync is enabled
        guard UserDefaults.standard.bool(forKey: "healthkit_sync_alcohol") else {
            print("🍷 Alcohol sync is disabled, skipping HealthKit save")
            return true // Return true since this is intentional, not an error
        }
        
        guard HKHealthStore.isHealthDataAvailable() else {
            print("❌ HealthKit not available on device")
            return false
        }
        
        guard let alcoholQuantityType = HKQuantityType.quantityType(forIdentifier: .numberOfAlcoholicBeverages) else {
            print("❌ Alcohol type not available")
            return false
        }
        
        // Convert amount to milliliters
        let amountInMl = unit.toMilliliters(amount)

        // Calculate standard drinks based on alcohol type and volume
        let standardDrinks = calculateStandardDrinks(volumeMl: amountInMl, alcoholType: alcoholType)
        
        let quantity = HKQuantity(unit: HKUnit.count(), doubleValue: standardDrinks)
        
        let sample = HKQuantitySample(
            type: alcoholQuantityType,
            quantity: quantity,
            start: date,
            end: date
        )
        
        print("🍷 Saving \(standardDrinks) standard drinks to HealthKit...")
        
        return await withCheckedContinuation { continuation in
            healthStore.save(sample) { success, error in
                if let error = error {
                    print("❌ Failed to save alcohol intake to HealthKit: \(error)")
                    continuation.resume(returning: false)
                } else {
                    print("✅ Alcohol intake saved to HealthKit successfully")
                    continuation.resume(returning: true)
                }
            }
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func calculateStandardDrinks(volumeMl: Double, alcoholType: Drink) -> Double {
        // Standard drink definitions (14g of pure alcohol)
        let alcoholByVolume: Double
        let standardDrinkMl: Double
        
        switch alcoholType {
        case .wine, .champagne:
            alcoholByVolume = 0.12 // 12% ABV
            standardDrinkMl = 148.0 // 5 fl oz
        case .beer:
            alcoholByVolume = 0.05 // 5% ABV
            standardDrinkMl = 355.0 // 12 fl oz
        case .strongAlcohol:
            alcoholByVolume = 0.40 // 40% ABV
            standardDrinkMl = 44.0 // 1.5 fl oz
        default:
            // Default to wine strength for other alcohol
            alcoholByVolume = 0.12
            standardDrinkMl = 148.0
        }
        
        // Calculate standard drinks: (volume * ABV) / (standard drink volume * standard ABV)
        let standardABV = 0.12 // Using wine as baseline
        return (volumeMl * alcoholByVolume) / (standardDrinkMl * standardABV)
    }
    
    // MARK: - HealthKit Record Management

    /// Generic method to delete a HealthKit record by matching quantity and date
    private func deleteHealthKitRecord(
        quantityType: HKQuantityType,
        expectedQuantity: Double,
        unit: HKUnit,
        date: Date,
        tolerance: Double,
        logPrefix: String
    ) async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("❌ HealthKit not available on device")
            return false
        }

        // Create a time window around the date (±1 minute) to find the record
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .minute, value: -1, to: date) ?? date
        let endDate = calendar.date(byAdding: .minute, value: 1, to: date) ?? date

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    print("❌ Error fetching \(logPrefix) records for deletion: \(error)")
                    continuation.resume(returning: false)
                    return
                }

                guard let samples = samples as? [HKQuantitySample] else {
                    print("❌ No \(logPrefix) samples found for deletion")
                    continuation.resume(returning: true) // No records to delete is success
                    return
                }

                // Find the sample with matching quantity and date
                let matchingSample = samples.first { sample in
                    let sampleQuantity = sample.quantity.doubleValue(for: unit)
                    let timeDiff = abs(sample.startDate.timeIntervalSince(date))
                    return abs(sampleQuantity - expectedQuantity) < tolerance && timeDiff < 60
                }

                guard let sampleToDelete = matchingSample else {
                    print("❌ No matching \(logPrefix) record found for deletion")
                    continuation.resume(returning: true) // No matching record is success
                    return
                }

                // Delete the matching sample
                self.healthStore.delete(sampleToDelete) { success, error in
                    if let error = error {
                        print("❌ Failed to delete \(logPrefix) record from HealthKit: \(error)")
                        continuation.resume(returning: false)
                    } else {
                        print("✅ \(logPrefix.capitalized) record deleted from HealthKit successfully")
                        continuation.resume(returning: true)
                    }
                }
            }

            self.healthStore.execute(query)
        }
    }

    func deleteWaterIntakeRecord(amount: Double, unit: WaterUnit, date: Date) async -> Bool {
        guard UserDefaults.standard.bool(forKey: "healthkit_sync_water") else {
            print("💧 Water sync is disabled, skipping HealthKit deletion")
            return true
        }

        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else {
            print("❌ Water type not available")
            return false
        }

        // Convert amount to milliliters for HealthKit
        let amountInMl = unit.toMilliliters(amount)

        return await deleteHealthKitRecord(
            quantityType: waterType,
            expectedQuantity: amountInMl,
            unit: HKUnit.literUnit(with: .milli),
            date: date,
            tolerance: 0.1,
            logPrefix: "water"
        )
    }

    func deleteCaffeineIntakeRecord(amount: Double, unit: WaterUnit, date: Date) async -> Bool {
        guard UserDefaults.standard.bool(forKey: "healthkit_sync_caffeine") else {
            print("☕️ Caffeine sync is disabled, skipping HealthKit deletion")
            return true
        }

        guard let caffeineType = HKQuantityType.quantityType(forIdentifier: .dietaryCaffeine) else {
            print("❌ Caffeine type not available")
            return false
        }

        // Convert amount to milliliters and calculate caffeine content
        let amountInMl = unit.toMilliliters(amount)
        let caffeinePerMl = 95.0 / 240.0 // mg per ml
        let expectedCaffeineAmount = amountInMl * caffeinePerMl

        return await deleteHealthKitRecord(
            quantityType: caffeineType,
            expectedQuantity: expectedCaffeineAmount,
            unit: HKUnit.gramUnit(with: .milli),
            date: date,
            tolerance: 0.1,
            logPrefix: "caffeine"
        )
    }

    func deleteAlcoholIntakeRecord(amount: Double, unit: WaterUnit, alcoholType: Drink, date: Date) async -> Bool {
        guard UserDefaults.standard.bool(forKey: "healthkit_sync_alcohol") else {
            print("🍷 Alcohol sync is disabled, skipping HealthKit deletion")
            return true
        }

        guard let alcoholQuantityType = HKQuantityType.quantityType(forIdentifier: .numberOfAlcoholicBeverages) else {
            print("❌ Alcohol type not available")
            return false
        }

        // Convert amount to milliliters and calculate standard drinks
        let amountInMl = unit.toMilliliters(amount)
        let expectedStandardDrinks = calculateStandardDrinks(volumeMl: amountInMl, alcoholType: alcoholType)

        return await deleteHealthKitRecord(
            quantityType: alcoholQuantityType,
            expectedQuantity: expectedStandardDrinks,
            unit: HKUnit.count(),
            date: date,
            tolerance: 0.01,
            logPrefix: "alcohol"
        )
    }
    
    // MARK: - HealthKit Record Updates

    func updateWaterIntakeRecord(oldAmount: Double, oldUnit: WaterUnit, newAmount: Double, newUnit: WaterUnit, oldDate: Date, newDate: Date) async -> Bool {
        print("🔄 Updating water intake record: \(oldAmount) \(oldUnit.shortName) -> \(newAmount) \(newUnit.shortName)")

        let deleteSuccess = await deleteWaterIntakeRecord(amount: oldAmount, unit: oldUnit, date: oldDate)
        guard deleteSuccess else {
            print("❌ Failed to delete old water record")
            return false
        }

        let addSuccess = await saveWaterIntake(amount: newAmount, unit: newUnit, date: newDate)
        guard addSuccess else {
            print("❌ Failed to add new water record")
            return false
        }

        print("✅ Water intake record updated successfully")
        return true
    }

    func updateCaffeineIntakeRecord(oldAmount: Double, oldUnit: WaterUnit, newAmount: Double, newUnit: WaterUnit, oldDate: Date, newDate: Date) async -> Bool {
        print("🔄 Updating caffeine intake record: \(oldAmount) \(oldUnit.shortName) -> \(newAmount) \(newUnit.shortName)")

        let deleteSuccess = await deleteCaffeineIntakeRecord(amount: oldAmount, unit: oldUnit, date: oldDate)
        guard deleteSuccess else {
            print("❌ Failed to delete old caffeine record")
            return false
        }

        let addSuccess = await saveCaffeineIntake(amount: newAmount, unit: newUnit, date: newDate)
        guard addSuccess else {
            print("❌ Failed to add new caffeine record")
            return false
        }

        print("✅ Caffeine intake record updated successfully")
        return true
    }

    func updateAlcoholIntakeRecord(oldAmount: Double, oldUnit: WaterUnit, oldAlcoholType: Drink, newAmount: Double, newUnit: WaterUnit, newAlcoholType: Drink, oldDate: Date, newDate: Date) async -> Bool {
        print("🔄 Updating alcohol intake record: \(oldAmount) \(oldUnit.shortName) \(oldAlcoholType.title) -> \(newAmount) \(newUnit.shortName) \(newAlcoholType.title)")

        let deleteSuccess = await deleteAlcoholIntakeRecord(amount: oldAmount, unit: oldUnit, alcoholType: oldAlcoholType, date: oldDate)
        guard deleteSuccess else {
            print("❌ Failed to delete old alcohol record")
            return false
        }

        let addSuccess = await saveAlcoholIntake(amount: newAmount, unit: newUnit, alcoholType: newAlcoholType, date: newDate)
        guard addSuccess else {
            print("❌ Failed to add new alcohol record")
            return false
        }

        print("✅ Alcohol intake record updated successfully")
        return true
    }
    
    // MARK: - Bulk Data Synchronization
    
    func syncAllHistoricalData(from portions: [WaterPortion], syncWater: Bool = true, syncCaffeine: Bool = true, syncAlcohol: Bool = true) async -> (success: Int, failed: Int, total: Int) {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("❌ HealthKit not available on device")
            return (0, 0, 0)
        }
        
        print("🔄 Starting bulk sync of \(portions.count) water portions...")
        
        var successCount = 0
        var failedCount = 0
        let total = portions.count
        
        // Group portions by date for better performance
        let groupedPortions = Dictionary(grouping: portions) { portion in
            Calendar.current.startOfDay(for: portion.createDate)
        }
        
        for (date, dayPortions) in groupedPortions {
            print("📅 Syncing \(dayPortions.count) portions for \(date)")
            
            for portion in dayPortions {
                do {
                    var syncTasks: [Task<Bool, Never>] = []
                    
                    // Sync water intake for hydrating drinks
                    if syncWater && (portion.drink.hydrationCategory == .fullyHydrating || 
                       portion.drink.hydrationCategory == .mildDiuretic || 
                       portion.drink.hydrationCategory == .partiallyHydrating) {
                        
                        let waterTask = Task {
                            await saveWaterIntake(
                                amount: portion.amount * portion.drink.hydrationFactor,
                                unit: portion.unit,
                                date: portion.createDate
                            )
                        }
                        syncTasks.append(waterTask)
                    }
                    
                    // Sync caffeine intake for caffeinated drinks
                    if syncCaffeine && portion.drink.containsCaffeine {
                        let caffeineTask = Task {
                            await saveCaffeineIntake(
                                amount: portion.amount,
                                unit: portion.unit,
                                date: portion.createDate
                            )
                        }
                        syncTasks.append(caffeineTask)
                    }
                    
                    // Sync alcohol intake for alcoholic drinks
                    if syncAlcohol && portion.drink.containsAlcohol {
                        let alcoholTask = Task {
                            await saveAlcoholIntake(
                                amount: portion.amount,
                                unit: portion.unit,
                                alcoholType: portion.drink,
                                date: portion.createDate
                            )
                        }
                        syncTasks.append(alcoholTask)
                    }
                    
                    // Wait for all sync tasks for this portion to complete
                    let results = await withTaskGroup(of: Bool.self) { group in
                        for task in syncTasks {
                            group.addTask {
                                await task.value
                            }
                        }
                        
                        var allSucceeded = true
                        for await result in group {
                            if !result {
                                allSucceeded = false
                            }
                        }
                        return allSucceeded
                    }
                    
                    if results {
                        successCount += 1
                    } else {
                        failedCount += 1
                    }
                    
                    // Small delay between individual portions to avoid overwhelming HealthKit
                    try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
                    
                } catch {
                    print("❌ Error syncing portion: \(error)")
                    failedCount += 1
                }
            }
            
            // Small delay between days to avoid overwhelming HealthKit
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        print("✅ Bulk sync completed: \(successCount) success, \(failedCount) failed, \(total) total")
        return (successCount, failedCount, total)
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

// MARK: - Helper Struct for Data Collection
struct HealthKitData {
    var height: Double?
    var weight: Double?
    var age: Int?
    var gender: HKBiologicalSex?
    var averageSleepHours: Double?
}
