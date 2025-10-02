//
//  EditWaterPortionView.swift
//  WaterTracker
//
//  Created by Jackson  on 29/09/2025.
//

import SwiftUI
import SwiftData

struct EditWaterPortionView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @State var waterPortion: WaterPortion

    @EnvironmentObject var revenueCatMonitor: RevenueCatMonitor

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 16) {
                if !revenueCatMonitor.userHasFullAccess {
                    buildAdBannerView(.editScreen)
                        .padding(.horizontal)
                }
                DatePicker(
                    selection: .init(
                        get: { waterPortion.createDate },
                        set: { waterPortion.createDate = $0 }
                    )
                ) {
                    Text(verbatim: "")
                }
                .font(.title2.weight(.medium))
            }
            .padding(16)

            DrinkSelector(
                amount: waterPortion.amount.description,
                drink: waterPortion.drink
            ) { newDrink, newAmount in
                waterPortion.drink = newDrink
                waterPortion.amount = newAmount
                saveChanges()
            }
            Spacer()
        }
    }

    func saveChanges() {
        try? modelContext.save()

        dismiss()
    }

}

#Preview {
    NavigationStack {
        EditWaterPortionView(
            waterPortion: .init(
                amount: 2200,
                drink: .coffee,
                createDate: Date(),
                dayDate: Date().rounded()
            )
        )
        .environmentObject(RevenueCatMonitor(state: .preview(false)))
    }
    .modelContainer(for: WaterPortion.self, inMemory: true)
}
