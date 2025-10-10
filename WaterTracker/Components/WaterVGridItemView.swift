//
//  WaterVGridItemView.swift
//  WaterTracker
//
//  Created by Jackson  on 29/09/2025.
//

import Foundation
import SwiftUI
import Charts
import SwiftData

struct WaterVGridItemView: View {
    @AppStorage("measurement_units") private var measurementUnitsString: String = "ml"
    @AppStorage("show_calories") private var showCalories: Bool = true
    @AppStorage("show_sugars") private var showSugars: Bool = true
    @AppStorage("show_caffeine") private var showCaffeine: Bool = true

    var waterPortion: WaterPortion

    var amount: Double {
        let unit = WaterUnit.fromString(measurementUnitsString)
        
        // waterPortion.amount is ALWAYS stored in milliliters
        // We just need to convert it to display units
        return switch unit {
        case .ounces: WaterUnit.ounces.fromMilliliters(waterPortion.amount)
        case .millilitres: waterPortion.amount
        }
    }

    private var hydrationEffectColor: Color {
        if waterPortion.drink.hydrationFactor < 0 {
            return .red
        } else if waterPortion.drink.hydrationFactor < 1.0 {
            // Special case for coffee (0.85) - show as blue-green
            if waterPortion.drink == .coffee {
                return .teal
            }
            return .orange
        } else {
            return .blue
        }
    }
    
    private var hydrationEffectText: String {
        let netAmountMl = waterPortion.amount * waterPortion.drink.hydrationFactor
        let unit = WaterUnit.fromString(measurementUnitsString)
        let netAmount = switch unit {
        case .ounces: WaterUnit.ounces.fromMilliliters(netAmountMl)
        case .millilitres: netAmountMl
        }
        let unitString = unit.shortName
        
        if waterPortion.drink.hydrationFactor < 0 {
            return String(localized: "Dehydrates \(abs(netAmount).formatted(.number.precision(.fractionLength(1)))) \(unitString)")
        } else if waterPortion.drink.hydrationFactor < 1.0 {
            if waterPortion.drink == .coffee {
                return String(localized: "Mild diuretic: \(netAmount.formatted(.number.precision(.fractionLength(1)))) \(unitString) net")
            }
            return String(localized: "Net hydration: \(netAmount.formatted(.number.precision(.fractionLength(1)))) \(unitString)")
        } else {
            return String(localized: "Fully hydrating")
        }
    }
    
    private var caffeineContent: Double {
        // Approximate caffeine content per 100ml for different drinks
        let caffeinePer100ml = switch waterPortion.drink {
        case .coffee: 40.0 // mg per 100ml
        case .coffeeWithMilk: 35.0 // slightly less due to milk
        case .tea: 20.0 // mg per 100ml
        case .energyShot: 320.0 // mg per 100ml (very high)
        default: 0.0
        }
        
        return (waterPortion.amount / 100.0) * caffeinePer100ml
    }
    
    private var caffeineDisplay: String {
        let caffeine = caffeineContent
        if caffeine > 0 {
            return String(localized: "\(Int(caffeine.rounded())) mg caffeine")
        }
        return ""
    }
    
    private var calorieContent: Double {
        return (waterPortion.amount / 100.0) * waterPortion.drink.caloriesPer100ml
    }
    
    private var sugarContent: Double {
        return (waterPortion.amount / 100.0) * waterPortion.drink.sugarsPer100ml
    }
    
    private var calorieDisplay: String {
        let calories = calorieContent
        if calories > 0 {
            return String(localized: "\(Int(calories.rounded())) cal")
        }
        return ""
    }
    
    private var sugarDisplay: String {
        let sugars = sugarContent
        if sugars > 0 {
            return String(localized: "\(sugars.formatted(.number.precision(.fractionLength(0...1)))) g sugar")
        }
        return ""
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(waterPortion.drink.emoji)
                .font(.largeTitle)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(waterPortion.drink.title)
                        .font(.headline)
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("\(amount.formatted(.number.precision(.fractionLength(1)))) \(WaterUnit.fromString(measurementUnitsString).shortName)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        if waterPortion.drink.hydrationFactor != 1.0 {
                            HStack {
                                Text(hydrationEffectText)
                                    .font(.caption)
                                    .foregroundStyle(hydrationEffectColor)
                                Spacer()
                            }
                        }

                        if showCaffeine && waterPortion.drink.containsCaffeine && caffeineContent > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "bolt.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.brown)
                                Text(caffeineDisplay)
                                    .font(.caption)
                                    .foregroundStyle(.brown)
                                Spacer()
                            }
                        }

                        if waterPortion.drink.hasNutritionalInfo {
                            HStack(spacing: 6) {
                                if showCalories && calorieContent > 0 {
                                    HStack(spacing: 4) {
                                        Image(systemName: "flame.fill")
                                            .font(.caption2)
                                            .foregroundStyle(.orange)
                                        Text(calorieDisplay)
                                            .font(.caption)
                                            .foregroundStyle(.orange)
                                    }
                                }

                                if showSugars && sugarContent > 0 {
                                    HStack(spacing: 4) {
                                        Image(systemName: "cube.fill")
                                            .font(.caption2)
                                            .foregroundStyle(.pink)
                                        Text(sugarDisplay)
                                            .font(.caption)
                                            .foregroundStyle(.pink)
                                    }
                                }
                                Spacer()
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
        .overlay(alignment: .topTrailing, content: {
            Text(waterPortion.createDate.formatted(date: .omitted, time: .shortened))
                .padding()
                .font(.footnote)
                .foregroundStyle(.secondary)
        })
    }
}

#Preview {
    let container = try! ModelContainer(for: WaterProgress.self, WaterPortion.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let context = container.mainContext
    
    let progress = WaterProgress(date: Date().rounded(), goalMl: 2500)
    context.insert(progress)
    
    let portion = WaterPortion(
        amount: 200,
        drink: .water,
        createDate: Date(),
        waterProgress: progress
    )
    context.insert(portion)
    
    return WaterVGridItemView(waterPortion: portion)
}
