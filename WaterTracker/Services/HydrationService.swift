//
//  HydrationService.swift
//  WaterTracker
//
//  Created by Assistant on 29/09/2025.
//

import Foundation
import SwiftData

@MainActor
final class HydrationService {
    static let shared = HydrationService()

    private var container: ModelContainer?
    private var healthKitService: HealthKitService?

    private init() {}

    func configure(container: ModelContainer, healthKitService: HealthKitService? = nil) {
        self.container = container
        self.healthKitService = healthKitService
    }

    func addPortion(amount: Double, unit: WaterUnit, drink: Drink = .water, date: Date = Date()) {
        guard let container else { return }
        let context = ModelContext(container)
        
        // Convert amount to millilitres before storing
        let amountInMl = unit.toMilliliters(amount)
        let portion = WaterPortion(amount: amountInMl, drink: drink, createDate: date, dayDate: date.rounded())
        context.insert(portion)
        try? context.save()
        
        // Save to HealthKit if HealthKit service is available
        if let healthKitService = healthKitService {
            Task {
                // Save water intake for hydrating drinks (amount is in ml)
                if drink.hydrationCategory == .fullyHydrating || drink.hydrationCategory == .mildDiuretic || drink.hydrationCategory == .partiallyHydrating {
                    await healthKitService.saveWaterIntake(
                        amount: amountInMl * drink.hydrationFactor,
                        unit: .millilitres,
                        date: date
                    )
                }
                
                // Save caffeine intake for caffeinated drinks (amount is in ml)
                if drink.containsCaffeine {
                    await healthKitService.saveCaffeineIntake(
                        amount: amountInMl,
                        unit: .millilitres,
                        date: date
                    )
                }
                
                // Save alcohol intake for alcoholic drinks (amount is in ml)
                if drink.containsAlcohol {
                    await healthKitService.saveAlcoholIntake(
                        amount: amountInMl,
                        unit: .millilitres,
                        alcoholType: drink,
                        date: date
                    )
                }
            }
        }
    }
}


