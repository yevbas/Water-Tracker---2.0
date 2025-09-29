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

    var body: some View {
        VStack(spacing: 16) {
//            if modelContext.hasChanges {
//                Button("Discard changes") {
//                    modelContext.rollback()
//                }
//            }
            DatePicker(
                selection: .init(
                    get: { waterPortion.createDate },
                    set: { waterPortion.createDate = $0 }
                )
            ) {
                Text(verbatim: "")
            }
            .padding(16)
            .font(.title2.weight(.medium))

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
                createDate: Date()
            )
        )
    }
    .modelContainer(for: WaterPortion.self, inMemory: true)
}
