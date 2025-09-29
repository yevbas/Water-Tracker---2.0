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

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { scroll in
                LazyHStack(spacing: 8) {
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
                        // 👇 trigger infinite prepend
//                        .onAppear {
//                            if date == dates.first {
//                                prependMoreDates()
//                            }
//                        }
                    }
                }
                .padding(.horizontal)
                .onAppear {
                    initiateDates()

                    // Scroll to today (last element) after layout
                    if let last = dates.last {
                        DispatchQueue.main.async {
                            scroll.scrollTo(last, anchor: .trailing)
                        }
                    }
                }
            }
        }
        .frame(height: viewHeight ?? 58)
    }

    private func initiateDates() {
        // 30 past days + today
        dates = (0...30).compactMap {
            Calendar.current.date(byAdding: .day, value: -$0, to: Date())?.rounded()
        }.reversed() // oldest → today
    }

    private func prependMoreDates() {
        guard let first = dates.first else { return }
        let newDates = (1...30).compactMap {
            Calendar.current.date(byAdding: .day, value: -$0, to: first)?.rounded()
        }.reversed()
        dates.insert(contentsOf: newDates, at: 0)
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
