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
    @EnvironmentObject private var sleepService: SleepService
    @EnvironmentObject var revenueCatMonitor: RevenueCatMonitor
    @EnvironmentObject private var healthKitService: HealthKitService

    @AppStorage("water_goal_ml") private var waterGoalMl: Int = 2500
    @AppStorage("measurement_units") private var measurementUnits: String = "ml"
    @AppStorage("show_weather_card") private var showWeatherCard: Bool = true
    @AppStorage("show_sleep_card") private var showSleepCard: Bool = true
    @AppStorage("show_statistics_card") private var showStatisticsCard: Bool = true

    @State var waterPortions: [WaterPortion] = []
    @State var selectedDate: Date = Date().rounded()

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
//        .navigationTitle("Current's progress")
//        .toolbar {
//            ToolbarItem(placement: .topBarLeading) {
//                Button {
//                    isPresentedSchedule = true
//                } label: {
//                    Image(systemName: "clock")
//                }
//            }
//            ToolbarItem(placement: .topBarLeading) {
////                DatePicker("", selection: .constant(Date()))
//                DatePicker(
//                    "",
//                    selection: $selectedDate,
//                    displayedComponents: [.date]
//                )
//            }
//            ToolbarItem(placement: .topBarTrailing) {
//                NavigationLink(destination: SettingsView.init) {
//                    Image(systemName: "gear")
//                }
//            }
//        }
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
                saveDrink(drink, amount, date: Date())
            }
            .presentationDetents([.medium])
        }
        .onChange(of: selectedImage) { _, newImage in
            if newImage != nil {
                isPresentedImagePicker = false
                isPresentedDrinkAnalysis = true
            }
        }
        .onChange(of: selectedDate, initial: true) { _, newDate in
            fetchWaterPortions(
                by: newDate ?? Date().rounded()
            )
        }
    }

    var headerBackgroundView: some View {
        VStack {
            Rectangle()
                .fill(.background)
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
            if waterPortions.isEmpty {
                NoDrinksView()
            } else {
                LazyVGrid(
                    columns: [.init()],
                    spacing: 12
                ) {
                    ForEach(waterPortions) { waterPortion in
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
                }
            }

            if selectedDate.rounded() == Date().rounded() {
                // Weather Card - Shows if cached data exists or if loading and toggle is enabled
                if showWeatherCard {
                    WeatherCardView()
                        .environmentObject(revenueCatMonitor)
                        .id("weather-card")
                }

                // Sleep Card - Shows sleep analysis and hydration recommendations if toggle is enabled
                if showSleepCard {
                    SleepCardView(
                        isLoading: sleepService.isLoading
                    )
                    .environmentObject(revenueCatMonitor)
                    .id("sleep-card")
                }
                
                // Statistics Card - Shows quick stats and navigation to detailed statistics if toggle is enabled
                if showStatisticsCard {
                    StatisticsCard()
                        .environmentObject(revenueCatMonitor)
                        .id("statistics-card")
                }
            }

            Spacer(minLength: 500)
        }
        .padding(.horizontal)
    }

    var circleInformationView: some View {
        VStack(spacing: scrollOffset >= scrollUpThreshold ? 3 : 6) {
            Text(percentageDisplay)
                .font(.system(size: scrollOffset < scrollUpThreshold ? 44 : 16, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
            
            // Improved hydration display with better visual hierarchy
            VStack(spacing: scrollOffset >= scrollUpThreshold ? 1 : 2) {
                Text(netHydrationDisplay)
                    .font(scrollOffset >= scrollUpThreshold ? .caption2.weight(.semibold) : .subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                
                if totalDehydrationMl(for: selectedDate) > 0 {
                    HStack(spacing: scrollOffset >= scrollUpThreshold ? 3 : 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text(dehydrationDisplay)
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                    .padding(.horizontal, scrollOffset >= scrollUpThreshold ? 6 : 8)
                    .padding(.vertical, scrollOffset >= scrollUpThreshold ? 1 : 2)
                    .background(
                        RoundedRectangle(cornerRadius: scrollOffset >= scrollUpThreshold ? 4 : 6)
                            .fill(.orange.opacity(0.1))
                    )
                }
                
                if totalCaffeineMg(for: selectedDate) > 0 {
                    HStack(spacing: scrollOffset >= scrollUpThreshold ? 3 : 4) {
                        Image(systemName: "bolt.fill")
                            .font(.caption2)
                            .foregroundStyle(.brown)
                        Text("\(Int(totalCaffeineMg(for: selectedDate).rounded())) mg caffeine")
                            .font(.caption2)
                            .foregroundStyle(.brown)
                    }
                    .padding(.horizontal, scrollOffset >= scrollUpThreshold ? 6 : 8)
                    .padding(.vertical, scrollOffset >= scrollUpThreshold ? 1 : 2)
                    .background(
                        RoundedRectangle(cornerRadius: scrollOffset >= scrollUpThreshold ? 4 : 6)
                            .fill(.brown.opacity(0.1))
                    )
                }
            }
            
            Text(goalDisplay)
                .font(scrollOffset >= scrollUpThreshold ? .caption2 : .caption)
                .foregroundStyle(.tertiary)
        }
        .frame(
            maxWidth: .infinity,
            alignment: scrollOffset >= scrollUpThreshold ? .leading : .center
        )
        .offset(x: scrollOffset >= scrollUpThreshold ? -16 : 0)
    }

    private var progressPercent: Double {
        let consumedMl = totalConsumedMl(for: selectedDate)
        let goalMl = Double(waterGoalMl)
        guard goalMl > 0 else { return 0 }
        return min(100, max(0, (consumedMl / goalMl) * 100))
    }

    private func totalConsumedMl(for date: Date?) -> Double {
        let items = waterPortions
        var sumMl: Double = 0
        for p in items {
            let amountInMl = switch p.unit {
            case .millilitres:
                p.amount
            case .ounces:
                p.amount * 29.5735
            }
            // Apply hydration factor to get net hydration
            sumMl += amountInMl * p.drink.hydrationFactor
        }
        return sumMl
    }
    
    private func totalRawConsumedMl(for date: Date?) -> Double {
        let items = waterPortions
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
    
    private func totalDehydrationMl(for date: Date?) -> Double {
        let items = waterPortions
        var dehydrationMl: Double = 0
        for p in items {
            let amountInMl = switch p.unit {
            case .millilitres:
                p.amount
            case .ounces:
                p.amount * 29.5735
            }
            // Only count negative hydration factors (dehydrating drinks)
            if p.drink.hydrationFactor < 0 {
                dehydrationMl += amountInMl * abs(p.drink.hydrationFactor)
            }
        }
        return dehydrationMl
    }
    
    private func totalCaffeineMg(for date: Date?) -> Double {
        let items = waterPortions
        var totalCaffeine: Double = 0
        for p in items {
            if p.drink.containsCaffeine {
                let amountInMl = switch p.unit {
                case .millilitres:
                    p.amount
                case .ounces:
                    p.amount * 29.5735
                }
                
                // Approximate caffeine content per 100ml for different drinks
                let caffeinePer100ml = switch p.drink {
                case .coffee: 40.0 // mg per 100ml
                case .coffeeWithMilk: 35.0 // slightly less due to milk
                case .tea: 20.0 // mg per 100ml
                case .energyShot: 320.0 // mg per 100ml (very high)
                default: 0.0
                }
                
                totalCaffeine += (amountInMl / 100.0) * caffeinePer100ml
            }
        }
        return totalCaffeine
    }

    private var percentageDisplay: String {
        "\(Int(progressPercent.rounded()))%"
    }

    private var netHydrationDisplay: String {
        let netHydrationMl = totalConsumedMl(for: selectedDate)
        let rawConsumedMl = totalRawConsumedMl(for: selectedDate)
        
        if measurementUnits == "fl_oz" {
            let netOz = netHydrationMl / 29.5735
            let rawOz = rawConsumedMl / 29.5735
            return "\(Int(netOz.rounded())) fl oz net (\(Int(rawOz.rounded())) consumed)"
        } else {
            return "\(Int(netHydrationMl.rounded())) ml net (\(Int(rawConsumedMl.rounded())) consumed)"
        }
    }
    
    private var dehydrationDisplay: String {
        let dehydrationMl = totalDehydrationMl(for: selectedDate)
        
        if measurementUnits == "fl_oz" {
            let dehydrationOz = dehydrationMl / 29.5735
            return "\(Int(dehydrationOz.rounded())) fl oz dehydrated"
        } else {
            return "\(Int(dehydrationMl.rounded())) ml dehydrated"
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

    func saveDrink(_ drink: Drink, _ amount: Double, date: Date) {
        let waterPortion = WaterPortion(
            amount: amount,
            unit: .millilitres,
            drink: drink,
            createDate: date,
            dayDate: date.rounded()
        )
        modelContext.insert(waterPortion)
        try? modelContext.save()

        // Save to HealthKit based on drink type
        Task {
            // Save water intake for hydrating drinks
            if drink.hydrationCategory == .fullyHydrating || drink.hydrationCategory == .mildDiuretic || drink.hydrationCategory == .partiallyHydrating {
                await healthKitService.saveWaterIntake(
                    amount: amount * drink.hydrationFactor,
                    unit: WaterUnit.millilitres,
                    date: Date()
                )
            }
            
            // Save caffeine intake for caffeinated drinks
            if drink.containsCaffeine {
                await healthKitService.saveCaffeineIntake(
                    amount: amount,
                    unit: WaterUnit.millilitres,
                    date: Date()
                )
            }
            
            // Save alcohol intake for alcoholic drinks
            if drink.containsAlcohol {
                await healthKitService.saveAlcoholIntake(
                    amount: amount,
                    unit: WaterUnit.millilitres,
                    alcoholType: drink,
                    date: Date()
                )
            }
        }

        // fetch updated data
        fetchWaterPortions(by: selectedDate ?? Date().rounded())
    }

    func remove(_ waterPortion: WaterPortion) {
        modelContext.delete(waterPortion)
        try? modelContext.save()

        // fetch updated data
        fetchWaterPortions(by: selectedDate ?? Date().rounded())
    }

    func fetchWaterPortions(by selectedDate: Date) {
        let dayDate = selectedDate.rounded()
        let fetchDescriptor = FetchDescriptor<WaterPortion>(
            predicate: #Predicate { $0.dayDate == dayDate },
            sortBy: [.init(\WaterPortion.createDate, order: .reverse)]
        )
        do {
            waterPortions = try modelContext.fetch(fetchDescriptor)
        } catch {
            // catch errors
        }
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
            .modelContainer(for: [WaterPortion.self, WeatherAnalysisCache.self, SleepAnalysisCache.self], inMemory: true)
            .environmentObject(RevenueCatMonitor(state: .preview(true)))
            .environmentObject(WeatherService())
            .environmentObject(SleepService())
            .environmentObject(HealthKitService())
    }
}


