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
    @AppStorage("measurement_units") private var measurementUnitsString: String = "ml"
    
    // Store original values for HealthKit updates (amount is in millilitres)
    @State private var originalAmount: Double
    @State private var originalDrink: Drink
    @State private var originalDate: Date

    @EnvironmentObject var revenueCatMonitor: RevenueCatMonitor
    @StateObject private var healthKitService = HealthKitService()
    
    init(waterPortion: WaterPortion) {
        self._waterPortion = State(initialValue: waterPortion)
        self._originalAmount = State(initialValue: waterPortion.amount)
        self._originalDrink = State(initialValue: waterPortion.drink)
        self._originalDate = State(initialValue: waterPortion.createDate)
    }

    var body: some View {
        let unit = WaterUnit.fromString(measurementUnitsString)
        let displayAmount = unit.fromMilliliters(waterPortion.amount)
        
        DrinkSelector(
            createDate: waterPortion.createDate,
            amount: String(format: "%.1f", displayAmount),
            drink: waterPortion.drink
        ) { newDrink, newAmount, newTime in
            waterPortion.drink = newDrink
            waterPortion.createDate = newTime
            
            // Only convert and update amount if it actually changed
            let currentUnit = WaterUnit.fromString(measurementUnitsString)
            let newAmountInMl = currentUnit.toMilliliters(newAmount)
            
            // Only update if the amount actually changed (with tolerance for precision errors)
            // Use a larger tolerance to account for floating point precision issues
            if abs(waterPortion.amount - newAmountInMl) > 1.0 {
                waterPortion.amount = newAmountInMl
            }

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
        // Check if any values have changed (amounts are in millilitres)
        let hasChanges = originalAmount != waterPortion.amount ||
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
            
            if oldWaterAmount != newWaterAmount || originalDate != waterPortion.createDate {
                // Both amounts are in millilitres, so we pass .millilitres as unit
                await healthKitService.updateWaterIntakeRecord(
                    oldAmount: oldWaterAmount,
                    oldUnit: .millilitres,
                    newAmount: newWaterAmount,
                    newUnit: .millilitres,
                    oldDate: originalDate,
                    newDate: waterPortion.createDate
                )
            }
        }
        
        // Update caffeine intake if the drink contains caffeine
        if originalDrink.containsCaffeine || waterPortion.drink.containsCaffeine {
            // Both amounts are in millilitres, so we pass .millilitres as unit
            await healthKitService.updateCaffeineIntakeRecord(
                oldAmount: originalAmount,
                oldUnit: .millilitres,
                newAmount: waterPortion.amount,
                newUnit: .millilitres,
                oldDate: originalDate,
                newDate: waterPortion.createDate
            )
        }
        
        // Update alcohol intake if the drink contains alcohol
        if originalDrink.containsAlcohol || waterPortion.drink.containsAlcohol {
            // Both amounts are in millilitres, so we pass .millilitres as unit
            await healthKitService.updateAlcoholIntakeRecord(
                oldAmount: originalAmount,
                oldUnit: .millilitres,
                oldAlcoholType: originalDrink,
                newAmount: waterPortion.amount,
                newUnit: .millilitres,
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
