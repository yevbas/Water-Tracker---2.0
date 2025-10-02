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
        let portion = WaterPortion(amount: amount, unit: unit, drink: drink, createDate: date, dayDate: date.rounded())
        context.insert(portion)
        try? context.save()
        
        // Save to HealthKit if it's water and HealthKit service is available
        if drink == .water, let healthKitService = healthKitService {
            Task {
                await healthKitService.saveWaterIntake(
                    amount: amount,
                    unit: unit,
                    date: date
                )
            }
        }
    }
}


