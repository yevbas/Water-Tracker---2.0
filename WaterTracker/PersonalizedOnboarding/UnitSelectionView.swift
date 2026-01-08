//
//  UnitSelectionView.swift
//  WaterTracker
//
//  Created by Assistant on 29/09/2025.
//

import SwiftUI

struct UnitSelectionView: View {
    @State private var selectedUnit: WaterUnit = .millilitres
    let onContinue: (WaterUnit) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Image(systemName: "ruler")
                        .font(.system(size: 52, weight: .bold))
                        .foregroundStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))

                    if #available(iOS 17.0, *) {
                        (Text("Select ") + Text(" measurement system").foregroundStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)))
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    } else {
                        Text("Select measurement system")
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Text("This will be used throughout the app for all water measurements")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                VStack(spacing: 16) {
                    ForEach(WaterUnit.allCases, id: \.self) { unit in
                        UnitSelectionCard(
                            unit: unit,
                            isSelected: selectedUnit == unit,
                            onTap: { selectedUnit = unit }
                        )
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(
                title: String(localized: "Continue"),
                colors: [.blue, .cyan]
            ) {
                onContinue(selectedUnit)
            }
            .padding(.horizontal, 24)
            .shimmer()
        }
    }
}

struct UnitSelectionCard: View {
    let unit: WaterUnit
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(unit.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(unitDescription(for: unit))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? .blue : .secondary)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? .blue : .clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func unitDescription(for unit: WaterUnit) -> String {
        switch unit {
        case .millilitres:
            return String(localized: "Metric system - commonly used worldwide")
        case .ounces:
            return String(localized: "Imperial system - commonly used in the US")
        }
    }
}

#Preview {
    UnitSelectionView { unit in
        print("Selected unit: \(unit)")
    }
}
