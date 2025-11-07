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
    @State var isPresentedPaywall = false

    @AppStorage("user_did_decline_onboarding_paywall") var userDidDeclineOnboardingPaywall = false
    @AppStorage("user_did_fail_payment_on_onboarding_paywall") var userDidFailPaymentOnOnboardingPaywall = false

    #warning("Legacy discount paywall implementation. May be returned in next versions. Lately declined my apple Code of Conduct")
//    @State var isPresentedDiscountedPaywall = false

    var planPreview: PlanPreviewModel?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if #available(iOS 17.0, *) {
                    (Text("Try ") + Text("  Aquio PRO").foregroundStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)))
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
            }
        }
        .safeAreaInset(edge: .bottom, content: {
            VStack(spacing: 16) {
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
            .background()
        })
        .sheet(isPresented: $isPresentedPaywall) {
            paywallView()
        }
#warning("Legacy discount paywall implementation. May be returned in next versions. Lately declined my apple Code of Conduct")
//        .sheet(isPresented: $isPresentedDiscountedPaywall) {
//            discountedPaywallView()
//        }
    }

    @ViewBuilder
    private func paywallView() -> some View {
//        if (Purchases.shared.cachedOfferings?.all ?? [:]).isEmpty {
        PaywallView(displayCloseButton: true)
            .onPurchaseCompleted { _ in endOnboarding() }
            .onPurchaseCancelled {
                userDidDeclineOnboardingPaywall = true
                endOnboarding()
            }
            .onRequestedDismissal {
                userDidDeclineOnboardingPaywall = true
                endOnboarding()
            }
            .onPurchaseFailure { _ in
                userDidFailPaymentOnOnboardingPaywall = true
                endOnboarding()
            }
            .interactiveDismissDisabled()
        // TODO: Legacy discount paywall implementation. May be returned in next versions
//        } else {
//            PaywallView(displayCloseButton: true)
//                .onPurchaseCompleted { _ in endOnboarding() }
//                .onPurchaseCancelled {
//                    isPresentedPaywall = false
//                    isPresentedDiscountedPaywall = true
//                }
//                .onRequestedDismissal {
//                    isPresentedPaywall = false
//                    isPresentedDiscountedPaywall = true
//                }
//                .onPurchaseFailure { _ in endOnboarding() }
//                .interactiveDismissDisabled()
//        }
    }

#warning("Legacy discount paywall implementation. May be returned in next versions. Lately declined my apple Code of Conduct")
//    @ViewBuilder
//    private func discountedPaywallView() -> some View {
//        if let discountedOffering = Purchases.shared.cachedOfferings?.all["annual_discounted"] {
//            PaywallView(
//                offering: discountedOffering,
//                displayCloseButton: true
//            )
//            .onPurchaseCompleted { _ in endOnboarding() }
//            .onPurchaseCancelled { endOnboarding() }
//            .onRequestedDismissal { endOnboarding() }
//            .onPurchaseFailure { _ in endOnboarding() }
//            .interactiveDismissDisabled()
//        }
//    }

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
