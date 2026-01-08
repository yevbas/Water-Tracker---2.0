//
//  ConfigureScreen.swift
//  WaterTracker
//
//  Created by Assistant on 29/09/2025.
//

import SwiftUI
import SwiftData

struct ConfigureScreen: View {
    let container: ModelContainer
    let healthKitService: HealthKitService?
    let onFinished: () -> Void

    @State private var isRunning = true

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                Text("Preparing your app...")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .task {
            if isRunning {
                await AppConfigurator.configureAll(container: container, healthKitService: healthKitService)
                isRunning = false
                onFinished()
            }
        }
    }
}

#Preview("ConfigureView") {
    let schema = Schema([WaterProgress.self, WaterPortion.self])
    let container = try! ModelContainer(for: schema, configurations: [.init(schema: schema, isStoredInMemoryOnly: true)])
    return ConfigureScreen(container: container, healthKitService: nil) {}
}


