//
//  ConfigureView.swift
//  WaterTracker
//
//  Created by Assistant on 29/09/2025.
//

import SwiftUI
import SwiftData

struct ConfigureView: View {
    let container: ModelContainer
    let onFinished: () -> Void

    @State private var isRunning = true

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                Text(String(localized: "Preparing your app…"))
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .task {
            if isRunning {
                await AppConfigurator.configureAll(container: container)
                isRunning = false
                onFinished()
            }
        }
    }
}

#Preview("ConfigureView") {
    let schema = Schema([WaterPortion.self])
    let container = try! ModelContainer(for: schema, configurations: [.init(schema: schema, isStoredInMemoryOnly: true)])
    return ConfigureView(container: container) {}
}


