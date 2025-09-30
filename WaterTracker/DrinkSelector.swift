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
    @State var amount: String = "250"
    @FocusState var isFocused: Bool
    @State var formattedAmount: String = ""
    @State var drink: Drink = .water
    @StateObject private var rc = RevenueCatMonitor.shared
    @State private var isShowingPaywall: Bool = false
    @AppStorage("measurement_units") private var measurementUnitsString: String = "ml"
    
    private var measurementUnits: WaterUnit {
        get { WaterUnit.fromString(measurementUnitsString) }
        set { measurementUnitsString = newValue == .ounces ? "fl_oz" : "ml" }
    }

    var onDrinkSelected: (Drink, Double) -> Void = { _, _  in }

    var body: some View {
        VStack {
            Spacer()
//            if #available(iOS 26.0, *) {
//                amountInput
//                    .glassEffect()
//            } else {
                amountInput
                    .background {
                        Capsule()
                            .fill(.ultraThinMaterial)
                    }
//            }
            Spacer()
            HStack {
                Spacer()
                DrinkTypeSelector(drink: $drink)
                addDrinkButton
            }
            .padding(.horizontal, 12)
        }
        .onAppear {
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
            if let amount = Double(amount) {
                if rc.userHasFullAccess || drink == .water {
                    onDrinkSelected(drink, amount)
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
//                            .submitLabel(.done)
//                            .onSubmit {
                            // dismiss
//                            }
                }
                .contentTransition(.numericText())
                .animation(.smooth, value: formattedAmount)
            Text(measurementUnits.shortName)
                .font(.system(.largeTitle, design: .rounded, weight: .medium))
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    DrinkSelector()
}
