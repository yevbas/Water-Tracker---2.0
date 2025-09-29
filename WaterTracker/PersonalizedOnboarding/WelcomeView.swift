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
            LottieView(animation: .named("plate"))
                .looping()
            VStack(alignment: .leading, spacing: 12) {
                if #available(iOS 17.0, *) {
                    (Text("Welcome to ") + Text("PlateAI").foregroundStyle(LinearGradient(colors: [.yellow, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)))
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                } else {
                    Text("Thanks for installing PlateAI")
                    font(.system(.largeTitle, design: .rounded, weight: .bold))
                }
                Text("You've just installed the best calorie counter app EVER!")
                    .font(.title2)
            }
            .offset(y: -64)
            PrimaryButton(
                title: String(localized: "Start!"),
                colors: [.yellow, .pink]
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
