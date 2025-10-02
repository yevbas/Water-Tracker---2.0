//
//  DrinkTypeSelector.swift
//  WaterTracker
//
//  Created by Jackson  on 18/09/2025.
//

import SwiftUI
import RevenueCatUI

struct DrinkTypeSelector: View {
    @Binding var drink: Drink
    @EnvironmentObject private var rc: RevenueCatMonitor
    @State private var isShowingPaywall: Bool = false

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 20) {
                // Group drinks by hydration category
                ForEach(HydrationCategory.allCases, id: \.self) { category in
                    VStack(spacing: 8) {
                        Text(category.displayName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 12) {
                            ForEach(drinksForCategory(category), id: \.self) { drink in
                                buildDrinkButton(drink)
                                    .background {
                                        if self.drink == drink {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(.ultraThinMaterial)
                                        }
                                    }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .scrollIndicators(.hidden)
        .animation(.smooth, value: drink)
    }
    
    private func drinksForCategory(_ category: HydrationCategory) -> [Drink] {
        return Drink.allCases.filter { $0.hydrationCategory == category }
    }

    func buildDrinkButton(_ drink: Drink) -> some View {
        Button(action: {
            if rc.userHasFullAccess || drink == .water {
                self.drink = drink
            } else {
                isShowingPaywall = true
            }
        }) {
            VStack(spacing: 4) {
                Text(drink.emoji)
                    .font(.system(size: 44))
                Text(drink.title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(width: 80, height: 80)
        .sheet(isPresented: $isShowingPaywall) {
            PaywallView()
        }
//        .background {
//            if self.drink == drink {
//                if #available(iOS 26.0, *) {
//                    RoundedRectangle(cornerRadius: 16)
//                        .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 16))
//                        .transition(.blurReplace)
//                } else {
//                    RoundedRectangle(cornerRadius: 16)
//                        .fill(.ultraThinMaterial)
//                        .transition(.blurReplace)
//                }
//            }
//        }
    }

}

#Preview {
    @Previewable @State var drink: Drink = .water

    return DrinkTypeSelector(drink: $drink)
}
