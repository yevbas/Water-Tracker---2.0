//
//  CustomDatePicker.swift
//  WaterTracker
//
//  Created by Jackson  on 29/09/2025.
//

import SwiftUI

struct CustomDatePicker: View {
    @Binding var selectedDate: Date?
    @State private var dates: [Date] = []
    @State private var viewHeight: CGFloat?
    @State private var isPrepending: Bool = false
    @State private var showingDatePicker = false
    @State private var hasInitialized = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { scroll in
                LazyHStack(spacing: 8) {
                    // Date picker item at the beginning
                    Button {
                        showingDatePicker = true
                    } label: {
                        buildDatePickerButtonContent()
                            .background {
                                RoundedRectangle(cornerRadius: 16)
                                    .foregroundStyle(.ultraThinMaterial)
                            }
                    }
                    .id("datePicker")
                    .buttonStyle(.plain)
                    
                    ForEach(dates, id: \.self) { date in
                        Button {
                            selectedDate = date
                        } label: {
                            buildButtonContent(for: date)
                                .background {
                                    RoundedRectangle(cornerRadius: 16)
                                        .foregroundStyle(.ultraThinMaterial)
                                }
                        }
                        .id(date)
                        .buttonStyle(.plain)
                        .background {
                            if viewHeight == nil {
                                GeometryReader { proxy in
                                    Color.clear.onAppear {
                                        viewHeight = proxy.size.height
                                    }
                                }
                            }
                        }
                        .onAppear {
                            // Prepend more dates when reaching the first date
                            if date == dates.first && !isPrepending {
                                prependMoreDates()
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .onAppear {
                    initiateDates()
                    
                    // Only set today as selected and scroll to it on first initialization
                    if !hasInitialized {
                        hasInitialized = true
                        if selectedDate == nil, let today = dates.last {
                            selectedDate = today
                        }
                        
                        // Scroll to the currently selected date (or today if none selected)
                        let dateToScrollTo = selectedDate ?? dates.last
                        if let targetDate = dateToScrollTo {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    scroll.scrollTo(targetDate, anchor: .center)
                                }
                            }
                        }
                    } else {
                        // On subsequent appearances, just scroll to the currently selected date
                        if let currentDate = selectedDate {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    scroll.scrollTo(currentDate, anchor: .center)
                                }
                            }
                        }
                    }
                }
            }
        }
        .frame(height: viewHeight ?? 58)
        .sheet(isPresented: $showingDatePicker) {
            datePickerSheet
        }
    }

    private func initiateDates() {
        // Get last month's dates + current month up to today
        let calendar = Calendar.current
        let today = Date()
        
        // Get first day of last month
        guard let firstDayOfLastMonth = calendar.dateInterval(of: .month, for: calendar.date(byAdding: .month, value: -1, to: today)!)?.start else { return }
        
        // Get all days from first day of last month to today
        var allDates: [Date] = []
        var currentDate = firstDayOfLastMonth
        
        while currentDate <= today {
            allDates.append(currentDate.rounded())
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        dates = allDates
    }

    private func prependMoreDates() {
        guard !isPrepending, let first = dates.first else { return }
        isPrepending = true
        
        let newDates = (1...30).compactMap {
            Calendar.current.date(byAdding: .day, value: -$0, to: first)?.rounded()
        }.reversed()
        
        dates.insert(contentsOf: newDates, at: 0)
        
        // Reset prepending flag
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isPrepending = false
        }
    }

    func buildButtonContent(for date: Date) -> some View {
        VStack(spacing: 8) {
            Text(Calendar.current.shortWeekdaySymbols[date.dayOfWeek - 1])
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(date.day.description)
                .font(.headline)
        }
        .foregroundStyle(selectedDate == date ? .blue : .primary)
        .padding()
    }
    
    func buildDatePickerButtonContent() -> some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Pick")
                .font(.headline)
        }
        .foregroundStyle(.primary)
        .padding()
    }
    
    private var datePickerSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                DatePicker(
                    "Select Date",
                    selection: Binding(
                        get: { selectedDate ?? Date() },
                        set: { selectedDate = $0.rounded() }
                    ),
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()
                
                Spacer()
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingDatePicker = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showingDatePicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

extension Date {
    var day: Int { Calendar.current.component(.day, from: self) }
    var dayOfWeek: Int { Calendar.current.component(.weekday, from: self) }

    func rounded() -> Date {
        let calendar = Calendar.current
        let comps = DateComponents(
            year: calendar.component(.year, from: self),
            month: calendar.component(.month, from: self),
            day: calendar.component(.day, from: self),
            hour: 12
        )
        return calendar.date(from: comps) ?? self
    }
}


#Preview {
    CustomDatePicker(selectedDate: .constant(Date().rounded()))
}
