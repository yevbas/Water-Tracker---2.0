//
//  EditWaterPortionView.swift
//  WaterTracker
//
//  Created by Jackson  on 29/09/2025.
//

import SwiftUI
import SwiftData

struct EditWaterPortionView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @State var waterPortion: WaterPortion
    
    // Store original values for HealthKit updates
    @State private var originalAmount: Double
    @State private var originalUnit: WaterUnit
    @State private var originalDrink: Drink
    @State private var originalDate: Date

    @EnvironmentObject var revenueCatMonitor: RevenueCatMonitor
    @StateObject private var healthKitService = HealthKitService()
    
    init(waterPortion: WaterPortion) {
        self._waterPortion = State(initialValue: waterPortion)
        self._originalAmount = State(initialValue: waterPortion.amount)
        self._originalUnit = State(initialValue: waterPortion.unit)
        self._originalDrink = State(initialValue: waterPortion.drink)
        self._originalDate = State(initialValue: waterPortion.createDate)
    }

    var body: some View {
        DrinkSelector(
            createDate: waterPortion.createDate,
            amount: waterPortion.amount.description,
            drink: waterPortion.drink
        ) { newDrink, newAmount, newTime in
            waterPortion.drink = newDrink
            waterPortion.amount = newAmount
            waterPortion.createDate = newTime

            saveChanges()
        }
    }

    func saveChanges() {
        // Save the SwiftData changes first
        try? modelContext.save()
        
        // Update HealthKit if there are changes and sync is enabled
        Task {
            await updateHealthKitRecords()
        }

        dismiss()
    }
    
    private func updateHealthKitRecords() async {
        // Check if any values have changed
        let hasChanges = originalAmount != waterPortion.amount ||
                        originalUnit != waterPortion.unit ||
                        originalDrink != waterPortion.drink ||
                        originalDate != waterPortion.createDate
        
        guard hasChanges else {
            print("📝 No changes detected, skipping HealthKit update")
            return
        }
        
        print("🔄 Updating HealthKit records due to changes in water portion")
        
        // Check if HealthKit is available and we have write permissions
        let hasWritePermissions = await healthKitService.checkHealthKitWritePermissions()
        guard hasWritePermissions else {
            print("❌ No HealthKit write permissions, skipping update")
            return
        }
        
        // Update water intake if the drink has hydration value
        if waterPortion.drink.hydrationCategory == .fullyHydrating || 
           waterPortion.drink.hydrationCategory == .mildDiuretic || 
           waterPortion.drink.hydrationCategory == .partiallyHydrating {
            
            let oldWaterAmount = originalAmount * originalDrink.hydrationFactor
            let newWaterAmount = waterPortion.amount * waterPortion.drink.hydrationFactor
            
            if oldWaterAmount != newWaterAmount || originalUnit != waterPortion.unit || originalDate != waterPortion.createDate {
                await healthKitService.updateWaterIntakeRecord(
                    oldAmount: oldWaterAmount,
                    oldUnit: originalUnit,
                    newAmount: newWaterAmount,
                    newUnit: waterPortion.unit,
                    oldDate: originalDate,
                    newDate: waterPortion.createDate
                )
            }
        }
        
        // Update caffeine intake if the drink contains caffeine
        if originalDrink.containsCaffeine || waterPortion.drink.containsCaffeine {
            await healthKitService.updateCaffeineIntakeRecord(
                oldAmount: originalAmount,
                oldUnit: originalUnit,
                newAmount: waterPortion.amount,
                newUnit: waterPortion.unit,
                oldDate: originalDate,
                newDate: waterPortion.createDate
            )
        }
        
        // Update alcohol intake if the drink contains alcohol
        if originalDrink.containsAlcohol || waterPortion.drink.containsAlcohol {
            await healthKitService.updateAlcoholIntakeRecord(
                oldAmount: originalAmount,
                oldUnit: originalUnit,
                oldAlcoholType: originalDrink,
                newAmount: waterPortion.amount,
                newUnit: waterPortion.unit,
                newAlcoholType: waterPortion.drink,
                oldDate: originalDate,
                newDate: waterPortion.createDate
            )
        }
        
        print("✅ HealthKit records update completed")
    }

}

#Preview {
    NavigationStack {
        EditWaterPortionView(
            waterPortion: .init(
                amount: 2200,
                drink: .coffee,
                createDate: Date(),
                dayDate: Date().rounded()
            )
        )
        .environmentObject(RevenueCatMonitor(state: .preview(false)))
    }
    .modelContainer(for: WaterPortion.self, inMemory: true)
}
