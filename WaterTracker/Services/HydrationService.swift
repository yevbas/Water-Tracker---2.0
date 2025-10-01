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

    private init() {}

    func configure(container: ModelContainer) {
        self.container = container
    }

    func addPortion(amount: Double, unit: WaterUnit, drink: Drink = .water, date: Date = Date()) {
        guard let container else { return }
        let context = ModelContext(container)
        let portion = WaterPortion(amount: amount, unit: unit, drink: drink, createDate: date)
        context.insert(portion)
        try? context.save()
    }
}


