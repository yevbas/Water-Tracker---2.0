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

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.ultraThinMaterial)
            .overlay {
                HStack(spacing: 12) {
                    Text(waterPortion.drink.emoji)
                        .font(.largeTitle)
                    VStack(alignment: .leading) {
                        Text(waterPortion.drink.title)
                            .font(.headline)
                        Text("\(waterPortion.amount.formatted()) ml")
                            .font(.subheadline)
                    }
                    Spacer()
                }
                .padding(.leading, 16)
            }
            .overlay(alignment: .topTrailing, content: {
                Text(Date().formatted(date: .omitted, time: .shortened))
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
    WaterVGridItemView(waterPortion: .init(amount: 200, createDate: Date()))
}
