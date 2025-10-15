//
//  ConvertUserView.swift
//  PlateAI
//
//  Created by Jackson  on 21/08/2025.
//

import SwiftUI
import RevenueCatUI
import RevenueCat

struct ConvertUserView: View {
    @State var isPresentedPaywall: Bool = false
    var planPreview: PlanPreviewModel?

    var body: some View {
        VStack(spacing: 16) {
            if #available(iOS 17.0, *) {
                (Text("Try ") + Text(" Aquio PRO").foregroundStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)))
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .padding(.horizontal)
            } else {
                Text("Try Aquio PRO")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .multilineTextAlignment(.center)
                .lineLimit(4)
            }
            Image(.appPreview)
                .resizable()
                .scaledToFill()
            VStack {
                Label("No payments due now", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                PrimaryButton(
                    title: String(localized: "Try for $0.00"),
                    colors: [.blue, .cyan]
                ) {
                    isPresentedPaywall = true
                }
                .padding(.horizontal)
                .shimmer()
            }
        }
        .sheet(isPresented: $isPresentedPaywall) {
            paywallView
        }
    }

    private var paywallView: some View {
        PaywallView(displayCloseButton: true)
            .onPurchaseCompleted { _ in endOnboarding() }
            .onPurchaseCancelled { endOnboarding() }
            .onRequestedDismissal { endOnboarding() }
            .onPurchaseFailure { _ in endOnboarding() }
            .interactiveDismissDisabled()
    }

    private func endOnboarding() {
        // Set the water goal based on the plan
        if let plan = planPreview {
            UserDefaults.standard.set(plan.waterMl, forKey: "water_goal_ml")
        }
        UserDefaults.standard.set(true, forKey: "onboarding_passed")
    }

}

#Preview {
    ConvertUserView()
}
