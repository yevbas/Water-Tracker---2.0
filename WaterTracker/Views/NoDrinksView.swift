//
//  NoDrinksView.swift
//  WaterTracker
//
//  Created by Jackson  on 19/09/2025.
//

import SwiftUI
import Lottie

struct NoDrinksView: View {
    var minHeight: CGFloat = 200

    var body: some View {
//        Label("No drink found", systemImage: "magnifyingglass")
//            .frame(
//                maxWidth: .infinity,
//                minHeight: minHeight,
//                maxHeight: .infinity
//            )
//            .font(.title.weight(.medium))

        RoundedRectangle(cornerRadius: 24)
            .fill(.ultraThinMaterial)
            .overlay {
                VStack {
                    LottieView(animation: .named("h2o-rocket"))
                        .looping()
//                        .frame(height: 120)
                    Text("No drinks found")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .padding()
                }
            }
            .frame(height: 200)
    }
}

#Preview {
    NoDrinksView()
}
