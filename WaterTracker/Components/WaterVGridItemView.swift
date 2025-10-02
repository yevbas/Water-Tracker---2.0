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
    var waterPortion: WaterPortion
    
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
            return "Dehydrates \(abs(netAmount).formatted()) ml"
        } else if waterPortion.drink.hydrationFactor < 1.0 {
            if waterPortion.drink == .coffee {
                return "Mild diuretic: \(netAmount.formatted()) ml net"
            }
            return "Net hydration: \(netAmount.formatted()) ml"
        } else {
            return "Fully hydrating"
        }
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.ultraThinMaterial)
            .overlay {
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
                            Text("\(waterPortion.amount.formatted()) ml")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        
                        if waterPortion.drink.hydrationFactor != 1.0 {
                            HStack {
                                Text(hydrationEffectText)
                                    .font(.caption)
                                    .foregroundStyle(hydrationEffectColor)
                                Spacer()
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .overlay(alignment: .topTrailing, content: {
                Text(waterPortion.createDate.formatted(date: .omitted, time: .shortened))
                    .padding()
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            })
            .frame(height: 75)
    }
}

#Preview {
//    NavigationStack {
//        DashboardView()
//            .modelContainer(for: WaterPortion.self, inMemory: true)
//    }
    WaterVGridItemView(waterPortion: .init(amount: 200, createDate: Date(), dayDate: Date().rounded()))
}
