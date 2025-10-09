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
    @State var formattedAmount: String = ""
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
        guard let amountValue = Double(amount) else { return "" }
        let amountMl = measurementUnits.toMilliliters(amountValue)
        let netAmountMl = amountMl * drink.hydrationFactor
        let netAmount = measurementUnits.fromMilliliters(netAmountMl)
        let unitString = measurementUnits.shortName
        
        if drink.hydrationFactor < 0 {
            return String(localized: "Dehydrates \(abs(netAmount).formatted(.number.precision(.fractionLength(1)))) \(unitString)")
        } else if drink.hydrationFactor < 1.0 {
            if drink == .coffee {
                return String(localized: "Mild diuretic: \(netAmount.formatted(.number.precision(.fractionLength(1)))) \(unitString) net")
            }
            return String(localized: "Net hydration: \(netAmount.formatted(.number.precision(.fractionLength(1)))) \(unitString)")
        } else {
            return String(localized: "Fully hydrating")
        }
    }
    
    private var caffeineContent: Double {
        guard let amountValue = Double(amount) else { return 0 }
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
            amount = String(Int(defaultAmount.rounded()))
            isFocused = true
        }
        .onChange(of: amount, initial: true) { oldValue, newValue in
            if let num = Double(newValue) {
                if num >= 10000 {
                    amount = "0"
                } else {
                    formattedAmount = num.formatted()
                }
            }
        }
    }

    var addDrinkButton: some View {
        Button(action: {
            if let amountValue = Double(amount) {
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
            Text(formattedAmount)
                .font(.system(size: 84, weight: .black, design: .rounded))
                .background {
                    TextField("", text: $amount)
                        .opacity(0)
                        .focused($isFocused)
                        .keyboardType(.numberPad)
                }
                .contentTransition(.numericText())
                .animation(.smooth, value: formattedAmount)
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
