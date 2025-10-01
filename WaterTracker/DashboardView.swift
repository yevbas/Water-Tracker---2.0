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

    @AppStorage("water_goal_ml") private var waterGoalMl: Int = 2500
    @AppStorage("measurement_units") private var measurementUnits: String = "ml"

    var waterPortionsByDate: [WaterPortion] {
        guard let selectedDate else { return [] }
        return allWaterPortions.filter {
            let calendar = Calendar.current
            let startDate = calendar.startOfDay(for: selectedDate)
            let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)
            return $0.createDate >= startDate && $0.createDate < endDate!
        }
    }

    @EnvironmentObject var revenueCatMonitor: RevenueCatMonitor

    @State var selectedDate: Date? = Date().rounded()
    @State var editingWaterPortion: WaterPortion?
    @State var isPresentedSchedule = false
    @State var isPresentedDrinkSelector = false
    @State var isPresentedImagePicker = false
    @State var selectedImage: UIImage?
    @State var isPresentedDrinkAnalysis = false

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
        .animation(.smooth, value: selectedDate)
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
                NavigationLink(destination: SettingsView.init) {
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
        .sheet(isPresented: $isPresentedImagePicker) {
            DrinkAnalysisView { drink, amount in
                saveDrink(drink, amount)
            }
            .presentationDetents([.medium])
        }
        .onChange(of: selectedImage) { _, newImage in
            if newImage != nil {
                isPresentedImagePicker = false
                isPresentedDrinkAnalysis = true
            }
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
                            if !revenueCatMonitor.userHasFullAccess {
                                buildAdBannerView(.mainScreen)
                                    .padding(.horizontal)
                            }
                            datePicker
                        }
                        HStack {
                            ZStack {
                                ProgressCircle(
                                    ringWidth: scrollOffset < scrollUpThreshold ? 22 : 12,
                                    percent: progressPercent,
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
        LazyVStack(spacing: 16, pinnedViews: []) {
            if waterPortionsByDate.isEmpty {
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
            }
            
            // Weather Card - Shows if cached data exists or if loading
            WeatherCardView(
                selectedDate: selectedDate!,
                isLoading: false
            )
        }
        .padding(.horizontal)
    }

    var circleInformationView: some View {
        VStack(spacing: 6) {
            Text(percentageDisplay)
                .font(.system(size: scrollOffset < scrollUpThreshold ? 44 : 22, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
            Text(consumedDisplay)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(goalDisplay)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(
            maxWidth: .infinity,
            alignment: scrollOffset >= scrollUpThreshold ? .leading : .center
        )
    }

    private var progressPercent: Double {
        let consumedMl = totalConsumedMl(for: selectedDate)
        let goalMl = Double(waterGoalMl)
        guard goalMl > 0 else { return 0 }
        return min(100, max(0, (consumedMl / goalMl) * 100))
    }

    private func totalConsumedMl(for date: Date?) -> Double {
        let items = waterPortionsByDate
        var sumMl: Double = 0
        for p in items {
            switch p.unit {
            case .millilitres:
                sumMl += p.amount
            case .ounces:
                sumMl += p.amount * 29.5735
            }
        }
        return sumMl
    }

    private var percentageDisplay: String {
        "\(Int(progressPercent.rounded()))%"
    }

    private var consumedDisplay: String {
        let consumedMl = totalConsumedMl(for: selectedDate)
        if measurementUnits == "fl_oz" {
            let oz = consumedMl / 29.5735
            return "\(Int(oz.rounded())) fl oz consumed"
        } else {
            return "\(Int(consumedMl.rounded())) ml consumed"
        }
    }

    private var goalDisplay: String {
        if measurementUnits == "fl_oz" {
            let oz = Double(waterGoalMl) / 29.5735
            return "Goal \(Int(oz.rounded())) fl oz"
        } else {
            return "Goal \(waterGoalMl) ml"
        }
    }

    var addDrinkButton: some View {
        Menu {
            Button(action: {
                isPresentedDrinkSelector = true
            }) {
                Label("Manual Input", systemImage: "hand.tap")
            }
            
            Button(action: {
                isPresentedImagePicker = true
            }) {
                Label("AI Photo Analysis", systemImage: "camera")
            }
        } label: {
            Image(systemName: "drop.circle.fill")
                .foregroundStyle(.blue)
                .font(.system(size: 74))
        }
    }

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
            .environmentObject(RevenueCatMonitor(state: .preview(true)))
    }
}


