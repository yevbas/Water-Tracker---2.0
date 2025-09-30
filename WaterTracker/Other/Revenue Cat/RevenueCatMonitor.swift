//
//  RevenueCatMonitor.swift
//  Weeshlist
//
//  Created by Jackson  on 18/04/2025.
//

import SwiftUI
import RevenueCat

// MARK: - Protocol for abstraction & testability
protocol RevenueCatMonitorProtocol {
    var userHasFullAccess: Bool { get }
}

// MARK: - RevenueCat Monitor using AsyncStream
final class RevenueCatMonitor: ObservableObject, RevenueCatMonitorProtocol {
    @Published private(set) var customerInfo: CustomerInfo?

    var userHasFullAccess: Bool {
#if DEBUG
        switch state {
        case .default: return false
        case .preview(let isFullAccessAvailable): return isFullAccessAvailable
        }
#else
        customerInfo?.userHasFullAccess ?? false
#endif
    }

    private var customerInfoStream: AsyncStream<CustomerInfo>?
    private var updateTask: Task<Void, Never>?
    private let state: MonitorState

    enum MonitorState {
        case `default`
        case preview(_ isFullAccessAvailable: Bool)
    }

    init(state: MonitorState = .default) {
        self.state = state

        switch state {
        case .default:
            // Check if Purchases is configured before accessing shared
            if Purchases.isConfigured {
                self.customerInfoStream = Purchases.shared.customerInfoStream
                startListeningForUpdates()
            } else {
                self.customerInfoStream = nil
                // Start listening once Purchases is configured
                Task {
                    await waitForPurchasesConfiguration()
                }
            }
        case .preview(_):
            self.customerInfoStream = nil
        }
    }

    deinit {
        updateTask?.cancel()
    }

    private func waitForPurchasesConfiguration() async {
        // Poll until Purchases is configured
        while !Purchases.isConfigured {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        // Now that Purchases is configured, set up the stream
        await MainActor.run {
            self.customerInfoStream = Purchases.shared.customerInfoStream
            startListeningForUpdates()
        }
    }
    
    private func startListeningForUpdates() {
        guard let customerInfoStream else { return }
        updateTask = Task {
            for await info in customerInfoStream {
                await MainActor.run {
                    self.customerInfo = info
                }
#if DEBUG
                print("🧾 Received customer info update: \(info)")
#endif
            }
        }
    }
}

// MARK: - Entitlement Helper
extension CustomerInfo {
    var userHasFullAccess: Bool {
        entitlements["full_access"]?.isActive ?? false
    }
}
