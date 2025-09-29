//
//  RateUsView.swift
//  PlateAI
//
//  Created by Jackson  on 21/08/2025.
//

import SwiftUI
import Lottie

struct RateUsView: View {
    var onContinue: () -> Void = { }

    @State var isPrimaryButtonEnabled = false

    var body: some View {
        VStack(spacing: 0) {
            LottieView(
                animation: .named("stars")
            )
            .playing(loopMode: .playOnce)
            .frame(height: 75)
            VStack(spacing: 16) {
                Text("Left rating for us!")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                Text("PlateAI makes hundreds of people daily closer to their health goals!")
                    .font(.system(.title, design: .rounded, weight: .regular))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }
            .padding(.horizontal)
            .padding(.top, 24)
            LottieView(
                animation: .named("plate")
            )
            .looping()
            Spacer()
            PrimaryButton(
                title: String(localized: "Continue"),
                isDisabled: !isPrimaryButtonEnabled
            ) {
                onContinue()
            }
            .padding(.horizontal)
        }
        .onAppear {
            WaterTrackerApp.requestReview()

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.75, execute: {
                self.isPrimaryButtonEnabled = true
            })
        }
    }
}

#Preview {
    RateUsView()
}
