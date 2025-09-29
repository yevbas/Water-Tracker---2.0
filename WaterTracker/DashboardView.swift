//
//  WaterDashboardView.swift
//  WaterTracker
//
//  Created by Jackson  on 08/09/2025.
//

import Foundation
import SwiftUI
import Charts
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) var modelContext

    @Query(sort: [.init(\WaterPortion.createDate, order: .reverse)], animation: .linear)
    var allWaterPortions: [WaterPortion]

    var waterPortionsByDate: [WaterPortion] {
        guard let selectedDate else { return [] }
        return allWaterPortions.filter {
            let calendar = Calendar.current
            let startDate = calendar.startOfDay(for: selectedDate)
            let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)
            return $0.createDate >= startDate && $0.createDate < endDate!
        }
    }

    @State var selectedDate: Date? = Date().rounded()
    @State var editingWaterPortion: WaterPortion?
    @State var isPresentedSchedule = false
    @State var isPresentedDrinkSelector = false

    // MARK: - Scroll Animation

    @State var scrollOffset = CGFloat.zero
    @State var screenHeight = CGFloat.zero
    @State var maxScrollHeight = CGFloat.zero

    let maxHeaderHeight: CGFloat = 375
    let minHeaderHeight: CGFloat = 95

    let maxContentOffset: CGFloat = 95
    let scrollUpThreshold: CGFloat = 105

    var contentYOffset: CGFloat {
        if scrollOffset >= scrollUpThreshold {
            return maxContentOffset
        } else {
            return maxHeaderHeight - scrollOffset
        }
    }

    var headerHeight: CGFloat {
        if scrollOffset == 0 {
            return maxHeaderHeight
        } else if scrollOffset < 0 {
            return maxHeaderHeight + (-1 * scrollOffset * 1.5)
        } else if scrollOffset >= scrollUpThreshold {
            return minHeaderHeight
        } else {
            return maxHeaderHeight - scrollOffset
        }
    }

    var headerOffset: CGFloat {
        if scrollOffset >= scrollUpThreshold {
            return minHeaderHeight
        } else {
            return maxHeaderHeight / -2
        }
    }

    // MARK: - View

    var body: some View {
        ZStack {
            headerBackgroundView
            ScrollView {
                contentBackgroundView
                //                    .background(.cyan)
                    .background(GeometryReader { scrollProxy in
                        Color.clear.onAppear {
                            maxScrollHeight = scrollProxy.size.height
                        }
                    })
                    .background(GeometryReader {
                        Color.clear.preference(
                            key: ViewOffsetKey.self,
                            value: -$0.frame(in: .named("scroll")).origin.y
                        )
                    })
                    .onPreferenceChange(ViewOffsetKey.self) {
                        scrollOffset = $0
                    }
                Spacer(minLength: 200)
            }
            .coordinateSpace(name: "scroll")
            .offset(y: contentYOffset)
            .scrollIndicators(.hidden)
            .zIndex(1)
        }
        .background(GeometryReader { proxy in
            Color.clear.onAppear {
                screenHeight = proxy.size.height
            }
        })
        .animation(.linear, value: contentYOffset)
        .overlay(alignment: .bottomTrailing) {
            addDrinkButton
                .padding(.trailing, 8)
        }
//        .onAppear {
//            seedTestData()
//        }
        .navigationTitle("Current's progress")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    isPresentedSchedule = true
                } label: {
                    Image(systemName: "clock")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {

                } label: {
                    Image(systemName: "gear")
                }
            }
        }
        .sheet(isPresented: $isPresentedSchedule) {
            ScheduleView()
        }
        .sheet(isPresented: $isPresentedDrinkSelector) {
            DrinkSelector(onDrinkSelected: saveDrink)
        }
        .sheet(item: $editingWaterPortion) { waterPortion in
            EditWaterPortionView(waterPortion: waterPortion)
        }
    }

    var headerBackgroundView: some View {
        VStack {
            Rectangle()
                .fill(.white)
                .frame(height: headerHeight)
                .overlay {
                    VStack {
                        if scrollOffset < scrollUpThreshold {
                            datePicker
                        }
                        HStack {
                            ZStack {
                                ProgressCircle(
                                    ringWidth: scrollOffset < scrollUpThreshold ? 22 : 12,
                                    percent: 50,
                                    foregroundColors: [.blue.opacity(0.55), .blue]
                                )
                                .overlay {
                                    if scrollOffset < scrollUpThreshold {
                                        circleInformationView
                                            .transition(.move(edge: .leading).combined(with: .blurReplace))
                                    }
                                }
                                .padding(.horizontal, scrollOffset < scrollUpThreshold ? 16 : 0)
                                .padding(.top, 4)
                                .padding(.bottom, 12)
                                //                            if scrollOffset < scrollUpThreshold {
                                //                                Chart(waterPortions) {
                                //                                    SectorMark(
                                //                                        angle: .value("Portion Size", $0.amount),
                                //                                        innerRadius: .ratio(0.925),
                                //                                        angularInset: 2.5
                                //                                    )
                                //                                    .cornerRadius(8)
                                //                                    .foregroundStyle(by: .value("Drink", $0.drink.rawValue))
                                //                                }
                                //                                .chartLegend(.hidden)
                                //                                .animation(.easeInOut, value: scrollOffset)
                                //                                .padding(40)
                                //                                .transition(.blurReplace.combined(with: .move(edge: .leading)))
                                //                            }
                            }
                            if scrollOffset >= scrollUpThreshold {
                                circleInformationView
                                    .transition(.asymmetric(insertion: .push(from: .trailing), removal: .move(edge: .trailing)))
                            }
                        }
                    }
                }
                .zIndex(0)
            Spacer()
        }

    }

    var datePicker: some View {
        CustomDatePicker(selectedDate: $selectedDate)
    }

    @ViewBuilder
    var contentBackgroundView: some View {
        if allWaterPortions.isEmpty {
            NoDrinksView()
        } else {
            LazyVGrid(
                columns: [.init()],
                spacing: 12
            ) {
                ForEach(waterPortionsByDate) { waterPortion in
                    WaterVGridItemView(waterPortion: waterPortion)
                        .onTapGesture {
                            editingWaterPortion = waterPortion
                        }
                        .contextMenu {
                            Button.init(action: {
                                editingWaterPortion = waterPortion
                            }) {
                                Label("Change", systemImage: "pencil")
                            }
                            Button(role: .destructive, action: {
                                remove(waterPortion)
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                .animation(.smooth, value: allWaterPortions)
            }
            .padding(.horizontal)
        }
    }

    var circleInformationView: some View {
        VStack {
            Group {
                Text("50%")
                Text("Subtitle 2")
                Text("Subtitle 3")
            }
            .frame(
                maxWidth: .infinity,
                alignment: scrollOffset >= scrollUpThreshold ? .leading : .center
            )
        }
    }

    var addDrinkButton: some View {
        Button(action: {
            isPresentedDrinkSelector = true
        }) {
            Image(systemName: "drop.circle.fill")
                .foregroundStyle(.blue)
                .font(.system(size: 74))
        }
    }

//    private func seedTestData() {
//        if !waterPortions.isEmpty { return }
//        let samples = [
//            WaterPortion(amount: 200, createDate: Date()),
//            WaterPortion(amount: 400, drink: .soda, createDate: Date()),
//            WaterPortion(amount: 200, createDate: Date()),
//            WaterPortion(amount: 400, drink: .coffee, createDate: Date()),
//            WaterPortion(amount: 200, createDate: Date()),
//            WaterPortion(amount: 400, drink: .juice, createDate: Date()),
//            WaterPortion(amount: 200, createDate: Date()),
//            WaterPortion(amount: 400, drink: .milk, createDate: Date()),
//            WaterPortion(amount: 400, drink: .milk, createDate: Date()),
//            WaterPortion(amount: 400, drink: .milk, createDate: Date()),
//            WaterPortion(amount: 400, drink: .milk, createDate: Date()),
//            WaterPortion(amount: 400, drink: .milk, createDate: Date()),
//            WaterPortion(amount: 400, drink: .milk, createDate: Date()),
//            WaterPortion(amount: 400, drink: .milk, createDate: Date()),
//            WaterPortion(amount: 400, drink: .milk, createDate: Date()),
//            WaterPortion(amount: 400, drink: .milk, createDate: Date()),
//            WaterPortion(amount: 400, drink: .milk, createDate: Date()),
//            WaterPortion(amount: 400, drink: .milk, createDate: Date()),
//            WaterPortion(amount: 400, drink: .milk, createDate: Date()),
//        ]
//        for s in samples { modelContext.insert(s) }
//        try? modelContext.save()
//    }

    func saveDrink(_ drink: Drink, _ amount: Double) {
        let waterPortion = WaterPortion(
            amount: amount,
            unit: .millilitres,
            drink: drink,
            createDate: Date()
        )
        modelContext.insert(waterPortion)
        try? modelContext.save()
    }

    func remove(_ waterPortion: WaterPortion) {
        modelContext.delete(waterPortion)
        try? modelContext.save()
    }

}

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

#Preview {
    NavigationStack {
        DashboardView()
            .modelContainer(for: WaterPortion.self, inMemory: true)
    }
}
