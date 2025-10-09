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
    @AppStorage("measurement_units") private var measurementUnits: String = "ml"

    var waterPortion: WaterPortion

    var amount: Double {
        let unit = WaterUnit.fromString(measurementUnits)

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
        let netAmount = waterPortion.amount * waterPortion.drink.hydrationFactor
        if waterPortion.drink.hydrationFactor < 0 {
            return String(localized: "Dehydrates \(abs(netAmount).formatted()) ml")
        } else if waterPortion.drink.hydrationFactor < 1.0 {
            if waterPortion.drink == .coffee {
                return String(localized: "Mild diuretic: \(netAmount.formatted()) ml net")
            }
            return String(localized: "Net hydration: \(netAmount.formatted()) ml")
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

                HStack {
                    Text("\(amount.formatted(.number.precision(.fractionLength(1)))) \(measurementUnits)")
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

                    if waterPortion.drink.containsCaffeine && caffeineContent > 0 {
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
