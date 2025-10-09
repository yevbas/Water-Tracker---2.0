//
//  DrinkSelector.swift
//  WaterTracker
//
//  Created by Jackson  on 11/09/2025.
//

import SwiftUI
import RevenueCatUI

enum PortionSize: CaseIterable {
    case cup
    case glass
    case shot
    case litre
    case other
}

struct DrinkSelector: View {
    @Environment(\.dismiss) var dismiss
    @State var createDate = Date()
    @State var amount: String = ""
    @FocusState var isFocused: Bool
    @State var drink: Drink = .water
    @EnvironmentObject private var rc: RevenueCatMonitor
    @State private var isShowingPaywall: Bool = false
    @AppStorage("measurement_units") private var measurementUnitsString: String = "ml"
    
    private var measurementUnits: WaterUnit {
        get { WaterUnit.fromString(measurementUnitsString) }
        set { measurementUnitsString = newValue == .ounces ? "fl_oz" : "ml" }
    }

    var onDrinkSelected: (Drink, Double, Date) -> Void = { _, _, _  in }
    
    // Default amount in milliliters
    private let defaultAmountMl: Double = 250
    
    // MARK: - Hydration Effect Helpers
    
    private var hydrationEffectColor: Color {
        if drink.hydrationFactor < 0 {
            return .red
        } else if drink.hydrationFactor < 1.0 {
            // Special case for coffee (0.85) - show as blue-green
            if drink == .coffee {
                return .teal
            }
            return .orange
        } else {
            return .blue
        }
    }
    
    private var hydrationEffectText: String {
        // Replace comma with period for parsing
        let normalizedAmount = amount.replacingOccurrences(of: ",", with: ".")
        guard let amountValue = Double(normalizedAmount) else { return "" }
        let amountMl = measurementUnits.toMilliliters(amountValue)
        let netAmountMl = amountMl * drink.hydrationFactor
        let netAmount = measurementUnits.fromMilliliters(netAmountMl)
        let unitString = measurementUnits.shortName
        
        // Format based on unit - integers for ml, decimals for oz
        let netAmountFormatted = switch measurementUnits {
        case .millilitres:
            Int(netAmount.rounded()).formatted()
        case .ounces:
            netAmount.formatted(.number.precision(.fractionLength(0...1)))
        }
        
        if drink.hydrationFactor < 0 {
            return String(localized: "Dehydrates \(abs(netAmount).formatted(.number.precision(.fractionLength(measurementUnits == .ounces ? 1 : 0)))) \(unitString)")
        } else if drink.hydrationFactor < 1.0 {
            if drink == .coffee {
                return String(localized: "Mild diuretic: \(netAmountFormatted) \(unitString) net")
            }
            return String(localized: "Net hydration: \(netAmountFormatted) \(unitString)")
        } else {
            return String(localized: "Fully hydrating")
        }
    }
    
    private var caffeineContent: Double {
        // Replace comma with period for parsing
        let normalizedAmount = amount.replacingOccurrences(of: ",", with: ".")
        guard let amountValue = Double(normalizedAmount) else { return 0 }
        let amountMl = measurementUnits.toMilliliters(amountValue)
        
        // Approximate caffeine content per 100ml for different drinks
        let caffeinePer100ml = switch drink {
        case .coffee: 40.0 // mg per 100ml
        case .coffeeWithMilk: 35.0 // slightly less due to milk
        case .tea: 20.0 // mg per 100ml
        case .energyShot: 320.0 // mg per 100ml (very high)
        default: 0.0
        }
        
        return (amountMl / 100.0) * caffeinePer100ml
    }
    
    private var caffeineDisplay: String {
        let caffeine = caffeineContent
        if caffeine > 0 {
            return String(localized: "\(Int(caffeine.rounded())) mg caffeine")
        }
        return ""
    }

