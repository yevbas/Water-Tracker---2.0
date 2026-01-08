//
//  WelcomeView.swift
//  PlateAI
//
//  Created by Jackson  on 21/08/2025.
//

import SwiftUI
import Lottie

struct WelcomeView: View {
    var onContinue: () -> Void = { }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                LottieView(animation: .named("h2o-rocket"))
                    .animationSpeed(0.5)
                    .looping()
                VStack(alignment: .leading, spacing: 8) {
                    if #available(iOS 17.0, *) {
                        (Text("Welcome to") + Text("    Aquio").foregroundStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)))
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    } else {
                        Text("Welcome to Aquio")
                            font(.system(.largeTitle, design: .rounded, weight: .bold))
                    }
                    Text("Your body needs water to function properly. Start using Aquio to track your water intake and stay on track!")
                        .font(.title3)
                }
                .offset(y: -64)
            }
            .padding(.horizontal)
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(
                title: String(localized: "Let's start"),
                colors: [.blue, .cyan],
                action: onContinue
            )
            .shimmer()
            .padding(.horizontal, 24)
            .buttonStyle(BreathingButtonStyle())
        }
    }
}

#Preview {
    WelcomeView()
}


