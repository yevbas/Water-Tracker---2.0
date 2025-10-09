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
    // MARK: - Environment & Storage

    @Environment(\.modelContext) var modelContext
    @EnvironmentObject private var sleepService: SleepService
    @EnvironmentObject var revenueCatMonitor: RevenueCatMonitor
    @EnvironmentObject private var healthKitService: HealthKitService

    @AppStorage("water_goal_ml") private var waterGoalMl: Int = 2500
    @AppStorage("measurement_units") private var measurementUnits: String = "ml"
    @AppStorage("show_weather_card") private var showWeatherCard: Bool = true
    @AppStorage("show_sleep_card") private var showSleepCard: Bool = true
    @AppStorage("show_statistics_card") private var showStatisticsCard: Bool = true

    // MARK: - State Properties

    @State var waterPortions: [WaterPortion] = []
    @State var selectedDate: Date = Date().rounded()
    @State var editingWaterPortion: WaterPortion?
    @State var isPresentedSchedule = false
    @State var isPresentedDrinkSelector = false
    @State var isPresentedImagePicker = false
    @State var selectedImage: UIImage?
    @State var isPresentedDrinkAnalysis = false

    // MARK: - Scroll Animation Properties

    @State var scrollOffset = CGFloat.zero
    @State var screenHeight = CGFloat.zero
    @State var maxScrollHeight = CGFloat.zero

    // MARK: - Animation Constants

    private enum AnimationConstants {
        static let maxHeaderHeight: CGFloat = 375
        static let minHeaderHeight: CGFloat = 95
        static let maxContentOffset: CGFloat = 95
        static let scrollUpThreshold: CGFloat = 105
        static let overscrollMultiplier: CGFloat = 1.5
        static let collapsedRingWidth: CGFloat = 12
        static let expandedRingWidth: CGFloat = 22
    }


    private enum CaffeineContent {
        static let coffeePer100ml: Double = 40.0
        static let coffeeWithMilkPer100ml: Double = 35.0
        static let teaPer100ml: Double = 20.0
        static let energyShotPer100ml: Double = 320.0
    }

    // MARK: - Computed Scroll Properties

    var contentYOffset: CGFloat {
        scrollOffset >= AnimationConstants.scrollUpThreshold
            ? AnimationConstants.maxContentOffset
            : AnimationConstants.maxHeaderHeight - scrollOffset
    }

    var headerHeight: CGFloat {
        switch scrollOffset {
        case 0:
            return AnimationConstants.maxHeaderHeight
        case ..<0:
            return AnimationConstants.maxHeaderHeight + (-scrollOffset * AnimationConstants.overscrollMultiplier)
        case AnimationConstants.scrollUpThreshold...:
            return AnimationConstants.minHeaderHeight
        default:
            return AnimationConstants.maxHeaderHeight - scrollOffset
        }
    }

    var headerOffset: CGFloat {
        scrollOffset >= AnimationConstants.scrollUpThreshold
            ? AnimationConstants.minHeaderHeight
            : AnimationConstants.maxHeaderHeight / -2
    }

    private var isHeaderCollapsed: Bool {
        scrollOffset >= AnimationConstants.scrollUpThreshold
    }

    // MARK: - View

    var body: some View {
        ZStack {
            headerBackgroundView
            scrollableContent
        }
        .background(screenHeightReader)
        .animation(.linear, value: contentYOffset)
        .overlay(alignment: .bottomTrailing) {
            addDrinkButton
                .padding(.trailing, 8)
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
            fetchWaterPortions(by: newDate ?? Date().rounded())
        }
    }

    // MARK: - Header View

    private var scrollableContent: some View {
        ScrollView {
            contentBackgroundView
                .background(scrollHeightReader)
                .background(scrollOffsetReader)
                .onPreferenceChange(ViewOffsetKey.self) {
                    scrollOffset = $0
                }
        }
        .coordinateSpace(name: "scroll")
        .offset(y: contentYOffset)
        .scrollIndicators(.hidden)
        .zIndex(1)
    }

    private var screenHeightReader: some View {
        GeometryReader { proxy in
            Color.clear.onAppear {
                screenHeight = proxy.size.height
            }
        }
    }

    private var scrollHeightReader: some View {
        GeometryReader { scrollProxy in
            Color.clear.onAppear {
                maxScrollHeight = scrollProxy.size.height
            }
        }
    }

    private var scrollOffsetReader: some View {
        GeometryReader { proxy in
            Color.clear.preference(
                key: ViewOffsetKey.self,
                value: -proxy.frame(in: .named("scroll")).origin.y
            )
        }
    }

    var headerBackgroundView: some View {
        VStack {
            Rectangle()
                .fill(.background)
                .frame(height: headerHeight)
                .overlay {
                    headerContent
                }
                .zIndex(0)
            Spacer()
        }
    }

    private var headerContent: some View {
        VStack {
            if !isHeaderCollapsed {
                headerTopSection
            }
            progressCircleSection
        }
    }

    private var headerTopSection: some View {
        Group {
            if !revenueCatMonitor.userHasFullAccess {
                buildAdBannerView(.mainScreen)
                    .padding(.horizontal)
            }
            datePicker
        }
    }

    private var progressCircleSection: some View {
        HStack {
            ZStack {
                ProgressCircle(
                    ringWidth: isHeaderCollapsed
                        ? AnimationConstants.collapsedRingWidth
                        : AnimationConstants.expandedRingWidth,
                    percent: progressPercent,
                    foregroundColors: [.blue.opacity(0.55), .blue]
                )
                .overlay {
                    if !isHeaderCollapsed {
                        circleInformationView
                            .transition(.move(edge: .leading).combined(with: .blurReplace))
                    }
                }
                .padding(.horizontal, isHeaderCollapsed ? 0 : 16)
                .padding(.top, 4)
                .padding(.bottom, 12)
            }
            if isHeaderCollapsed {
                circleInformationView
                    .transition(.asymmetric(
                        insertion: .push(from: .trailing),
                        removal: .move(edge: .trailing)
                    ))
            }
        }
    }

    // MARK: - Content View

    var datePicker: some View {
        CustomDatePicker(selectedDate: $selectedDate)
    }

    @ViewBuilder
    var contentBackgroundView: some View {
        LazyVStack(spacing: 16, pinnedViews: []) {
            waterPortionsSection

            if isToday {
                todayCardsSection
            }

            Spacer(minLength: 500)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var waterPortionsSection: some View {
        if waterPortions.isEmpty {
            NoDrinksView()
        } else {
            LazyVGrid(columns: [.init()], spacing: 12) {
                ForEach(waterPortions) { waterPortion in
                    waterPortionItem(waterPortion)
                }
            }
        }
    }

    private func waterPortionItem(_ waterPortion: WaterPortion) -> some View {
        WaterVGridItemView(waterPortion: waterPortion)
            .onTapGesture {
                editingWaterPortion = waterPortion
            }
            .contextMenu {
                Button {
                    editingWaterPortion = waterPortion
                } label: {
                    Label("Change", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    remove(waterPortion)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
    }

    @ViewBuilder
    private var todayCardsSection: some View {
        if showWeatherCard {
            WeatherCardView()
                .environmentObject(revenueCatMonitor)
                .id("weather-card")
        }

        if showSleepCard {
            SleepCardView(isLoading: sleepService.isLoading)
                .environmentObject(revenueCatMonitor)
                .id("sleep-card")
        }

        if showStatisticsCard {
            StatisticsCard()
                .environmentObject(revenueCatMonitor)
                .id("statistics-card")
        }
    }

    private var isToday: Bool {
        selectedDate.rounded() == Date().rounded()
    }

    // MARK: - Circle Information View

    var circleInformationView: some View {
        VStack(spacing: isHeaderCollapsed ? 3 : 6) {
            percentageText
            hydrationDetailsStack
            goalText
        }
        .frame(
            maxWidth: .infinity,
            alignment: isHeaderCollapsed ? .leading : .center
        )
        .offset(x: isHeaderCollapsed ? -16 : 0)
    }

    private var percentageText: some View {
        Text(percentageDisplay)
            .font(.system(
                size: isHeaderCollapsed ? 16 : 44,
                weight: .bold,
                design: .rounded
            ))
            .contentTransition(.numericText())
    }

    private var hydrationDetailsStack: some View {
        VStack(spacing: isHeaderCollapsed ? 1 : 2) {
            Text(netHydrationDisplay)
                .font(isHeaderCollapsed
                    ? .caption2.weight(.semibold)
                    : .subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            if totalDehydrationMl(for: selectedDate) > 0 {
                dehydrationBadge
            }

            if totalCaffeineMg(for: selectedDate) > 0 {
                caffeineBadge
            }
        }
    }

    private var dehydrationBadge: some View {
        HStack(spacing: isHeaderCollapsed ? 3 : 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption2)
                .foregroundStyle(.orange)
            Text(dehydrationDisplay)
                .font(.caption2)
                .foregroundStyle(.orange)
        }
        .padding(.horizontal, isHeaderCollapsed ? 6 : 8)
        .padding(.vertical, isHeaderCollapsed ? 1 : 2)
        .background(
            RoundedRectangle(cornerRadius: isHeaderCollapsed ? 4 : 6)
                .fill(.orange.opacity(0.1))
        )
    }

    private var caffeineBadge: some View {
        HStack(spacing: isHeaderCollapsed ? 3 : 4) {
            Image(systemName: "bolt.fill")
                .font(.caption2)
                .foregroundStyle(.brown)
            Text("\(Int(totalCaffeineMg(for: selectedDate).rounded())) mg caffeine")
                .font(.caption2)
                .foregroundStyle(.brown)
        }
        .padding(.horizontal, isHeaderCollapsed ? 6 : 8)
        .padding(.vertical, isHeaderCollapsed ? 1 : 2)
        .background(
            RoundedRectangle(cornerRadius: isHeaderCollapsed ? 4 : 6)
                .fill(.brown.opacity(0.1))
        )
    }

    private var goalText: some View {
        Text(goalDisplay)
            .font(isHeaderCollapsed ? .caption2 : .caption)
            .foregroundStyle(.tertiary)
    }

    // MARK: - Calculations

    private var progressPercent: Double {
        let consumedMl = totalConsumedMl(for: selectedDate)
        let goalMl = Double(waterGoalMl)
        guard goalMl > 0 else { return 0 }
        return min(100, max(0, (consumedMl / goalMl) * 100))
    }

    /// Total net hydration in ml (accounting for hydration factors)
    private func totalConsumedMl(for date: Date?) -> Double {
        waterPortions.reduce(0) { sum, portion in
            // portion.amount is already in millilitres
            return sum + (portion.amount * portion.drink.hydrationFactor)
        }
    }

    /// Total raw consumption in ml (not accounting for hydration factors)
    private func totalRawConsumedMl(for date: Date?) -> Double {
        waterPortions.reduce(0) { sum, portion in
            // portion.amount is already in millilitres
            sum + portion.amount
        }
    }

    /// Total dehydration effect in ml (from dehydrating drinks)
    private func totalDehydrationMl(for date: Date?) -> Double {
        waterPortions.reduce(0) { sum, portion in
            // portion.amount is already in millilitres
            if portion.drink.hydrationFactor < 0 {
                return sum + (portion.amount * abs(portion.drink.hydrationFactor))
            }
            return sum
        }
    }

    /// Total caffeine consumed in mg
    private func totalCaffeineMg(for date: Date?) -> Double {
        waterPortions.reduce(0) { sum, portion in
            guard portion.drink.containsCaffeine else { return sum }

            // portion.amount is already in millilitres
            let caffeinePer100ml = caffeineContent(for: portion.drink)

            return sum + (portion.amount / 100.0) * caffeinePer100ml
        }
    }

    /// Returns caffeine content per 100ml for a given drink
    private func caffeineContent(for drink: Drink) -> Double {
        switch drink {
        case .coffee:
            return CaffeineContent.coffeePer100ml
        case .coffeeWithMilk:
            return CaffeineContent.coffeeWithMilkPer100ml
        case .tea:
            return CaffeineContent.teaPer100ml
        case .energyShot:
            return CaffeineContent.energyShotPer100ml
        default:
            return 0.0
        }
    }

    // MARK: - Display Strings

    private var percentageDisplay: String {
        "\(Int(progressPercent.rounded()))%"
    }

    private var netHydrationDisplay: String {
        let netHydrationMl = totalConsumedMl(for: selectedDate)
        let rawConsumedMl = totalRawConsumedMl(for: selectedDate)

        let isOunces = measurementUnits == "fl_oz"
        let netAmount = isOunces ? WaterUnit.ounces.fromMilliliters(netHydrationMl) : netHydrationMl
        let rawAmount = isOunces ? WaterUnit.ounces.fromMilliliters(rawConsumedMl) : rawConsumedMl
        let unit = isOunces ? "fl oz" : "ml"

        return "\(Int(netAmount.rounded())) \(unit) net (\(Int(rawAmount.rounded())) consumed)"
    }

    private var dehydrationDisplay: String {
        let dehydrationMl = totalDehydrationMl(for: selectedDate)

        let isOunces = measurementUnits == "fl_oz"
        let amount = isOunces ? WaterUnit.ounces.fromMilliliters(dehydrationMl) : dehydrationMl
        let unit = isOunces ? "fl oz" : "ml"

        return "\(Int(amount.rounded())) \(unit) dehydrated"
    }

    private var goalDisplay: String {
        let isOunces = measurementUnits == "fl_oz"
        let amount = isOunces ? WaterUnit.ounces.fromMilliliters(Double(waterGoalMl)) : Double(waterGoalMl)
        let unit = isOunces ? "fl oz" : "ml"

        return "Goal \(Int(amount.rounded())) \(unit)"
    }

    // MARK: - Add Drink Button

    var addDrinkButton: some View {
        Menu {
            Button {
                isPresentedDrinkSelector = true
            } label: {
                Label("Manual Input", systemImage: "hand.tap")
            }

            Button {
                isPresentedImagePicker = true
            } label: {
                Label("AI Photo Analysis", systemImage: "camera")
            }
        } label: {
            Image(systemName: "drop.circle.fill")
                .foregroundStyle(.blue)
                .font(.system(size: 74))
        }
    }

    // MARK: - Data Operations

    /// Saves a new drink entry to the model context and HealthKit
    func saveDrink(_ drink: Drink, _ amount: Double, date: Date) {
        // Convert amount to millilitres based on current measurement unit
        let unit = WaterUnit.fromString(measurementUnits)
        let amountInMl = unit.toMilliliters(amount)
        
        let waterPortion = WaterPortion(
            amount: amountInMl,
            drink: drink,
            createDate: date,
            dayDate: date.rounded()
        )
        modelContext.insert(waterPortion)
        try? modelContext.save()

        Task {
            await saveToHealthKit(drink: drink, amountInMl: amountInMl)
        }

        fetchWaterPortions(by: selectedDate ?? Date().rounded())
    }

    /// Saves drink data to HealthKit based on drink type (amount is already in ml)
    private func saveToHealthKit(drink: Drink, amountInMl: Double) async {
        // Save water intake for hydrating drinks
        if drink.hydrationCategory == .fullyHydrating ||
           drink.hydrationCategory == .mildDiuretic ||
           drink.hydrationCategory == .partiallyHydrating {
            await healthKitService.saveWaterIntake(
                amount: amountInMl * drink.hydrationFactor,
                unit: .millilitres,
                date: Date()
            )
        }

        // Save caffeine intake for caffeinated drinks
        if drink.containsCaffeine {
            await healthKitService.saveCaffeineIntake(
                amount: amountInMl,
                unit: .millilitres,
                date: Date()
            )
        }

        // Save alcohol intake for alcoholic drinks
        if drink.containsAlcohol {
            await healthKitService.saveAlcoholIntake(
                amount: amountInMl,
                unit: .millilitres,
                alcoholType: drink,
                date: Date()
            )
        }
    }

    /// Removes a water portion entry
    func remove(_ waterPortion: WaterPortion) {
        modelContext.delete(waterPortion)
        try? modelContext.save()
        fetchWaterPortions(by: selectedDate ?? Date().rounded())
    }

    /// Fetches water portions for the selected date
    func fetchWaterPortions(by selectedDate: Date) {
        let dayDate = selectedDate.rounded()
        let fetchDescriptor = FetchDescriptor<WaterPortion>(
            predicate: #Predicate { $0.dayDate == dayDate },
            sortBy: [.init(\WaterPortion.createDate, order: .reverse)]
        )

        do {
            waterPortions = try modelContext.fetch(fetchDescriptor)
        } catch {
            // Handle fetch errors silently
            waterPortions = []
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


