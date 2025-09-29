//
//  DrinkTypeSelector.swift
//  WaterTracker
//
//  Created by Jackson  on 18/09/2025.
//

import SwiftUI

struct DrinkTypeSelector: View {
    @Binding var drink: Drink

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 16) {
                ForEach(Drink.allCases, id: \.self) { drink in
//                    if #available(iOS 26.0, *) {
//                        buildDrinkButton(drink)
//                            .glassEffect(self.drink == drink ? .clear : .identity)
//                    } else {
                        buildDrinkButton(drink)
                            .background {
                                if self.drink == drink {
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                }
                            }
//                    }
                }
            }
        }
        .scrollIndicators(.hidden)
        .animation(.smooth, value: drink)
    }

    func buildDrinkButton(_ drink: Drink) -> some View {
        Button(action: {
            self.drink = drink
        }) {
            Text(drink.emoji)
                .font(.system(size: 44))
        }
        .frame(width: 64, height: 64)
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
