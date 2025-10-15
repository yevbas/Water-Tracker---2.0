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
        VStack(spacing: 24) {
            LottieView(animation: .named("h2o-rocket"))
                .animationSpeed(0.5)
                .looping()
            VStack(alignment: .leading, spacing: 12) {
                if #available(iOS 17.0, *) {
                    (Text("Welcome to ") + Text(" Aquio").foregroundStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)))
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                } else {
                    Text("Thanks for installing Aquio")
                    font(.system(.largeTitle, design: .rounded, weight: .bold))
                }
                Text("Stay hydrated with a personalized daily water goal.")
                    .font(.title2)
            }
            .offset(y: -64)
            PrimaryButton(
                title: String(localized: "Start!"),
                colors: [.blue, .cyan]
            ) {
                onContinue()
            }
            .shimmer()
            .padding(.horizontal)
        }
        .padding(.horizontal)
    }
}

#Preview {
    WelcomeView()
}
