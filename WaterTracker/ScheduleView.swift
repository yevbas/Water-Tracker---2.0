//
//  ScheduleView.swift
//  WaterTracker
//
//  Created by Jackson  on 10/09/2025.
//

import SwiftUI

struct ScheduleView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    Spacer()
                    Text(Date().formatted(date: .omitted, time: .shortened))
                }
                HStack {
                    Spacer()
                    Text(Date().formatted(date: .omitted, time: .shortened))
                }
                HStack {
                    Spacer()
                    Text(Date().formatted(date: .omitted, time: .shortened))
                }
            }
            .padding(.horizontal)
        }
//        .navigationTitle("Water Schedule")
//        .listStyle(.plain)
//        .toolbar {
//            ToolbarItem(placement: .topBarLeading) {
//                Button {
//
//                } label: {
//                    Image(systemName: "info.circle")
//                }
//            }
//            ToolbarItem(placement: .topBarTrailing) {
//                Button {
//
//                } label: {
//                    Image(systemName: "plus.circle")
//                }
//            }
//        }
    }

//    var addButton: some View {
//        Button {
//
//        } label: {
//            RoundedRectangle(cornerRadius: 16)
//                .fill(.ultraThinMaterial)
//                .frame(height: 55)
//                .overlay {
//                    Image(systemName: "plus")
//                }
//        }
//    }

}

#Preview {
    NavigationStack {
        ScheduleView()
    }
}
