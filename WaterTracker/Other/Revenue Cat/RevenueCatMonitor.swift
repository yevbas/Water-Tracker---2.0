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

    static let shared = RevenueCatMonitor()

    var userHasFullAccess: Bool {
#if DEBUG
        switch state {
        case .default: return true
        case .preview(let isFullAccessAvailable): return isFullAccessAvailable
        }
#else
        customerInfo?.userHasFullAccess ?? false
#endif
    }

    private let customerInfoStream: AsyncStream<CustomerInfo>?
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
            self.customerInfoStream = Purchases.shared.customerInfoStream
            startListeningForUpdates()
        case .preview(_):
            self.customerInfoStream = nil
        }
    }

    deinit {
        updateTask?.cancel()
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
