//
//  Shimmer.swift
//  PlateAI
//
//  Created by Jackson  on 21/05/2025.
//

import SwiftUI

struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = -0.6

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, .white.opacity(0.6), .clear]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .rotationEffect(.degrees(30))
                    .offset(x: geometry.size.width * phase)
                    .blendMode(.overlay)
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1.6
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        self.modifier(Shimmer())
    }
}