    var body: some View {
        VStack {
            if !rc.userHasFullAccess {
                buildAdBannerView(.createScreen)
                    .padding()
            }
            DatePicker(selection: $createDate, displayedComponents: [.hourAndMinute]) {
                Text(verbatim: "")
            }
            .font(.title2.weight(.medium))
            .padding()
            Spacer()
            amountInput
                .background {
                    Capsule()
                        .fill(.ultraThinMaterial)
                }
            
            // Hydration effect info
            if drink.hydrationFactor != 1.0 || drink.containsCaffeine {
                hydrationInfoView
                    .padding(.top, 8)
            }
            
            Spacer()
            HStack {
                Spacer()
                DrinkTypeSelector(drink: $drink)
                addDrinkButton
            }
            .padding(.horizontal, 12)
        }
        .onAppear {
            // Set default amount based on measurement unit
            let defaultAmount = switch measurementUnits {
            case .millilitres: 
                defaultAmountMl
            case .ounces:
                measurementUnits.fromMilliliters(defaultAmountMl)
            }
            
            // Format based on unit - integers for ml, decimals for oz
            amount = switch measurementUnits {
            case .millilitres:
                String(Int(defaultAmount.rounded()))
            case .ounces:
                String(format: "%.1f", defaultAmount)
            }
            isFocused = true
        }
        .onChange(of: amount, initial: false) { oldValue, newValue in
            // Validate input - replace comma with period for parsing
            let normalizedValue = newValue.replacingOccurrences(of: ",", with: ".")
            
            // Check if it's a valid number
            if !newValue.isEmpty {
                if let num = Double(normalizedValue) {
                    // Prevent values that are too large
                    if num >= 10000 {
                        amount = oldValue
                    }
                } else {
                    // Invalid number, revert to old value
                    amount = oldValue
                }
            }
        }
    }

    var addDrinkButton: some View {
        Button(action: {
            // Replace comma with period for parsing
            let normalizedAmount = amount.replacingOccurrences(of: ",", with: ".")
            if let amountValue = Double(normalizedAmount) {
                // Convert to milliliters if needed
                let amountInMl = measurementUnits.toMilliliters(amountValue)
                
                
                if rc.userHasFullAccess || drink == .water {
                    onDrinkSelected(drink, amountInMl, createDate)
                    dismiss()
                } else {
                    isShowingPaywall = true
                }
            }
        }) {
            Image(systemName: "drop.circle.fill")
                .foregroundStyle(.blue)
                .font(.system(size: 74))
        }
        .sheet(isPresented: $isShowingPaywall) {
            PaywallView()
        }
    }

    var amountInput: some View {
        HStack(spacing: 8) {
            Text(amount.isEmpty ? "0" : amount)
                .font(.system(size: 84, weight: .black, design: .rounded))
                .background {
                    TextField("", text: $amount)
                        .opacity(0)
                        .focused($isFocused)
                        .keyboardType(measurementUnits == .ounces ? .decimalPad : .numberPad)
                }
                .contentTransition(.numericText())
                .animation(.smooth, value: amount)
            Text(measurementUnits.shortName)
                .font(.system(.largeTitle, design: .rounded, weight: .medium))
        }
        .padding(.horizontal, 24)
    }
    
    var hydrationInfoView: some View {
        VStack(spacing: 6) {
            if drink.hydrationFactor != 1.0 {
                HStack(spacing: 6) {
                    Image(systemName: "drop.fill")
                        .font(.caption)
                        .foregroundStyle(hydrationEffectColor)
                    Text(hydrationEffectText)
                        .font(.callout)
                        .foregroundStyle(hydrationEffectColor)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background {
                    Capsule()
                        .fill(hydrationEffectColor.opacity(0.15))
                }
            }
            
            if drink.containsCaffeine && caffeineContent > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.caption)
                        .foregroundStyle(.brown)
                    Text(caffeineDisplay)
                        .font(.callout)
                        .foregroundStyle(.brown)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background {
                    Capsule()
                        .fill(.brown.opacity(0.15))
                }
            }
        }
        .animation(.smooth, value: drink)
        .animation(.smooth, value: amount)
    }
}

#Preview {
    DrinkSelector()
}
